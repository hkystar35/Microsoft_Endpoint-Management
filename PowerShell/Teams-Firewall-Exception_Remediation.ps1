<#
	.SYNOPSIS
		Creates Windows Firewall rules for Microsoft Teams
	
	.DESCRIPTION
		Finds teams.exe files in AppData folders and creates Windows Firewall rules for each
	
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
	
	#region FUNCTION Create-FirewallRule
	FUNCTION Create-FirewallRule {
		PARAM
		(
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][ValidateSet('TCP', 'UDP', 'TCPUDP')][Alias('P')][string]$Protocol,
			[Parameter(ParameterSetName = 'RemoveExisting')][switch]$RemoveExisiting = $false,
			[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$Description,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$DisplayName,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$FilePath,
			[Parameter(ParameterSetName = 'RemoveExisting',
					   Mandatory = $false)][ValidateNotNullOrEmpty()][string]$SearchExisting
		)
		
		TRY {
			$Protocols = "TCP", "UDP"
			$FirewallDisplayName = $DisplayName
			$FirewallRuleDescription = $Description
			
			
			#region Remove Existing Firewall Rules
			TRY {
				IF ($RemoveExisiting) {
					$GetExistingRules = Get-NetFirewallRule | Where-Object{
						$_.DisplayName -like "*$($SearchExisting)*"
					}
					IF ($GetExistingRules) {
						$GetExistingRules | ForEach-Object{
							Write-Log -Message "Found Existing Firewall Rule, Deleting: $($_.DisplayName) ($($_.Name))" -Level Info
							$_ | Remove-NetFirewallRule -Confirm:$false
						}
					}
				}
			} CATCH {
				
				$Line = $_.InvocationInfo.ScriptLineNumber
				"Error was in Line $line"
				Write-Log -Message "Error: $_" -Level Error
				Write-Log -Message "Error: on line $line" -Level Error
			}
			#endregion Remove Existing Firewall Rules
			
			#region Create New Firewall Rules
			TRY {
				IF (Test-Path -Path $FilePath -PathType Leaf) {
					FOREACH ($Protocol IN $Protocols) {
						$NewFirewallRule = New-NetFirewallRule -DisplayName "$FirewallDisplayName" -Description "$FirewallRuleDescription" -Direction Inbound -Program "$FilePath" -Protocol $Protocol -Action Allow -EdgeTraversalPolicy DeferToUser -Enabled True -Profile Any
						IF ($NewFirewallRule) {
							Write-Log -Message "Created new $Protocol Firewall Rule `"$($NewFirewallRule.DisplayName)`" for Program file `"$FilePath`"" -Level Info
						} ELSE {
							Write-Log -Message "Failed to create $Protocol Firewall Rule `"$FirewallDisplayName `" for Program file `"$FilePath`"" -Level Error
						}
					}
				} ELSE {
					Write-Log -Message "Could not create Firewall Rule `"$($NewFirewallRule.DisplayName)`", target file ($FilePath) does not exist." -Level Error
				}
			} CATCH {
				
				$Line = $_.InvocationInfo.ScriptLineNumber
				"Error was in Line $line"
				Write-Log -Message "Error: $_" -Level Error
				Write-Log -Message "Error: on line $line" -Level Error
			}
			
			#endregion Create New Firewall Rules
		} CATCH {
			
			$Line = $_.InvocationInfo.ScriptLineNumber
			"Error was in Line $line"
			Write-Log -Message "Error: $_" -Level Error
			Write-Log -Message "Error: on line $line" -Level Error
		}
	}
	#endregion FUNCTION Create-FirewallRule
	
	Write-Log -Message " ----- BEGIN $($ScriptName) REMEDIATION execution ----- "
}
PROCESS {
	TRY {
		$SearchFileName = 'teams.exe'
		$SearchFolderPath = "$env:HOMEDRIVE\Users\*\AppData\Local\Microsoft\Teams\current\*"
		
		Write-Log -Message "Finding $($SearchFileName) in search path $($SearchFolderPath)"
		$TeamsEXEs = Get-ChildItem -Path $SearchFolderPath -Filter $SearchFileName -Recurse -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
		Write-Log -Message "Found $($TeamsEXEs.Count) matching files"
		
		Write-Log -Message "Creating Firewall rules for each file"
		FOREACH ($TeamsEXE IN $TeamsEXEs) {
			Create-FirewallRule -Protocol TCPUDP -Description "Firewall exception for Microsoft Teams" -DisplayName "Microsoft Teams" -FilePath $TeamsEXE -RemoveExisiting -SearchExisting 'teams.exe'
		}
		
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
	}
}
END {
	Write-Log -Message " ----- END $($ScriptName) REMEDIATION execution ----- "
}