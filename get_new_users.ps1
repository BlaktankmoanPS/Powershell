get-aduser -SearchBase "OU=Employees,DC=prempnut,DC=local" -Filter * -Properties whenCreated |?{$_.whenCreated -gt $(Get-Date).AddDays(-90)} |Select Name,whenCreated
