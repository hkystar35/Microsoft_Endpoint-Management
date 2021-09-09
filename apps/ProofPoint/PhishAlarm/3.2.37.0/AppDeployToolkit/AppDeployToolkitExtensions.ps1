<#
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
	<#
			.SYNOPSIS
			Gets Microsoft Office information
			.DESCRIPTION
			No parameters
			.EXAMPLE
			PS C:\> Get-OfficeInfo
			.NOTES
			If more than one installation is detected, ouput as array
	#>
	[CmdletBinding()]
	PARAM()
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
							Write-Log -Message "Found Office application [$($AppProps.DisplayName) $($OfficeBitness)]." -severity 1 -Source ${CmdletName}
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
			
			# Remove empty entries
			$Value = $Value | ?{$_ -ne $null}
			# Return the value
			$Value
		} CATCH {
			Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
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
#Get-MSIinfo -Path 'E:\git\apps\Biscom\SFT Client 5.1.1011\Files\BiscomSFT-Outlook-2019-addin-x86.msi'

#region FUNCTION Get-ShortName
FUNCTION Get-ShortName {
	<#
			.SYNOPSIS
			Gets files shortname
	
			.DESCRIPTION
			used for 8.3 naming conventions, like file~01.txt
	
			.PARAMETER InputObject
			A description of the InputObject parameter.
	
			.EXAMPLE
				$File | Get-ShortName
	
			.NOTES
		
	#>
	
	[CmdletBinding()]
	PARAM
	(
		[Parameter(ValueFromPipeline = $true)]$InputObject
	)
	
	BEGIN {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	PROCESS {
		TRY {
			$fso = New-Object -ComObject Scripting.FileSystemObject
			
			IF ($_.psiscontainer) {
				$fso.getfolder($_.fullname).ShortName
			} ELSE {
				$fso.getfile($_.fullname).ShortName
			}
		} CATCH {
			Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
		
	}
	END {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion FUNCTION Get-ShortName

#region FUNCTION Get-SmartScreenSettingsStatus
FUNCTION Get-SmartScreenSettingsStatus {
	<#
			.SYNOPSIS
			Gets SmartScreen setting
	
			.DESCRIPTION
			Gets SmartScreen setting
	
			.EXAMPLE
				PS C:\> Get-SmartScreenSettingsStatus
	
			.NOTES
			Additional information about the function.
	#>
	
	[CmdletBinding()]
	PARAM ()
	
	BEGIN {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	PROCESS {
		TRY {
			TRY {
				#$val = Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -ErrorAction Stop
				$Val = Get-RegistryKey -Key HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled
			} CATCH {
				Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
			IF ($val) {
				Write-Log -Message "Smart screen settings is set to: $($val.SmartScreenEnabled)" -Severity 1 -Source ${CmdletName}
				RETURN $val.SmartScreenEnabled
			} ELSE {
				Write-Log -Message 'Smart screen settings is set to: Off (by default)' -Severity 1 -Source ${CmdletName}
				RETURN $false
			}
		} CATCH {
			Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
		
	}
	END {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion FUNCTION Get-SmartScreenSettingsStatus

#region FUNCTION Set-SmartScreenSettingsStatus
FUNCTION Set-SmartScreenSettingsStatus {
	[CmdletBinding()]
	PARAM (
		[Parameter(Mandatory)][ValidateSet("Off", "Prompt", "RequireAdmin")][String]$State
	)
	BEGIN {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		TRY {
			# Make sure we run as admin                        
			$usercontext = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
			$IsAdmin = $usercontext.IsInRole(544)
			IF (-not ($IsAdmin)) {
				Write-Log -Message "Must run powerShell as Administrator to perform these actions" -Severity 3 -Source ${CmdletName}
			}
		} CATCH {
			Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	PROCESS {
		TRY {
			#$Set = Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -ErrorAction Stop -Value $State -Force -PassThru
			$Set = Set-RegistryKey -Key HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name SmartScreenEnabled -Value $State
			RETURN $Set
		} CATCH {
			Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	END {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion FUNCTION Set-SmartScreenSettingsStatus

#region FUNCTION Create-FirewallRule
FUNCTION Create-FirewallRule {
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateSet('TCP', 'UDP', 'TCPUDP')][ValidateNotNullOrEmpty()][Alias('P')][string]$Protocol,
		[switch]$RemoveExisiting = $false,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Description,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$DisplayName,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$FilePath,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$SearchExisting
	)
	BEGIN {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	PROCESS {
		
		TRY {
			$Protocols = "TCP", "UDP"
			$FirewallDisplayName = $DisplayName
			$FirewallRuleDescription = $Description
			
			#region Remove Existing Firewall Rules
			TRY {
				IF ($RemoveExisiting) {
					$GetExistingRules = Get-NetFirewallRule | Where-Object{
						$_.DisplayName -like "*$($SearchExisting)*"
					}
					IF ($GetExistingRules) {
						$GetExistingRules | ForEach-Object{
							Write-Log -Message "Found Existing Firewall Rule, Deleting: $($_.DisplayName) ($($_.Name))" -Severity 1 -Source ${CmdletName}
							$_ | Remove-NetFirewallRule
						}
					}
				}
			} CATCH {
				Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
			#endregion Remove Existing Firewall Rules
			
			#region Create New Firewall Rules
			TRY {
				IF (Test-Path -Path $FilePath -PathType Leaf) {
					FOREACH ($Protocol IN $Protocols) {
						$NewFirewallRule = New-NetFirewallRule -DisplayName "$FirewallDisplayName" -Description "$FirewallRuleDescription" -Direction Inbound -Program "$FilePath" -Protocol $Protocol -Action Allow -EdgeTraversalPolicy DeferToUser -Enabled True
						IF ($NewFirewallRule) {
							Write-Log -Message "Created new $Protocol Firewall Rule: $FirewallDisplayName" -Severity 1 -Source ${CmdletName}
						} ELSE {
							Write-Log -Message "Failed to create $FirewallDisplayName rule for protocol $Protocol." -Severity 2 -Source ${CmdletName}
						}
					}
				} ELSE {
					Write-Log -Message "Could not create new firewall rule, target file for rule not found." -Severity 2 -Source ${CmdletName}
				}
			} CATCH {
				Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			}
			
			#endregion Create New Firewall Rules
		} CATCH {
			Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	END {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion FUNCTION Create-FirewallRule

#region FUNCTION Upload-FTP
FUNCTION Upload-FTP {
	<#
			.SYNOPSIS
			Uploading to FTP site
	
			.DESCRIPTION
			A detailed description of the Upload-FTP function.
	
			.PARAMETER File
			A description of the File parameter.
	
			.PARAMETER User
			A description of the User parameter.
	
			.PARAMETER Password
			A description of the Password parameter.
	
			.PARAMETER URI
			A description of the URI parameter.
	
			.EXAMPLE
				PS C:\> Upload-FTP -File $value1 -User $value2 -Password $value3 -URI $value4
	
			.NOTES
				https://stackoverflow.com/a/2485696/537243
	#>
	
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true)]$File,
		[Parameter(Mandatory = $true)]$User,
		[Parameter(Mandatory = $true)]$Password,
		[Parameter(Mandatory = $true)]$URI
	)
	BEGIN {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	PROCESS {
		TRY {
			[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
			Write-Log -Message "Uploading to FTP Site: $($URI)" -Severity 1 -Source ${CmdletName}
			$baseURI = "ftp://$([System.Web.HttpUtility]::UrlEncode($User)):$([System.Web.HttpUtility]::UrlEncode($Password))@$($URI)"

			$LocalFile = Get-Item $File -ErrorAction Stop
			Write-Log -Message "File to upload: $($LocalFile.FullName)" -Severity 1 -Source ${CmdletName}
			$RemoteFile = $LocalFile.Name
			$ftpURI = "$($baseURI)/$($RemoteFile)"
			$webclient = New-Object -TypeName System.Net.WebClient
			$ftpURI = New-Object -TypeName System.Uri -ArgumentList $ftpURI
			$webclient.UploadFile($ftpURI, $($LocalFile.FullName))
			Write-Log -Message "Upload Succeeded" -Severity 1 -Source ${CmdletName}
		} CATCH {
			Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	END {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion FUNCTION Upload-FTP

#region FUNCTION Verb-Noun
#FUNCTION Verb-Noun {
<#
		.SYNOPSIS
		.DESCRIPTION
		.PARAMETER
		.EXAMPLE
		.NOTES
		.LINK
		http://psappdeploytoolkit.com
#>
<#	[CmdletBinding()]
		PARAM (
		)
	
		BEGIN {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
		}
		PROCESS {
		TRY {
			
		} CATCH {
			Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
		}
		END {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
		}
		}
#>
#endregion FUNCTION Verb-Noun

#region FUNCTION Create-7zip
FUNCTION Create-7zip {
	<#
			.SYNOPSIS
			Creates 7zip files from contents of directory
	
			.DESCRIPTION
			A detailed description of the Create-7zip function.
	
			.PARAMETER Directory
			A description of the Directory parameter.
	
			.PARAMETER DestinationFile
			Needs to end in .7z
	
			.PARAMETER PathTo7ZipEXE
			A description of the PathTo7ZipEXE parameter.
	
			.EXAMPLE
			PS C:\> Create-7zip -Directory 'Value1' -DestinationFile 'Value2'
	
			.NOTES
			Additional information about the function.
	#>
	
	PARAM
	(
		[Parameter(Mandatory = $true)][SupportsWildcards()][ValidateNotNullOrEmpty()][String]$Directory,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$DestinationFile,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$PathTo7ZipEXE
	)
	
	BEGIN {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	PROCESS {
		TRY {
			Write-Log -Message "Creating Zip file" -severity 1 -Source ${CmdletName}
			
			[Array]$arguments = "a", "-t7z", "$DestinationFile", "$Directory"
			$Result = Execute-Process -Path $PathTo7ZipEXE -Parameters $arguments -PassThru
			Write-Log -Message "Zip file attempt finished" -severity 1 -Source ${CmdletName}
			Write-Output $Result
		} CATCH {
			Write-Log -Message "<error message>. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
		}
	}
	END {
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion FUNCTION Create-7zip

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