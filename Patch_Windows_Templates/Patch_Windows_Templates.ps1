# /=======================================================================
# /=
# /=  Patch_Windows_Templates.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	04/16/2018
# /=
# /=  REQUIREMENTS: Windows Server Templates need to be running PowerShell v.3
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
# /=   1.0  04/16/2018  Jake Bentz      Created script
# /=
# /=======================================================================#
#
#Create variable for list of templates
$Templates=get-template | where{$_.Name -like "Template-Win*"}
Write-Host "Patching" $Templates.Name
#
# Create log folder if it doesn't exist
$Logpath = ".\output"
If ((Test-Path -Path $Logpath) -ne $true) { New-Item -ItemType directory -Path $Logpath}
#
# Create log file
$Logfile = ".\output\Patch_Template"+ (get-date -format '_ddMMMyyyy_hhmm') +".txt"
Write "================================================================" > $Logfile
Write "Patch Template Output File" >> $Logfile
Write "================================================================" >> $Logfile
#
# Convert template to VM
Write "============================" >> $Logfile
Foreach ($Template in $Templates) {
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Converting to VM "
$Output = $Output += $Template
Write $Output >> $Logfile
Write-Host $Output
Set-Template -Template $Template -ToVM -Confirm:$false >> $Logfile
}
Write "============================" >> $Logfile
Write-Host "Sleeping 30"
Start-sleep -s 30
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output >> $Logfile
#
#Create variable for list of templates after conversion to VM
$TemplateVMs=get-vm | where{$_.Name -like "Template-Win*"}
Write-Host "Patching" $TemplateVMs.Name
#
#Start VM
Write "============================" >> $Logfile
Foreach ($TemplateVM in $TemplateVMs) {
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Starting VM "
$Output = $Output += $TemplateVM
Write $Output >> $Logfile
Write-Host $Output
Start-VM -VM $TemplateVM | Get-VMQuestion | Set-VMQuestion -DefaultOption -Confirm:$false >> $Logfile
}
Write "============================" >> $Logfile
Write-Host "Sleeping 120"
Start-sleep -s 120
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output >> $Logfile
#
#Create variables for Guest OS credentials - This is needed for the Invoke-VMScript cmdlet
#to be able to execute actions inside the Guest.
#If you don't want to enter the Guest OS local administrator password as clear text in the script,
#follow the steps on following link to create a file and store it as an encrypted
#string: http://stackoverflow.com/questions/6239647/using-powershell-credentials-without-being-prompted-for-a-password
$Username = "administrator"
$OSPwd = cat .\OSPwd.txt | convertto-securestring
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $OSPwd
#
#The following is the cmdlet that will invoke the Get-WUInstall inside the GuestVM to install all available Windows updates; optionally results can be exported to a log file to see the patches installed and related results.
Write "============================" >> $Logfile
Foreach ($TemplateVM in $TemplateVMs) {
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Patching VM "
$Output = $Output += $TemplateVM
Write $Output >> $Logfile
Write-Host $Output
Invoke-VMScript -ScriptType PowerShell -ScriptText "ipmo PSWindowsUpdate; Get-WUInstall -WindowsUpdate -AcceptAll -AutoReboot" -VM $TemplateVM -GuestCredential $Cred >> $Logfile
}
Write "============================" >> $Logfile
Write-Host "Sleeping 3600"
Start-sleep -s 3600
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output >> $Logfile
#
#Optionally restart VMGuest one more time in case Windows Update requires it and for whatever reason the AutoReboot switch didn’t complete it.
Write "============================" >> $Logfile
Foreach ($TemplateVM in $TemplateVMs) {
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Restarting VM "
$Output = $Output += $TemplateVM
Write $Output >> $Logfile
Write-Host $Output
Restart-VMGuest -VM $TemplateVM -Confirm:$false >> $Logfile
}
Write "============================" >> $Logfile
Write-Host "Sleeping 120"
Start-sleep -s 120
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output >> $Logfile
#
#After a desired wait period, shutdown the server
Write "============================" >> $Logfile
Foreach ($TemplateVM in $TemplateVMs) {
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Shutting down VM "
$Output = $Output += $TemplateVM
Write $Output >> $Logfile
Write-Host $Output
Shutdown-VMGuest -VM $TemplateVM -Confirm:$false >> $Logfile
}
Write "============================" >> $Logfile
Write-Host "Sleeping 120"
Start-sleep -s 120
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output >> $Logfile
#
#Convert VM to Template
Write "============================" >> $Logfile
Foreach ($TemplateVM in $TemplateVMs) {
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Converting to Template "
$Output = $Output += $TemplateVM
Write $Output >> $Logfile
Write-Host $Output
Set-VM -VM $TemplateVM -ToTemplate -Confirm:$false >> $Logfile
}
$Output = (get-date -format 'dd-MMM-yyyy hh:mm')
$Output = $Output += " Complete"
Write $Output >> $Logfile
Write "============================" >> $Logfile
