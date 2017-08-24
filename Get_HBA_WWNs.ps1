# /=======================================================================
# /=
# /=  Get_HBA_WWNs.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	08/24/2017
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script reads HBA WWNs for specified hosts
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  08/24/2017	 Jake Bentz	 Created script
# /=
# /=======================================================================#
#
$servername  = Read-Host "Hostname(s)"
Get-VMhost $servername | Get-VMHostHBA -Type FibreChannel | Select VMHost,Device,@{N="WWN";E={"{0:X}"-f$_.PortWorldWideName}} | Sort VMhost,Device | format-table -autosize
