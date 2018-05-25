$VM = read-host "VM"
Get-VM $VM| Select Name, @{N="IP Address";E={@($_.guest.IPAddress[0])}}
