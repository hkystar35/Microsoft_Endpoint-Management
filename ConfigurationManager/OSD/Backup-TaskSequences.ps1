<#
	.SYNOPSIS
		Exports all Task Sequences (without content) to specified server share and emails recipients upon completion.
	
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER SiteCode
		A description of the SiteCode parameter.
	
	.PARAMETER MailTo
		Specify the email address for the notification email.
	
	.PARAMETER BackupFolder
		Specify the folder to backup the zip files.
	
	.PARAMETER PAY
		Specify the SCC Site Code.
	
	.NOTES
		===========================================================================
		
		Created on:   	08/30/2019 3:07:56 PM
		Created by:   	hkystar35@contoso.com
		Organization: 	contoso
		Filename:       Backup-TaskSequences.ps1
		===========================================================================
#>
[CmdletBinding()]
PARAM
(
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$SiteCode = 'PAY',
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$MailTo = 'EUCEngineers@contoso.com',
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][ValidateScript({
			[System.IO.Directory]::Exists($_)
		})][string]$BackupFolder = '\\INT-SCCM-PR-01\TS\Backups'
)
BEGIN {
	$InvocationInfo = $MyInvocation
	[System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
	[string]$ScriptFullPath = $ScriptFileInfo.FullName
	[string]$ScriptNameFileExt = $ScriptFileInfo.Name
	[string]$ScriptName = $ScriptFileInfo.BaseName
	[string]$scriptRoot = Split-Path $ScriptFileInfo
	
	#region FUNCTION Send-Email
	FUNCTION Send-Email {
		PARAM
		(
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$Body,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$To,
			[ValidateNotNullOrEmpty()]$From = "$($env:COMPUTERNAME)@contoso.com",
			[ValidateNotNullOrEmpty()]$CC,
			$CurrentScriptName = $ScriptName,
			[ValidateNotNullOrEmpty()][string]$Subject,
			[Parameter(Mandatory = $false)][switch]$html = $false,
			[Parameter(Mandatory = $false)][ValidateSet('Normal', 'High', 'Low')]$Priority = 'Normal'
		)
		BEGIN {
		}
		PROCESS {
			
			TRY {
				# Create Email Arguments hastable
				$EmailArgs = @{
				}
				
				#region Format args
				IF (!$Subject) {
					$EmailArgs += @{
						Subject = "$CurrentScriptName run on $($env:COMPUTERNAME)"
					}
				} ELSE {
					$EmailArgs += @{
						Subject = $Subject
					}
				}
				
				# If Html, add to hashtable and convert variable to string
				IF ($html) {
					$BodyHTML = $Body | Out-String
					$EmailArgs += @{
						BodyAsHtml = $true
						Body	   = $BodyHTML
					}
				} ELSE {
					$EmailArgs += @{
						Body = $Body
					}
				}
				
				# If CC used, add to hashtable
				IF ($CC) {
					$EmailArgs += @{
						CC = $CC
					}
				}
				
				# Add required params to hashtable
				$EmailArgs += @{
					To		   = $To
					From	   = $From
					SmtpServer = 'post.contoso.com'
					Priority   = $Priority
				}
				
				# Capture args in new variable for error collection
				$EmailArgsReturn = $EmailArgs
				
				#endregion Format args
				
				#Send email
				Write-Log -Message "Sending email to $($To). . ."
				Send-MailMessage @EmailArgs -ErrorAction Stop
				Write-Log -Message ". . . sent." -Level Info
				$EmailArgsReturn += @{
					Status = 'Success'
					Error  = 0
				}
			} CATCH {
				$Line = $_.InvocationInfo.ScriptLineNumber
				Write-Log -Message "Email failed to send." -Level Error
				Write-Log -Message "Error: $_" -Level Error
				Write-Log -Message "Error: on line $line" -Level Error
				$EmailArgsReturn += @{
					Status = 'Error'
					Error  = "Line $Line"
				}
			}
		}
		END {
			# Return hashtable values
			RETURN $EmailArgsReturn
		}
	}
	#endregion FUNCTION Send-Email
	
	#region FUNCTION Write-Log
	FUNCTION Write-Log {
		[CmdletBinding()]
		PARAM
		(
			[Parameter(Mandatory = $true,
					   ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][Alias("LogContent")][string]$Message,
			[Parameter(Mandatory = $false)][Alias('LogPath')][string]$Path = "$env:windir\Logs\$($ScriptName).log",
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
	
	#region Set SCCM cmdlet location
	TRY {
		$StartingLocation = Get-Location
		IF ($env:SMS_ADMIN_UI_PATH) {
		}
		Import-Module -Name $env:SMS_ADMIN_UI_PATH.Replace('\bin\i386', '\bin\ConfigurationManager.psd1')
		IF (!$SiteCode) {
			$SiteCode = (Get-PSDrive -PSProvider CMSITE).Name
		}
		Write-Log -Message "Changing location to $($SiteCode):\"
		Set-Location -Path "$($SiteCode):\"
		Write-Log -Message "done."
	} CATCH {
		Write-Log -Message 'Could not import SCCM module' -Level Warn
		Set-Location -Path $StartingLocation
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log -Message "Error: $_"
		Write-Log -Message "Error: on line $line"
		#Send-ErrorEmail -Message "Could not import SCCM module.`nError on line $line.`nError: $_"
		BREAK
	}
	#endregion Set SCCM cmdlet location
	
	Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
}
PROCESS {
	TRY {
		## Main Script Block
		Write-Log -Message "Gathering all Task Sequences from Site $SiteCode. This can take a few minutes..."
		$GetAllTaskSequences = Get-CMTaskSequence
		$TScount = $GetAllTaskSequences.Count
		Write-Log -Message "Found $($GetAllTaskSequences.Count) Task Sequences to backup"
		$Success = @()
		$Errors = @()
		
		IF ($GetAllTaskSequences.Count -gt 1) {
			$i = 0
			FOREACH ($TS IN $GetAllTaskSequences) {
				$i++
				$Date = Get-Date -Format 'yyyyMMdd-HHmmss'
				$ExportFilePath = (Join-Path "$BackupFolder" -ChildPath ($TS.Name + '_' + $TS.PackageID + '_' + $Date + '.zip'))
				
				TRY {
					$TS | Export-CMTaskSequence -ExportFilePath "$ExportFilePath" -WithDependence $false -WithContent $false -Comment "Backup of $($TS.Name) on $Date." -Force
					Write-Log -Message "TS Backup $i of $TScount - Success - $($TS.Name) to $ExportFilePath"
					$Success += $TS
				} CATCH {
					Write-Log -Message "TS Backup $i of $TScount - FAIL - $($TS.Name) to $ExportFilePath" -Level Error
					$Errors += $TS
				}
				Clear-Variable ExportFilePath, Date -ErrorAction SilentlyContinue
			}
		}
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		$LastError = $_
		Write-Log -Message "Error on line $line`: $_" -Level Error
	}
}
END {
	Write-Log -Message "$($Success.count) of $($GetAllTaskSequences.count) Task Sequences successfully backed up."
	
	$Body = @"
Task Sequence backup successfully ran.

$($Success.count) of $TScount Task Sequences successfully backed up.
"@
	IF ($Errors -or $Errors.count -ge 1) {
		Write-Log -Message "Failed to backup $($Success.count) Task Sequences."
		$Body += @"

Failed to backup $($Success.count) of $TScount Task Sequences.

Error on line $line

Error Text:
$LastError

---------------------------
"@
	}
	Send-Email -Body $Body -To $MailTo -Subject "$($ScriptName) script executed"
	Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}
