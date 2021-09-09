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
PARAM (
	[Parameter(Mandatory = $false)][ValidateSet('Install', 'Uninstall')][string]$DeploymentType = 'Install',
	[Parameter(Mandatory = $false)][ValidateSet('Interactive', 'Silent', 'NonInteractive')][string]$DeployMode = 'Interactive',
	[Parameter(Mandatory = $false)][switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory = $false)][switch]$TerminalServerMode = $false,
	[Parameter(Mandatory = $false)][switch]$DisableLogging = $false
)

TRY {
	## Set the script execution policy for this process
	TRY {
		Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
	} CATCH {
	}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'Microsoft Corporation'
	[string]$appName = 'Microsoft Dynamics CRM 2016 for Microsoft Office Outlook'
	[string]$appVersion = '8.1.0000.0371'
	[string]$appBaseVersion = '8.0.0000.0000'
	[string]$appMSIProductCode = '{0C524D20-0409-0080-8A9E-0C4C490E4E54}' # base install version 8.0.0000.0000
	[string]$appProcessesString = 'outlook,calendly' # comma-separated, but all inside sigle quote, like 'chrome,firefox,iexplore'
	[string]$appServicesString = $false #'' # comma-separated, but all inside sigle quote, like 'zoom,ccmexec,spotify'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '04'
	[string]$appScriptVersion = '1.3.0'
	[string]$appScriptDate = '03/26/2019'
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
	IF (($DeployMode -ne 'Silent') -or !($appProcessesString)) {
		$SkipProcessesCheck = 'YES'
	} ELSEIF ($DeployMode -eq 'Silent' -and ($appProcessesString)) {
		$runningApps = 0
		$appProcesses | ForEach-Object{
			IF (Get-Process -Name $_ -ErrorAction SilentlyContinue) {
				$runningApps += 1
				[array]$runningAppNames += $_
			}
		}
		IF ($runningApps -gt 0) {
			$DeployMode = 'Interactive'
		} ELSEIF ($runningApps -eq 0) {
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
	IF (Test-Path -LiteralPath 'variable:HostInvocation') {
		$InvocationInfo = $HostInvocation
	} ELSE {
		$InvocationInfo = $MyInvocation
	}
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	TRY {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		IF (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
			THROW "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
		}
		IF ($DisableLogging) {
			. $moduleAppDeployToolkitMain -DisableLogging
		} ELSE {
			. $moduleAppDeployToolkitMain
		}
	} CATCH {
		IF ($mainExitCode -eq 0) {
			[int32]$mainExitCode = 60008
		}
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		IF (Test-Path -LiteralPath 'variable:HostInvocation') {
			$script:ExitCode = $mainExitCode; EXIT
		} ELSE {
			EXIT $mainExitCode
		}
	}
	
	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
	#Log Entries Change DeployMode
	Write-Log -Message ('Starting Mode: {0}.' -f $StartingDeployMode) -Severity 1 -Source $deployAppScriptFriendlyName
	IF ($SkipProcessesCheck -eq 'YES') {
		Write-Log -Message 'DeployMode is not Silent and/or there are no processes to detect. No change to DeployMode' -Severity 1 -Source $deployAppScriptFriendlyName
	}
	IF ($SkipProcessesCheck -ne 'YES') {
		Write-Log -Message ('Checked for {0} running apps: {1}.' -f $appProcesses.Count, $appProcessesString) -Severity 1 -Source $deployAppScriptFriendlyName
		IF ($DetectedApps -ne '') {
			$DetectedApps = " ($($runningAppNames))"
		}
		Write-Log -Message ('{0} Apps{1} detected. Mode is {2}' -f $runningApps, $DetectedApps, $DeployMode) -Severity 2 -Source $deployAppScriptFriendlyName
	}
	#>		
	IF ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		## Show Welcome Message
		IF ($appProcessesString) {
			Show-InstallationWelcome -CloseApps "$appProcessesString" -AllowDeferCloseApps -DeferTimes 3 -CheckDiskSpace -PersistPrompt -BlockExecution -CloseAppsCountdown 1800
		} ELSE {
			Show-InstallationWelcome -AllowDeferCloseApps -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		}
		## <Perform Pre-Installation tasks here>
		
		#region remove previous installs if needed
		$GetCRMInstalls = @()
		$GetCRMInstalls += Get-InstalledApplication -Name 'Dynamics' | Where-Object{
			$_.Publisher -like "*Microsoft*" -and
			$_.DisplayName -notlike "*Language Pack*"
		}
		$CRMUninstall = @()
		IF ($GetCRMInstalls -or $GetCRMInstalls.count -ge 1) {
			$GetCRMInstalls | ForEach-Object{
				IF ([system.Version]$_.DisplayVersion -lt [system.Version]$appBaseVersion) {
					$CRMUninstall += $_
				} ELSEIF ([system.Version]$_.DisplayVersion -ge [system.Version]$appBaseVersion) {
					Write-Log -Message "Existing CRM plugin installed: $($_.DisplayName) version $($_.DisplayVersion)." -Severity 1 -Source $installPhase
					$DynamicsAlreadyInstalled = $true
				}
			}
		} ELSEIF (!$GetCRMInstalls -or $GetCRMInstalls.count -eq 0) {
			$DynamicsAlreadyInstalled = $false
			Write-Log -Message "No existing CRM plugins to uninstall." -Severity 1 -Source $installPhase
		}
		
		IF ($CRMUninstall) {
			$CRMUninstall | Where-Object{$_.UninstallString -like "*SetupClient.exe*"} | ForEach-Object{
				# Attempt to remove existing server connections
				$CRMUninstallConfigRemove = Execute-Process -Path "$($_.InstallLocation)ConfigWizard\Microsoft.Crm.Application.Outlook.ConfigWizard.exe" -Parameters "/q /XA /l `"$($configToolkitLogDir)\$($appName)_ConfigWiz_RemoveExisting.log`"" -PassThru -IgnoreExitCodes '2,-2'
				Write-Log -Message "Config removal for $($_.DisplayName) version $($_.DisplayVersion) exit: $($CRMUninstallConfigRemove)" -Severity 2 -Source $installPhase
				Write-Log -Message "Existing CRM plugin found, attempting to uninstall $($_.DisplayName) version $($_.DisplayVersion)." -Severity 2 -Source $installPhase
				
				#region CRM Garbage cleanup for registry
				
				# Set block of HKCU keys to remove
				[scriptblock]$DeleteKeys_HKCU = {
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Microsoft Dynamics CRM 2013 for Microsoft Office Outlook' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Microsoft Dynamics CRM 2011 for Microsoft Office Outlook' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\MSCRM' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\MSCRMClient' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\MSCRMMsgStore' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\MSCRMIntegration' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Office\Outlook\Addins\crmaddin.RibbonAddin' -SID $UserProfile.SID
				}
				
				# Set block of HKLM keys to remove
				$DeleteKeys = 'HKEY_LOCAL_MACHINE\Software\Microsoft\MSCRM',
				'HKEY_LOCAL_MACHINE\Software\Microsoft\MSCRMClient',
				'HKEY_LOCAL_MACHINE\Software\Microsoft\MSCRMIntegration',
				'HKEY_LOCAL_MACHINE\Software\Microsoft\Office\Outlook\Addins\crmaddin.Addin'
				
				# Delete HKLM keys
				$DeleteKeys | ForEach-Object{
					Remove-RegistryKey -Key $_
				}
				
				# Delete HKCU keys
				Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $DeleteKeys_HKCU
				
				#endregion CRM Garbage cleanup for registry
				
				$Uninstaller = ($_.uninstallstring).split('/')[0]
				$Uninstaller = $Uninstaller.TrimEnd()
				Execute-Process -Path $Uninstaller -Parameters "/X /Q /LV `"$($configToolkitLogDir)\$($appName)_$($_.DisplayName)-$($_.DisplayVersion)_Uninstall.log`""
			}
		}
		
		
		#endregion remove previous installs if needed
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		## <Perform Installation tasks here>
		
		#region Set config XML
		#$CRM_URL = 'https://crm.paylocity.com' # Old URL, pre-Modern Auth
		$CRM_Org = 'Paylocity'
		$CRM_URL = 'https://int-crm-web-01.paylocity.com'

		[string]$XML_Content = @"
<Deployments>
	<Deployment>
		<DiscoveryUrl>$($CRM_URL)</DiscoveryUrl>
		<Organizations>
			<Organization IsPrimary='true'>$($CRM_Org)</Organization>
			<Organization>$($CRM_Org)</Organization>
		</Organizations>
		<CEIPNotification>false</CEIPNotification>
	</Deployment>
</Deployments>
"@
		#endregion Set config XML
		
		# Get Office info
		$OfficeInfo = Get-OfficeInfo
		
		# If Office not installed, exit script
		IF ($OfficeInfo) {
			# Try installing for the latest Outlook version installed
			FOREACH ($App IN $OfficeInfo) {
				
				# Only try on Office installs with Outlook installed; weeds out combo installs and language packs
				IF ($App.Bitness) {
					#region Set Office version variables
					SWITCH ($App.Bitness) {
						'x64' {
							$Bitness = 'x64'; $Bitness_hotfix = 'amd64'
						}
						'x86' {
							$Bitness = 'x86'; $Bitness_hotfix = 'i386'
						}
					}
					IF ($App.Year -like "*365*") {
						$Year = '2016'
					} ELSE {
						$Year = $App.Year
					}

					# Office 2019 still uses Major Version 16.0
					IF ($App.Year -eq "2019" -and $App.Version -ne '16.0') {
						$Version = '16.0'
					}ELSE{
						$Version = $App.Version
					}
					$Bitness = $App.Bitness
					#endregion Set Office version variables
					
					#region Source paths
					$InstallerPath = "$dirFiles\$Bitness\Install"
					$HotfixPath    = "$dirFiles\$Bitness\Hotfixes"
					#endregion Source paths
					
					#region Install Base Dynamics CRM
					IF (!$DynamicsAlreadyInstalled) {
						# Path to extract setup files to based on bitness
						$InstallerExtractPath = Join-Path $InstallerPath "Extracted"
						New-Folder -Path $InstallerExtractPath
						
						# Extract Installer based on bitness
						$Extract = Execute-Process -Path "$InstallerPath\CRM2016-Client-ENU-$($Bitness_hotfix).exe" -Parameters "/Extract:`"$($InstallerExtractPath)`" /quiet /log:`"$($configToolkitLogDir)\CRM_exe_ExtractFiles.log`"" -WaitForMsiExec -PassThru
						
						IF ($Extract.ExitCode -eq 0) {
							# Install base application based on bitness
							#region Prerequisites
							$PrerequisitePath = "$dirFiles\Prerequisites"
							# Microsoft SQL Server 2012 Express - SQLEXPR_x64
								#Execute-Process -Path "$PrerequisitePath\SQLEXPR_x64_ENU.exe" -Parameters ""
							# Microsoft .NET Framework 4.5.2.
							# Microsoft Windows Installer 4.5.
							# Microsoft Visual C++ Redistributable.
							# Microsoft Report Viewer 2010.
							# Microsoft Application Error Reporting.
							# Windows Identity Foundation (WIF).
							# Microsoft SQL Server Native Client.
								Execute-MSI -Action Install -Path "$PrerequisitePath\sqlncli_x64.msi" -AddParameters "IACCEPTSQLNCLILICENSETERMS=YES"
							# Microsoft SQL Server Compact 4.0.
								$SSCEFile = "$PrerequisitePath\SSCERuntime_x64-ENU.msi"
								$SSCEexisting = Get-InstalledApplication -Name "Microsoft SQL Server Compact"
								$SSCEFileSourceVersion = Get-MSIinfo -Path $SSCEFile -Property ProductVersion
								$SSCEFileSourceVersion = $SSCEFileSourceVersion | ?{$_ -ne $null}
								IF(!$SSCEexisting -or ([version]$SSCEexisting.DisplayVersion -lt [version]$SSCEFileSourceVersion)){
									Write-Log -Message "Current version is ($($SSCEFileSourceVersion)), which is less than source version ($($SSCEexisting.DisplayVersion))"
									Execute-MSI -Action Install -Path $SSCEFile
									#Execute-Process -Path $SSCEFile -Parameters "/I /QN REBOOT=REALLYSUPPRESS /L*V `"$($configToolkitLogDir)\SSCERuntime_x64-ENU.log`""
								}ELSE{
									Write-Log -Message "Current version is ($($SSCEFileSourceVersion)), which is greater than or equal to source version ($($SSCEexisting.DisplayVersion))"
								}
								#PAUSE
								
							# Microsoft System CLR Types for SQL Server 2012
								Execute-MSI -Action Install -Path "$PrerequisitePath\SQLSysClrTypes.msi" -AddParameters "IACCEPTSQLNCLILICENSETERMS=YES"
							

							#msiexec /i ReportViewer.msi /LV* "C:\Windows\Temp\reportviewermsi.log" /qn REBOOT=ReallySuppress
							#wusa.exe Windows6.1-KB974405-x64.msu /quiet /norestart%uFEFF
							#endregion Prerequisites

							$Installer = Execute-Process -Path "$InstallerExtractPath\SetupClient.exe" -Parameters "/Q /LV `"$($configToolkitLogDir)\CRM_exe_Install.log`"" -WaitForMsiExec -PassThru
						} ELSE {
							Write-Log -Message "Unable to extract files. Exiting script." -Severity 3 -Source $installPhase
							Exit-Script -ExitCode $Extract.ExitCode
						}
					} ELSEIF ($DynamicsAlreadyInstalled) {
						Write-Log -Message "Dynamics already installed, skipping." -Severity 2 -Source $installPhase
					}
					#endregion Install Base Dynamics CRM
					
					#region Configuration Wizard
					# Get installed app info for ConfigWizard location
					$InstalledCRM = Get-InstalledApplication -Name 'Microsoft Dynamics' | Where-Object{
						$_.UninstallSubkey -like "Microsoft CRM Client" -and $_.InstallLocation -like "*\Microsoft Dynamics CRM\Client\"
					}
					
					# Attempt to remove existing server connections
                    $ConfigRemove = Execute-Process -Path "$($InstalledCRM.InstallLocation)ConfigWizard\Microsoft.Crm.Application.Outlook.ConfigWizard.exe" -Parameters "/q /XA /l `"$($configToolkitLogDir)\$($appName)_ConfigWiz_RemoveExisting.log`"" -PassThru
					Write-Log -Message "Config removal exit: $($ConfigRemove)" -Severity 2 -Source $installPhase
					
					# Create XML config file
					$XMLPath = Split-Path $InstalledCRM.InstallLocation.TrimEnd('\')
					New-Item -Path $XMLPath -Name Default_Client_Config.xml -ItemType File -Force -OutVariable XMLFile | Set-Content -Value $XML_Content
					Write-Log -Message "Console User: $($CurrentConsoleUserSession.NTAccount)" -Severity 1 -Source $installPhase
					Write-Log -Message "Logged On User: $($CurrentLoggedOnUserSession.NTAccount)" -Severity 1 -Source $installPhase
					
					# Set logged on user
					IF ($CurrentConsoleUserSession) {
						$ProcessAsUser = $CurrentConsoleUserSession
					} ELSE {
						$ProcessAsUser = $CurrentLoggedOnUserSession
					}
					
					# Run ConfigWizard
					# Try to Run Configuration Wizard as User first
					$ConfigAsUser = Execute-ProcessAsUser -UserName $($ProcessAsUser.NTAccount) -Path "$($InstalledCRM.InstallLocation)ConfigWizard\Microsoft.Crm.Application.Outlook.ConfigWizard.exe" -Parameters "/q /i `"$($XMLFile.FullName)`" /XA /l `"$($configToolkitLogDir)\$($appName)_ConfigWiz.log`"" -RunLevel HighestAvailable -Wait -PassThru
					Write-Log -Message "Configuration Wizard Execute-ProcessAsUser ($($ProcessAsUser.NTAccount)) Exit Code: $($ConfigAsUser)" -Severity 1 -Source $installPhase
					IF ($ConfigAsUser -ne 0) {
						Write-Log -Message "Configuration Wizard failed as ($($ProcessAsUser.NTAccount)) with Exit Code $($ConfigAsUser.ExitCode). Will try to run as SYSTEM." -Severity 2 -Source $installPhase
						$ConfigAsSYSTEM = Execute-Process -Path "$($InstalledCRM.InstallLocation)ConfigWizard\Microsoft.Crm.Application.Outlook.ConfigWizard.exe" -Parameters "/q /i `"$($XMLFile.FullName)`" /XA /l `"$($configToolkitLogDir)\$($appName)_ConfigWiz.log`"" -PassThru
						Write-Log -Message "Configuration Wizard Execute-Process as SYSTEM Exit Code: $($ConfigAsSYSTEM.ExitCode)" -Severity 1 -Source $installPhase
						IF ($ConfigAsSYSTEM -eq 0 -or $ConfigAsSYSTEM -eq 3010) {
							Write-Log -Message "Configuration Wizard succeeded as SYSTEM." -Severity 1 -Source $installPhase
						} ELSE {
							Write-Log -Message "Configuration Wizard failed as SYSTEM. Will need to configure URL manually in Outlook." -Severity 3 -Source $installPhase
						}
					}
					#endregion Configuration Wizard
					
					#region Install hotfix
					# Get hotfix from source based on bitness
					$Hotfix = Get-ChildItem -Path $HotfixPath -Filter *$($Bitness_hotfix)*.exe -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
					Write-Log -Message "Hotfix found: $($Hotfix.FullName)" -Severity 1 -Source $installPhase
					
					# Parse hotfix Article ID from source file
					$KB = $Hotfix -split ('-') | Where-Object {$_ -like "kb*"}
					Write-Log -Message "Hotfix Article ID found: $($KB)" -Severity 1 -Source $installPhase
					
					# Get existing KB
					$InstalledHotfix = Get-InstalledApplication -Name 'dynamics' -IncludeUpdatesAndHotfixes | Where-Object{
						$_.UninstallSubkey -like "KB*"
					} | Sort-Object DisplayVersion -Descending | Select-Object -First 1
					IF ($InstalledHotfix) {
						Write-Log -Message "Existing related hotfix already installed: $($InstalledHotfix.DisplayName) version $($InstalledHotfix.DisplayVersion)" -Severity 1 -Source $installPhase
						$InstalledKB = $InstalledHotfix.UninstallSubkey.Split('_') | Where-Object{$_ -like "KB*"}
					}
					
					# Compare KBs
					IF ($InstalledKB -and ($InstalledKB -eq $KB)) {
						Write-Log -Message "Hotfix $($InstalledKB) already installed. Skipping." -Severity 2 -Source $installPhase
					} ELSE {
						Execute-Process -Path $($Hotfix.FullName) -Parameters "/quiet /norestart /log:`"$($configToolkitLogDir)\CRM_Hotfix_$($KB)_Install.log`" CRM.PATCH.ARGS=`"/qn /norestart /L*v `"$($configToolkitLogDir)\CRM_Hotfix_$($KB)-Patch_Install.log`"`"" -IgnoreExitCodes 2
					}
					#endregion Install hotfix

					#region HKCU Keys
				
					# Get Addin Name from Registry
					$searchstring = "*crm*"
					$HKCUAddInKey = Get-ChildItem -Path 'HKCU:\Software\Microsoft\Office\Outlook\Addins\*' | Where-Object{
						$_.PSChildName -like "$($searchstring)"
					} -ErrorAction SilentlyContinue | Select-Object -Last 1
					$HKLMAddInKey = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Office\Outlook\Addins\*' | Where-Object{
						$_.PSChildName -like "$($searchstring)"
					} -ErrorAction SilentlyContinue | Select-Object -Last 1
					$HKLMwowAddInKey = Get-ChildItem -Path 'HKLM:\SOFTWARE\WOW6432node\Microsoft\Office\Outlook\Addins\*' | Where-Object{
						$_.PSChildName -like "$($searchstring)"
					} -ErrorAction SilentlyContinue | Select-Object -Last 1
					IF ($HKCUAddInKey) {
						$AddinName = $HKCUAddInKey.PSChildName
						Write-Log -Message 'HKCU'
					} ELSEIF (!$HKCUAddInKey -and $HKLMAddInKey -and !$HKLMwowAddInKey) {
						$AddinName = $HKLMAddInKey.PSChildName
						Write-Log -Message 'HKLM'
					} ELSEIF (!$HKCUAddInKey -and !$HKLMAddInKey -and $HKLMwowAddInKey) {
						$AddinName = $HKLMwowAddInKey.PSChildName
						Write-Log -Message 'HKLMwow'
					}
					
					IF($Version -and $AddinName){
						[scriptblock]$HKCURegistrySettings = {
							Set-RegistryKey -Key "HKCU\Software\Policies\Microsoft\Office\$($Version)\Outlook\Resiliency\AddinList" -Name "$AddinName" -Value 1 -SID $UserProfile.SID
							Set-RegistryKey -Key "HKCU\Software\Microsoft\Office\$($Version)\Outlook\Resiliency\DoNotDisableAddinList" -Name "$AddinName" -Value 1 -SID $UserProfile.SID
							Remove-RegistryKey -Key "HKCU\Software\Microsoft\Office\$($Version)\Outlook\Resiliency\DisabledItems" -SID $UserProfile.SID
							Set-RegistryKey -Key "HKCU\Software\Microsoft\Office\$($Version)\Outlook\Resiliency\DisabledItems" -SID $UserProfile.SID
							Remove-RegistryKey -Key "HKCU\Software\Microsoft\Office\$($Version)\Outlook\Resiliency\CrashingAddinList" -SID $UserProfile.SID
							Set-RegistryKey -Key "HKCU\Software\Microsoft\Office\$($Version)\Outlook\Resiliency\CrashingAddinList" -SID $UserProfile.SID
							#Set-RegistryKey -Key "HKCU\Software\Microsoft\Office\$($OfficeInfo.version)\Outlook\Resiliency" -Name "CheckPoint" -Value 1
						}
						Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $HKCURegistrySettings
					}ELSE{
						Write-Log -Message "Outlook Add-in Resiliency registry keys not added. Version ($($Version)) or Add-in Name ($($AddinName)) not found." -Severity 2 -Source $installPhase
					}
					#endregion HKCU Keys				

				}
				#region Delete extracted files if install successful
				IF ($Installer.ExitCode -eq 0 -or $Installer.ExitCode -eq 3010) {
					Remove-Folder -Path $InstallerExtractPath
				}
				#endregion Delete extracted files if install successful
				
			}
		} ELSE {
			Write-Log -Message "No installation of Office detected. Skipping install. SCCM will show install as failed." -Severity 3 -Source $installPhase
		}
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		## <Perform Post-Installation tasks here>
		
		
		## Display a message at the end of the install
		#Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait
	} ELSEIF ($deploymentType -ieq 'Uninstall') {
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		## Show Welcome Message, close $appServicesString processes with a 60 second countdown before automatically closing
		IF ($appProcessesString) {
			Show-InstallationWelcome -CloseApps "$appProcessesString" -CloseAppsCountdown 300
		}
		## <Perform Pre-Uninstallation tasks here>
		
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		# <Perform Uninstallation tasks here>
		
		#region Remove previous versions
		$CRMInstalls = @()
		$CRMInstalls = Get-InstalledApplication -Name 'Microsoft Dynamics CRM 2011 for Microsoft Office Outlook'
		$CRMInstalls += Get-InstalledApplication -Name 'Microsoft Dynamics CRM 2013 for Microsoft Office Outlook'
		$CRMInstalls += Get-InstalledApplication -Name 'Microsoft Dynamics CRM 2016 for Microsoft Office Outlook'
		$CRMInstalls += Get-InstalledApplication -Name 'Microsoft Dynamics 365 for Microsoft Office Outlook'
		IF ($CRMInstalls.count -gt 0) {
			$CRMInstalls | Where-Object{
				$_.UninstallString -like "*SetupClient.exe*"
			} | ForEach-Object{
				$Uninstaller = ($_.uninstallstring).split('/')[0]
				$Uninstaller = $Uninstaller.TrimEnd()
                $ConfigRemove = Execute-Process -Path "$($_.InstallLocation)ConfigWizard\Microsoft.Crm.Application.Outlook.ConfigWizard.exe" -Parameters "/q /XA /l `"$($configToolkitLogDir)\CRM_ConfigWiz_RemoveExisting_$($installPhase).log`"" -PassThru
                Write-Log -Message "Config removal exit: $($ConfigRemove)" -Severity 2 -Source $installPhase
				Execute-Process -Path $Uninstaller -Parameters "/X /Q /LV `"$($configToolkitLogDir)\$($_.DisplayName)-$($_.DisplayVersion)_Uninstall.log`""
				
				#region CRM Garbage cleanup for registry
				
				# Set block of HKCU keys to remove
				[scriptblock]$DeleteKeys_HKCU = {
					#Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Microsoft Dynamics 365 for Microsoft Office Outlook' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Microsoft Dynamics CRM 2016 for Microsoft Office Outlook' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Microsoft Dynamics CRM 2015 for Microsoft Office Outlook' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Microsoft Dynamics CRM 2013 for Microsoft Office Outlook' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Microsoft Dynamics CRM 2011 for Microsoft Office Outlook' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\MSCRM' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\MSCRMClient' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\MSCRMMsgStore' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\MSCRMIntegration' -SID $UserProfile.SID
					Remove-RegistryKey -Key 'HKCU\Software\Microsoft\Office\Outlook\Addins\crmaddin.RibbonAddin' -SID $UserProfile.SID
				}
				
				# Set block of HKLM keys to remove
				$DeleteKeys = 'HKEY_LOCAL_MACHINE\Software\Microsoft\MSCRM',
				'HKEY_LOCAL_MACHINE\Software\Microsoft\MSCRMClient',
				'HKEY_LOCAL_MACHINE\Software\Microsoft\MSCRMIntegration',
				'HKEY_LOCAL_MACHINE\Software\Microsoft\Office\Outlook\Addins\crmaddin.Addin'
				
				# Delete HKLM keys
				$DeleteKeys | ForEach-Object{
					Remove-RegistryKey -Key $_
				}
				
				# Delete HKCU keys
				Invoke-HKCURegistrySettingsForAllUsers -RegistrySettings $DeleteKeys_HKCU
				
				#endregion CRM Garbage cleanup for registry
				
				}
		}
		#endregion Remove previous versions
		
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
} CATCH {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}