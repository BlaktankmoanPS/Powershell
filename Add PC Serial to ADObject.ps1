# Prompt user for computer name
$computerName = Read-Host -Prompt "Enter the computer name"

# Use WMI to retrieve the serial number
try {
    $serialNumber = Get-WmiObject -Class Win32_BIOS -ComputerName $computerName | Select-Object -ExpandProperty SerialNumber
    if ($serialNumber -ne $null) {
        Write-Host "Serial number for computer '$computerName' is: $serialNumber"

        # Set the AD attribute to update
        $adAttributeName = "serialNumber"

        # Construct the LDAP path for the computer
        $ldapPath = "LDAP://" + (Get-ADComputer -Filter {Name -eq $computerName}).DistinguishedName

        # Get the AD computer object
        $adComputer = [ADSI] $ldapPath

        # Set the serial number to the specified attribute
        $adComputer.Put($adAttributeName, $serialNumber)
        $adComputer.SetInfo()

        Write-Host "Serial number '$serialNumber' has been written to the computer '$computerName' AD object attribute '$adAttributeName'."
    } else {
        Write-Host "Unable to retrieve serial number for computer '$computerName'."
    }
} catch {
    Write-Host "Error: $_"
}
