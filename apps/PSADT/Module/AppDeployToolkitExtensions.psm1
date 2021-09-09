﻿<#
.SYNOPSIS
	This script is a template that allows you to extend the toolkit with your own custom functions.
    # LICENSE #
    PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows. 
    Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. 
    You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is automatically dot-sourced by the AppDeployToolkitMain.ps1 script.
.NOTES
    Toolkit Exit Code Ranges:
    60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
    69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
    70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
)

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

# Variables: Script
[string]$appDeployToolkitExtName = 'PSAppDeployToolkitExt'
[string]$appDeployExtScriptFriendlyName = 'App Deploy Toolkit Extensions'
[version]$appDeployExtScriptVersion = [version]'1.5.0'
[string]$appDeployExtScriptDate = '02/12/2017'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters

##*===============================================
##* FUNCTION LISTINGS
##*===============================================

# <Your custom functions go here>
#region FUNCTION Remove-DesktopShortcut
FUNCTION Remove-DesktopShortcut {
<#
	.SYNOPSIS
		Removes Desktop Shortcuts - requires PSADT toolkit functions
	.DESCRIPTION
		Specify file name, without file extension, to delete Desktop Shortcuts that applications create during install. Support wildcards
	.PARAMETER Name
		File name without file extension
	.PARAMETER UseWildCard
		A description of the UseWildCard parameter.
	.EXAMPLE
		PS C:\> Remove-DesktopShortcut -Name 'Value1'
	.NOTES
		Additional information about the function.
#>
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true,
				   Position = 1)][SupportsWildcards()][ValidateNotNullOrEmpty()][Alias('N')][string]$Name,
		[Parameter(Position = 2)][Alias('WC')][switch]$UseWildCard
	)
	BEGIN {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	PROCESS {
		SWITCH ($UseWildCard) {
			false {
				$FileName = $Name + '.lnk'
			}
			true {
				$FileName = $Name + '*' + '.lnk'
			}
		}
		TRY {
			$Paths = "$envCommonDesktop", "$envUserDesktop"
			$Paths | ForEach-Object{
				IF (!(Test-Path -Path $_\$FileName)) {
					Write-Log -Message "LNK doesn't exist: $_\$FileName" -severity 1 -Source ${CmdletName}
				} ELSEIF (Test-Path -Path $_\$FileName) {
					Remove-File -Path $_\$FileName
				}
			}
			Refresh-Desktop
		} CATCH {
			Write-Log -Message "Unable to remove $FileName or syntax error." -severity 2 -Source ${CmdletName}
		}
	}
	END {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion FUNCTION Remove-DesktopShortcut

#region FUNCTION Get-OfficeInfo
FUNCTION Get-OfficeInfo {
	BEGIN {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	PROCESS {
		Write-Log -Message "Getting Microsoft Office information." -severity 1 -Source ${CmdletName}
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
							# Parse Name, Version, Year, and bitness for each app
							$OfficeVersion = $AppProps | ForEach-Object -Process {
								$_.DisplayVersion.SubString(0, 4)
							}
							$OfficeYear = $AppProps | ForEach-Object -Process {
								($_.DisplayName) -replace '\D', ''
							}
							IF (($AppProps.PSPath | Split-Path -Leaf) -like 'O365*') {
								$C2R = $true
								$OfficeBitness = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Office\ClickToRun\REGISTRY\MACHINE\Software\Microsoft\Office\$OfficeVersion\Outlook" -Name Bitness | Select-Object -ExpandProperty bitness
								$OfficeInstaller = 'C2R'
								$OfficeName = ($AppProps | ForEach-Object -Process {
										((($_.DisplayName).replace('Microsoft', '')).Replace('Office', '')).replace(' ', '')
									}) + '_' + $OfficeVersion + '_' + $OfficeBitness
							} ELSE {
								$OfficeBitness = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Office\$OfficeVersion\Outlook" -Name Bitness | Select-Object -ExpandProperty bitness
								$OfficeInstaller = 'MSI'
								$OfficeName = 'Office' + $OfficeYear + '_' + $OfficeVersion + '_' + $OfficeBitness
							}
							
							# Add data to Output object
							$Output += New-Object -TypeName 'PSObject' -Property @{
								Name	   = $OfficeName
								Year	   = $OfficeYear
								Version    = $OfficeVersion
								Bitness    = $OfficeBitness
								Installer  = $OfficeInstaller
							}
							Write-Log -Message "Found Office application [$($AppProps.DisplayName)]." -severity 1 -Source ${CmdletName}
						}
					}
				}
			}
			Write-Output -InputObject $output
		} CATCH {
			Write-Output -InputObject 'error'
		}
	}
	END {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion FUNCTION Get-OfficeInfo

#region FUNCTION Get-MSIinfo
FUNCTION Get-MSIinfo {
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$Path,
		[Parameter(Mandatory = $true)][ValidateSet('ProductCode', 'ProductVersion', 'ProductName', 'Manufacturer', 'ProductLanguage', 'FullVersion', 'UpgradeCode')][ValidateNotNullOrEmpty()][string]$Property
	)
	BEGIN {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	PROCESS {
		TRY {
			# Read property from MSI database
			$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
			$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($Path.FullName, 0))
			$Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
			$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
			$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
			$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
			$Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
			
			# Commit database and close view
			$MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
			$View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)
			$MSIDatabase = $null
			$View = $null
			
			# Return the value
			RETURN $Value
		} CATCH {
			Write-Warning -Message $_.Exception.Message; BREAK
		}
	}
	END {
		# Run garbage collection and release ComObject
		[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null
		[System.GC]::Collect()
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion FUNCTION Get-MSIinfo

##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

If ($scriptParentPath) {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
}
Else {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================