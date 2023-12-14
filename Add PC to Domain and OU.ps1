$Domain = "prempnut.local"
Write-Host "Please enter your desired computer name: [Default $env:computername]:"
$computername = Read-Host

$renamecomputer = $true
if ($computername -eq "" -or $computername -eq $env:computername) { $computername = $env:computername; $renamecomputer = $false }

Write-Host "Please enter your desired location [1-4] [Default 1]:
1. Desktops
2. Laptops
3. Surface Tablets
4. Excluded PCs"
$ou = Read-Host

$validate = $false
if ($ou -eq "" -or $ou -eq "1") { $ou = "OU=Desktops,OU=Workstations,DC=PremPnut,DC=local"; $validate = $true }
if ($ou -eq "2") { $ou = "OU=Laptops,OU=Workstations,DC=PremPnut,DC=local"; $validate = $true }
if ($ou -eq "3") { $ou = "OU=Surface Tablets,OU=Workstations,DC=PremPnut,DC=local"; $validate = $true }
if ($ou -eq "4") { $ou = "OU=Excluded PCs,OU=Workstations,DC=PremPnut,DC=local"; $validate = $true }
if ($validate -eq $false) { Write-Host "Invalid input, defaulting to [1]."; $ou = "OU=Desktops,OU=Workstations,DC=PremPnut,DC=local"}


$credentials = Get-Credential
Write-Host "Adding $computername to the domain"
Add-Computer -Domain $Domain -OUPath $ou -NewName $computername -Credential $Credential -Restart -Force
