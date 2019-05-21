#requires -version 5
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
# /=   2.0  04/19/2019  Jake Bentz      Rewrite for use with vRealize Orchestrator
# /=======================================================================#
#


[CmdletBinding()]param(
    [Parameter(Mandatory=$true)][string[]]$VmNames,
    #[Parameter(Mandatory=$true)][string]$VmName,
    [Parameter(Mandatory=$true)][string]$VCenterServer,
    [Parameter(Mandatory=$true)][string]$UserName,
    [Parameter(Mandatory=$true)][string]$EncryptedPassword,
    [Parameter(Mandatory=$true)][string]$GuestUserName,
    [Parameter(Mandatory=$true)][string]$GuestEncryptedPassword,
	[Parameter(Mandatory=$true)][string]$GuestKeyPath,
	[Parameter(Mandatory=$true,ParameterSetName="WithKey")][Byte[]]$Key,
    [Parameter(Mandatory=$true,ParameterSetName="WithKeyFile")][string]$KeyPath,
    [Parameter(Mandatory=$true,ParameterSetName="NoKey")][switch]$NoKey
	#[Parameter(Mandatory=$true,ParameterSetName="WithGuestKey")][Byte[]]$GuestKey,
    #[Parameter(Mandatory=$true,ParameterSetName="NoGuestKey")][switch]$NoGuestKey
)

# Create log folder if it doesn't exist
$Logpath = "D:\vra_prod_shared_items\scripts\PatchTemplates\Logs"
If ((Test-Path -Path $Logpath) -ne $true) { New-Item -ItemType directory -Path $Logpath}

# Clean up log directory
# Delete all Files in $Logpath older than 30 day(s)
$Daysback = "-120"
$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)
Get-ChildItem $Logpath | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item

# Create log file
$Logfile = $Logpath+"\update-templates"+ (get-date -format '_ddMMMyyyy_hhmm') +".log"
Write "================================================================" | Tee-Object $Logfile
Write "Patch Template Output" | Tee-Object $Logfile -Append
Write "================================================================" | Tee-Object $Logfile -Append
#
Write "$(get-date -format 'dd-MMM-yyy hh:mm') vCenter Connection Account:  $UserName "| Tee-Object $Logfile -Append
Write "$(get-date -format 'dd-MMM-yyy hh:mm') vCenter Connection: Connect-VIServer -Server $VCenterServer -Credential $credential -WarningAction 'SilentlyContinue' -ErrorAction 'Stop'" | Tee-Object $Logfile -Append

#Script to run on VM
#$script = "Get-Hotfix | sort-object InstalledOn"
	#Script to run on VM
	$script = "Function WSUSUpdate {
		  param ( [switch]`$rebootIfNecessary,
				  [switch]`$forceReboot)  
		`$Criteria = ""IsInstalled=0 and Type='Software'""
		`$Searcher = New-Object -ComObject Microsoft.Update.Searcher
		try {
			`$SearchResult = `$Searcher.Search(`$Criteria).Updates
			if (`$SearchResult.Count -eq 0) {
				Write-Output ""There are no applicable updates.""
				exit
			} 
			else {
				`$Session = New-Object -ComObject Microsoft.Update.Session
				`$Downloader = `$Session.CreateUpdateDownloader()
				`$Downloader.Updates = `$SearchResult
				`$Downloader.Download()
				`$Installer = New-Object -ComObject Microsoft.Update.Installer
				`$Installer.Updates = `$SearchResult
				`$Result = `$Installer.Install()
			}
		}
		catch {
			Write-Output ""There are no applicable updates.""
		}
		If(`$rebootIfNecessary.IsPresent) { If (`$Result.rebootRequired) { Restart-Computer -Force} }
		If(`$forceReboot.IsPresent) { Restart-Computer -Force }
	}
	WSUSUpdate -rebootIfNecessary
	"
	

#Setup environment
$InformationPreference = "Continue";
Write-Information 'Patch-Templates.ps1'

#Use KeyPath if provided to get key
if ($KeyPath) {
    try {
        Write-Verbose "$(get-date -format 'dd-MMM-yyy hh:mm') Key file specified, reading key..." | Tee-Object $Logfile -Append
        $Key = [byte[]]$(Get-Content -Path $KeyPath)
    } catch {
        Write-Error "$(get-date -format 'dd-MMM-yyy hh:mm') Failed to read key from $KeyPath!" | Tee-Object $Logfile -Append
        exit
    }
}

#Use GuestKeyPath if provided to get key
if ($GuestKeyPath) {
    try {
        Write-Verbose "$(get-date -format 'dd-MMM-yyy hh:mm') Key file specified, reading key..." | Tee-Object $Logfile -Append
        $GuestKey = [byte[]]$(Get-Content -Path $GuestKeyPath)
    } catch {
        Write-Error "$(get-date -format 'dd-MMM-yyy hh:mm') Failed to read key from $GuestKeyPath!" | Tee-Object $Logfile -Append
        exit
    }
}

#Create password
if ($Key) {
    Write-Verbose "$(get-date -format 'dd-MMM-yyy hh:mm') Custom key provided, decrypting password..." | Tee-Object $Logfile -Append
    $secureString = $($EncryptedPassword | ConvertTo-SecureString -Key $Key)
} else {
    $secureString = $($EncryptedPassword | ConvertTo-SecureString)
}

#Create guest password
if ($GuestKey) {
    Write-Verbose "$(get-date -format 'dd-MMM-yyy hh:mm') Custom guest key provided, decrypting password..." | Tee-Object $Logfile -Append
    $GuestSecureString = $($GuestEncryptedPassword | ConvertTo-SecureString -Key $GuestKey)
} else {
    $GuestSecureString = $($GuestEncryptedPassword | ConvertTo-SecureString)
}

#Build credential object
try {
    Write-Verbose "$(get-date -format 'dd-MMM-yyy hh:mm') Building credential object..." | Tee-Object $Logfile -Append
    $credential = New-Object System.Management.Automation.PsCredential -ArgumentList $UserName,$secureString -ErrorAction 'Stop'
} catch {
    Write-Error "$(get-date -format 'dd-MMM-yyy hh:mm') Error while creating credentials!" | Tee-Object $Logfile -Append
    exit 1
}

#Build guest credential object
try {
    Write-Verbose "$(get-date -format 'dd-MMM-yyy hh:mm') Building guest credential object..." | Tee-Object $Logfile -Append
    $GuestCredential = New-Object System.Management.Automation.PsCredential -ArgumentList $GuestUserName,$GuestSecureString -ErrorAction 'Stop'
} catch {
    Write-Error "$(get-date -format 'dd-MMM-yyy hh:mm') Error while creating guest credentials!" | Tee-Object $Logfile -Append
    exit 1
}

#Connect to vCenter server
try{
    Write-Verbose "$(get-date -format 'dd-MMM-yyy hh:mm') Importing PowerCLI module..."
    Import-Module VMware.VimAutomation.Core -ErrorAction 'Stop' -Verbose:$false

    Write-Verbose "$(get-date -format 'dd-MMM-yyy hh:mm') Connecting to vCenter server $VCenterServer..."
    Connect-ViServer -Server $VCenterServer -Credential $credential -ErrorAction 'Stop' | Out-Null
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

#Update template
foreach($VmName in $VmNames){

	try {
	#Get Template
	$template = Get-Template $VmName

	try {
	#Convert Template to VM
	if($showProgress) { Write-Progress -Activity "Update Template" -Status "Converting Template: $($VmName) to VM" -PercentComplete 5 }
	Write "$(get-date -format 'dd-MMM-yyy hh:mm') Converting Template: $($VmName) to VM" | Tee-Object $Logfile -Append
	$template | Set-Template -ToVM -Confirm:$false | Tee-Object $Logfile -Append
    } catch { 
	Write "$(get-date -format 'dd-MMM-yyy hh:mm') Error: Template not found." | Tee-Object $Logfile -Append
    }

	#Start VM
	if($showProgress) { Write-Progress -Activity "Update Template" -Status "Starting VM: $($VmName)" -PercentComplete 20 }
	Write "$(get-date -format 'dd-MMM-yyy hh:mm') Starting VM: $($VmName)" | Tee-Object $Logfile -Append
	Get-VM $VmName | Start-VM -RunAsync:$RunAsync | Tee-Object $Logfile -Append
	
	#Wait for VMware Tools to start
	if($showProgress) { Write-Progress -Activity "Update Template" -Status "Giving VM: $($VmName) 30 seconds to start VMwareTools" -PercentComplete 35 }
	Write "$(get-date -format 'dd-MMM-yyy hh:mm') Giving VM: $($VmName) 30 seconds to start VMwareTools" | Tee-Object $Logfile -Append
	sleep 30

	#Running Script on Guest VM
	if($showProgress) { Write-Progress -Activity "Update Template" -Status "Running Script on Guest VM: $($VmName)" -PercentComplete 50 }
	Write "$(get-date -format 'dd-MMM-yyy hh:mm') Running Script on Guest VM: $($VmName)" | Tee-Object $Logfile -Append
	Get-VM $VmName | Invoke-VMScript -ScriptText $script -GuestCredential $GuestCredential | Tee-Object $Logfile -Append
	}
catch { 
	Write "$(get-date -format 'dd-MMM-yyy hh:mm') Error:" | Tee-Object $Logfile -Append
	Write $error | Tee-Object $Logfile -Append
	Throw $error
	#stops post-update copy of template
	$updateError = $true
	}
}

	#Wait for Windows Updates to finish after reboot
	if($showProgress) { Write-Progress -Activity "Update Template" -Status "Giving VM: $($VmName) 600 seconds to finish rebooting after Windows Update" -PercentComplete 65 }
	Write "$(get-date -format 'dd-MMM-yyy hh:mm') Giving VM: $($VmName) 600 seconds to finish rebooting after Windows Update" | Tee-Object $Logfile -Append
	sleep 600

foreach($VmName in $VmNames){
	try {
	#Shutdown the VM
	if($showProgress) { Write-Progress -Activity "Update Template" -Status "Shutting Down VM: $($VmName)" -PercentComplete 80 }
	Write "$(get-date -format 'dd-MMM-yyy hh:mm') Shutting Down VM: $($VmName)" | Tee-Object $Logfile -Append
	Get-VM $VmName | Stop-VMGuest -Confirm:$false | Tee-Object $Logfile -Append
	
	#Wait for shutdown to finish
	if($showProgress) { Write-Progress -Activity "Update Template" -Status "Giving VM: $($VmName) 30 seconds to finish Shutting Down" -PercentComplete 90 }
	Write "$(get-date -format 'dd-MMM-yyy hh:mm') Giving VM: $($VmName) 120 seconds to finish Shutting Down" | Tee-Object $Logfile -Append
    sleep 120
	
	#Convert VM back to Template
	if($showProgress) { Write-Progress -Activity "Update Template" -Status "Convert VM: $($VmName) back to template" -PercentComplete 100 }
	Write "$(get-date -format 'dd-MMM-yyy hh:mm') Convert VM: $($VmName) back to template" | Tee-Object $Logfile -Append
	Get-VM $VmName | Set-VM -ToTemplate -Confirm:$false | Tee-Object $Logfile -Append
	}
	catch { 
	Write "$(get-date -format 'dd-MMM-yyy hh:mm') Error:" | Tee-Object $Logfile -Append
	Write $error | Tee-Object $Logfile -Append
	Throw $error
	#stops post-update copy of template
	$updateError = $true
	}
}
