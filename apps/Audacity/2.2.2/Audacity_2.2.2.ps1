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
	[string]$appVendor = 'Audacity Team'
	[string]$appName = 'Audacity'
	[string]$appVersion = '2.2.2'
	[string]$appMSIProductCode = $false #''
	[string]$appProcessesString = 'Audacity' # comma-separated, but all inside sigle quote, like 'chrome,firefox,iexplore'
	[string]$appServicesString = $false #'' # comma-separated, but all inside sigle quote, like 'zoom,ccmexec,spotify'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '06/29/2018'
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
		
		# Remove previous
		$GetInstalled = Get-InstalledApplication -Name "$appName"
		
		$GetInstalled | ForEach-Object{
			IF ([string]$_.DisplayVersion -as [System.Version] -and ([System.Version]$_.DisplayVersion -lt [system.Version]$appVersion)) {
				$arguments = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LOG=`"$configToolkitLogDir\$($appName)_$($appVersion)_Uninstall.log`""
				$ManualPath = 'Audacity\unins000.exe'
				IF ($_) {
					$UninstallString = $_.UninstallString -Replace ('" "', ';') -Replace ('"', '')
					$Uninstaller = $UninstallString.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
					Write-Log -Message "Regquery worked" -Severity 1 -Source $installPhase
					Execute-Process -Path "$($uninstaller[0])" -Parameters "$arguments" -wait
				} ELSEIF (Test-Path -Path "$envProgramFilesX86\$ManualPath" -PathType Leaf) {
					Write-Log -Message "Used if-then x86" -Severity 1 -Source $installPhase
					Execute-Process -Path "$envProgramFilesX86\$ManualPath" -Parameters $arguments
				} ELSEIF (Test-Path -Path "$envProgramFiles\$ManualPath" -PathType Leaf) {
					Write-Log -Message "Used if-then" -Severity 1 -Source $installPhase
					Execute-Process -Path "$envProgramFiles\$ManualPath" -Parameters $arguments
				}
			}
		}
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		
		## <Perform Installation tasks here>
		Execute-Process -Path 'audacity-win-2.2.2.exe' -Parameters "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LOG=`"$configToolkitLogDir\$($appName)_$($appVersion)_Install.log`""
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>
		
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
		Remove-DesktopShortcut -Name "Audacity" -UseWildCard
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		
		# <Perform Uninstallation tasks here>
		
		$GetInstalled = Get-InstalledApplication -Name "$appName"
		$arguments = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LOG=`"$configToolkitLogDir\$($appName)_$($appVersion)_Uninstall.log`""
		$ManualPath = 'Audacity\unins000.exe'
		IF ($GetInstalled) {
			$UninstallString = $GetInstalled.UninstallString -Replace ('" "', ';') -Replace ('"', '')
			$Uninstaller = $UninstallString.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
			Write-Log -Message "Regquery worked" -Severity 1 -Source $installPhase
			Execute-Process -Path "$($uninstaller[0])" -Parameters "$arguments" -wait
		} ELSEIF (Test-Path -Path "$envProgramFilesX86\$ManualPath" -PathType Leaf) {
			Write-Log -Message "Used if-then x86" -Severity 1 -Source $installPhase
		Execute-Process -Path "$envProgramFilesX86\$ManualPath" -Parameters $arguments
		} ELSEIF (Test-Path -Path "$envProgramFiles\$ManualPath" -PathType Leaf) {
			Write-Log -Message "Used if-then" -Severity 1 -Source $installPhase
		Execute-Process -Path "$envProgramFiles\$ManualPath" -Parameters $arguments
		}
		
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