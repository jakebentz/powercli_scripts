# /=======================================================================
# /=
# /=  Storage_vMotions.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE: 06/07/2018
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script performs storage vmotions based on imported CSV file data
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  06/07/2018  Jake Bentz      Created script
# /=
# /=======================================================================
#
Import-Csv C:\Filename.csv | ForEach-Object {move-vm -VM $_.VMGuest -Destination $_.Datastore}
