<#
	.SYNOPSIS
		Checks Windows Firewall for proper Microsoft Teams rules
	
	.DESCRIPTION
		Finds teams.exe files in AppData folders and checks that the Firewall Rules for those files are properly configured. If rules are correct, passes back 0 value. If they are incorrect, passes a value of 1 or higher.
	
	.NOTES
		===========================================================================
		
		Created on:   	3/20/2020 10:20:29
		Created by:   	hkystar35
		Organization: 	
		Filename:	    Teams-Firewall-Exception.ps1
		===========================================================================
	
#>
BEGIN {
	$InvocationInfo = $MyInvocation
	[System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
	[string]$ScriptFullPath = $ScriptFileInfo.FullName
	[string]$ScriptNameFileExt = $ScriptFileInfo.Name
	[string]$ScriptName = 'Teams-Firewall-Exception'
	[string]$scriptRoot = Split-Path $ScriptFileInfo
	
	#region FUNCTION Write-Log
	FUNCTION Write-Log {
		PARAM (
			[parameter(Mandatory = $true, HelpMessage = "Value added to the log file.")][ValidateNotNullOrEmpty()][string]$Message,
			[parameter(Mandatory = $false, HelpMessage = "Severity for the log entry.")][ValidateNotNullOrEmpty()][ValidateSet("Error", "Warn", "Info")][string]$Level = "Info",
			[parameter(Mandatory = $false, HelpMessage = "Name of the log file that the entry will written to.")][ValidateNotNullOrEmpty()][string]$FileName = "$($ScriptName).log",
			[string]$LogsDirectory = "$env:windir\Logs"
		)
		# Determine log file location
		IF ($FileName2.Length -le 4) {
			$FileName2 = "GenericScriptLog_$(Get-Date -Format yyyy-MM-dd)$FileName2"
		}
		$LogFilePath = Join-Path -Path $LogsDirectory -ChildPath $FileName
		
		# Construct time stamp for log entry
		IF (-not (Test-Path -Path 'variable:global:TimezoneBias')) {
			[string]$global:TimezoneBias = [System.TimeZoneInfo]::Local.GetUtcOffset((Get-Date)).TotalMinutes
			IF ($TimezoneBias -match "^-") {
				$TimezoneBias = $TimezoneBias.Replace('-', '+')
			} ELSE {
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
		$LogText = "<![LOG[$($Message)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""ApplyDriverPackage"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
		
		# Add value to log file
		TRY {
			Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
		} CATCH [System.Exception] {
			Write-Warning -Message "Unable to append log entry to ApplyDriverPackage.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
		}
	}
	#endregion FUNCTION Write-Log
	
	Write-Log -Message " ----- BEGIN $($ScriptName) DISCOVERY execution ----- "
}
PROCESS {
	TRY {
		$SearchFileName = 'teams.exe'
		$SearchFolderPath = "$env:HOMEDRIVE\Users\*\AppData\Local\Microsoft\Teams\current\*"
		Write-Log -Message "Finding $($SearchFileName) in search path $($SearchFolderPath)"
		$TeamsEXEs = Get-ChildItem -Path $SearchFolderPath -Filter $SearchFileName -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
		Write-Log -Message "Found $($TeamsEXEs.Count) matching files"
		Write-Log -Message "Gathering all Windows Firewall rules"
		$FirewallRules = Get-NetFirewallRule -All
		Write-Log -Message "Found $($FirewallRules.Count) total rules"
		$TeamsRules = $FirewallRules | Where-Object {$_.DisplayName -like "*teams*"} | Select-Object -Property *, @{L = "ProgramPath"; E = {$_ | Get-NetFirewallApplicationFilter | Select-Object -ExpandProperty Program}}
		Write-Log -Message "Firewall rule(s) found related to $($SearchFileName): $($TeamsRules.Count)"
		
		# Start counter at 0
		$i = 0
		
		Write-Log -Message "Checking that rules exist for discoverd $SearchFileName files"
		$TeamsEXEs | ForEach-Object{
			IF ($TeamsRules.ProgramPath -notcontains $_) {
				Write-Log -Message "Rule not found for file: $($_)" -Level Warn
				$i++
			} ELSE {
				Write-Log -Message "Rule found for file: $($_)"
			}
		}
		
		Write-Log -Message "Checking related Firewall rule settings"
		IF ($TeamsRules.Count -eq 0 `
			-or $TeamsRules.Profile -notcontains 'Any' `
			-or $TeamsRules.Enabled -contains $false `
			-or $TeamsRules.Direction -notcontains 'Inbound' `
			-or $TeamsRules.Action -notcontains 'Allow' `
) {
			Write-Log -Message "Found rule not matching criteria." -Level Warn
			$i++
		} ELSE {
			Write-Log -Message "No issues found with rule settings"
		}
		
		Write-Log -Message "Finished discovery, passing back return value of $($i)"
		$i
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
	}
}
END {
	Write-Log -Message " ----- END $($ScriptName) DISCOVERY execution ----- "
}