FUNCTION Check-OSDiskFreespace {
<#
	.SYNOPSIS
		Checks free disk space on the OS drive
	
	.DESCRIPTION
		Checks free disk space on the OS drive
	
	.PARAMETER MinimumDiskSpaceGB
		Set to return $true or $false if disk space does not meet minimum requirement
	
	.EXAMPLE
		PS C:\> Check-OSDiskFreespace -MinimumDiskSpaceGB 20
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $false,
				   HelpMessage = 'If free space greater than integer supplied, returns $true')][ValidateNotNullOrEmpty()][ValidateRange(1, [int]::MaxValue)][int]$MinimumDiskSpaceGB
	)
	
	# Get OS Disk
	$OSDisk = (Get-CimInstance -ClassName win32_operatingsystem).SystemDrive
	
	# Get Disk Space
	$OSDisk_Space = Get-CimInstance -ClassName CIM_LogicalDisk | Where-Object {$_.DeviceID -eq $OSDisk} | Select-Object @{
		Name = "Size(GB)"; Expression = {
			[Math]::Round($_.size/1gb, 2)
		}
	}, @{
		Name = "Free Space(GB)"; Expression = {
			[Math]::Round($_.freespace/1gb, 2)
		}
	}, @{
		Name = "Free (%)"; Expression = {
			(($_.freespace/1gb)/($_.size/1gb)).tostring("P")
		}
	}, DeviceID, DriveType
	
	# Return ture/false if Free space less than $MinimumDiskSpaceGB
	IF ($PSBoundParameters.ContainsKey('MinimumDiskSpaceGB')) {
		SWITCH ($OSDisk_Space.'Free Space(GB)' -gt $MinimumDiskSpaceGB) {
			$true {
				RETURN $true
			}
			$false {
				RETURN $false
			}
		}
	}
	ELSE {
		RETURN $OSDisk_Space
	}
}
