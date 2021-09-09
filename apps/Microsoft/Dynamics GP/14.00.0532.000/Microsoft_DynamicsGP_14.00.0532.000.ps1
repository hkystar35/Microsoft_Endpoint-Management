<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows. 
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. 
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
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
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'Microsoft Corporation'
	[string]$appName = 'Microsoft Dynamics GP'
	[string]$appVersion = '14.00.0532.000'
	[string]$appMSIProductCode = '{CF6D9CA6-A969-4809-92AF-49B96C4FB838}'
	[string]$appProcessesString = $false #'' # comma-separated, but all inside sigle quote, like 'chrome,firefox,iexplore'
	[string]$appServicesString = $false #'' # comma-separated, but all inside sigle quote, like 'zoom,ccmexec,spotify'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '06/25/2018'
	[string]$appScriptAuthor = 'Nicolas Wendlowsky'
	##*===============================================
	#Do not modify these variables:
	$appProcesses = $appProcessesString -split (',')
	$appServices = $appServicesString -split (',')
	## Change DeployMode to Interactive if running processes detected that need to be closed.
	#region ChangeDeployMode
	## Leave $appProcessesString variable at '' or $NULL and this will be skipped.
    ## -- when running interactive/noninteractive, check whether process is running. If not, then change to Silent.
	$StartingDeployMode = $DeployMode
	If (($DeployMode -ne 'Silent') -or !($appProcessesString)) {
		$SkipProcessesCheck = 'YES'
	} elseif ($DeployMode -eq 'Silent' -and ($appProcessesString)) {
		$runningApps = 0
		$appProcesses | ForEach-Object{
			If (Get-Process -Name $_ -ErrorAction SilentlyContinue) {
				$runningApps += 1
				[array]$runningAppNames += $_
			}
		}
		If ($runningApps -gt 0) {
			$DeployMode = 'Interactive'
		} Elseif ($runningApps -eq 0) {
			$DetectedApps = ''
		}
	}
	#endregion
	#>
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.7.0'
	[string]$deployAppScriptDate = '02/13/2018'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}
	
	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
	#Log Entries Change DeployMode
		Write-Log -Message ('Starting Mode: {0}.' -f $StartingDeployMode) -Severity 1 -Source $deployAppScriptFriendlyName
		if ($SkipProcessesCheck -eq 'YES') {
			Write-Log -Message 'DeployMode is not Silent and/or there are no processes to detect. No change to DeployMode' -Severity 1 -Source $deployAppScriptFriendlyName
		}
		if ($SkipProcessesCheck -ne 'YES') {
			Write-Log -Message ('Checked for {0} running apps: {1}.' -f $appProcesses.Count,$appProcessesString) -Severity 1 -Source $deployAppScriptFriendlyName
			if ($DetectedApps -ne '') {
				$DetectedApps = " ($($runningAppNames))"
			}
			Write-Log -Message ('{0} Apps{1} detected. Mode is {2}' -f $runningApps, $DetectedApps, $DeployMode) -Severity 2 -Source $deployAppScriptFriendlyName
		}
	#>		
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		## Show Welcome Message
		if ($appProcessesString) {
			Show-InstallationWelcome -CloseApps "$appProcessesString" -AllowDeferCloseApps -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		} else {
			Show-InstallationWelcome -AllowDeferCloseApps -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		}
		
		## <Perform Pre-Installation tasks here>
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		#Variables
		$Server = 'INT-GP-01'
		
		## <Perform Installation tasks here>
		#region Pre-Reqs
			# Lync SDK
			Execute-MSI -Action Install -Path "$dirFiles\redist\LyncSdkRedist\LyncSdkRedist.msi"
			
			# Windows Installer 4.5 (should not be needed)
			
			# SQL Native CLient
			Execute-MSI -Action Install -Path "$dirFiles\redist\SqlNativeClient\sqlncli_x64.msi" -AddParameters "IACCEPTSQLNCLILICENSETERMS=YES"
			
			# Dexterity Shared Components
			Execute-MSI -Action Install -Path "$dirFiles\redist\DexteritySharedComponents\Microsoft_Dexterity14_SharedComponents_x64_en-us.msi"
			
			# Watson
			Execute-MSI -Action Install -Path "$dirFiles\redist\Watson\dw20sharedamd64.msi" -AddParameters "APPGUID={F1B57F7A-EACA-488C-A900-B064D679E3D7}"
			
			# OpenXML
			Execute-MSI -Action Install -Path "$dirFiles\redist\OpenXmlFormatSDK\OpenXMLSDKv2.msi"
			
		#endregion Pre-Reqs
		
		#region Install Great Plains and patch
		Execute-MSI -Action Install -Path 'GreatPlains.msi' -Patch 'MicrosoftDynamicsGP14-KB3045195-ENU.msp'
		#endregion Install Great Plains and patch
		
		#region Set ODBC connection
		Execute-Process -Path "$envWinDir\SysWOW64\odbcconf.exe" -Parameters "CONFIGSYSDSN `"SQL Server Native Client 11.0`" `"DSN=GP 2015|SERVER=$($Server)|TRUSTED_CONNECTION=NO`""
		
		$KeyNamesValues = 	"Driver,C:\WINDOWS\SysWOW64\sqlncli11.dll",
							"Server,$($Server)",
							"LastUser,sa",
							"QuotedId,No",
							"AnsiNPW,No",
							"AutoTranslate,No"
		$KeyNamesValues | ForEach-Object{
			$Value = $_ -split (',')
			Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\GP 2015' -Name $($Value[0]) -Value $($Value[1])
		}
		#endregion Set ODBC connection
		
		#region Install add-ins
			
			#Smart List Builder
				Execute-MSI -Action Install -Path "$dirFiles\Add-ins\SmartList Builder 2015 (14.00.0004)\SmartListBuilder2015.msi"
			
			#Collections Management
				Execute-Process -Path "$dirFiles\Add-ins\Collections Management\CM_and_CDA_2015_Setup.exe" -Parameters "/sp- /verysilent /SUPPRESSMSGBOXES /LOG=`"$configToolkitLogDir\CM_and_CDA_2015_$($installPhase).log`" /NORESTART"
			
			#Management Reporter
				Execute-MSI -Action Install -Path "$dirFiles\Add-ins\MR\mrclient_x64.msi" -Transform "$dirFiles\Add-ins\MR\MR.mst"
			
			#Extender
				Execute-MSI -Action Install -Path "$dirFiles\Add-ins\Extender 2015 (14.00.0050)\Extender 2015.msi"
		
		#endregion Install add-ins
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>
		
		#region Get GP install directory
			$GPInstallDir = Get-InstalledApplication -Name "Microsoft Dynamics GP 2015"
			IF ($GPInstallDir.Count -gt 1) {
				$GPInstallDir | ForEach-Object{
					IF (($_.InstallLocation) -and ($_.InstallLocation -ne $null) -and ($_.InstallLocation -ne '')) {
						$GPInstallLocation = $_.InstallLocation
					}
				}
			}ELSE{ $GPInstallLocation = $GPInstallDir.InstallLocation}
		#endregion Get GP install directory
	
		#region Change ACL on $GP_Dir
			$UserName = $CurrentLoggedOnUserSession.NTAccount
			$ModifyFolders = Get-ChildItem $GP_Dir -Directory
			$ModifyFolders | ForEach-Object{
				$Path = $_.FullName
				$ACL = (Get-Item $Path).GetAccessControl('Access')
				$AR = New-Object System.Security.AccessControl.FileSystemAccessRule($UserName, 'Modify', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
				$ACL.SetAccessRule($AR)
				Set-Acl -Path $Path -AclObject $ACL
			}
		#endregion Change ACL on $GP_Dir
		
		#region copy GPShare and WilloWare CTK files
		$GPShare_Files = '\\INT-GP-01\GPShare'
		$PSDrive = New-PSDrive -Name GP -Root $GPShare_Files -PSProvider FileSystem -WhatIf
		Copy-File -Path "$GPShare_Files\R309.DIC" -Destination $GPInstallLocation\Data
		Copy-File -Path "$GPShare_Files\R309.DIC" -Destination $GPInstallLocation\Data
		Copy-File -Path "$dirFiles\CTK\4600W.CNK" -Destination $GPInstallLocation
		Copy-File -Path "$dirFiles\CTK\4600W.DIC" -Destination $GPInstallLocation
		Copy-File -Path "$dirFiles\CTK\Documentation\ConsultingToolkit.chm" -Destination "$GPInstallLocation\Documentation"
		Copy-File -Path "$dirFiles\CTK\Documentation\ConsultingToolkit.pdf" -Destination "$GPInstallLocation\Documentation"
		
		#endregion copy GPShare and WilloWare CTK files
		
		#region Configure GP
		
		# %ProgramFiles(x86)%\Microsoft Dynamics\GP2015
		
		#endregion Configure GP
		
		## Display a message at the end of the install
		#Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
		## Show Welcome Message, close $appServicesString processes with a 60 second countdown before automatically closing
		if ($appProcessesString) {
			Show-InstallationWelcome -CloseApps "$appProcessesString" -CloseAppsCountdown 300
		}
		
		## <Perform Pre-Uninstallation tasks here>
		
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		
		# <Perform Uninstallation tasks here>
		
		#region Uninstall MSIs
			$MSIs = '{8AF10E19-4330-4077-A1B5-491ACDC24B08}', <#LyncSdkRedist#>
					'{D411E9C9-CE62-4DBF-9D92-4CB22B750ED5}', <#SQL Native Client#>
					'{F1B57F7A-EACA-488C-A900-B064D679E3D7}', <#DexteritySharedComponents#>
					'{91730409-8000-11D3-8CFE-0150048383C9}', <#Watson dw20sharedia64#>
					'{171D8D76-3F05-455A-A8AF-C561C2679905}', <#OpenXmlFormatSDK#>
					'{CF6D9CA6-A969-4809-92AF-49B96C4FB838}', <#GreatPlains#>
					'{885AF052-1940-4D58-BD72-F27470935178}', <#SmartList Builder 2015 (Not in SCCM Detection Method)#>
					'{968B9128-1D4A-87D3-2EDE-B85C3858566C}', <#mrclient_x64#>
					'{D60D729C-3F37-4AE6-AEF1-68E9E0E1DD0F}', <#Extender 2015 (Not in SCCM Detection Method)#>
					'{031A6ABD-04A9-48A0-944C-706845B963C9}'  <#SmartConnect (Not in SCCM Detection Method)#>
			$MSIs | ForEach-Object{
				Execute-MSI -Action Uninstall -Path "$($_)"
			}
		#endregion Uninstall MSIs
		
		#region Delete ODBC connection
			Remove-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\ODBC\ODBC.INI\GP 2015'
		#endregion Delete ODBC connection
		
		#region delete GPShare and WilloWare CTK files
		$GP_Dir = "$envProgramFilesX86\Microsoft Dynamics\GP2015"
		$CTK_Dir = Join-Path -Path $GP_Dir -ChildPath 'Documentation'
		$CTK_DirFiles = 'ConsultingToolkit.chm', 'ConsultingToolkit.pdf'
		$CTK_Files = '4600W.CNK', '4600W.DIC'
		$GPShare_Files = 'R309.DIC', 'REPORTS.DIC'
		
		$CTK_DirFiles | ForEach-Object{
			Remove-File -Path $CTK_Dir\$_
		}
		$CTK_Files | ForEach-Object{
			Remove-File -Path $GP_Dir\$_
		}
		$GPShare_Files | ForEach-Object{
			Remove-File -Path $GP_Dir\Data\$_
		}
		#endregion delete GPShare and WilloWare CTK files
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		## <Perform Post-Uninstallation tasks here>
		
		## Display a message at the end of the uninstall
		#Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended uninstallations.' -ButtonRightText 'OK' -Icon Information -NoWait
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}