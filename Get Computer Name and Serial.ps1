# Import the Active Directory module
Import-Module ActiveDirectory

# Specify the OU path
$ouPath = "OU=Workstations,DC=PremPnut,DC=local"

# Get all computers from the specified OU
$computers = Get-ADComputer -Filter * -SearchBase $ouPath -Properties Name, SerialNumber

# Output computer name and serialNumber to CSV file
$outputFile = "C:\Data\serials.csv"
$outputData = @()

foreach ($computer in $computers) {
    $computerName = $computer.Name
    $serialNumber = $computer.SerialNumber -join ','  # Convert collection to string

    $outputData += [PSCustomObject]@{
        'ComputerName' = $computerName
        'SerialNumber' = $serialNumber
    }
}

$outputData | Export-Csv -Path $outputFile -NoTypeInformation
Write-Host "Results exported to $outputFile"