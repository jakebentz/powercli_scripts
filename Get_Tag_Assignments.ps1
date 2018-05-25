Get-TagAssignment | select Entity,Tag | sort-object Entity | ft -a | export-csv .\TagAssignments.csv
