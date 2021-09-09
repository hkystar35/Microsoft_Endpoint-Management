<#
	.SYNOPSIS
		Enable or disable Windows Updates SUGs
	
	.DESCRIPTION
		Determines if current date is within FREEZE timeframe and disables ADR Rules when needed to ensure no updates pushed to FREEZE groups. Best to run on the 1st of each month.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.155
		Created on:   	11/27/2018 11:04 AM
		Created by:   	Nhkystar35
		Organization: 	contoso
		Filename: Change-FreezeADRRules.ps1
		===========================================================================
#>


BEGIN {
	#region Variables
	$ScriptPath = Get-Location
	$ScriptName = $MyInvocation.MyCommand.Name
	$StartFreeze = Get-Date -Month 12 -Day 01 -Hour 00 -Minute 00 -Second 00 -Millisecond 01
	$EndFreeze = Get-Date -Year ($StartFreeze.AddYears(1).Year) -Month 01 -Day 31 -Hour 00 -Minute 00 -Second 00 -Millisecond 01
	$CollectionSearchString = 'WindowsUpdates_FREEZE_*'
	#endregion Variables
	
	#region Functions
	#region FUNCTION Write-Log
	FUNCTION Write-Log {
		[CmdletBinding()]
		PARAM
		(
			[Parameter(Mandatory = $true,
					   ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][Alias("LogContent")][string]$Message,
			[Parameter(Mandatory = $false)][Alias('LogPath')][string]$Path = "$env:windir\Logs\$($ScriptName).log",
			[Parameter(Mandatory = $false)][ValidateSet("Error", "Warn", "Info")][string]$Level = "Info",
			[Parameter(Mandatory = $false)][switch]$NoClobber
		)
		
		BEGIN {
			# Set VerbosePreference to Continue so that verbose messages are displayed. 
			$VerbosePreference = 'SilentlyContinue'
		}
		PROCESS {
			
			# If the file already exists and NoClobber was specified, do not write to the log. 
			IF ((Test-Path $Path) -AND $NoClobber) {
				Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
				RETURN
			}
			
			# If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
ELSEIF (!(Test-Path $Path)) {
				Write-Verbose "Creating $Path."
				$NewLogFile = New-Item $Path -Force -ItemType File
			} ELSE {
				# Nothing to see here yet. 
			}
			
			# Format Date for our Log File 
			$FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
			
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
	#region FUNCTION Is-DateBetweenTimes
	FUNCTION Is-DateBetweenTimes(
		[Datetime]$start,
		[Datetime]$end
	) {
		$d = get-date
		IF (($d -ge $start) -and ($d -le $end)) {
			RETURN $true
		} ELSE {
			RETURN $false
		}
	}
	#endregion FUNCTION Is-DateBetweenTimes
	#region FUNCTION Send-ErrorEmail
	FUNCTION Send-ErrorEmail {
		PARAM
		(
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Message,
			[ValidateNotNullOrEmpty()]$To = 'EUCEngineers@contoso.com',
			[ValidateNotNullOrEmpty()]$From = 'EUCEngineers@contoso.com',
			[ValidateNotNullOrEmpty()][string]$Script = $ScriptName
		)
		
		#TODO: Place script here
		Send-MailMessage -To $To -From $From -Subject "$Script Script Error on $($env:COMPUTERNAME)" -Body $Message -SmtpServer 'post.contoso.com'
		Write-Log -Message "Email sent to $To from $From with message body of `"$Message`""
	}
	
	#endregion FUNCTION Send-ErrorEmail
	#endregion Functions
    #region Set SCCM cmdlet location
    TRY {
		    $StartingLocation = Get-Location
		    Import-Module -Name $env:SMS_ADMIN_UI_PATH.Replace('\bin\i386', '\bin\ConfigurationManager.psd1')
		    Write-Log -Message "Changing location to $($SiteCode.Name):\"
		    $SiteCode = Get-PSDrive -PSProvider CMSITE
		    Set-Location -Path "$($SiteCode.Name):\"
		    Write-Log -Message "done."
	    } CATCH {
		    Write-Log -Message 'Could not import SCCM module' -Level Warn
		    Set-Location -Path $StartingLocation
            $Line = $_.InvocationInfo.ScriptLineNumber
            Write-Log -Message "Error: $_"
            Write-Log -Message  "Error: on line $line"
            Send-ErrorEmail -Message "Could not import SCCM module.`nError on line $line.`nError: $_"
            BREAK
	    }
    #endregion Set SCCM cmdlet location
    Write-Log "-----------------------------------------------------------------"
    Write-Log "----------------------------- BEGIN -----------------------------"
}
PROCESS {
	TRY {
		#Determine if FREEZE is in effect
		$CollectionNames = Get-CMCollection -Name "$CollectionSearchString" -ErrorAction Stop | Select-Object -ExpandProperty Name
	    $ADR = Get-CMAutoDeploymentRule -Fast
	    $Deployments = $ADR | Get-CMAutoDeploymentRuleDeployment | Where-Object{$_.CollectionName -in $CollectionNames}
        $FREEZE = Is-DateBetweenTimes $StartFreeze $EndFreeze
		IF (!$CollectionNames) {
			Write-Log -Message "No collections found for search string `"$($CollectionSearchString)`"." -Level Warn
			Send-ErrorEmail -Message "Could not find Windows Update collections to disable for FREEZE Check.`nVerify Collection search string `"$($CollectionSearchString)`" is still accurate." -To 'hkystar35@contoso.com'
            THROW 1
		} ELSEIF (!$ADR) {
			Write-Log -Message "No ADRs found for search string `"$($CollectionSearchString)`"." -Level Warn
			Send-ErrorEmail -Message "Could not find ADRs for FREEZE Check.`nVerify ADRs exist." -To 'hkystar35@contoso.com'
            THROW 1
		} ELSEIF (!$Deployments) {
			Write-Log -Message "No ADR Deployment Rules found for search string `"$($CollectionSearchString)`"." -Level Warn
			Send-ErrorEmail -Message "Could not find ADR Deployment Rules for FREEZE Check.`nVerify ADR Deployment Rules exist." -To 'hkystar35@contoso.com'
            THROW 1
		}
		IF ($FREEZE) {
			Write-Log -Message "FREEZE is in effect. Disabling ADR rules." -Level Warn
			
			$Deployments | ForEach-Object{
				IF ($_.Enabled) {
					Write-Log -Message "Setting $($_.CollectionName) to Disabled"
					#Set-CMAutoDeploymentRuleDeployment -InputObject $_ -EnableDeployment $false
				} ELSEIF (!$_.Enabled) {
					Write-Log -Message "Rule for $($_.CollectionName) already Disabled"
				}
			}
		} ELSEIF (!$FREEZE) {
			Write-Log -Message "Freeze is NOT in effect. Enabling ADR rules." -Level Warn
			#Enable any disabled FREEZE rules
			$Deployments | ForEach-Object{
				IF (!$_.Enabled) {
					Write-Log -Message "Setting $($_.CollectionName) to Enabled"
					#Set-CMAutoDeploymentRuleDeployment -InputObject $_ -EnableDeployment $true
				} ELSE {
					Write-Log -Message "RUle for $($_.CollectionName) already Enabled"
				}
			}
		}
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		"Error was in Line $line"
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
        Write-Log "----------------------------- END -----------------------------"
	}
}
END {
	Write-Log "----------------------------- END -----------------------------"
}
