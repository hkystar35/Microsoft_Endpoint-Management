<#
	.SYNOPSIS
		Converts Collection to all Direct membership
	
	.DESCRIPTION
		Takes collection members, adds them as Direct members, then removes any Included Collections from membership.
	
	.PARAMETER CollectionIDs
		String array of Collection IDs
	
	.PARAMETER PurgeInclusionCollections
		Default is $TRUE
		If set to $false, leaves all Inclusion Rules
	
	.PARAMETER PurgeQueries
		Default is $FALSE
		If set to $true, removes all Rules in each collection that are Query Rules
	
	.PARAMETER PurgeExclusionCollections
		Default is $FALSE
		If set to $true, removes all Rules in each collection that are Exclusion Rules
	
	.NOTES
		===========================================================================
		
		Created on:   	4/16/2021 09:56:10
		Created by:   	hkystar35@contoso.com
		Organization: 	contoso
		Filename:	      Convert-CMASCollectionToStatic
		===========================================================================
#>
[CmdletBinding()]
PARAM
(
	[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$CollectionIDs,
	
	[bool]$PurgeInclusionCollections = $true,
	
	[bool]$PurgeQueries = $false,
	
	[bool]$PurgeExclusionCollections = $false
)
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
				HelpMessage = 'Value added to the log file.')][ValidateNotNullOrEmpty()][string]$Message,
			
			[Parameter(Mandatory = $false,
				HelpMessage = 'Severity for the log entry.')][ValidateNotNullOrEmpty()][ValidateSet('Error', 'Warn', 'Info')][string]$Level = "Info",
			
			[Parameter(Mandatory = $false,
				HelpMessage = 'Name of the log file that the entry will written to.')][ValidateNotNullOrEmpty()][string]$FileName = "$($ScriptName).log",
			
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
	
}
PROCESS {
	TRY {
		
		$URI
		
		FUNCTION Connect-CMAdminService {
			PARAM
			(
				[Parameter(ParameterSetName = 'DefaultCredentials',
					Mandatory = $true)]$DefaultCredential,
				
				[Parameter(ParameterSetName = 'ActiveDirectory',
					Mandatory = $true)]$ADuser,
				
				[Parameter(ParameterSetName = 'ActiveDirectory',
					Mandatory = $true)]$ADpassword,
				
				[Parameter(ParameterSetName = 'AzureAD',
					Mandatory = $true)]$AADuser,
				
				[Parameter(ParameterSetName = 'AzureAD',
					Mandatory = $true)]$AADpassword,
				
				[Parameter(ParameterSetName = 'Certificate',
					Mandatory = $true)]$Certificate
			)
			
			SWITCH ($PsCmdlet.ParameterSetName) {
				'DefaultCredentials' {
					#TODO: Place script here
					BREAK
				}
				'ActiveDirectory' {
					#TODO: Place script here
					BREAK
				}
				'AzureAD' {
					#TODO: Place script here
					BREAK
				}
				'Certificate' {
					#TODO: Place script here
					BREAK
				}
			}
			
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
