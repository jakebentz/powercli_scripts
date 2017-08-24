# /=======================================================================
# /=
# /=  Get_CDP_Info.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	08/24/2017
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script reads CDP info for specified hosts
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  08/24/2017	 Jake Bentz	 Created script
# /=
# /=======================================================================#
#
$servername = Read-Host "Hostname(s)"
#
get-vmhost $servername|
%{Get-View $_.ID} |
%{$esxname = $_.Name; Get-View $_.ConfigManager.NetworkSystem} |
%{ foreach($physnic in $_.NetworkInfo.Pnic){
    $pnicInfo = $_.QueryNetworkHint($physnic.Device)
    foreach($hint in $pnicInfo){
      Write-Host $esxname $physnic.Device
      if( $hint.ConnectedSwitchPort ) {
        $hint.ConnectedSwitchPort
      }
      else {
        Write-Host "No CDP information available."; Write-Host
      }
    }
  }
}
