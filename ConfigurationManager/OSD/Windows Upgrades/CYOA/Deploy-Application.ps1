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
	
	.PARAMETER OSDPackageID
		A description of the OSDPackageID parameter.
	
	.PARAMETER DeployMode
		Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
	
	.PARAMETER AllowRebootPassThru
		Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
	
	.PARAMETER TerminalServerMode
		Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
	
	.PARAMETER DisableLogging
		Disables logging to file for the script. Default is: $false.
	
	.PARAMETER Deadline
		A description of the Deadline parameter.
	
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
PARAM
(
	[Parameter(Mandatory = $false)][ValidateSet('Install', 'Uninstall')][string]$DeploymentType = 'Install',
	[Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-zA-Z]{3}[0-9a-fA-F]{5}$')][ValidateNotNullOrEmpty()][string]$OSDPackageID,
	[Parameter(Mandatory = $false)][ValidateSet('Interactive', 'Silent', 'NonInteractive')][string]$DeployMode = 'Interactive',
	[Parameter(Mandatory = $false)][switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory = $false)][switch]$TerminalServerMode = $false,
	[Parameter(Mandatory = $false)][switch]$DisableLogging = $false,
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][ValidateScript({
			[string]$_ -as [datetime]
		})][datetime]$Deadline
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
	[string]$appVendor = 'contoso'
	[string]$appName = 'Windows 10 In-Place Upgrade'
	[string]$appVersion = '2.2'
	[string]$appLang = 'EN'
	[string]$appRevision = '30'
	[string]$appScriptVersion = '2.2.1'
	[string]$appScriptDate = '07/18/2018'
	[string]$appScriptAuthor = 'hkystar35'
	##*===============================================
	#Do not modify these variables:
	$appProcesses = $appProcessesString -split (',')
	$appServices = $appServicesString -split (',')
	
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''
	$DeployMode = 'Interactive'
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
	IF ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		## <Perform Pre-Installation tasks here>
		# Write-Log -Message "" -Severity 1 -Source $installPhase
		# Force to interactive
		$DeployMode = 'Interactive'
		
		#region Determine if machine is inside domain or VPN
		$ServerFQDN = 'AH-DC-01.contoso.com'
		$TestConnection = Test-Connection -ComputerName $ServerFQDN -BufferSize 16 -Count 1 -Quiet -ErrorAction SilentlyContinue
		IF ($TestConnection) {
			$NetworkType = 'Internal'
			Write-Log -Message "Network Connection should be internal: $NetworkType" -Severity 1 -Source $installPhase
		} ELSE {
			$NetworkType = 'External'
			Write-Log -Message "Network Connection should be external: $NetworkType" -Severity 1 -Source $installPhase
		}
		Write-Log -Message "Network Connection is:  $NetworkType" -Severity 1 -Source $installPhase
		#endregion
		
		#region Get logged on user information and set to variables
		$LoggedOnUser = Get-LoggedOnUser | Where-Object{
			$_.UserName -notlike "_*"
		}
		[string[]]$LoggedOnUserProfilePath = Get-UserProfiles | Where-Object {
			$_.NTAccount -eq $($LoggedOnUser.NTAccount)
		} | Select-Object -ExpandProperty 'ProfilePath'
		[string]$Domain = $LoggedOnUser.DomainName
		[string]$UserName = $LoggedOnUser.UserName

		# If internal, use ADSI to get Full Name
		TRY {
			IF ($NetworkType -eq 'Internal') {
				$ADSIInfo = [adsi]"WinNT://$Domain/$UserName,user" | Select-Object fullname, name -ErrorAction SilentlyContinue
				$SplitName = $ADSIInfo.FullName -split ' '
				$GivenName = $SplitName[0]
				$Surname = $SplitName[1] + $SplitName[2] + $SplitName[3] + $SplitName[4]
				$FullName = $ADSIInfo.FullName
			}
		} CATCH {
			$GivenName = $UserName[0]
			$Surname = $UserName.Substring(1)
			IF ($UserName.Substring($UserName.get_Length() - 1) -match "[0-9]") {
				$Surname = $Surname.Substring(0, $Surname.Length - 1)
			}
			$FullName = $GivenName + '. ' + $Surname
		}
		#endregion
		
		#region Create AppData folder and copy email scripts for running via Task Scheduler
		$UserProfileInPlaceUpgrade = "$LoggedOnUserProfilePath\appdata\Roaming\contoso\InPlaceUpgrade\CYOA"
		New-Folder -Path $UserProfileInPlaceUpgrade
		Copy-File -Path "$scriptParentPath\*" -Destination "$UserProfileInPlaceUpgrade" -Recurse
		#endregion
		
		#region Check for PowerBroker
		$PowerBroker = Get-InstalledApplication -Name "BeyondTrust PowerBroker"
		IF ($PowerBroker) {
			[string]$PowerBrokerInstalled = "$($PowerBroker.DisplayVersion)"
		} ELSEIF (!$PowerBroker) {
			[string]$PowerBrokerInstalled = "No"
		}
		#endregion
		
	    #region Set Registry Key, Values, and get existing data
    # Registry Key Path
    $InPlaceUpgradeKey = 'HKLM:\SOFTWARE\contoso\InPlaceUpgrade'
    IF (!(Test-Path -Path $InPlaceUpgradeKey)) {$CreateKey = Set-RegistryKey -Key "$InPlaceUpgradeKey"}
    $GetRegkeys = Get-RegistryKey -Key "$InPlaceUpgradeKey"
    IF (!($GetRegkeys.DeadlineDate)) {Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'DeadlineDate'}
    IF (!($GetRegkeys.UpgradeNow)) {Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'UpgradeNow'}
    IF (!($GetRegkeys.DeferDate)) {Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'DeferDate'}
    IF (!($GetRegkeys.UpgradeDate)) {Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'UpgradeDate'}
    IF (!($GetRegkeys.LastRunDate)) {Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'LastRunDate'}
    IF (!($GetRegkeys.LastRunUser)) {Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'LastRunUser'}
    IF (!($GetRegkeys.PowerBrokerStatus)) {Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'PowerBrokerStatus'}
    IF (!($GetRegkeys.StartingOS)) {Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'StartingOS'}
    IF (!($GetRegkeys.OSDPackageID)) { Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'OSDPackageID'}
    #endregion
		
		SWITCH ($envOS.Version) {
			6.3.9600 {
				$OSVersion = ('Windows 8.1 ({0})' -f $OSInfo.Version)
			}
			10.0.16299 {
				$OSVersion = ('Windows 10 1709 ({0})' -f $OSInfo.Version)
			}
			10.0.15063 {
				$OSVersion = ('Windows 10 1703 ({0})' -f $OSInfo.Version)
			}
			10.0.14393 {
				$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
			}
			10.0.10586 {
				$OSVersion = ('Windows 10 1511 ({0})' -f $OSInfo.Version)
			}
			10.0.16299 {
				$OSVersion = ('Windows 10 1709 ({0})' -f $OSInfo.Version)
			}
			10.0.15063 {
				$OSVersion = ('Windows 10 1703 ({0})' -f $OSInfo.Version)
			}
			10.0.14393 {
				$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
			}
			10.0.10586 {
				$OSVersion = ('Windows 10 1511 ({0})' -f $OSInfo.Version)
			}
			10.0.14393 {
				$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
			}
			10.0.10240 {
				$OSVersion = ('Windows 10 1507 (RTM) ({0})' -f $OSInfo.Version)
			}
		}
		
		#region If Deadline date set in script param, use it. Else, add 35 days.
    IF ([string]$GetRegkeys.DeadlineDate -as [datetime]) {
      $DeadlineDate = $GetRegkeys.DeadlineDate
      Write-Log -Message "Deadline already in Registry. Value: $($DeadlineDate)" -Severity 1 -Source $installPhase
    }ELSEIF ([string]$Deadline -as [datetime]) {
      $DeadlineDate = $Deadline
      Write-Log -Message "Deadline set from script params. Value: $($DeadlineDate)" -Severity 1 -Source $installPhase
      Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'DeadlineDate' -Value "$DeadlineDate"
    } ELSEIF(!$DeadlineDate){
	  $DeadlineDate = (Get-Date).AddDays(35).ToString("yyyy-MM-dd 23:59:59")
      Write-Log -Message "Deadline not set in Reg or by script params. Default set to: $($DeadlineDate)" -Severity 1 -Source $installPhase
      Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'DeadlineDate' -Value "$DeadlineDate"
    }
    #endregion
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		#region Launch Form
		Write-Log -Message "Launching choice form." -Severity 1 -Source $installPhase
		$FormResults = Show-CYOA_Form_psf -Fullname "$FullName" -DeadlineDate "$DeadlineDate"
		#endregion Launch Form
		
		#region Parse Form Output
		IF ($FormResults.UpgradeNow -eq 'Yes') {
			Write-Log -Message "User chose to upgrade now." -Severity 1 -Source $installPhase
			# Set regkey values
			$UpgradeNow_Value = 'Yes'
			$DeferDate_Value = $null
			$UpgradeDate_Value = $FormResults.UpgradeDate
			$LastRunDate_Value = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
			$LastRunUser_Value = $UserName
			$PowerBrokerStatus_Value = $PowerBrokerInstalled
			$StartingOS_Value = $envOS.Version
			
			# Invoke TS
			$TSOutput = Invoke-OSDInstall -OSDPackageID $OSDPackageID
			Write-Log -Message "Invoke TS ID $OSDPackageID. Exit Code: $($TSOutput.ReturnValue)" -Severity 1 -Source $installPhase
			IF ($TSOutput.ReturnValue -ne 0) {
				Write-Log -Message "Invoke TS ID $OSDPackageID failed in SYSTEM context. Trying as LoggedOn User $UserName." -Severity 1 -Source $installPhase
				$Reminder_Arguments_ScriptFullPath = "$UserProfileInPlaceUpgrade\Files\Invoke-OSDInstall.ps1"
				$Reminder_Arguments_Parameters = "-OSDPackageID $OSDPackageID"
				$Reminder_Arguments = "-NoProfile -WindowStyle Hidden -command `"& {$Reminder_Arguments_ScriptFullPath $Reminder_Arguments_Parameters}`""
				$TSOutput_AsUser = Execute-ProcessAsUser -UserName "$Username" -Path "$PSHOME\powershell.exe" -Parameters "$Reminder_Arguments" -PassThru
				Write-Log -Message "Invoke TS ID $OSDPackageID as user $UserName. Exit Code: $($TSOutput_AsUser)" -Severity 1 -Source $installPhase
			}
			# Set ICS creation
			$Attachment = $false
			
			# Set Email Type
			$EmailType = 'TicketNow'
			
		} ELSEIF ($FormResults.UpgradeNow -eq 'No') {
			Write-Log -Message "User chose to defer upgrade to later date: $($FormResults.DeferDate)" -Severity 1 -Source $installPhase
			# Set regkey values
			$UpgradeNow_Value = 'No'
			[datetime]$DeferDate_Value = $FormResults.DeferDate
			$UpgradeDate_Value = $null
			$LastRunDate_Value = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
			$LastRunUser_Value = $UserName
			$PowerBrokerStatus_Value = $PowerBrokerInstalled
			$StartingOS_Value = $envOS.Version
			
			# Set ICS creation
			$Attachment = $true
			
			# Set Email Type
			$EmailType = 'Defer'
		}
		#endregion Parse Form Output
		
		## <Perform Installation tasks here>
		
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>
		
		#region Set Email Addresses
			$Email_NotifyOnly = 'EUC@contoso.com'
			$Email_Zendesk = 'AskEUC@contoso.com'
			$Email_LoggedOnUser = $UserName + '@' + $Domain + '.com'
		#endregion Set Email Addresses
		
    		#region Set Email or Calendar and Scheduled Tasks
			IF ($EmailType -eq 'TicketNow') {
				$EmailResult = New-EMailGun -UserName $UserName -MailTo $Email_Zendesk
				Write-Log -Message "Attempt to send Zendesk Email. If success, output: $($EmailResult.Result)." -Severity 1 -Source $installPhase
			} ELSEIF ($EmailType -eq 'Defer') {
				$ICSFIlePath = New-ICSEvent -StartDate "$DeferDate_Value" -Subject "In-Place Upgrade to Windows 10" -FilePathAndName "$UserProfileInPlaceUpgrade\$($envCOMPUTERNAME)_$($UserName).ics"
				Write-Log -Message "Attempt to create ICS file. If success, here is path: $($ICSFIlePath.Filepath)." -Severity 1 -Source $installPhase
				$EmailResult = New-EMailGun -UserName $UserName -MailTo $Email_NotifyOnly -DeferDate $DeferDate_Value -AttachmentPath "$($ICSFIlePath.Filepath)"
				Write-Log -Message "Attempt to send NotifyOnly Email. If success, output: $($EmailResult.Result)." -Severity 1 -Source $installPhase
				
				# Create or update Scheduled Tasks
				# Global Variables
				$ActionEXE = 'PowerShell.exe'
				
				# Upgrade Scheduled Task
				$Upgrade_TaskName = $appName
				$Upgrade_LibraryPath = $appVendor
				$Upgrade_Description = 'Trigger CYOA form to prompt for upgrade'
				$Upgrade_ActionEXE = $ActionEXE
				$Upgrade_Arguments_ScriptFullPath = "$UserProfileInPlaceUpgrade\Deploy-Application.ps1"
				$Upgrade_Arguments_Parameters = "-OSDPackageID $OSDPackageID"
				$Upgrade_Arguments = "-NoProfile -WindowStyle Hidden -command `"& {$Upgrade_Arguments_ScriptFullPath $Upgrade_Arguments_Parameters}`""
				$Upgrade_Trigger_Date = $DeferDate_Value
				Write-Log -Message "Setting Scheduled Task `"$Upgrade_TaskName`" to run on $Upgrade_Trigger_Date." -Severity 1 -Source $installPhase
				$Upgrade_SchTask = New-ScheduledTaskAsUser -DomUserName $Domain\$UserName  -STFolder $Upgrade_LibraryPath -TaskName $Upgrade_TaskName -Path $Upgrade_ActionEXE -Parameters $Upgrade_Arguments -Trigger_Date $Upgrade_Trigger_Date
				
				Start-Sleep -Seconds 10
				# Reminder Scheduled Task
				$Reminder_TaskName = $appName + '-Reminder Email'
				$Reminder_LibraryPath = $appVendor
				$Reminder_Description = 'Send reminder email 24 hours prior to upgrade'
				$Reminder_ActionEXE = $ActionEXE
				$Reminder_Arguments_ScriptFullPath = "$UserProfileInPlaceUpgrade\Files\New-EMailGun.ps1"
				$Reminder_Arguments_Parameters = "-UserName $UserName -MailTo $Email_LoggedOnUser -Reminder"
				$Reminder_Arguments = "-NoProfile -WindowStyle Hidden -command `"& {$Reminder_Arguments_ScriptFullPath $Reminder_Arguments_Parameters}`""
				IF (($difference = NEW-TIMESPAN -Start (Get-Date) -End $Upgrade_Trigger_Date).Days -lt 2) {
					$Reminder_Trigger_Date = ($Upgrade_Trigger_Date).AddHours(-($difference.TotalHours/2)).ToString("yyyy-MM-dd HH:mm:ss")
				} ELSE {
					$Reminder_Trigger_Date = ($Upgrade_Trigger_Date).AddDays(-1).ToString("yyyy-MM-dd HH:mm:ss")
				}
				Write-Log -Message "Setting Scheduled Task `"$Reminder_TaskName`" to run on $Reminder_Trigger_Date." -Severity 1 -Source $installPhase
				# start here!!!!!
				$Reminder_SchTask = New-ScheduledTaskAsUser -DomUserName $Domain\$UserName -STFolder $Reminder_LibraryPath -TaskName $Reminder_TaskName -Path $Reminder_ActionEXE -Parameters $Reminder_Arguments -Trigger_Date $Reminder_Trigger_Date
				
			}
		#endregion Set Email or Calendar
		
		#region Set Registry Entries
			IF($UpgradeNow_Value){ Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'UpgradeNow' -Value $UpgradeNow_Value}
			IF($DeferDate_Value){ Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'DeferDate' -Value $DeferDate_Value}
			IF($UpgradeDate_Value){ Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'UpgradeDate' -Value $UpgradeDate_Value}
			IF($LastRunDate_Value){ Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'LastRunDate' -Value $LastRunDate_Value}
			IF($LastRunUser_Value){ Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'LastRunUser' -Value $LastRunUser_Value}
			IF($PowerBrokerStatus_Value){ Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'PowerBrokerStatus' -Value $PowerBrokerStatus_Value}
			IF($StartingOS_Value){ Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'StartingOS' -Value $StartingOS_Value}
			IF($OSDPackageID){ Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'OSDPackageID' -Value $OSDPackageID}
			IF(!$FirstRun){ Set-RegistryKey -Key "$InPlaceUpgradeKey" -Name 'FirstRun' -Value 'Installed'}
		#endregion Set Registry Entries
		
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
		
		#region Delete Registry Keys
		$InPlaceUpgradeKey = 'HKLM:\SOFTWARE\contoso\InPlaceUpgrade'
		Remove-RegistryKey -Key "$InPlaceUpgradeKey"
		#endregion Delete Registry Keys
		
		#region Delete Script Folder
		$UserProfiles = Get-UserProfiles | Select-Object -Property ProfilePath
		$UserProfiles | ForEach-Object{
			Remove-Folder -Path "$($_.ProfilePath)\appdata\Roaming\contoso\InPlaceUpgrade\CYOA"
		}
		#endregion Delete Script Folder
		
		#region Delete Scheduled Tasks
		#$appNameNoSpace = $appName -replace ' '
		$appNameNoSpace = 'Windows 10 In-Place Upgrade'
		$ScheduledTasks = Get-ScheduledTask  | Where-Object{$_.TaskName -like "$appName*" -or $_.TaskName -like "$appnamenospace*"}
        IF(!$ScheduledTasks){Write-Log -Message "Did not find matching Scheduled Tasks." -Severity 1 -Source $installPhase}
		$ScheduledTasks | ForEach-Object{
            Write-Log -Message "Found Scheduled Task $($_.TaskName), attempting to delete..." -Severity 1 -Source $installPhase
			$SchTask_Result = Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -PassThru -ErrorAction SilentlyContinue
			Write-Log -Message "Successfully Unregistered Scheduled Task $($_.TaskName)." -Severity 1 -Source $installPhase
		}
		#endregion Delete Scheduled Tasks
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		## <Perform Post-Uninstallation tasks here>
		#>
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
