<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.152
	 Created on:   	6/20/2018 3:21 PM
	 Created by:   	
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Gets Microsoft Office information on version, bitness, and MSI or C2R installer type.
#>

TRY {
	# Hash table for apps in registry
	$regKeyApplication = @()
	# Hash table for results
	$output = @()
	# HKLM paths for 32- and 64-bit apps
	$regKeyApplications = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
	FOREACH ($offkey IN $regKeyApplications) {
		IF (Test-Path -LiteralPath $offkey -ErrorAction SilentlyContinue) {
			# Get all keys in paths and add to object
			[psobject[]]$FoundApps = Get-ChildItem -LiteralPath $offkey -ErrorAction SilentlyContinue
			# Add only apps meeting criteria to new variable
			FOREACH ($FoundApp IN $FoundApps) {
				$AppProps = Get-ItemProperty -LiteralPath $FoundApp.PSPath -ErrorAction Stop
				IF (($AppProps.DisplayName -like 'Microsoft Office Professional Plus*' -or $AppProps.DisplayName -like 'Microsoft Office 365 ProPlus*') -and $AppProps.PSChildName -notlike 'Office*.PROPLUS') {
					$regKeyApplication += $AppProps
				}
			}
		}
	}
	# Parse Name, Version, Year, and bitness for each app
	Write-Log -Message "Check for running application(s) [$runningAppsCheck]..." -Source ${CmdletName}
	FOREACH ($regKeyApp IN $regKeyApplication) {
		$OfficeVersion = $regKeyApp | ForEach-Object -Process {
			$_.DisplayVersion.SubString(0, 4)
		}
		$OfficeYear = $regKeyApp | ForEach-Object -Process {
			($_.DisplayName) -replace '\D', ''
		}
		IF (($regKeyApp.PSPath | Split-Path -Leaf) -like 'O365*') {
			$C2R = $true
			$OfficeBitness = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Office\ClickToRun\REGISTRY\MACHINE\Software\Microsoft\Office\$OfficeVersion\Outlook" -Name Bitness | Select-Object -ExpandProperty bitness
			$OfficeInstaller = 'C2R'
			$OfficeName = ($regKeyApp | ForEach-Object -Process {
					((($_.DisplayName).replace('Microsoft', '')).Replace('Office', '')).replace(' ', '')
				}) + '_' + $OfficeVersion + '_' + $OfficeBitness
		} ELSE {
			$OfficeBitness = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Office\$OfficeVersion\Outlook" -Name Bitness | Select-Object -ExpandProperty bitness
			$OfficeInstaller = 'MSI'
			$OfficeName = 'Office' + $OfficeYear + '_' + $OfficeVersion + '_' + $OfficeBitness
		}
		# Add data to Output object
		$temp = New-Object -TypeName System.Object
		$temp | Add-Member -MemberType NoteProperty -Name Name -Value $OfficeName
		$temp | Add-Member -MemberType NoteProperty -Name Year -Value $OfficeYear
		$temp | Add-Member -MemberType NoteProperty -Name Version -Value $OfficeVersion
		$temp | Add-Member -MemberType NoteProperty -Name Bitness -Value $OfficeBitness
		$temp | Add-Member -MemberType NoteProperty -Name Installer -Value $OfficeInstaller
		$output += $temp
	}
	Write-Output -InputObject $output
} CATCH {
	Write-Output -InputObject 'error'
}