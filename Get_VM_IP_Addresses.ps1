$guest = Read-Host "VM Name"
Get-VM $guest | Select Name, @{N="IP Address";E={@($_.guest.IPAddress[0])}} | ft -a
