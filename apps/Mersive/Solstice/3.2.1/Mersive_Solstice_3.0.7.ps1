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
	[string]$appVendor = 'Mersive Technologies, Inc.'
	[string]$appName = 'Solstice'
	[string]$appVersion = '3.0.7.7305'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '10/26/2017'
	[string]$appScriptAuthor = 'Nicolas Wendlowsky'
	##*===============================================
    ##Code to switch Deploy Mode based on runnings applications
	## Code to switch Deploy Mode
    ## -- when running interactive, check whether process is running. If not, then change to silent
	$checkApps = "solsticeclient_v2","solsticeclient"
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
	#Log Entries from code
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
		Show-InstallationWelcome -CloseApps 'solsticeclient_v2,solsticeclient' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		# solsticeclient_v2.exe
		## <Perform Pre-Installation tasks here>
		
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		## <Perform Installation tasks here>
		Execute-Process -Path 'SolsticeClientSetup-3.0.7_SCCM.exe' -Arguments "/s /f1`"$dirFiles\setup_install.iss`" `"/v REBOOT=ReallySuppress /QN /l*v `"$configToolkitLogDir\$appName-$appVersion-$deploymentType.log`"`""
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		## <Perform Post-Installation tasks here>
        
        # Create FireWall rule to allow, and remove previous rules
            $DisplayName = "solsticeclient"
            $Description = $DisplayName
			## !!! When configuring the .iss file, it's VITAL to remove the comma in the install directory !!! ##
            $TargetFile = "$envProgramFilesx86\Mersive Technologies Inc\Solstice\Client\solsticeclient.exe"
            $Protocols = "TCP","UDP"

            #Remove Existing Firewall Rules
            $GetExistingRules = Get-NetFirewallRule -DisplayName $DisplayName | select Name -ErrorAction SilentlyContinue
            if($GetExistingRules){
                foreach($GetExistingRule in $GetExistingRules){
                    Write-Log -Message "Found Existing Firewall Rule, Deleting: $($GetExistingRule.Name)" -Severity 1 -Source $deployAppScriptFriendlyName
                    Remove-NetFirewallRule -Name $GetExistingRule.Name
                }
            }
            #Create New Firewall Rules
            if(Test-Path -Path $TargetFile){
                Foreach($Protocol in $Protocols){
                    New-NetFirewallRule -DisplayName "$DisplayName" -Description "$Description" -Direction Inbound -Program "$TargetFile" -Protocol $Protocol -Action Allow -EdgeTraversalPolicy DeferToUser -Enabled True
                    Write-Log -Message "Created new $Protocol Firewall Rule: $DisplayName" -Severity 1 -Source $deployAppScriptFriendlyName
                }
            }

        #Shortcut
        $SDS = "10.128.61.115"
        $BadStartMenuPath = "$envCommonStartMenuPrograms\Mersive Technologies, Inc"
        $StartMenuPath = "$envCommonStartMenuPrograms\Mersive Technologies Inc"
        $FileName = "Solstice Client.lnk"

        Remove-File -Path "$envCommonStartUp\$FileName"        
        Remove-File -Path "$envCommonDesktop\$FileName"
        Remove-Folder -Path "$BadStartMenuPath"
        New-Folder -Path "$StartMenuPath"
        New-Shortcut -Path "$StartMenuPath\$FileName" -TargetPath "`"$TargetFile`"" -Arguments "-sdsaddress $SDS" -IconLocation "$envProgramFilesx86\Mersive Technologies Inc\Solstice\Client\SolsticeClient.exe" -Description "Solstice Client"

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
		Show-InstallationWelcome -CloseApps 'solsticeclient_v2,solsticeclient' -CloseAppsCountdown 300
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		# <Perform Uninstallation tasks here>
		Execute-Process -Path 'SolsticeClientSetup-3.0.7_SCCM.exe' -Arguments "/x /s /f1`"$dirFiles\setup_uninstall.iss`" `"/v REBOOT=ReallySuppress /QN /l*v `"$configToolkitLogDir\$appName-$appVersion-$deploymentType.log`"`""
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		## <Perform Post-Uninstallation tasks here>

        # Removes FireWall rules
            $DisplayName = "solsticeclient*"
            $GetExistingRules = Get-NetFirewallRule -DisplayName $DisplayName | select Name -ErrorAction SilentlyContinue
            if($GetExistingRules){
                foreach($GetExistingRule in $GetExistingRules){
                    Write-Log -Message "Found Existing Firewall Rule, Deleting: $($GetExistingRule.Name)" -Severity 1 -Source $deployAppScriptFriendlyName
                    Remove-NetFirewallRule -Name $GetExistingRule.Name
                }
            }
        $BadStartMenuPath = "$envCommonStartMenuPrograms\Mersive Technologies, Inc"
        $StartMenuPath = "$envCommonStartMenuPrograms\Mersive Technologies Inc"
        $FileName = "Solstice Client.lnk"
        
        Remove-File -Path "$envCommonDesktop\$FileName"
        Remove-Folder -Path "$BadStartMenuPath"
        Remove-Folder -Path "$StartMenuPath"

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