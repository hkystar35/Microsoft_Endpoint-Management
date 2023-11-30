<#
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
	[string]$appVendor = ''
	[string]$appName = 'DeleteTempFiles'
	[string]$appVersion = '1'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '02'
	[string]$appScriptVersion = '1.0.1'
	[string]$appScriptDate = '9/19/2018'
	[string]$appScriptAuthor = ''
	##*===============================================
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
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		
		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -CustomText "Deleting temp files and caches..."
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Installation tasks here>
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		## <Perform Installation tasks here>
        Get-FreeDiskSpace

			## These paths delete ONLY files (except *.log) and leaves sub-folders
			$Path01 = "$env:Temp\"
			$Path02 = "$env:SystemDrive\Temp\"
			
			## These paths delete sub-folders AND files (except *.log)
			$FolderPath01 = "$envSystemRoot\SoftwareDistribution\Download"

				#Do not edit variable name. Just use REM for unused path numbers
				$Paths = "$Path01","$Path02"
				$FolderPaths = "$FolderPath01"
			
					#Files ONLY
					ForEach ($Path in $Paths) {
					Write-Log -Message "Deleting Files from $Path" -Severity 2 -Source $deployAppScriptFriendlyName
					
					#$TempFiles = Get-ChildItem -Path $Path -exclude *.log -File -recurse ### This line only works in Powershell 3.0 or higher
					$TempFiles = Get-ChildItem -Path "$Path" -exclude *.log -rec | where { ! $_.PSIsContainer }
					$TempFiles | foreach ($_) {
												IF ($_.Fullname) {
												Write-Log -Message "$($_.fullname)" -Severity 1 -Source $deployAppScriptFriendlyName
												Remove-Item $_.Fullname -force -Recurse
												} Else {
                                                Write-Log -Message "Empty Directory" -Severity 1 -Source $deployAppScriptFriendlyName
                                                }
												}
					}
					
					#Folders AND Files
					ForEach ($FolderPath in $FolderPaths) {
					Write-Log -Message "Deleting Files from $FolderPath" -Severity 2 -Source $deployAppScriptFriendlyName
					
					$TempFiles = Get-ChildItem -Path $FolderPath -exclude *.log -recurse
					$TempFiles | foreach ($_) {
												IF ($_.Fullname) {
                                                Write-Log -Message "$($_.fullname)" -Severity 1 -Source $deployAppScriptFriendlyName
												Remove-Item $_.Fullname -force -Recurse
												} Else {
                                                Write-Log -Message "Empty Directory" -Severity 1 -Source $deployAppScriptFriendlyName
                                                }
                                                }
					}
		Write-Log -Message "FINISHED deleting specified files and folders. Look for Severity 2 entries for targeting paths." -Severity 1 -Source $deployAppScriptFriendlyName
		
		#Delete old profiles older than 3 months
		
		#Delete SCCM Cache older than 1 day
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>
		#Creating new file for records
		$CleanupFile = "$envComputerNameFQDN-contoso_DiskCleanup.txt"
		$CleanupFilePath = "$envSystemRoot\temp\contoso"
		$CleanupFileName = "$CleanupFilePath\$CleanupFile"
		$CleanupServerPath = "\\kirk\it\logs\DiskCleanUp"
		New-Folder -path "$CleanupFilePath"
		New-Folder -path "$CleanupServerPath"
		
		If (Test-Path $CleanupFileName){
			Write-Log -Message "Detection file ($CleanupFileName) already exists." -Severity 1 -Source $deployAppScriptFriendlyName
			Write-Log -Message "Appending Date to file." -Severity 1 -Source $deployAppScriptFriendlyName
			Add-Content "$CleanupFileName" "`ncontoso Disk Cleanup was run again on $currentDateTime"
			Copy-File -Path "$CleanupFileName" -Destination "$CleanupServerPath\$CleanupFile"
			} Else {
				Write-Log -Message "Creating Detection file ($CleanupFileName)." -Severity 1 -Source $deployAppScriptFriendlyName
				New-Item "$CleanupFileName" -type file -force -value "contoso Disk Cleanup was first run on $currentDateTime"
				Copy-File -Path "$CleanupFileName" -Destination "$CleanupServerPath\$CleanupFile"
				}
		
		
		## Display a message at the end of the install
        Get-FreeDiskSpace
	}	
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing

		
		## Show Progress Message (with the default message)

		
		## <Perform Pre-Uninstallation tasks here>
		
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		
		# <Perform Uninstallation tasks here>
		
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
		## <Perform Post-Uninstallation tasks here>
		
		
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
