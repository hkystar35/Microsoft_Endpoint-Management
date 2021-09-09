<#
	.SYNOPSIS
		A brief description of the  file.
	
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER AssignmentIDs
		A description of the AssignmentIDs parameter.
	
	.PARAMETER To
		A description of the To parameter.
	
	.PARAMETER From
		A description of the From parameter.
	
	.PARAMETER EmailSubject
		A description of the EmailSubject parameter.
	
	.PARAMETER AssignmentID
		A description of the AssignmentID parameter.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.156
		Created on:   	2/28/2019 11:08 AM
		Created by:   	NWendlowsky
		Organization: 	Paylocity
		Filename:
		===========================================================================
#>
PARAM
(
	[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$AssignmentIDs,
	[Parameter(Mandatory = $true)]$To,
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]$From,
	[ValidateNotNullOrEmpty()][string]$EmailSubject
)


BEGIN {
	$InvocationInfo = $MyInvocation
	[System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
	[string]$ScriptFullPath = $ScriptFileInfo.FullName
	[string]$ScriptNameFileExt = $ScriptFileInfo.Name
	[string]$ScriptName = $ScriptFileInfo.BaseName
	[string]$scriptRoot = Split-Path $ScriptFileInfo
	$SiteCode = 'PAY'
	$SCCMserver = 'AH-SCCM-01.paylocity.com'
	
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
			[ValidateNotNullOrEmpty()]$To = 'EUCEngineers@paylocity.com',
			[ValidateNotNullOrEmpty()]$From = "$($env:COMPUTERNAME)@paylocity.com",
			[ValidateNotNullOrEmpty()]$CC,
			$ScriptName = $ScriptName,
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
					SmtpServer = 'post.paylocity.com'
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
	#
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
		Write-Log -Message "Error: on line $line"
		Send-ErrorEmail -Message "Could not import SCCM module.`nError on line $line.`nError: $_"
		BREAK
	}
	#endregion Set SCCM cmdlet location
	#>
}
PROCESS {
	TRY {
		
		#region FUNCTION Get-WindowsErrorMessage
		FUNCTION Get-WindowsErrorMessage {
			[CmdletBinding()]
			PARAM
			(
				$ErrorCode,
				$ErrorSource = "Windows",
				[switch]$SimpleOutput = $false
			)
			
			#This error code was generated from the Windows Exception Library
			IF ($ErrorSource -eq "Windows") {
				IF ($ErrorCode -ge 60000 -and $ErrorCode -le 79999) {
					$PSADT_Error = $true
					$ErrorSource = "PSADT"
					SWITCH ($ErrorCode) {
						#60000 - 68999	 Reserved FOR built-in EXIT codes IN Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
						#69000 - 69999	 Recommended FOR user customized EXIT codes IN Deploy-Application.ps1
						#70000 - 79999	 Recommended FOR user customized EXIT codes IN AppDeployToolkitExtensions.ps1
						60001	{
							$ErrorMessage = "An error occurred IN Deploy-Application.ps1. Check your script syntax use."
						}
						60002	{
							$ErrorMessage = "Error when running Execute-Process FUNCTION"
						}
						60003	{
							$ErrorMessage = "Administrator privileges required FOR Execute-ProcessAsUser FUNCTION"
						}
						60004	{
							$ErrorMessage = "Failure when loading .NET Winforms / WPF Assemblies"
						}
						60005	{
							$ErrorMessage = "Failure when displaying the Blocked Application dialog"
						}
						60006	{
							$ErrorMessage = "AllowSystemInteractionFallback option was not selected IN the config XML file, so toolkit will not fall back to SYSTEM context with no interaction."
						}
						60007	{
							$ErrorMessage = "Failed to export the schedule task XML file IN Execute-ProcessAsUser FUNCTION"
						}
						60008	{
							$ErrorMessage = "Deploy-Application.ps1 failed to dot source AppDeployToolkitMain.ps1 either because it could not be found or there was an error WHILE it was being dot sourced."
						}
						60009	{
							$ErrorMessage = "The -UserName parameter IN the Execute-ProcessAsUser FUNCTION has a DEFAULT value that is empty because no logged IN users were detected when the toolkit was launched."
						}
						60010	{
							$ErrorMessage = "Deploy-Application.exe failed before PowerShell.exe PROCESS could be launched."
						}
						60011	{
							$ErrorMessage = "Deploy-Application.exe failed to execute the PowerShell.exe process."
						}
						60012	{
							$ErrorMessage = "A UI prompt timed out or the user opted to defer the installation."
						}
						60013	{
							$ErrorMessage = "IF Execute-Process FUNCTION captures an EXIT code out of range FOR int32 then RETURN this custom EXIT code."
						}
						
					}
				} ELSE {
					$ErrorMessage = [ComponentModel.Win32Exception]$ErrorCode
				}
			}
			
			#Write Output of Function
			IF ($SimpleOutput) {
				Write-Output $ErrorMessage
			} ELSE {
				IF ($PSADT_Error) {
					Write-Output "$ErrorSource Error $($ErrorCode): $($ErrorMessage)"
				} ELSE {
					Write-Output "$ErrorSource Error $($ErrorCode): $($ErrorMessage.Message)"
				}
			}
		}
		#endregion FUNCTION Get-WindowsErrorMessage
		
		#region FUNCTION Get-CMAppDeploymentReport
		FUNCTION Get-CMAppDeploymentReport {
			PARAM
			(
				[string]$AssignmentID,
				[Parameter(Mandatory = $true)][string]$SiteCode,
				[Parameter(Mandatory = $true)][string]$SCCMServer
			)
			TRY {
				
				#Select Deployment to Report on
				Write-Log -Message "Generating Deployment Report for AssignmentID $($AssignmentID)"
				
				#Get Summary Data
				$Summary = Get-WMIObject -ComputerName $SCCMServer -Namespace "root\sms\Site_$($SiteCode)" -class SMS_DeploymentSummary -Filter "AssignmentID = $AssignmentID and FeatureType = 1"
				
				# Get Collection Info
				$CollectionInfo = Get-WMIObject -ComputerName $SCCMServer -Namespace "root\sms\Site_$($SiteCode)" -Class SMS_Collection -Filter "CollectionID = ""$($Summary.CollectionID)"""
				$CollectionName = $CollectionInfo.Name
				$CollectionID = $CollectionInfo.CollectionID
				SWITCH ($CollectionInfo.CollectionType) {
					1 {
						$CollectionType = "Device"
					}
					2 {
						$CollectionType = "User"
					}
					default {
						$CollectionType = "Other"
					}
				}
				
				# Set Summary Info
				$SummaryTable = $Summary | Select-Object AssignmentID, CollectionID, CollectionName, SoftwareName, @{
					Name																	   = "DeploymentTime"; Expression = {
						$([Management.ManagementDateTimeConverter]::toDateTime($_.DeploymentTime))
					}
				}, @{
					Name = "DeploymentIntent"; Expression = {
						SWITCH ($_.DeploymentIntent) {
							1 {
								"Required"
							}
							2 {
								"Available"
							}
							default {
								"Unknown"
							}
						}
					}
				}, @{
					Name																		    = "EnforcementDeadline"; Expression = {
						$([Management.ManagementDateTimeConverter]::toDateTime($_.EnforcementDeadline))
					}
				}, NumberSuccess, NumberInProgress, NumberErrors, NumberUnknown, NumberTargeted, PackageID
				# Set Title
				$Title = "Summary of Deployment for $($Summary.SoftwareName) to $($CollectionInfo.MemberCount) $($CollectionType)(s)"
				
				
				Write-Log -Message "Found AssignmentID $($AssignmentID) details: $($Summary.SoftwareName) deployed to Collection $($Summary.CollectionName) ($($Summary.CollectionID)) for $($Summary.NumberTargeted) $($CollectionType)(s)"
				
				# Add Summary Info to output object
				$OutputReport = New-Object -TypeName PSObject -Property @{
					"Title"   = $Title
					"Results" = $SummaryTable
				}
				Write-Log -Message "Report Title: $Title"
				
				### Get Detail Data
				# Get Deployment Assets
				$Detail = Get-WMIObject -ComputerName $SCCMServer -Namespace "root\sms\Site_$($SiteCode)" -class SMS_AppDeploymentAssetDetails -Filter "AssignmentID = $AssignmentID"
				# Get Deployment Status Details
				$ErrorData = Get-WMIObject -ComputerName $SCCMServer -Namespace "root\sms\Site_$($SiteCode)" -class SMS_AppDeploymentErrorAssetDetails -Filter "AssignmentID = $AssignmentID"
				
				#region Loop through assets to gather data
				# Set Array
				$Devices = @()
				$Count = 0
				FOREACH ($Target IN $Detail) {
					TRY {
						$Count++
						Write-Log -Message "Adding member $($Count) of $($Detail.count) ($($Target.MachineName))"
						
						# Set Error Info
						$ErrorCode = $ErrorData | Where-Object{
							$Target.MachineID -eq $_.MachineID
						} | Select-Object -ExpandProperty ErrorCode
						$ErrorMessage = Get-WindowsErrorMessage -ErrorCode $ErrorCode
						
						# Set State
						SWITCH ($Target.AppStatusType) {
							1 {
								$State = "Success"
							}
							2 {
								$State = "In Progress"
							}
							3 {
								$State = "Requirements Not Met"
							}
							4 {
								$State = "Offline"
							}
							5 {
								IF ($ErrorCode -eq '60012') {
									$State = "Deferred"
								} ELSEIF ($ErrorCode -ne '60012') {
									$State = "Error"
								}
							}
							default {
								$State = "UnknownState"
							}
						}
						
				<#
				$CIComplianceInfo = Get-WMIObject -ComputerName $SCCMServer -Namespace "root\sms\Site_$($SiteCode)" -Class SMS_CI_ComplianceHistory -Filter "ResourceID = $($Target.MachineID) and CI_ID = $($Target.AppCI)"
				TRY {
					$CIComplianceInfo = $CIComplianceInfo | Sort-Object -Property ComplianceStartDate -Descending | Select-Object * -First 1
					$LastComplianceStateChange = $([Management.ManagementDateTimeConverter]::toDateTime($($CIComplianceInfo.ComplianceStartDate)))
				} CATCH {
					$LastComplianceStateChange = ""
				}
				#>
						
						$Device = New-Object -TypeName PSObject -Property @{
							Name = $($Target.MachineName)
							State = $($State)
							ErrorCode = $($ErrorCode)
							ErrorMessage = $($ErrorMessage)
							#LastComplianceStateChange = $($LastComplianceStateChange)
						}
						
						$Devices += $Device
					} CATCH {
						$Line = $_.InvocationInfo.ScriptLineNumber
						"Error was in Line $line around member $($Target.MachineNam)"
						Write-Log -Message "Error: $_" -Level Error
						Write-Log -Message "Error: on line $line" -Level Error
					}
				}
				#endregion Loop through assets to gather data
				
				# Add Device Details to Output object
				$OutputReport | Add-Member -MemberType NoteProperty -Name "DetailResults" -Value $Devices
				
				# Output results to PSObject
				Write-Output $OutputReport
			} CATCH {
				$Line = $_.InvocationInfo.ScriptLineNumber
				"Error was in Line $line"
				Write-Log -Message "Error: $_" -Level Error
				Write-Log -Message "Error: on line $line" -Level Error
			}
		}
		#endregion FUNCTION Get-CMAppDeploymentReport
		
		# Set Varaible
		$Body_Tables = ''
		
		#region Loop to calculate numbers
		#[array]$AssignmentIDs = $AssignmentIDs.Split(',')
		FOREACH ($AssignmentID IN $AssignmentIDs) {
			Write-Log -Message "AssignmentID loop start: $AssignmentID of array: $AssignmentIDs"
			# Set report data to variable
			$Report = Get-CMAppDeploymentReport -AssignmentID $AssignmentID -SCCMServer $SCCMserver -SiteCode $SiteCode
			
			# Set numbers
			$Success = $Report.Results.NumberSuccess
			$InProgress = $Report.Results.NumberInProgress
			$Deferred = ($Report.DetailResults | Where-Object{
					$_.State -eq 'Deferred'
				}).count
			$Errors = ([int32]$Report.Results.NumberErrors - [int32]$Deferred)
			$Total = $Report.Results.NumberTargeted
			$Offline = $Report.Results.NumberUnknown
			$TotalOnline = $Total - $Offline
			Write-log -Message "Total: $Total / Offline: $Offline /// Total Online: $TotalOnline / Success: $Success / In Progress: $InProgress / Deferred: $Deferred / Errors: $Errors"
			
			
			# Set percentages
			$SuccessPercent = ($Success/$TotalOnline).ToString("P")
			$InProgressPercent = ($InProgress/$TotalOnline).ToString("P")
			$DeferredPercent = ($Deferred/$TotalOnline).ToString("P")
			$ErrorsPercent = ($Errors/$TotalOnline).ToString("P")
			$OfflinePercent = ($Offline/$TotalOnline).ToString("P")
			
			# Add table title
			$Body_Tables += @"
<p><span style="font-size: 10.0pt; font-family: 'Times New Roman',serif;">$($Report.Results.SoftwareName) deployed to $($Report.Results.CollectionName)</span></p>
"@
			
			# Add data Table
			$Body_Tables += @"
<table style="border-collapse: collapse; width: 220pt;" width="293">
<tbody>
<tr style="height: 12pt; background-color: #f58e07;">
<td style="height: 12pt; width: 75px;">Status</td>
<td style="width: 75px;">Count</td>
<td style="width: 75px;">Percent</td>
</tr>
<tr style="height: 12.0pt;">
<td style="height: 12pt; width: 75px;">Success</td>
<td style="width: 75px;">$($Success)</td>
<td style="width: 75px;">$($SuccessPercent)</td>
</tr>
<tr style="height: 12.0pt;">
<td style="height: 12pt; width: 75px;">In Progress</td>
<td style="width: 75px;">$($InProgress)</td>
<td style="width: 75px;">$($InProgressPercent)</td>
</tr>
<tr style="height: 12.0pt;">
<td style="height: 12pt; width: 75px;">Deferred</td>
<td style="width: 75px;">$($Deferred)</td>
<td style="width: 75px;">$($DeferredPercent)</td>
</tr>
<tr style="height: 12.0pt;">
<td style="height: 12pt; width: 75px;">Error</td>
<td style="width: 75px;">$($Errors)</td>
<td style="width: 75px;">$($ErrorsPercent)</td>
</tr>
</tbody>
</table>
"@
			# Add table footer
			$Body_Tables += @"
<p>Table stats use Online targets only.</p>
<p><span style="font-size: 10.0pt; font-family: 'Times New Roman',serif;">Total Targeted: $($Total) `| Online: $($TotalOnline) / Offline: $($Offline)</span></p>
<p>&nbsp;</p>        
"@
			
			$DefaultSubject = $Report.Title
			
			# Garbage cleanup variables
			Clear-Variable report, Success, successpercent, inprogress, inprogresspercent, errors, errorspercent, deferred, deferredpercent, total, offline, totalonline
		}
		#endregion Loop to calculate numbers
		
		# Send Email
		IF (!$Subject) {
			$Subject = $DefaultSubject
		}
		
		$Salutation = @"
<p>&nbsp;</p>
<p><span style="font-size: 10pt; font-family: times new roman, times;">____________________________</span></p>
<p><span style="font-size: 10pt; font-family: times new roman, times;">&nbsp;<strong>Nic Wendlowsky</strong> | End User Computing Engineer</span></p>
<p><span style="font-size: 10pt; font-family: times new roman, times;">Paylocity | <a href="mailto:nwendlowsky@paylocity.com"><span style="color: #0563c1;">nwendlowsky@paylocity.com</span></a></span></p>
<p><span style="font-size: 10pt; font-family: times new roman, times;"><strong>C: 208.972.1757</strong> | EUC: 888-729-5624 (4526 &ndash;internal)</span></p>
<p><span style="font-size: 10pt; font-family: times new roman, times;"><a href="mailto:askeuc@paylocity.com"><span style="color: #0563c1;">askeuc@paylocity.com</span></a></span></p>
<p><span style="font-size: 10pt; font-family: times new roman, times;"><a href="https://employee.paylocity.com"><span style="color: #0563c1;">EUC Self-Help</span></a></span></p>
"@
		$EmailBody = $Body_Tables
		$EmailBody += $Salutation
		Send-Email -Body $EmailBody -html -Subject $($Subject) -To $To
		
		
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		"Error was in Line $line"
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
	}
}


END {
	Write-Log "End of script $($ScriptName) -----------------------------------------------------------------------"
}
