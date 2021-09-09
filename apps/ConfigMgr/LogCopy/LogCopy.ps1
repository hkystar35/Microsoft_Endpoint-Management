<#
    .SYNOPSIS
    A brief description of the !Template.ps1 file.
	
    .DESCRIPTION
    A description of the file.
	
    .PARAMETER Input
    A description of the Input parameter.
	
    .NOTES
    ===========================================================================

    Created on:   	1/26/2021 13:31:23
    Created by:   	Nicolas.Wendlowsky@chobani.com
    Organization: 	Chobani
    Filename:	      
    ===========================================================================
#>
#[CmdletBinding()]

BEGIN {
	$InvocationInfo = $MyInvocation
	[System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
	[string]$ScriptFullPath = $ScriptFileInfo.FullName
	[string]$ScriptNameFileExt = $ScriptFileInfo.Name
	[string]$ScriptName = $ScriptFileInfo.BaseName
	[string]$scriptRoot = Split-Path $ScriptFileInfo
	# Set TLS
	[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
	
	[string]$Global:Component = 'Begin-Script'
	#region FUNCTION Write-Log
	FUNCTION Write-Log {
    <#
        .SYNOPSIS
        Create log file
	
        .DESCRIPTION
        Logs messages in Configuration Manager-specific format for easy cmtrace.exe reading
	
        .PARAMETER Message
        Value added to the log file.
	
        .PARAMETER Level
        Severity for the log entry.
	
        .PARAMETER FileName
        Name of the log file that the entry will written to.
	
        .PARAMETER LogsDirectory
        A description of the LogsDirectory parameter.
	
        .EXAMPLE
        PS C:\> Write-Log -Message 'Value1'
	
        .NOTES
        Additional information about the function.
    #>
		
		[CmdletBinding()]
		PARAM
		(
			[Parameter(Mandatory = $true,
				HelpMessage = 'Value added to the log file.')]
			[ValidateNotNullOrEmpty()]
			[string]$Message,
			
			[Parameter(Mandatory = $false,
				HelpMessage = 'Severity for the log entry.')]
			[ValidateNotNullOrEmpty()]
			[ValidateSet('Error', 'Warn', 'Info')]
			[string]$Level = "Info",
			
			[Parameter(Mandatory = $false,
				HelpMessage = 'Name of the log file that the entry will written to.')]
			[ValidateNotNullOrEmpty()]
			[string]$FileName = "$($ScriptName).log",
			
			[string]$LogsDirectory = "$env:windir\Logs"
		)
		
		# Determine log file location
		IF ($FileName.Length -le 4) {
			$FileName = "GenericScriptLog_$(Get-Date -Format yyyy-MM-dd)$FileName"
		}
		$LogFilePath = Join-Path -Path $LogsDirectory -ChildPath $FileName
		
		# Construct time stamp for log entry
		IF (-not (Test-Path -Path 'variable:global:TimezoneBias')) {
			[string]$global:TimezoneBias = [System.TimeZoneInfo]::Local.GetUtcOffset((Get-Date)).TotalMinutes
			IF ($TimezoneBias -match "^-") {
				$TimezoneBias = $TimezoneBias.Replace('-', '+')
			}
			ELSE {
				$TimezoneBias = '-' + $TimezoneBias
			}
		}
		$Time = -join @((Get-Date -Format "HH:mm:ss.fff"), $TimezoneBias)
		
		# Construct date for log entry
		$Date = (Get-Date -Format "MM-dd-yyyy")
		
		# Construct context for log entry
		$Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
		
		# Switch Severity to number
		SWITCH ($Level) {
			"Info"	{
				$Severity = 1
			}
			"Warn"  {
				$Severity = 2
			}
			"Error" {
				$Severity = 3
			}
			default {
				$Severity = 1
			}
		}
		
		# Construct final log entry
		$LogText = "<![LOG[$($Message)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""$($component)"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
		
		# Add value to log file
		TRY {
			Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop -WhatIf:$false
		}
		CATCH [System.Exception] {
			Write-Warning -Message "Unable to append log entry to $($FileName) file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
		}
	}
	#endregion FUNCTION Write-Log
	Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
	#region FUNCTION Install-PoShPackageProviders
	FUNCTION Install-PoShPackageProviders {
    <#
        .SYNOPSIS
        Silently installs package providers
	
        .DESCRIPTION
        Mainly used for ensuring NuGet is installed
	
        .PARAMETER PackageProviders
        A description of the PackageProviders parameter.
	
        .EXAMPLE
        PS C:\> Install-PoShPackageProviders
	
        .NOTES
        Additional information about the function.
    #>
		
		[CmdletBinding()]
		PARAM
		(
			[ValidateNotNullOrEmpty()]
			[string[]]$PackageProviders
		)
		
		TRY {
			FOREACH ($PackageProvider IN $PackageProviders) {
				IF ((Get-PackageProvider -Name $PackageProvider -ErrorAction SilentlyContinue) -eq $null) {
					Write-Log -Message "$PackageProvider missing. Installing now."
					Find-PackageProvider -Name $PackageProvider -OutVariable Latest -ErrorAction Stop
					Install-PackageProvider -Name $PackageProvider -MinimumVersion $Latest[0].version -ErrorAction Stop
				}
			}
		}
		CATCH {
			Write-Log -Message "Could not install $PackageProvider" -Level Warn
			$Line = $_.InvocationInfo.ScriptLineNumber
			Write-Log -Message "Error: on line $line"
			THROW "Error: $_"
		}
	}
	
	#endregion FUNCTION Install-PoShPackageProviders
	#region FUNCTION Install-PoShModules
	FUNCTION Install-PoShModules {
    <#
        .SYNOPSIS
        Silently installs PoSh modules
	
        .DESCRIPTION
        PowerShellGet, sqlserver, etc.
	
        .PARAMETER ModuleNames
        A description of the ModuleNames parameter.
	
        .EXAMPLE
        PS C:\> Install-PoShModules
	
        .NOTES
        Additional information about the function.
    #>
		
		[CmdletBinding()]
		PARAM
		(
			[ValidateNotNullOrEmpty()]
			[Alias('M')]
			[string[]]$ModuleNames
		)
		
		FOREACH ($ModuleName IN $ModuleNames) {
			IF ($ModuleName) {
				IF ((Get-Module -Name $ModuleName -ErrorAction SilentlyContinue) -eq $null) {
					Write-Log -Message "$ModuleName module not imported."
					Install-Module -Name $ModuleName -Force -ErrorAction Stop
					Import-Module $ModuleName -Force -Cmdlet:$false -ErrorAction Stop
					TRY {
						Get-Module -Name $ModuleName -ErrorAction Stop
						Write-Log -Message "$ModuleName module now present found."
					}
					CATCH {
						Write-Log -Message "Could not import $ModuleName module" -Level Warn
						$Line = $_.InvocationInfo.ScriptLineNumber
						Write-Log -Message "Error: on line $line"
						Send-ErrorEmail -Message "Could not import $ModuleName module.`nError on line $line.`nError: $_"
						THROW "Error: $_"
					}
				}
			}
			ELSE {
				Write-Log -Message 'No Modules to import.'
			}
		}
	}
	#endregion FUNCTION Install-PoShModules
	
	FUNCTION Remove-InvalidFileNameChars {
		PARAM (
			[Parameter(Mandatory = $true,
				Position = 0,
				ValueFromPipeline = $true,
				ValueFromPipelineByPropertyName = $true)]
			[String]$Name
		)
		
		$invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
		$re = "[{0}]" -f [RegEx]::Escape($invalidChars)
		RETURN ($Name -replace $re)
	}
	
}
PROCESS {
	TRY {
		
		$ServerLoc = "\\af.lan\it\OSD\Logs"
		Write-Log "File Share: $ServerLoc"
		#Parse MAC address
		$GetMAC = @(@(Get-WmiObject Win32_NetworkAdapterConfiguration | Select-Object -ExpandProperty macaddress) -like "*:*")[0]
		$MACaddress = $GetMAC -replace ":", "-"
		
		#Parse MAC address
		$IPaddress = @(@(Get-WmiObject Win32_NetworkAdapterConfiguration | Select-Object -ExpandProperty IPAddress) -like "*.*")[0]
		
		Write-Log "Computer: $env:COMPUTERNAME | MAC: $MACaddress | IP: $IPaddress"
		
		#Env Variables
		$FolderName = $env:ComputerName + "_" + $MACaddress + "_" + $IPaddress
		$FolderPathName = ($ServerLoc + "\" + $FolderName)
		
		IF (!(Test-Path "$FolderPathName")) {
			New-Item -ItemType Directory -Force -Path "$FolderPathName"
		}
		
		$Paths = @(
			'x:\windows\temp\smstslog',
			'x:\smstslog',
			"$env:HomeDrive\_SMSTaskSequence\Logs\Smstslog",
			"$env:HomeDrive\windows\ccm\logs\Smstslog"
		)
		
		FOREACH ($Path IN $Paths) {
			IF (Test-Path $Path -PathType Container) {
				#$DestinationFolder = New-Item -Path "$FolderName\$()"
				$Path = Get-Item $Path
				$Logs = Get-ChildItem -Path "$($Path.FullName)\*" -Filter *.log -Recurse
				$Logs | ForEach-Object{
					Write-Log "Copying file $($_.FullName) to $FolderPathName"
					Copy-Item -Path $_.FullName -Destination "$FolderPathName\$(Remove-InvalidFileNameChars -Name $($Path.FullName))_$($_.Name)"
				}
			}
		}
		"$env:windir\ccm\logs\smsts.log" | ForEach-Object{
			$ccmlogPath = Get-Item $_
			Write-Log "Copying file $($ccmlogPath.FullName) to $FolderPathName"
			Copy-Item -Path $ccmlogPath.fullname -Destination "$FolderPathName\$(Remove-InvalidFileNameChars -Name $ccmlogPath.FullName)_$($ccmlogPath.Name)" -ErrorAction SilentlyContinue
		}
	}
	CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log "Error: $_" -Level Error
		Write-Log "Error: on line $line" -Level Error
	}
}
END {
	Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}