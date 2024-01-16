$domainName = "prempnut.local"
$localAccount = "Employee"
$newPassword = "whatever password you use"

$computers = Get-ADComputer -Filter * -SearchBase "OU=Surfaces,OU=Workstations,DC=PremPnut,DC=local" -Server $domainName |
             Select-Object -ExpandProperty Name

foreach ($computer in $computers) {
    $computerName = $computer + ".$domainName"

    if (Test-Connection -ComputerName $computerName -Count 1 -Quiet) {
        try {
            $localAccountObj = [adsi]("WinNT://$computerName/$localAccount,user")
    
            if ($localAccountObj -ne $null) {
                $localAccountObj.SetPassword($newPassword)
                $localAccountObj.SetInfo()
                Write-Host "Updated password for $localAccount on $computer"
            } else {
                Write-Host "Local account $localAccount not found on $computer" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Failed to update password for $localAccount on $computer" -ForegroundColor Red
        }
    } else {
        Write-Host "Connection to $computer failed or network path not found" -ForegroundColor Red
    }
}
