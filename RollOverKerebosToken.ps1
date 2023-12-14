# $creds need to be in SAMAccountName Format ie PREMPNUT\username
$creds = Get-Credential

cd 'C:\Program Files\Microsoft Azure Active Directory Connect'

Import-Module .\AzureADSSO.psd1

New-AzureADSSOAuthenticationContext


Get-AzureADSSOStatus | ConvertFrom-Json

Update-AzureADSSOForest -OnPremCredentials $creds
