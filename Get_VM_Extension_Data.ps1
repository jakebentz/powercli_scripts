# /=======================================================================
# /=
# /=  Get_VM_Extension_Data.ps1
# /=
# /=  AUTHOR: Jake Bentz
# /=  DATE:	06/26/2018
# /=
# /=  REQUIREMENTS: N/A
# /=
# /=  DESCRIPTION: This script uses Get-View to list extension data for a given VM
# /=  Twitter: @TripDeezil
# /=
# /=  REVISION HISTORY
# /=   VER  DATE        AUTHOR/EDITOR   COMMENT
# /=   1.0  05/25/2018	 Jake Bentz	 Created script
# /=
# /=======================================================================
#
$guest = Read-Host "VM Name"
$VM = get-vm $guest | get-view
$VM.Capability
$VM.Config
  $VM.Config.Files
  $VM.Config.Tools
  $VM.Config.Flags
  $VM.Config.ConsolePreferences
  $VM.Config.DefaultPowerOps
  $VM.Config.Hardware
  $VM.Config.CpuAllocation
  $VM.Config.MemoryAllocation
  $VM.Config.LatencySensitivity
  $VM.Config.BootOptions
  $VM.Config.VAppConfig
  $VM.Config.InitialOverhead
$VM.Layout
$VM.Storage
$VM.ResourceConfig
  $VM.ResourceConfig.CpuAllocation
  $VM.ResourceConfig.MemoryAllocation
$VM.Runtime
  $VM.Runtime.DasVmProtection
$VM.Guest
  $VM.Guest.IpStack
    $VM.Guest.IpStack.DnsConfig
    $VM.Guest.IpStack.IpRouteConfig
  $VM.Guest.Disk
  $VM.Guest.Screen
$VM.Summary
  $VM.Summary.Runtime
  $VM.Summary.Guest
  $VM.Summary.Config
  $VM.Summary.Storage
  $VM.Summary.QuickStats
$VM.Snapshot
$VM.Client
  $VM.Client.ServiceContent
