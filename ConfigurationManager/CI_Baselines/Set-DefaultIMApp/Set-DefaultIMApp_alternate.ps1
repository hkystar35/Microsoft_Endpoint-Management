#region Discovery
[switch]$Remediate = $true
[string]$IMname = 'Teams'

[string]$ScriptName = 'Set-DefaultIMApp.ps1' #$ScriptFileInfo.BaseName
# Set TLS
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'

[string]$Component = 'Begin-Script'
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
	
	.PARAMETER LoggingDisabled
		A description of the LoggingDisabled parameter.
	
	.EXAMPLE
		PS C:\> Write-Log -Message 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true,
				   HelpMessage = 'Value added to the log file.')][ValidateNotNullOrEmpty()][string]$Message,
		[Parameter(Mandatory = $false,
				   HelpMessage = 'Severity for the log entry.')][ValidateSet('Error', 'Warn', 'Info')][ValidateNotNullOrEmpty()][string]$Level = "Info",
		[Parameter(Mandatory = $false,
				   HelpMessage = 'Name of the log file that the entry will written to.')][ValidateNotNullOrEmpty()][string]$FileName = "$($ScriptName).log",
		[string]$LogsDirectory = $env:TEMP, #"$env:windir\Logs",
		[switch]$WriteVerbose = $VerboseLogging
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
	IF ($WriteVerbose) {
		Write-Verbose $LogText
	}
	#ELSE {
	TRY {
		Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop -WhatIf:$false
	}
	CATCH [System.Exception] {
		Write-Warning -Message "Unable to append log entry to $($FileName) file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
	}
	#}
	
}
#endregion FUNCTION Write-Log
Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "

TRY {
	
	# Gather variables
	$Component = 'Check-Registry'
	# IM Provider registry path
	$imProviderPath = "HKCU:\Software\IM Providers"
	Write-Log "Value of `$imProviderPath is $imProviderPath"
	# Retrieve current IM Provider Information
	$imProvider = Get-ItemProperty -Path $imProviderPath -ErrorAction SilentlyContinue
	Write-Log "Value of `$imProvider is $imProvider and $($imProvider.DefaultIMApp)"
	# Build Path for Teams
	$teamsPath = Join-Path -Path $imProviderPath -ChildPath $IMname
	Write-Log "Value of `$teamsPath is $teamsPath"
	Write-Log "Value of `$Remediate is $Remediate"
	Write-Log "Value of `$IMname is $IMname"
	# Detection
	Write-Log "Discovery Only - No changes will be made"
	IF (Test-Path $teamsPath) {
		Write-Log "$teamsPath already exists"
		IF ($imProvider.DefaultIMApp -eq $IMname) {
			Write-Log "Default IM app already set to $($imProvider.DefaultIMApp)"
			RETURN 0
		}
	}
	ELSE {
		Write-Log "Default IM app is NOT set to $IMname (Default IM app is set to $($imProvider.DefaultIMApp))"
		RETURN 1
	}
	
}
CATCH {
	$Line = $_.InvocationInfo.ScriptLineNumber
	Write-Log "Error: $_" -Level Error
	Write-Log "Error: on line $line" -Level Error
	RETURN 2
}
Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
#endregion Discovery

#region Remediate
[switch]$Remediate = $true
[string]$IMname = 'Teams'

[string]$ScriptName = 'Set-DefaultIMApp.ps1' #$ScriptFileInfo.BaseName
# Set TLS
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'

[string]$Component = 'Begin-Script'
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
	
	.PARAMETER LoggingDisabled
		A description of the LoggingDisabled parameter.
	
	.EXAMPLE
		PS C:\> Write-Log -Message 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true,
				   HelpMessage = 'Value added to the log file.')][ValidateNotNullOrEmpty()][string]$Message,
		[Parameter(Mandatory = $false,
				   HelpMessage = 'Severity for the log entry.')][ValidateSet('Error', 'Warn', 'Info')][ValidateNotNullOrEmpty()][string]$Level = "Info",
		[Parameter(Mandatory = $false,
				   HelpMessage = 'Name of the log file that the entry will written to.')][ValidateNotNullOrEmpty()][string]$FileName = "$($ScriptName).log",
		[string]$LogsDirectory = $env:TEMP, #"$env:windir\Logs",
		[switch]$WriteVerbose = $VerboseLogging
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
	IF ($WriteVerbose) {
		Write-Verbose $LogText
	}
	#ELSE {
	TRY {
		Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop -WhatIf:$false
	}
	CATCH [System.Exception] {
		Write-Warning -Message "Unable to append log entry to $($FileName) file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
	}
	#}
	
}
#endregion FUNCTION Write-Log
Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
TRY {
	
	# Gather variables
	$Component = 'Check-Registry'
	# IM Provider registry path
	$imProviderPath = "HKCU:\Software\IM Providers"
	Write-Log "Value of `$imProviderPath is $imProviderPath"
	# Retrieve current IM Provider Information
	$imProvider = Get-ItemProperty -Path $imProviderPath -ErrorAction SilentlyContinue
	Write-Log "Value of `$imProvider is $imProvider and $($imProvider.DefaultIMApp)"
	# Build Path for Teams
	$teamsPath = Join-Path -Path $imProviderPath -ChildPath $IMname
	Write-Log "Value of `$teamsPath is $teamsPath"
	Write-Log "Value of `$Remediate is $Remediate"
	Write-Log "Value of `$IMname is $IMname"
	# Remediation
	Write-Log "Remediation param set" -Level Warn
	$Component = 'Set-Registry'
	# If there is a current provider set, set this as the previous IM provider
	# This is if a user unticks the setting in Teams, Teams knows what to fallback to
	IF ($imProvider.DefaultIMApp) {
		# Check Teams IM Provider path exists (it should if Teams has been run before)
		IF (Test-Path $teamsPath) {
			Write-Log "$teamsPath already exists, no action needed..."
		}
		ELSE {
			Write-Log -Level Warn "$teamsPath does not exist, creating..."
			New-Item -Path $imProviderPath -Name $IMname
		}
		# Path should now be created
		IF (Test-Path $teamsPath) {
			Write-Log "Setting previous IM app: $($imProvider.DefaultIMApp) "
			Set-ItemProperty -Path $teamsPath PreviousDefaultIMApp -Value $imProvider.DefaultIMApp -Type String
		}
		ELSE {
			Write-Log "Unable to create $teamsPath!" -Level Error
			RETURN 1
		}
	}
	# Set Teams as Deafult IM App
	Write-Log "Setting Default IM App to $IMname"
	Set-ItemProperty -Path $imProviderPath -Name "DefaultIMApp" -Value $IMname -ErrorAction Stop
	RETURN 0
	
}
CATCH {
	$Line = $_.InvocationInfo.ScriptLineNumber
	Write-Log "Error: $_" -Level Error
	Write-Log "Error: on line $line" -Level Error
	RETURN 2
}
Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
#endregion Remediate