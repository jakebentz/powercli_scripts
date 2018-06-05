# /=======================================================================
# /=
# /=  Get_All_Tag_Assignments.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	05/25/2018
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script gets all tag assignments
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  05/25/2018	 Jake Bentz	 Created script
# /=
# /=======================================================================
#
get-vm | Get-TagAssignment | select Entity,Tag | sort-object Entity | export-csv .\All_TagAssignments.csv
