Add-Type -AssemblyName System.Windows.Forms

function Create-Button {
    param (
        [string]$name,
        [int]$x,
        [int]$y
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($x, $y)
    $button.Size = New-Object System.Drawing.Size(150, 23)
    $button.Text = $name
    $button.Name = $name
    $form.Controls.Add($button)

    $button.Add_Click({
        ButtonClick -Sender $this
   })
}

function Restart-Server {
    param (
        [string]$serverName
    )

    Restart-Computer -ComputerName "$serverName.prempnut.local" -Force
}

function ButtonClick {
[CmdletBinding()]
param (
    [Object]$Sender
)
     $sender.BackColor = [System.Drawing.Color]::Yellow
        $serverName = $sender.Name
        Restart-Server $serverName
        Start-Sleep -Seconds 30
        if (Wait-ForServerToRestart $serverName) {
            $sender.BackColor = [System.Drawing.Color]::LimeGreen
        }else{
            $sender.BackColor = [System.Drawing.Color]::Red
        }
}

function Wait-ForServerToRestart {
    param (
        [string]$serverName
    )

    $timeout = 300  # 5 minutes timeout (adjust as needed)
    $startTime = Get-Date

    while ((Get-Date) -lt ($startTime.AddSeconds($timeout))) {
        Start-Sleep -Seconds 5
        if (Test-Connection -ComputerName "$serverName.prempnut.local" -Count 2 -Quiet) {
            return $true
        }
    }

    # If the server did not come back online within the timeout
    return $false
    #throw "Server $serverName did not restart within the specified timeout."
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Server Restart Control"
$form.Size = New-Object System.Drawing.Size(400, 300)

# Create buttons
$buttonNames = @(
    "Prep-DC01", "Prep-FS01", "Prep-Util01", "Prep-RDS01", "Prep-App01",
    "Prep-SQLProd01", "Prep-Web01", "Prep-WSUS01", "Prep-Dev01", "Prep-SQLDEV01",
    "Prep-BPWeb01", "PNUTHMIPC01", "Reboot All"
)

$xPos = 10
$yPos = 10

foreach ($buttonName in $buttonNames) {
    Create-Button -name $buttonName -x $xPos -y $yPos
    $yPos += 30
}


$form.ShowDialog()
