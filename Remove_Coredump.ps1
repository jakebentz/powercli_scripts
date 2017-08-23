# /=======================================================================
# /=
# /=  Remove_Coredump.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	08/23/2017
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script removes coredumps from all connected hosts
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  08/23/2017	 Jake Bentz	 Created script
# /=
# /=======================================================================#
#
Get-VMHost | % {
 write-host "Connecting to" $_
 $esxcli = get-esxcli -vmhost $_
 write-host "removing coredump from" $_
 $esxcli.system.coredump.file.remove($null, $true)
}
