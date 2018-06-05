# /=======================================================================
# /=
# /=  Run_Command_On_Guest.ps1.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	05/25/2018
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script uses Invoke-VMScript to run a command string on specified guests
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  05/25/2018	 Jake Bentz	 Created script
# /=
# /=======================================================================
#
$VM = read-host "VM"
$command = read-host "Command"
get-vm $VM | Invoke-VMScript $command
