$VMGuest = Read-Host "VM(s)"

New-VIProperty -Name ToolsVersion -ObjectType VirtualMachine -ValueFromExtensionProperty 'Config.tools.ToolsVersion' -Force
New-VIProperty -Name ToolsVersionStatus -ObjectType VirtualMachine -ValueFromExtensionProperty 'Guest.ToolsVersionStatus' -Force

Get-VM $VMGuest | select Name, Version, ToolsVersion, ToolsVersionStatus | ft -a
