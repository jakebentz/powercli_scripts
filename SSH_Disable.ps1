$server = Read-Host "Server Name (wildcard accepted)"

get-vmhost $server |ForEach {Stop-VMHostService -HostService ($_ | Get-VMHostService | Where {$_.Key -eq "TSM-SSH"})}
