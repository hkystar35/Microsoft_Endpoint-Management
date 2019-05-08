$NetAdapterName = 'Wi-Fi' #<Name of Network Adapter with internet access>
$VMSwitchName = 'AutopilotExternal'
$VMName = 'WindowsAutopilot'
$VHDPath = 'D:\VMs\HyperV'
$ISO = 'D:\Software\ISO\Operating Systems\SW_DVD9_Win_Pro_Ent_Edu_N_10_1809_64-bit_English_MLF_X21-96501.ISO'

New-VMSwitch -Name $VMSwitchName -NetAdapterName $NetAdapterName -AllowManagementOS $true #-WhatIf
New-VM -Name $VMName -MemoryStartupBytes 2GB -BootDevice VHD -NewVHDPath $VHDPath\VMs\WindowsAutopilot.vhdx -Path $VHDPath\VMData -NewVHDSizeBytes 80GB -Generation 2 -Switch $VMSwitchName 
Add-VMDvdDrive -Path $ISO -VMName $VMName 
Start-VM -VMName $VMName
#Set-VMMemory -VMName $VMName -StartupBytes 16GB
Checkpoint-VM -Name $VMName -SnapshotName "Finished Windows install"