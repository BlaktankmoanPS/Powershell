[string]$userName = "your email"
[string]$userPassword = "your password"
    
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
    
function Get-DaysToExpire($date) {

    $today = Get-Date; $ts = New-Timespan -Start $today -End $date; $ts.Days
}
Get-ADUser -filter { Enabled -eq $True -and PasswordNeverExpires -eq $False } –Properties "DisplayName", "mail", "msDS-UserPasswordExpiryTimeComputed" | ? { $_.mail -ne $null } |
Select-Object -Property "Displayname", @{Name = "ExpiryDate"; Expression = { [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed") } }, "mail", 
@{Name = "Days"; Expression = { Get-DaysToExpire([datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")) } } | ? { 
    $_.Days -lt 5 -and $_.Days -gt 0
} | % {
    Write-Host "Send Mail to $($_.DisplayName): $($_.mail), $($_.Days), $($_.ExpiryDate.ToString('MM/dd/yyyy hh:mm tt'))"
    Send-MailMessage -To $($_.mail) -Subject "Network account password expires in $($_.Days) days" -Body "Your network password is going to expire in $($_.Days) days. Please change your password prior to $($_.ExpiryDate)" -From "ppreports@premiumpnut.com" -SmtpServer "smtp.office365.com" -Port "587" -UseSsl -Credential $credObject
}
