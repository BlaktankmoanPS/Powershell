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
        if ($name -eq "Reboot All") {
            $confirmation = Show-ConfirmationDialog "Did Daddy Peanut approve this???"
            if ($confirmation -eq "Yes") {
                ButtonClick -Sender $this
            }
        } else {
            ButtonClick -Sender $this
        }
    })
}

function Show-ConfirmationDialog {
    param (
        [string]$message
    )

    $result = [System.Windows.Forms.MessageBox]::Show($message, "Confirmation", "YesNo", "Question")
    return $result.ToString()
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
    $serverName = $Sender.Name

    if ($serverName -eq "Reboot All") {
        $buttonNames | Where-Object { $_ -ne "Reboot All" } | ForEach-Object {
            Restart-Server $_
        }
        Start-Sleep -Seconds 30
        if (Wait-ForAllServersToRestart) {
            $Sender.BackColor = [System.Drawing.Color]::LimeGreen
        } else {
            $Sender.BackColor = [System.Drawing.Color]::Red
        }
    } else {
        Restart-Server $serverName
        Start-Sleep -Seconds 30
        if (Wait-ForServerToRestart $serverName) {
            $Sender.BackColor = [System.Drawing.Color]::LimeGreen
        } else {
            $Sender.BackColor = [System.Drawing.Color]::Red
        }
    }
}

function Wait-ForAllServersToRestart {
    $timeout = 300  # 5 minutes timeout (adjust as needed)
    $startTime = Get-Date

    $buttonNames | ForEach-Object {
        $serverName = $_
        do {
            Start-Sleep -Seconds 5
            if (!(Test-Connection -ComputerName "$serverName.prempnut.local" -Count 2 -Quiet)) {
                break
            }
        } while ((Get-Date) -lt ($startTime.AddSeconds($timeout)))
        
        if ((Get-Date) -ge ($startTime.AddSeconds($timeout))) {
            return $false
        }
    }

    return $true
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

$columns = 2
$buttonWidth = 150
$buttonHeight = 23
$marginX = 20
$marginY = 20

$xPos = $marginX
$yPos = $marginY

foreach ($buttonName in $buttonNames) {
    Create-Button -name $buttonName -x $xPos -y $yPos
    $xPos += $buttonWidth + $marginX

    if ($xPos + $buttonWidth + $marginX -gt $form.Width - 2 * $marginX) {
        $xPos = $marginX
        $yPos += $buttonHeight + $marginY
    }
}


$form.ShowDialog()
