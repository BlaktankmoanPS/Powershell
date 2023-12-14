#Install-Module -Name ExchangeOnlineManagement -RequiredVersion 3.1.0
#Import-Module ExchangeOnlineManagement -RequiredVersion 3.1.0

# Prompt for the user's email address
$userEmailAddress = Read-Host -Prompt "Enter the user's email address"

# Connect to Azure Active Directory
Connect-AzureAD

# Get the user object based on the email address
$user = Get-AzureADUser -Filter "Mail eq '$userEmailAddress'"
$username = $user.UserPrincipalName
$userDisplay = $user.DisplayName

# Set location to write file
Set-Location "\\prep2012\IT Drive\Onboarding and Offboarding\Offboarding"

if ($user) {
    # Retrieve all Active Directory groups for the user
    $adGroups = Get-AzureADUserMembership -ObjectId $user.ObjectId |
                Where-Object {$_.ObjectType -eq "Group"} |
                Select-Object -ExpandProperty DisplayName

    # Retrieve all M365 groups (Office 365 groups) for the user                    
    Connect-ExchangeOnline
    $m365Groups = Get-UnifiedGroup | where { (Get-UnifiedGroupLinks $_.PrimarySmtpAddress -LinkType Members | foreach {$_.Name}) -contains "$username" } | Select DisplayN

    $distributionLists = Get-DistributionGroup | 
                         Where-Object { (Get-DistributionGroupMember $_.Name | 
                        ForEach-Object {$_.PrimarySmtpAddress}) -contains "$username"}

    # Output the groups to a text file
    $outputFileName = $userEmailAddress.Replace("@", "_") + "_GroupInformation.txt"
    $outputFilePath = "$outputFileName"
    $outputContent = ""

    if ($adGroups) {
        $outputContent += "Active Directory Groups:`r`n"
        $outputContent += $adGroups -join "`r`n"
        $outputContent += "`r`n`r`n"
    } else {
        $outputContent += "No Active Directory Groups found.`r`n`r`n"
    }

    if ($m365Groups) {
        $outputContent += "M365 Groups:`r`n"
        $outputContent += $m365Groups.DisplayName -join "`r`n"
        $outputContent += "`r`n`r`n"
    } else {
        $outputContent += "No M365 Groups found.`r`n`r`n"
    }

    if ($distributionLists) {
        $outputContent += "Distribution Lists:`r`n"
        $outputContent += $distributionLists -join "`r`n"
    } else {
        $outputContent += "No Distribution Lists found.`r`n"
    }

    $outputContent | Out-File -FilePath $outputFilePath

    Write-Host "Group information exported to $outputFilePath"
} else {
    Write-Host "User not found. Please check the email address and try again."
}

# Disconnect from Azure Active Directory
Disconnect-AzureAD
Disconnect-ExchangeOnline -Confirm:$false

Function Remove-Runspace {

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "id")]
    [Outputtype("None")]

    Param
    (
        [Parameter(Mandatory, Position = 0, ParameterSetName = "id")]
        [ValidateNotNullorEmpty()]
        [int32]$ID,

        [Parameter(Mandatory, ValueFromPipeline, Position = 0, ParameterSetName = "runspace")]
        [System.Management.Automation.Runspaces.Runspace]$Runspace
    )

    Begin {
        Write-Verbose "Starting $($MyInvocation.Mycommand)"
    } #begin

    Process {
        if ($id) {
            Write-Verbose "Getting runspace ID $id"
            $runspace = Get-Runspace -id $id
            if (-not $Runspace) {
                Throw "Failed to find a runspace with an id of $id"
            }

        }
        Write-Verbose "Removing runspace $($runspace.id)"
        if ($PSCmdlet.ShouldProcess("$($Runspace.id) - $($Runspace.name)")) {
            if ($Runspace.RunspaceStateInfo -eq "closing" -OR $runspace.RunspaceAvailability -eq "busy") {
                Write-Warning "Can't remove this runspace in its current state"
                Write-Warning ($runspace | Out-String)
            }
            else {
                $Runspace.close()
                $Runspace.dispose()
            }
        }
    } #process


    End {
        Write-Verbose "Ending $($MyInvocation.Mycommand)"
    } #end

} #close function

Get-Runspace | foreach { Remove-Runspace $_.Id }

# Convert to Shared Mailbox and Strip License

# Import Modules
Import-Module ExchangeOnlineManagement
Import-Module AzureAD

# Connect to Office 365
Connect-ExchangeOnline

# Prompt for the email address
$UserAccount = Read-Host "Enter the email address of the user account"

# Convert the user mailbox to a shared mailbox
Set-Mailbox -Identity $UserAccount -Type Shared

# Remove Microsoft 365 Business Standard license from the user account
$HasLicenses =  Get-MsolUser -UserPrincipalName $UserAccount | select Licenses | ForEach { if($_.Licenses.AccountSkuID -eq "appriver3651009581:O365_BUSINESS_PREMIUM") { $true } }

if ($HasLicenses) {
    Set-MsolUserLicense -UserPrincipalName $UserAccount -RemoveLicenses "appriver3651009581:O365_BUSINESS_PREMIUM"
}

# Disable AD User Account and move it to Disabled Employees OU

#Import Module
Import-Module ActiveDirectory

# Prompt for the username
$SamAccountName = Read-Host "Enter the username"

# Set the path for the output text file
$OutputPath = "\\prep2012\IT Drive\Onboarding and Offboarding\Offboarding\$SamAccountName`_groups.txt"

# Connect to the Active Directory module
Import-Module ActiveDirectory

# Retrieve the user's groups
$UserGroups = Get-ADUser -Identity $SamAccountName -Properties MemberOf |
              Select-Object -ExpandProperty MemberOf

# Remove the user from all groups
foreach ($Group in $UserGroups) {
    Remove-ADGroupMember -Identity $Group -Members $SamAccountName -Confirm:$false
}

# Disable the user account
Set-ADUser -Identity $SamAccountName -Enabled $false

# Move the account to the Disabled Users OU
$TargetOU = "OU=Disabled Users,OU=Employees,DC=PremPnut,DC=local"
Get-ADUser -Identity $SamAccountName |
    Move-ADObject -TargetPath $TargetOU

# Output the user's groups to a text file
$UserGroups | Out-File -FilePath $OutputPath -Encoding UTF8

# Output a success message
Write-Host "User '$SamAccountName' has been removed from all groups, disabled, and moved to the Disabled Users OU."
Write-Host "Group information has been saved to: $OutputPath"
