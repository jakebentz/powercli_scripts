# /=======================================================================
# /=
# /=  Patch_Templates.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	08/25/2017
# /=
# /=  REQUIREMENTS: Server 2008/2012 Templates need to be running PowerShell v.3
# /=  minimum, but v.4 or higher is recommended. # /=  The PSWindowsUpdate
# /=  Module directory needs to be imported in the PSModulePath on the template.
# /=  https://gallery.technet.microsoft.com/scriptcenter/2d191bcd-3308-4edd-9de2-88dff796b0bc
# /=  Encrypted password file for local administrator account ".\OSPwd.txt"
# /=  Execution Policy on template needs to be Remote-Signed
# /=  Twitter: @TripDeezil
# /=
# /=  DESCRIPTION: This script patches the specified templates
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  08/25/2017  Jake Bentz      Created script
# /=
# /=======================================================================#
#
#Create variable for list of templates
$Template = Read-Host "Template name(s)"
#
# Create log folder if it doesn't exist
$Logpath = ".\output"
If ((Test-Path -Path $Logpath) -ne $true) { New-Item -ItemType directory -Path $Logpath}
#
# Create log file
$Logfile = ".\output\Patch_Template"+ (get-date -format '_ddMMMyyyy_hhmm') +".txt"
Write "================================================================" | Tee-Object $Logfile
Write "Patch Template Output File" | Tee-Object $Logfile -Append
Write "================================================================" | Tee-Object $Logfile -Append
#
# Convert template to VM
Write "============================" | Tee-Object $Logfile -Append
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Converting to VM "
$Output = $Output += $Template
Write $Output | Tee-Object $Logfile -Append
Set-Template -Template $Template -ToVM -Confirm:$false | Tee-Object $Logfile -Append
Start-sleep -s 60
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output | Tee-Object $Logfile -Append
Write "============================" | Tee-Object $Logfile -Append
#
#Start VM
Write "============================" | Tee-Object $Logfile -Append
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Starting VM "
$Output = $Output += $Template
Write $Output | Tee-Object $Logfile -Append
Start-VM -VM $Template | Get-VMQuestion | Set-VMQuestion -DefaultOption -Confirm:$false | Tee-Object $Logfile -Append
Start-sleep -s 120
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output | Tee-Object $Logfile -Append
Write "============================" | Tee-Object $Logfile -Append
#
#Create variables for Guest OS credentials - This is needed for the Invoke-VMScript cmdlet to be able to execute actions inside the Guest.
#If you don't want to enter the Guest OS local administrator password as clear text in the script, follow the steps on following link to create a file and store it as an encrypted string: http://stackoverflow.com/questions/6239647/using-powershell-credentials-without-being-prompted-for-a-password
$Username = "administrator"
$OSPwd = cat .\OSPwd.txt | convertto-securestring
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $OSPwd
#
#The following is the cmdlet that will invoke the Get-WUInstall inside the GuestVM to install all available Windows updates; optionally results can be exported to a log file to see the patches installed and related results.
Write "============================" | Tee-Object $Logfile -Append
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Patching VM "
$Output = $Output += $Template
Write $Output | Tee-Object $Logfile -Append
Invoke-VMScript -ScriptType PowerShell -ScriptText "ipmo PSWindowsUpdate; Get-WUInstall –WindowsUpdate –AcceptAll –AutoReboot" -VM $Template -GuestCredential $Cred | Tee-Object $Logfile -Append
Start-sleep -s 3600
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output | Tee-Object $Logfile -Append
Write "============================" | Tee-Object $Logfile -Append
#
#Optionally restart VMGuest one more time in case Windows Update requires it and for whatever reason the –AutoReboot switch didn’t complete it.
Write "============================" | Tee-Object $Logfile -Append
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Restarting VM "
$Output = $Output += $Template
Write $Output | Tee-Object $Logfile -Append
Restart-VMGuest -VM $Template -Confirm:$false | Tee-Object $Logfile -Append
Start-sleep -s 120
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output | Tee-Object $Logfile -Append
Write "============================" | Tee-Object $Logfile -Append
#
#After a desired wait period, Shutdown the server
Write "============================" | Tee-Object $Logfile -Append
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Shutdown VM "
$Output = $Output += $Template
Write $Output | Tee-Object $Logfile -Append
Shutdown-VMGuest –VM $Template -Confirm:$false | Tee-Object $Logfile -Append
Start-sleep -s 120
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output | Tee-Object $Logfile -Append
Write "============================" | Tee-Object $Logfile -Append
#
#Convert VM to Template
Write "============================" | Tee-Object $Logfile -Append
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Convert VM to Template"
$Output = $Output += $Template
Write $Output | Tee-Object $Logfile -Append
Set-VM –VM $Template -ToTemplate -Confirm:$false | Tee-Object $Logfile -Append
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output | Tee-Object $Logfile -Append
Write "============================" | Tee-Object $Logfile -Append
