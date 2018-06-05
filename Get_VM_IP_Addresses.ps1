# /=======================================================================
# /=
# /=  Get_VM_IP_Addresses.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	05/25/2018
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script reads IP info for specified guests
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  05/25/2018	 Jake Bentz	 Created script
# /=
# /=======================================================================#
$guest = Read-Host "VM Name"
Get-VM $guest | Select Name, @{N="IP Address";E={@($_.guest.IPAddress[0])}} | ft -a
