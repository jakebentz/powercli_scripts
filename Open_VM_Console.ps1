# /=======================================================================
# /=
# /=  Open_VM_Console.ps1.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	05/25/2018
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script opens the VM Console for specified guests
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  05/25/2018	 Jake Bentz	 Created script
# /=
# /=======================================================================
#
$VM = read-host "VM"
get-vm $VM | Open-VMConsoleWindow
