<#
		.SYNOPSIS
		Insatalls INF drivers using PNPUtil.exe and a source folder.
	
		.DESCRIPTION
		Insatalls INF drivers using PNPUtil.exe and a source folder.
	
		.PARAMETER DriverFolder
		Full path to folder containing driver files.

		.PARAMETER StaticLogName
		Switch to set Log Name to static name in case MyInvocation won't work where it's being run from.
	
		.NOTES
		===========================================================================

		Created on:   	09/18/2019 11:23:55 AM
		Created by:   	NWendlowsky@paylocity.com
		Organization: 	Paylocity
		Filename:	      Install-DriversPNPUtil.p1
		===========================================================================
#>
[CmdletBinding()]
PARAM
(
	[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.IO.DirectoryInfo]$DriverFolder,
	[switch]$StaticLogName = $false
)
BEGIN {
	$InvocationInfo = $MyInvocation
	[System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
	[string]$ScriptFullPath = $ScriptFileInfo.FullName
	[string]$ScriptNameFileExt = $ScriptFileInfo.Name
	[string]$ScriptName = $ScriptFileInfo.BaseName
	[string]$scriptRoot = Split-Path $ScriptFileInfo
	
	switch($StaticLogName){
		true    {$LogName = 'Install-DriversPNPUtil'}	
		default {$LogName = 'default'}#$ScriptName}
	}
	
	#region FUNCTION Write-Log
	FUNCTION Write-Log {
		[CmdletBinding()]
		PARAM
		(
			[Parameter(Mandatory = $true,
			ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][Alias("LogContent")][string]$Message,
			[Parameter(Mandatory = $false)][Alias('LogPath')][string]$Path = "$env:windir\Logs\$($LogName).log",
			[Parameter(Mandatory = $false)][ValidateSet("Error", "Warn", "Info")][string]$Level = "Info",
			[Parameter(Mandatory = $false)][switch]$NoClobber,
			[Parameter(Mandatory = $false)][int]$MaxLogSize = '2097152'
		)
		
		BEGIN {
			# Set VerbosePreference to Continue so that verbose messages are displayed. 
			$VerbosePreference = 'SilentlyContinue'
			$FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		}
		PROCESS {
			
			# Test if log exists
			IF (Test-Path -Path $Path) {
				$FilePath = Get-Item -Path $Path
				IF ($NoClobber) {
					Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
					RETURN
				}
				IF ($FilePath.Length -gt $MaxLogSize) {
					Rename-Item -Path $FilePath.FullName -NewName $($FilePath.BaseName).log_ -Force
				}
			} ELSEIF (!(Test-Path $Path)) {
				Write-Verbose "Creating $Path."
				$NewLogFile = New-Item $Path -Force -ItemType File
			}
			# Write message to error, warning, or verbose pipeline and specify $LevelText 
			SWITCH ($Level) {
				'Error' {
					Write-Error $Message
					$LevelText = 'ERROR:'
				}
				'Warn' {
					Write-Warning $Message
					$LevelText = 'WARNING:'
				}
				'Info' {
					Write-Verbose $Message
					$LevelText = 'INFO:'
				}
			}
			
			# Write log entry to $Path 
			"$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
		}
		END {
		}
	}
	#endregion FUNCTION Write-Log	
	
	Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
}
PROCESS {
	TRY {
		
		## Main Script Block
		$DriverPath = $DriverFolder.Fullname
		$PNPUtil = (Get-Item -Path "$env:windir\System32\pnputil.exe").FullName
		$INFfiles = Get-ChildItem "$($DriverPath)" -Recurse -Filter "*.inf" 
		
		IF($INFfiles){
			IF($INFfiles.count -gt 1){
				ForEach($File in $INFfiles){
					TRY{
						Write-Log -Message "Installing driver $($File.Name)"
						Start-Process -FilePath "$PNPUtil" -ArgumentList "/add-driver $($File.FullName) /install" -Wait -ErrorAction SilentlyContinue
						Write-Log -Message "$($File.Fullname) installed successfully"
					}
					CATCH{
						Write-Log -Message "$($File.Fullname) failed: $_" -Level Error
					}
				}
			}ELSE{
				Write-Log -Message "Installing driver $($INFfiles.Name)"
				Start-Process -FilePath "$PNPUtil" -ArgumentList "/add-driver $($INFfiles.FullName) /install" -Wait
				Write-Log -Message "$($INFfiles.Fullname) installed successfully"
			}
			$ExitCode = 3010
			Exit 3010
		}ELSE{
			$errormessage = "No INF drivers found in $DriverPath"
			Write-Log -Message $errormessage -WarningAction
			THROW $errormessage
		}
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
		THROW $_
	}
}
END {
	Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}