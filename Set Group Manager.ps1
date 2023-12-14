# Import the Active Directory module
Import-Module ActiveDirectory

# Get all Security Groups in Active Directory
$securityGroups = Get-ADGroup -Filter {GroupCategory -eq 'Security'} -Properties ManagedBy

# Get the Enterprise Admins group
$enterpriseAdmins = Get-ADGroup -Filter {Name -eq 'Enterprise Admins'}

# Iterate through each Security Group
foreach ($securityGroup in $securityGroups) {
    # Assign Enterprise Admins group as the manager
    $securityGroup | Set-ADGroup -ManagedBy $enterpriseAdmins.DistinguishedName
    Write-Host "Assigned Enterprise Admins as the manager for $($securityGroup.Name)"
}