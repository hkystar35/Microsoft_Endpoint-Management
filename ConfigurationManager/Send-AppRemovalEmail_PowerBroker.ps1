<#
	.SYNOPSIS
		Email users to uninstall PowerBroker
	
	.DESCRIPTION
		A description of the file.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.159
		Created on:   	2/22/2019 10:23 PM
		Created by:   	Nhkystar35
		Organization: 	contoso
		Filename:
		===========================================================================
#>
BEGIN {
	$InvocationInfo = $MyInvocation
	[System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
	[string]$ScriptFullPath = $ScriptFileInfo.FullName
	[string]$ScriptNameFileExt = $ScriptFileInfo.Name
	[string]$ScriptName = $ScriptFileInfo.BaseName
	[string]$scriptRoot = Split-Path $ScriptFileInfo
	
	
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
	
	#region FUNCTION Send-Email
	FUNCTION Send-Email {
		PARAM
		(
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$Body,
			[ValidateNotNullOrEmpty()]$To = 'EUCEngineers@contoso.com',
			[ValidateNotNullOrEmpty()]$From = "$($env:COMPUTERNAME)@contoso.com",
			[ValidateNotNullOrEmpty()]$CC = 'EUCEngineers@contoso.com',
			$ScriptName,
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
				
				# Format Subject line
				IF (!$Subject) {
					IF ($ScriptName) {
						$ScriptName = $ScriptName + ' '
					}
					$EmailArgs += @{
						Subject = "$ScriptName Script Error on $($env:COMPUTERNAME)"
					}
				} ELSE {
					$EmailArgs += @{
						Subject = $Subject + " (Script generated on $($env:COMPUTERNAME))"
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
				
				#Send email
				TRY {
					Write-Log -Message "Sending email to $($To). . ." -Level Info
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
			} CATCH {
				$Line = $_.InvocationInfo.ScriptLineNumber
				"Error was in Line $line"
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
	Write-Log -Message "---------------------- BEGIN SCRIPT $($ScriptName) ----------------------"
}
PROCESS {
	TRY {
		# SQL Query
		$SQL = @"
select distinct
v_GS_INSTALLED_SOFTWARE.ProductName0 as 'AppName'
,v_GS_INSTALLED_SOFTWARE.Publisher0 as 'AppPublisher'
,v_GS_INSTALLED_SOFTWARE.ProductVersion0 as 'AppVersion'
,RU.Mail0 AS 'Email'
,RSYS.Name0 AS 'MachineName'

from 
v_R_User RU
inner join v_UsersPrimaryMachines PRIM on RU.ResourceID = PRIM.UserResourceID
inner join v_R_System RSYS on PRIM.MachineID = RSYS.ResourceID
inner join v_GS_INSTALLED_SOFTWARE on RSYS.ResourceID = v_GS_INSTALLED_SOFTWARE.ResourceID
inner join v_UsersPrimaryMachines on PRIM.MachineID = RSYS.ResourceID

where v_GS_INSTALLED_SOFTWARE.ProductName0 = 'BeyondTrust PowerBroker Desktops Client for Windows'

order by 'MachineName'
"@
		
		# Invoke SQL Query
		Write-Log -Message "Querying SCCM SQL. . ."
		$PBInstalls = Invoke-Sqlcmd -ServerInstance 'ah-sccm-01.contoso.com' -Database 'CM_PAY' -Query $SQL
		Write-Log -Message ". . . done."
		
		#region HTML Mail body
		$TableHeader = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #FF6611;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@
		$Salutation = @"
<p>&nbsp;</p>
<p>There's a script to remove PowerBroker in the <a title="AppStore" href="http://appstore.contoso.com" target="_blank">AppStore</a> by searching for "PowerBroker" and choosing Install on "REMOVE PowerBroker - All Versions". (<em>Please use the script, testing has shown trying to remove from Add/Remove Programs to be unreliable</em>)</p>
<p>If you run into issues with the AppStore, the same script is visible in your <a title="Software Center" href="softwarecenter:" target="_blank">Software Center</a> in the Applications tab.</p>
<p>This <span style="text-decoration: underline;"><strong>WILL require a reboot</strong></span>, so do not initialize it until you are ready. A pop-up window will appear giving you a timer until the reboot is forced.</p>
<p>If you are still on Windows 8.1, this is especially important as it will delay upgrading to Windows 10.</p>
<p>&nbsp;</p>
<p>If you have questions or we have misidentified the machine in table as yours, please let us know!</p>
<p>Thank you,</p>
<p><strong>EUC Engineering</strong></p>
<p>contoso | <a title="EUC Engineers" href="mailto:EUCEngineers@contoso.com" target="_blank">EUCEngineers@contoso.com</a></p>
<p>EUC: 888-729-5624 (4526 &ndash;internal)</p>
<p><a href="mailto:askeuc@contoso.com"><span style="color: #0563c1;">askeuc@contoso.com</span></a></p>
<p><a title="Zendesk" href="https://employee.contoso.com" target="_blank"><span style="color: #0563c1;">EUC Self-Help</span></a></p>
"@
		#endregion HTML Mail body
		
		# Array for table email to EUC/engineers
		$FinalTable = @()
		
		# Loop though each member to generate individual email
		Write-Log -Message "Sending emails to users matching SQL query data."
		Write-Log -Message "Total users to email: $($PBInstalls.count)."
		#FOREACH ($Member IN $PBInstalls) {
		#
		#test line
		$Member = @()
		$Member += New-Object -TypeName PSObject -Property @{
			AppName	     = "BeyondTrust PowerBroker Desktops Client for Windows"
			AppPublisher = "BeyondTrust Software, Inc."
			AppVersion   = "17.3.0.30"
			Email	     = "hkystar35@contoso.com"
			MachineName  = "EUCE-P1-TEST"
		}
		#>
		$Email = $($Member.Email)
		$FirstName = Get-ADUser -Filter {
			EmailAddress -eq $Email
		} | Select-Object -ExpandProperty GivenName
		# HTML Setup
		$Greeting = @"
<p>Hello $($FirstName)!</p>
<p>You are receiving this email because we see you still have PowerBroker installed on your machine (See table below).</p>
"@
		$Table = $Member | ConvertTo-Html -Property AppName, AppVersion, MachineName -Head $TableHeader -As Table
		$Body = $Greeting
		$Body += $Table
		$Body += $Salutation
		$EmailStatus = Send-Email -Subject 'Uninstall PowerBroker!' -Body $Body -html -Priority High -To $Email -From 'EUCEngineers@contoso.com' -CC 'hkystar35@contoso.com'
		# Data for table email after individual emails sent
		
		$FinalTable += New-Object -TypeName PSObject -Property @{
			AppName = $Member.AppName
			AppVersion = $Member.AppVersion
			MachineName = $Member.MachineName
			Email   = $Email
			"Email Status" = ($EmailStatus | Select-Object @{
					Label = "Status"; E = {
						$_.Status
					}
				}).status
			"Time Sent" = "$(Get-Date) $((Get-TimeZone).id)"
		}
		
		Clear-Variable email, firstname, greeting, table, body -ErrorAction SilentlyContinue
		#}
		
		$Table = $FinalTable | ConvertTo-Html -Property AppName, AppVersion, MachineName, Email, "Email Status", "Time Sent" -Head $TableHeader -As Table
		
		$Body = @"
<p><strong>PowerBroker removal email sent to users in this table:</strong></p>
"@
		$Body += $Table
		Write-Log -Message "Sending email status table to eucengineers@contoso.com for documentation."
		#Send-Email -Subject 'Uninstall PowerBroker email sent' -Body $Body -html -Priority Normal -To 'EUC@contoso.com' -CC 'EUCEngineers@contoso.com'
		Send-Email -Subject 'Uninstall PowerBroker email sent' -Body $Body -html -Priority Normal -To 'hkystar35@contoso.com' -CC 'hkystar35@contoso.com'
		
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		"Error was in Line $line"
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
	}
}
END {
	Write-Log -Message "---------------------- End SCRIPT $($ScriptName) ----------------------"
}
	
