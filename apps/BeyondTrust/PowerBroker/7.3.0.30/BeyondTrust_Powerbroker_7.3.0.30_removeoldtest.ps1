﻿<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
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
	[switch]$AllowRebootPassThru = $true,
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
	[string]$appVendor = 'BeyondTrust Software, Inc.'
	[string]$appName = 'BeyondTrust PowerBroker Client for Windows'
	[string]$appVersion = '7.3.0.30'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '10/11/2017'
	[string]$appScriptAuthor = 'Nicolas Wendlowsky'
	##*===============================================
    ##Code to switch Deploy Mode based on runnings applications
	## Code to switch Deploy Mode
    <## -- when running interactive, check whether process is running. If not, then change to silent
	$checkApps = "BeyondTrust.SessionMonitoring.Service","PowerBroker","btservice"

    $runningApps = 0
	$StartingDeployMode = $DeployMode

    If ($DeployMode -eq 'Interactive') {
        ForEach ($app in $checkApps) {
            If (Get-Process -Name $app -ErrorAction SilentlyContinue) {
            $runningApps = $runningApps + 1
            }
        }
        If ($runningApps -gt 0) {
			$runningAppsMessage =  "Running apps detected. Mode stays at"
        }
        ElseIf ($runningApps -eq 0) {
            $DeployMode = 'Silent'
			$runningAppsMessage =  "Running apps NOT detected. Mode switches to"
        }
    }
    #End Code 
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
	[version]$deployAppScriptVersion = [version]'3.6.9'
	[string]$deployAppScriptDate = '02/12/2017'
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
	<#Log Entries from code
	Write-Log -Message "Starting Mode: $StartingDeployMode." -Severity 1 -Source $deployAppScriptFriendlyName
	Write-Log -Message "Checking for running apps: $checkApps." -Severity 1 -Source $deployAppScriptFriendlyName
	Write-Log -Message "$runningAppsMessage $DeployMode." -Severity 2 -Source $deployAppScriptFriendlyName
	#>		
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		## Show Welcome Message
		#Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		
		## <Perform Pre-Installation tasks here>
		$Term = 'chrome'
		$Processes = Get-Process | Where-Object {$_.Description -like "*$Term*" -or $_.Name -like "*$Term*" -or $_.ProcessName -like "*$Term*" -or $_.Product -like "*$Term*"} | Select-Object Name, ProcessName, Description, Product
		$Services = Get-Service | Where-Object {$_.DisplayName -like "*$Term*"} | Select-Object servicename, name, starttype, status
		
		$Services | ForEach-Object{
			if ($_.StartType -ne 'Manual' -or $_.StartType -ne 'Disabled') {
				Try {
					Set-Service -Name $_.Name -StartupType $ServSet -WhatIf
					Write-Log -Message  "Setting Service "$_.Name" to $ServSet." -Severity 1 -Source $installPhase
				} Catch {
					Write-Log -Message "Error setting "$_.Name" service to $ServSet." -Severity 2 -Source $installPhase
				}
			}
			if ($_.Status -ne 'Stopped') {
				Try {
					Stop-Service -Name $_.Name -WhatIf # -Force
					Write-Log -Message "Stopped service "$_.Name"." -Severity 1 -Source $installPhase
				} Catch {
					Write-Log -Message "Error stopping "$_.Name" service." -Severity 2 -Source $installPhase
				}
			}
		}
		
		$Processes | ForEach-Object{
			try {
				Stop-Process -Name $_.Name -WhatIf # -Force
				Write-Log -Message "Stopped process "$_.Name"." -Severity 1 -Source $installPhase
			} catch {
				Write-Log -Message "Error stopping process "$_.Name"." -Severity 2 -Source $installPhase
			}
		}
		#
		$processes = "btmonitor","btservice","privman"
        foreach($process in $processes){
		    Stop-Process -Name "$Process*" -Force
            Write-Log -Message "Stopped Process: $Process." -Severity 1 -Source $deployAppScriptFriendlyName
        }

		
		$PrePB_exitCode = Remove-MSIApplications -Name "BeyondTrust PowerBroker Desktops Client for Windows" -PassThru
        $PreMSI_exitCode = Remove-MSIApplications -Name "BeyondTrust Certificate Installer"
        if($PrePB_exitCode.ExitCode -eq 3010 -or $PreMSI_exitCode.ExitCode -eq 3010){
            Write-Log -Message "Exit code: 3010"
            Show-InstallationPrompt -Message "A previous version of $appName was uninstalled and requires a reboot before installing version $appVersion. Please re-run installer after restart."  -ButtonMiddleText 'Reboot' -Icon Warning -PersistPrompt $true -MinimizeWindows $true
            Show-InstallationRestartPrompt -Countdownseconds 1200 -CountdownNoHideSeconds 1200
            #Exit-Script -ExitCode 3010
        }
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		## <Perform Installation tasks here>
        Execute-MSI -Action Install -Path 'certinstaller.msi'		
        Execute-Process -Path "$envSystem32Directory\certutil.exe" -Parameters "-f -p `"Pork Sandwich Best Friday`" -importpfx `"$dirFiles\cert2.pfx`"" -SecureParameters
        $PBexitCode = Execute-MSI -Action Install -Path 'PowerBroker for Windows Client (64 Bit) 7.3.msi' -AddParameters 'ADDLOCAL=PBWClient,Client_x64,Runtime_x64,SessionMonitor_x64,IEIntegration_x64,CPIntegration,EventMonitor_x64,FileIntegrity_x64 SERVER=BeyondInsight' -PassThru
        if($PBexitCode.ExitCode -eq 3010){
            Write-Log -Message "Exit code: 3010"
            Show-InstallationRestartPrompt -Countdownseconds 1200 -CountdownNoHideSeconds 1200
            #Exit-Script -ExitCode 3010
        }		
#>
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
		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		#Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 300
		
		## <Perform Pre-Uninstallation tasks here>

		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		# <Perform Uninstallation tasks here>

		
		$processes = "btmonitor", "btservice", "privman"
		foreach ($process in $processes) {
			Stop-Process -Name "$Process*" -Force
			Write-Log -Message "Stopped Process: $Process." -Severity 1 -Source $deployAppScriptFriendlyName
		}
		
		$PrePB_exitCode = Remove-MSIApplications -Name "BeyondTrust PowerBroker Desktops Client for Windows" -PassThru
		$PreMSI_exitCode = Remove-MSIApplications -Name "BeyondTrust Certificate Installer"
		if ($PrePB_exitCode.ExitCode -eq 3010 -or $PreMSI_exitCode.ExitCode -eq 3010) {
			Write-Log -Message "Exit code: 3010"
			Show-InstallationPrompt -Message "A previous version of $appName was uninstalled and requires a reboot before installing version $appVersion. Please re-run installer after restart." -ButtonMiddleText 'Reboot' -Icon Warning -PersistPrompt $true -MinimizeWindows $true
			Show-InstallationRestartPrompt -Countdownseconds 1200 -CountdownNoHideSeconds 1200
			#Exit-Script -ExitCode 3010
		}
		
		#PB
		#Execute-MSI -Action Uninstall -Path '{9DFCB69B-BCAB-47C3-89F1-2A2D69F8567A}' -PassThru
		$PBexitCode = Remove-MSIApplications -Name "BeyondTrust PowerBroker Desktops Client for Windows" -PassThru
		#CertUtil
		Execute-MSI -Action Uninstall -Path '{9DFCB69B-BCAB-47C3-89F1-2A2D69F8567A}'
		Remove-MSIApplications -Name "BeyondTrust Certificate Installer"
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		## <Perform Post-Uninstallation tasks here>

        if($PBexitCode.ExitCode -eq 3010){
            Write-Log -Message "Exit code: 3010"
            Show-InstallationRestartPrompt -Countdownseconds 1200 -CountdownNoHideSeconds 1200
            #Exit-Script -ExitCode 3010
        }
		
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