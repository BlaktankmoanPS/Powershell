#Define Programs to Install and their locations
$Executables = @()
$BitDefender = '\\prep2012\SharedFiles\IT Program Files\Chris Scripts\Installers\epskit_x64'
$Chrome = '\\prep2012\SharedFiles\IT Program Files\Chris Scripts\Installers\ChromeSetup.exe'
$Dameware = '\\prep2012\SharedFiles\IT Program Files\Chris Scripts\Installers\DamewareAgent.msi'
$NetExtender = '\\prep2012\SharedFiles\IT Program Files\Chris Scripts\Installers\NXSetupU.exe'
$Office = '\\prep2012\SharedFiles\IT Program Files\Chris Scripts\Installers\OfficeSetup.exe'
$Executables += $BitDefender
$Executables += $Chrome
$Executables += $Dameware
$Executables += $NetExtender
$Executables += $Office
foreach ($executable in $Executables) {
    #Install the programs
    Start-Process -FilePath $executable -Wait
    $Shell = New-Object -ComObject "WScript.Shell"
    $Button = $Shell.Popup("Click OK When it's done, Guillermo.", 0, "Program is Installing", 0)
}
