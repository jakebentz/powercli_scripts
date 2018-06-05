#
# Import-VCDB.ps1
#
# Version:	1.0
# Author:	Arnim van Lieshout
#
# This script will import your vCenter database objects from .xml files created with Export-VCDB.ps1
#
# I've put every step in a seperate function, so you can easily select the steps you need in your environment
#

$dst = Connect-VIServer "vCenterServername" -NotDefault

#Import datacenters
function Import-Datacenters {
	$rootfolder = Get-Folder -Server $dst -NoRecursion
	Import-Clixml "Datacenters.xml" | %{New-Datacenter -Location $rootfolder -Name $_.Name}
}

#Import folder structure (no datacenter folders!)
function Import-Folders {
	$FolderStructure = Import-Clixml "Folders.xml"
	filter New-FolderStructure {
		param($parent)
		if (-not($folder = Get-Folder $_.name -Location $parent -ErrorAction:SilentlyContinue)) {$folder = New-Folder $_.name -Location $parent}
		$_.children | New-FolderStructure($folder)
	}
	$FolderStructure.GetEnumerator() | %{$dc = get-datacenter $_.name -server $dst; $_.value | New-FolderStructure($dc)}
}

#Import clusters
function Import-Clusters {
	ForEach ($c in (Import-Clixml "Clusters.xml")) {
		$nc = New-Cluster -Location (Get-Datacenter $c.datacenter -Server $dst) -Name $c.name
		Set-Cluster -Cluster $nc -VMSwapfilePolicy $c.VMSwapfilePolicy -DrsEnabled:$true -DrsAutomationLevel $c.DrsAutomationLevel -DrsMode $c.DrsMode -HAAdmissionControlEnabled $c.HAAdmissionControlEnabled -HAFailoverLevel $c.HAFailoverLevel -HAIsolationResponse $c.HAIsolationResponse -HARestartPriority $c.HARestartPriority -Confirm:$false
		Set-Cluster -Cluster $nc -DrsEnabled $c.DrsEnabled -HAEnabled $c.HAEnabled -Confirm:$false
	}
}

#Import custom attributes definitions
function Import-CustomAttributes {
	Import-Clixml "CustomAttributes.xml" | % {New-CustomAttribute -Server $dst -Name $_.name -TargetType $_.TargetType}
}

#Import customization profiles
function Import-CustomizationProfiles {
	$view = Get-View -Server $dst CustomizationSpecManager
	Import-Clixml "CustomizationProfiles.xml" | %{$view.CreateCustomizationSpec($view.XmlToCustomizationSpecItem($_))}
}

#Import roles
function Import-Roles {
	#First remove existing roles on destination server
	Get-VIRole -Server $dst | Where-Object {-not $_.IsSystem} | Remove-VIRole -Confirm:$false
	foreach ($role in (Import-Clixml "Roles.xml")) {
		$privileges = Get-VIPrivilege -PrivilegeItem -Server $dst
		New-VIRole -Server $dst -Name $role.Name -Privilege ($privileges | ? {$role.PrivilegeList -contains $_.id})
	}
}

#Import vmhosts
function Import-VMHosts {
	#First get credentials for adding hosts
	$HostCred = $Host.UI.PromptForCredential("Please enter credentials", "Enter ESX host credentials", "root", "")
	filter Get-HostLocation {
		param($parent)
		if ($_.child) {
			$_.child | Get-HostLocation(Get-Folder -Server $dst -Location $parent $_.Name)
		} else {
			Get-Folder -Server $dst -Location $parent $_.Name
		}
	}
	foreach ($vmhost in (Import-Clixml "VMHosts.xml")) {
		if ($vmhost.Cluster) {
			Add-VMHost $vmhost.Name -Location (Get-Cluster $vmhost.Cluster -Location (Get-Datacenter $vmhost.Datacenter -Server $dst)) -Credential $HostCred -Force
			#Add-VMHost $vmhost.Name -Location (Get-Cluster $vmhost.Cluster -Location (Get-Datacenter $vmhost.Datacenter -Server $dst)) -Credential $HostCred -ErrorAction SilentlyContinue -ErrorVariable ConnectError | Out-Null
		} else {
			Add-VMHost $vmhost.Name -Location ($vmhost.Path | Get-HostLocation(Get-Datacenter $vmhost.Datacenter -Server $dst)) -Credential $HostCred -Force
			#Add-VMHost $vmhost.Name -Location ($vmhost.Path | Get-HostLocation(Get-Datacenter $vmhost.Datacenter -Server $dst)) -Credential $HostCred -ErrorAction SilentlyContinue -ErrorVariable ConnectError | Out-Null
		}
	}
}

#Import vm locations (Move vm's to original location)
function Import-VmLocations {
	filter Get-VmLocation {
		param($parent)
		if ($_.child) {
			$_.child | Get-VmLocation(Get-Folder -Server $dst -Location $parent $_.Name)
		} else {
			Get-Folder -Server $dst -Location $parent $_.Name
		}
	}
	foreach ($vm in (Import-Clixml "VmLocations.xml")) {
		$dc = Get-Datacenter -Server $dst $vm.datacenter
		Move-VM ($dc | Get-VM $vm.Name) -Destination ($vm.path | Get-VmLocation($dc)) 
	}
}

#Import DRS rules
function Import-DrsRules {
	ForEach ($r in (Import-CliXml "DrsRules.xml")) {
		New-DrsRule -Server $dst -Cluster (Get-Cluster -Server $dst -Name $r.Cluster) -Name $r.Name -Enabled $r.Enabled -KeepTogether $r.KeepTogether -VM (Get-VM -Server $dst $r.VMs)
	}
}

#Import permissions
function Import-Permissions {
	#Because we need the name of the entity in a regular expression (Get-view filters are regular expressions!!)
	#we have to escape all metacharacters
	filter Escape-MetaCharacters {
		foreach($MetaChar in '^','$','{','}','[',']','(',')','.','*','+','?','|','<','>','-','&') {$_=$_.replace($MetaChar,"\$($Metachar)")}
		$_
	}
	foreach ($p in (Import-Clixml "Permissions.xml")) {
		$ev = Get-View -ViewType $p.EntityType -Filter @{"Name" = $($p.EntityName | Escape-MetaCharacters)} -Server $dst
		$perm = New-Object VMware.Vim.Permission
		$perm.principal = $p.Principal
		$perm.group = $p.Group
		$perm.propagate = $p.Propagate
		$perm.roleId = $(Get-VIRole $p.Role -Server $dst).id
		$authMgr = Get-View AuthorizationManager -Server $dst
		$authMgr.SetEntityPermissions($ev.MoRef, $perm)
	}
}

#Main
#Import-Datacenters
#Import-Folders
#Import-Clusters
#Import-CustomAttributes
#Import-CustomizationProfiles
#Import-Roles
#Stop code execution to give the opportunity to enable EVC mode on clusters if needed before adding ESX(i) hosts
#[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
#$answer = [System.Windows.Forms.MessageBox]::show("Enable EVC mode on your clusters if needed Now!`nWhen finished, press OK to continue adding hosts","Enable EVC Mode", [System.Windows.Forms.MessageBoxButtons]::Ok, [System.Windows.Forms.MessageBoxIcon]::Asterisk)
Import-VMHosts
Import-DrsRules
#Import-Permissions
Import-VmLocations
