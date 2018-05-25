$VM = read-host "VM"
$command = read-host "Command"
get-vm $VM | Invoke-VMScript $command
