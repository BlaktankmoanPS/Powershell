# Check if the script is running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script as an administrator."
    Exit
}

# Get the drive letter you want to encrypt (e.g., C:)
$driveLetter = "C:"

# Check if BitLocker is available on the system
if ((Get-BitLockerVolume -MountPoint $driveLetter -ErrorAction SilentlyContinue) -eq $null) {
    Write-Host "BitLocker is not available on this system or the drive letter is incorrect."
    Exit
}

# Check if BitLocker is already enabled on the drive
if ((Get-BitLockerVolume -MountPoint $driveLetter).VolumeStatus -eq "FullyEncrypted") {
    Write-Host "BitLocker is already enabled and the drive is fully encrypted."
    Exit
}



# Enable BitLocker on the specified drive
Enable-BitLocker -MountPoint $driveLetter -RecoveryPasswordProtector -SkipHardwareTest

Write-Host "BitLocker has been enabled on the drive. Encryption is in progress."
