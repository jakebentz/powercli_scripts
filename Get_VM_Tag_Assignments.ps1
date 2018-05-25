$VM = Read-Host "VM"
Get-VM $VM | Get-TagAssignment | select Entity,Tag | sort-object Entity | ft -a
