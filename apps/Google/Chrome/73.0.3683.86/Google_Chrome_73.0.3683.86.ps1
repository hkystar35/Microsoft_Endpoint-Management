﻿<#
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
	[string]$appVendor = 'Google LLC'
	[string]$appName = 'Google Chrome'
	[string]$appVersion = '73.0.3683.86'
	[string]$appMSIProductCode = <#$false #> '{B2F94B3E-055E-3E7A-B2C3-3C63FC1B1C90}'
	[string]$appProcessesString = <#$false #> 'chrome' # comma-separated, but all inside sigle quote, like 'chrome,firefox,iexplore'
	[string]$appServicesString = $false #'' # comma-separated, but all inside sigle quote, like 'zoom,ccmexec,spotify'
	[string]$appArch = 'x64'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.1.0'
	[string]$appScriptDate = '04/01/2019'
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
			Show-InstallationWelcome -CloseApps "$appProcessesString" -ForceCloseAppsCountdown 3600 -PersistPrompt -CheckDiskSpace -BlockExecution
			#-AllowDeferCloseApps -CheckDiskSpace -PersistPrompt -CloseAppsCountdown 1800
		} else {
			Show-InstallationWelcome -CheckDiskSpace -PersistPrompt
		}
		## <Perform Pre-Installation tasks here>
		
		# Remove user-based installs
		$ChromeInstalls = Get-InstalledApplication -Name 'Chrome'

		foreach($ChromeInstall in $ChromeInstalls){
			IF($ChromeInstall.UninstallString -notlike "*msiexec*"){
				$UninstallString = $ChromeInstall.UninstallString -replace '"',';'
				$UninstallString = $UninstallString.Split(';')
				IF(!$UninstallString[0]){
					$UninstallString = $UninstallString[1..($UninstallString.Length-1)]
				}
				IF($UninstallString[0] -like "*setup.exe*" -and $UninstallString[1] -like " --*"){
					[string]$Parameters = "--silent --force-uninstall" + $UninstallString[1]
					Execute-Process -Path "$($UninstallString[0])" -Parameters "$Parameters" -IgnoreExitCodes 20
				}
			}
		}
		
		# Remove installs from AppData folders
		$Users = Get-UserProfiles
		foreach($User in $Users){
			$Uninstall = Get-ChildItem -Path	"$($User.ProfilePath)\AppData\Local\Google\Chrome\Application\*\Installer" -Filter setup.exe -Recurse -ErrorAction SilentlyContinue
			IF(($Uninstall) -and (Test-Path -Path $Uninstall.FullName -PathType Leaf -ErrorAction SilentlyContinue)){
				$ChromeUser = Execute-ProcessAsUser -Path "$($Uninstall.FullName)" -Parameters "--silent --uninstall --force-uninstall" -PassThru -ErrorAction SilentlyContinue -Wait
				Write-Log -Message "Chrome appdata uninstaller exit code: $ChromeUser (Ignore codes 19 and 20)"
			}
		}
		
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		## <Perform Installation tasks here>
		
		Execute-MSI -Action Install -Path 'GoogleChromeStandaloneEnterprise64.msi'
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		## <Perform Post-Installation tasks here>
		
		## Set registry settings
		<#
				[HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome]
 
				"AutoFillEnabled"=dword:00000000
 
				"BackgroundModeEnabled"=dword:00000000
 
				"ComponentUpdatesEnabled"=dword:00000000
 
				"HardwareAccelerationModeEnabled"=dword:00000000
 
				"HideWebStoreIcon"=dword:00000001
 
				"ImportAutofillFormData"=dword:00000000
 
				"ImportHistory"=dword:00000000
 
				"ImportSavedPasswords"=dword:00000000
 
				"ImportSearchEngine"=dword:00000000
 
				"MetricsReportingEnabled"=dword:00000000
 
				"PasswordManagerEnabled"=dword:00000000
 
 
				[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Update]
 
				"AutoUpdateCheckPeriodMinutes"=dword:00000000
 
				"Update{8A69D345-D564-463C-AFF1-A69D9E530F96}"=dword:00000000
		#>
		
		<#
		#Browser
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name AutoFillEnabled -Value 0 -Type DWord
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name BackgroundModeEnabled -Value 0 -Type DWord
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name ComponentUpdatesEnabled -Value 0 -Type DWord
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name HideWebStoreIcon -Value 1 -Type DWord
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name ImportAutofillFormData -Value 0 -Type DWord
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name ImportSavedPasswords -Value 0 -Type DWord
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name MetricsReportingEnabled -Value 0 -Type DWord
		#Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name PasswordManagerEnabled -Value 0 -Type DWord
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name BrowserSignin -Value 0
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name AutofillCreditCardEnabled -Value 0
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name AutofillAddressEnabled -Value 0
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name 
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name 
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name 
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name 
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Chrome' -Name 
		#>
		#Updates
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Update' -Name 'AutoUpdateCheckPeriodMinutes' -Value 0
		Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\Software\Policies\Google\Update' -Name 'Update{8A69D345-D564-463C-AFF1-A69D9E530F96}'
		
		
		
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
		# Remove user-based installs
		$ChromeInstalls = Get-InstalledApplication -Name 'Chrome'
		
		foreach($ChromeInstall in $ChromeInstalls){
			IF($ChromeInstall.UninstallString -notlike "*msiexec*"){
				$UninstallString = $ChromeInstall.UninstallString -replace '"',';'
				$UninstallString = $UninstallString.Split(';')
				IF(!$UninstallString[0]){
					$UninstallString = $UninstallString[1..($UninstallString.Length-1)]
				}
				IF($UninstallString[0] -like "*setup.exe*" -and $UninstallString[1] -like " --*"){
					[string]$Parameters = "--silent --force-uninstall" + $UninstallString[1]
					Execute-Process -Path "$($UninstallString[0])" -Parameters "$Parameters" -IgnoreExitCodes 20
				}
			}
		}
		
		# Remove installs from AppData folders
		$Users = Get-UserProfiles
		foreach($User in $Users){
			$Uninstall = Get-ChildItem -Path	"$($User.ProfilePath)\AppData\Local\Google\Chrome\Application\*\Installer" -Filter setup.exe -Recurse -ErrorAction SilentlyContinue
			IF(($Uninstall) -and (Test-Path -Path $Uninstall.FullName -PathType Leaf -ErrorAction SilentlyContinue)){
				$ChromeUser = Execute-ProcessAsUser -Path "$($Uninstall.FullName)" -Parameters "--silent --uninstall --force-uninstall" -PassThru -ErrorAction SilentlyContinue -Wait
				Write-Log -Message "Chrome appdata uninstaller exit code: $ChromeUser (Ignore codes 19 and 20)"
			}
		}
		
		Remove-MSIApplications -Name 'Google Chrome'
		
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