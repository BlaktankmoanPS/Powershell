$server = "Prep-UTIL01"

# Create a session to the remote server
$session = New-PSSession -ComputerName $server

# Invoke the Delta Sync command remotely
Invoke-Command -Session $session -ScriptBlock {
    # Run the Delta Sync command
    Start-ADSyncSyncCycle -PolicyType Delta
}

# Close the session
Remove-PSSession -Session $session
