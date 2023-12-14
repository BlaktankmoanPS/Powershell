Import-Module ActiveDirectory
$UserList=Get-ADUSER -Filter * -SearchScope Subtree -SearchBase “OU=Employees, DC=PremPnut, DC=local”
foreach ($User in $UserList) {Set-ADUSER $user -clear proxyAddresses}