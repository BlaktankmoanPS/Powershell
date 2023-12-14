# Set Execution Policy
# Set-ExecutionPolicy Unrestricted

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