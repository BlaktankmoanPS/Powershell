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
