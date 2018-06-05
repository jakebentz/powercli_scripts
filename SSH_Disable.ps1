# /=======================================================================
# /=
# /=  SSH_Disable.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE: 05/25/2018
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script disables SSH on specified hosts
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  05/25/2018  Jake Bentz      Created script
# /=
# /=======================================================================
#
$server = Read-Host "Server Name (wildcard accepted)"
get-vmhost $server |ForEach {Stop-VMHostService -HostService ($_ | Get-VMHostService | Where {$_.Key -eq "TSM-SSH"})}
