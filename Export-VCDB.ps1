#
# Export-VCDB.ps1
#
# Version:	1.0
# Author:	Arnim van Lieshout
#
# This script will export your vCenter database objects to several .xml files.
# These files can be used in combination with the Import-VCDB.ps1 script to recreate those objects into another vCenter database
#
# I've put every step in a seperate function, so you can easily select the steps you need in your environment
#
# Known Limitations:
# - Datacenter folders are not supported
# - Resourcepools are not supported
# - Objectnames used in vCenter must be unique, because the name is used as a unique reference
# - Cluster EVC mode is not supported
#

$src = Connect-VIServer "vCenterServerName" -NotDefault
$ClusterName = "Clustername"

#Export datacenters
function Export-Datacenters {
	Get-Datacenter -Server $src | Select Name | Export-Clixml "Datacenters.xml"
}

#Export folder structure (no datacenter folders!)
function Export-Folders {
	filter Get-FolderStructure {
		$folder = "" | select Name,Children
		$folder.Name = $_.name
		$folder.Children = @($_ | Get-Folder -NoRecursion | Get-FolderStructure )
		$folder
	}
	$FolderStructure=@{}
	Get-Datacenter -Server $src | %{$FolderStructure[$_.name] = $_ | Get-Folder -NoRecursion | Get-FolderStructure}
	$FolderStructure | Export-Clixml "Folders.xml"
}

#Export clusters
function Export-Clusters {
	$Clusters = @()
	ForEach ($dc in (Get-Datacenter -Server $src)) {
		foreach ($c in ($dc | Get-Cluster -Server $src)) {
			$c | Add-Member -MemberType Noteproperty -Name Datacenter -Value $dc.name
			$Clusters += $c
		}
	}
	$Clusters | Export-Clixml "Clusters.xml"
}

#Export custom attributes definitions
function Export-CustomAttributes {
	Get-CustomAttribute -Server $src | Where-Object {$_.TargetType} | Export-Clixml "CustomAttributes.xml"
}

#Export customization profiles
function Export-CustomizationProfiles {
	$profiles = @()
	$view = Get-View -Server $src CustomizationSpecManager
	ForEach ($cp in $view.info) {$profiles += $view.CustomizationSpecItemToXml($view.GetCustomizationSpec($cp.name))}
	$profiles | Export-Clixml "CustomizationProfiles.xml"
}

#Export roles
function Export-Roles {
	Get-VIRole -Server $src | Where-Object {-not $_.IsSystem} | Export-Clixml "Roles.xml"
}

#Export vm locations
function Export-VmLocations {
	filter Get-Path {
		param($child)
		$folder = Get-View -Server $src $_.parent
	
		if ($folder.gettype().name -eq "Datacenter") {
			$child
		} else {
			$path = "" | select Name,Child
			$path.name = $folder.name
			$path.child = $child
			$folder | Get-Path($path)
		}
	}
	$VmLocations = @()
	foreach ($vm in Get-VM -Server $src) {
		$VmObj = "" | Select Name,Datacenter,Path
		$VmObj.Name = $vm.name
		$VmObj.Datacenter = $($vm | Get-Datacenter).name
		$VmObj.Path = $vm | Get-View | Get-Path
		$VmLocations += $VmObj
	}
	$VmLocations | Export-Clixml "VmLocations.xml"
}

#Export DRS rules
function Export-DrsRules {
	$DrsRules=@()
	ForEach ($c in (Get-Cluster $ClusterName -Server $src)) {
		ForEach($r in ($c | Get-DrsRule -Server $src)) {
			$RuleObj = "" | Select Cluster, Name, Enabled, KeepTogether, VMs
			$RuleObj.Cluster = $c.name
			$RuleObj.Name = $r.name
			$RuleObj.Enabled = $r.enabled
			$RuleObj.KeepTogether = $r.KeepTogether
			$RuleObj.vms = @($r.VMIds | % {(Get-VM -Server $src -Id $_).Name})
			$DrsRules += $RuleObj
		}
	}
	$DrsRules | Export-Clixml "DrsRules.xml"
}

#Export permissions
function Export-Permissions {
	$Permissions=@()
	foreach ($p in Get-VIPermission -Server $src) {
		$PermObj = "" | Select EntityName, EntityType, Principal, Propagate, Group, Role
		$PermObj.Principal = $p.Principal
		$PermObj.Propagate = $p.Propagate
		$PermObj.Group = $p.IsGroup
		$PermObj.Role = $p.Role
		$pv = Get-view -Server $src -Id $p.EntityId
		$PermObj.EntityName = $pv.Name
		$PermObj.EntityType = $pv.GetType().Name
		$Permissions += $PermObj
	}
	$Permissions | Export-Clixml "Permissions.xml"
}

#Export vmhosts
function Export-VMHosts {
	filter Get-Path {
		param($child)
		$folder = Get-View -Server $src $_.parent
	
		if ($folder.gettype().name -eq "Datacenter") {
			$child
		} else {
			$path = "" | select Name,Child
			$path.name = $folder.name
			$path.child = $child
			$folder | Get-Path($path)
		}
	}
	$VMHosts = @()
	foreach ($h in (Get-Cluster $ClusterName -Server $src | Get-VMHost)) {
		$HostObj = "" | Select Name,Datacenter,Cluster,Path
		$HostObj.Name = $h.name
		$HostObj.Datacenter = $(Get-Datacenter -VMHost $h).name
		$HostObj.Cluster = $(Get-Cluster -VMHost $h).name
		if (-not $HostObj.Cluster) {$HostObj.Path = Get-view -Server $src $($h | Get-View).parent | Get-Path}
		$VMHosts += $HostObj
	}
	$VMHosts | Export-Clixml "VMHosts.xml"
}

#Disconnect hosts
function Disconnect-Hosts {
	#Disconnect ESX hosts
	Get-Cluster $ClusterName -Server $src | Get-VMHost | Set-VMHost -State "Disconnected" -Confirm:$false
}

#Main
#Export-Datacenters
#Export-Folders
#Export-Clusters
#Export-CustomAttributes
#Export-CustomizationProfiles
#Export-Roles
Export-VmLocations
Export-DrsRules
#Export-Permissions
Export-VMHosts
#[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
#$answer = [System.Windows.Forms.MessageBox]::show("You are about to disconnect your ESX(i) host(s) from your vCenter server`nAre you sure you want to disconnect your hosts?","Disconnect ESX(i) hosts", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Exclamation)
#if($answer -eq [Windows.Forms.DialogResult]::Yes){
#	Disconnect-Hosts
#	}
