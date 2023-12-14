# Prompt for computer name
$computerName = Read-Host "Enter the computer name"

# Prompt for computer type
$computerType = Read-Host "Enter the computer type (Laptops, Desktops, Surface Tablets)"

# Determine the appropriate OU based on the computer type
switch ($computerType) {
    "Laptops" { $ou = "Laptops" }
    "Desktops" { $ou = "Desktops" }
    "Surface Tablets" { $ou = "Surface Tablets" }
    default {
        Write-Host "Invalid computer type entered."
        exit
    }
}

# Construct the DN (Distinguished Name) based on the computer name and type
$computerDN = "CN=$computerName, OU=$ou, OU=Workstations, DC=PremPnut, DC=local"

# Retrieve serial number using wmic
$serialNumber = Invoke-Command { cmd.exe /c "wmic bios get serialnumber" } | Out-String
$serialNumber = $serialNumber -ireplace "SerialNumber", ""
$serialNumber = $serialNumber -ireplace "`n", ""
$serialNumber = $serialNumber -ireplace "`r", ""
$serialNumber = $serialNumber -ireplace " ", ""
$serialNumber = $serialNumber -ireplace "`t", ""

# Set the serialNumber attribute in Active Directory
Set-ADObject -Identity $computerDN -Replace @{serialNumber = $serialNumber}
