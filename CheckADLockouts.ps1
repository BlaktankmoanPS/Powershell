#Collect lockout accounts from ADS
Import-Module ActiveDirectory

[string]$userName = "ppreports@premiumpnut.com"
[string]$userPassword = "PPr3port5"
    
# Convert to SecureString
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

try
{    
    $logname = "security"
    $dcname = (Get-AdDomain).pdcemulator
    $xmlquery=@'
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[(EventID=4740)]]</Select>
  </Query>
</QueryList>
'@
    $content = Get-WinEvent -FilterXml $xmlquery -ComputerName $dcname
    $list = @()
    $content | % { $timecreated = $_.TimeCreated; $username = ([xml]$_.ToXml()).Event.EventData.Data[0]."#text"; $computername = ([xml]$_.ToXml()).Event.EventData.Data[1]."#text"; $list += @{TimeCreated=$timecreated;Username=$username;ComputerName=$computername}}

    #$content = Get-WinEvent -FilterHashTable @{LogName="Security"; ID=4740} -ComputerName $dcname #| Select -expand Properties
    $ofs = "`r`n`r`n"
    $body = "Fetching event log started on " + (Get-Date) + $ofs

    if ($list -eq $null -or $list.Count -le 0)
    {
        $body = $body + "No lock-out accounts happened today" + $ofs
    }
    else
    {
        foreach($event in $list)
        {
            $source = $event.ComputerName;
            $user = $event.Username;
            $timecreated = $event.TimeCreated;
            $body = $body + $timecreated +  " - " + $source + " - " + $user + $ofs
        }
    }
    #If ($content -eq $null)
    #{
    #    $body = $body + "No lock-out accounts happened today" + $ofs
    #}
    #Else 
    #{
    #    Foreach ($event in $content)
    #    {
    #        $source = $event.Value[1].ToString()
    #        $username = $event.value[0].ToString()
    #        $body = $body + $event.TimeCreated +  " - " + $source + $ofs
    #    }
    #}
    $body

    
    Send-MailMessage -To "it@premiumpnut.com" -Subject "AD Account Lockouts" -Body $body -From "ppreports@premiumpnut.com" -SmtpServer "smtp.office365.com" -Port "587" -UseSsl -Credential $credObject
}
catch
{
    $errMsg = "Error Occurred while running AD Lockout script: $_" 
    Send-MailMessage -To "it@premiumpnut.com" -Subject "AD Account Lockouts - Error Occurred" -Body $errMsg -From "ppreports@premiumpnut.com" -SmtpServer "smtp.office365.com" -Port "587" -UseSsl -Credential $credObject
}