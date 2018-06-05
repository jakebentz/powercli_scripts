# /=======================================================================
# /=
# /=  Get_VM_Tag_Assignments.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	05/25/2018
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script reads tag assignments for specified guests
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  05/25/2018	 Jake Bentz	 Created script
# /=
# /=======================================================================
#
$VM = Read-Host "VM"
Get-VM $VM | Get-TagAssignment | select Entity,Tag | sort-object Entity | ft -a
