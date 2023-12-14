#Check to see if User is running on Prep-UTIL01
# Prompt for confirmation
$confirmMsg = "Are you running the script on the Utility Server? (Yes/No)"
$confirmResult = [System.Windows.Forms.MessageBox]::Show($confirmMsg, "Confirmation", "YesNo", "Question")

if ($confirmResult -eq "Yes") {
    # Continue running the script
    Write-Host "Continuing script execution..."
}
else {
    # Display "DUMBASS" pop-up and stop the script
    $dumbassMsg = "DUMBASS"
    [System.Windows.Forms.MessageBox]::Show($dumbassMsg, "Error", "OK", "Error")
    Write-Host "Script stopped."
    Exit
}

#User Information
$first = Read-Host -Prompt "Enter First Name"
$initial = Read-Host -Prompt "Enter Initial (leave blank if not needed)"
$last = Read-Host -Prompt "Enter Last Name"
$display = "$first $last"
$username = $first + $initial + "." + $last.ToLower()
$title = Read-Host -Prompt "Enter Job Title"
$dept = Read-Host -Prompt "Enter Department"
$supervisor = Read-Host -Prompt "Enter user name of supervisor/manager"

#Sets Address Tab, OU, & Homefolder Lcoation
$street = "311 Barrington Road"
$city = "Douglas"
$state = "Georgia"
$zip = "31535"
$country = "us"
$password = "~Today2023!!"
$passwordsecure = ConvertTo-SecureString -String $password -AsPlainText -Force
$company = "Premium Peanut, LLC."
$ou = "OU=Employees,DC=PremPnut,DC=local"
$email = $username + "@premiumpnut.com"

#Checks for duplicate user, and starts user creation process
$usercheck = Get-ADUser -filter { SamAccountName -eq $username } -ErrorAction SilentlyContinue
if ($usercheck)
{
    Write-Warning "User:$username already exists"
}
else{
    New-ADUser -Name $display -GivenName $first -Surname $last -Path $ou -ChangePasswordAtLogon $true -Enabled $true -Email $email `
            -AccountPassword $passwordsecure -StreetAddress $street -City $city -State $state `
             -PostalCode $zip `
             -Title $title -DisplayName $display -Department $dept -Company $company -SamAccountName $username -Country $country `
              -UserPrincipalName "$first.$last@premiumpnut.com"

    If ($supervisor) {
        Set-ADUser -Identity "$first.$last" -Manager $supervisor
        }

    Set-ADUser -Identity "$first.$last" -Add @{Proxyaddresses="SMTP:$first.$last@premiumpnut.com", "smtp:$first.$last@premiumpeanut.com", "smtp:$first.$last@premiumpeanutllc.com"}
    $user = Get-ADUser $username -Properties SamAccountName,ProxyAddresses
    $user.ProxyAddresses.add("SMTP:$($email)")

    Write-Host "User: $username created. Password: $password" -ForegroundColor Green
}
$user = Get-ADUser -filter { SamAccountName -eq $username } -ErrorAction SilentlyContinue

if ($user)
{
    $copy = Read-Host "Would you like to copy rights from existing user? (Y or N)"
    if ($copy -ieq "Y" -or $copy -ieq "Yes")
    {
            $copyuser = Read-Host "Enter User to copy rights"

            $usertocopy = Get-ADUser -filter { SamAccountName -eq $copyuser } -ErrorAction SilentlyContinue

            if ($usertocopy)
            {
                Get-ADPrincipalGroupMembership -Identity $usertocopy | ForEach-Object `
                    { `
                        $group = $_
                        if (-not (Get-ADPrincipalGroupMembership -Identity $user | Where-Object { $_.DistinguishedName -eq $group } ) ) { `
                            Write-Host "$($_.Name) Added"
                            Add-ADPrincipalGroupMembership -Identity $user -MemberOf $_ `
                        }`
                    }
            }
            else {
                Write-Host "$usertocopy is not a valid username" -ForegroundColor Red
            }
    }
    else 
    {    
        $groups = Get-ADGroup -Filter {GroupScope -eq "Global" } | Select Name | Sort-Object -Property Name | Out-GridView -Title "Select Groups to assign" -OutputMode Multiple
        $i=0;
        Write-Host "Assigning Groups...`n`n" -ForegroundColor Green    
        $groups | ForEach-Object `
        { 
            $complete = $i/$groups.Count
            Write-Progress -Activity "Assigning Groups..." -Status "Assigning Group: $($_.Name)" -PercentComplete $complete;
            $group = Get-ADGroup $_.Name -ErrorAction SilentlyContinue
            if ($group) 
            { 
                Add-ADPrincipalGroupMembership -Identity $username -MemberOf $_.Name -ErrorAction SilentlyContinue
                Write-Host "Group: $($_.Name) added" -ForegroundColor Green
            } 
            else {
                Write-Error "Group:$($_.Name) doesn't exist."
            }
            $i++;
        }
    }
}
#Creates the HomeDrive Folder since we were having issues with it not being created using the script vs manually creating accounts. 
#New-Item -Path \\prep2012\users\$username -ItemType directory -force   NO LONGER NEEDED SINCE MOVE TO ONEDRIVE!!
 
# AzureAD Sync
$server = "Prep-UTIL01"

# Prompt for credentials
$credentials = Get-Credential

# Create a session to the remote server using the provided credentials
$session = New-PSSession -ComputerName $server -Credential $credentials

# Invoke the Delta Sync command remotely
Invoke-Command -Session $session -ScriptBlock {
    #Import Module
    Import-Module ADSync
    # Run the Delta Sync command
    Start-ADSyncSyncCycle -PolicyType Delta
}

# Show pop-up box
$wshell = New-Object -ComObject Wscript.Shell
$popUpResult = $wshell.Popup("Pausing Script to do shit in the background", 0, "Pausing Script to do shit in the background", 1)

# Pause execution 
Start-Sleep -Seconds 60

# Continue execution once OK is clicked
Write-Host "Script resumed." is clicked
Write-Host "Script resumed."

$server = "Prep-UTIL01"

# Invoke the Delta Sync command remotely
Invoke-Command -Session $session -ScriptBlock {
    #Import Module
    Import-Module ADSync
    # Run the Delta Sync command
    Start-ADSyncSyncCycle -PolicyType Delta
}

# Close the session
Remove-PSSession -Session $session

#Enable MFA 
# Connect to Microsoft Online Service
Connect-MsolService

#Get Username
$user = Read-Host -Prompt "Enter Email Address"

# Create the StrongAuthenticationRequirement Object
$sa = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$sa.RelyingParty = "*"
$sa.State = "Enabled"
$sar = @($sa)

# Enable MFA for the user
Set-MsolUser -UserPrincipalName $user -StrongAuthenticationRequirements $sar
