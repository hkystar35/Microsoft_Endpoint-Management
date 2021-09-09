<#
	.SYNOPSIS
		Creates Wiki page and CAB tickets for Monthly Updates
	
	.DESCRIPTION
		Using Zendesk API and Confluence module for PowerShell, this script gathers the recent month's Windows Updates from SCCM, formats them for a Wiki page, creates the page, then creates the Zendesk tickets based on the set schedules.
	
	.PARAMETER EmergencySchedule
		Switch to designate if schedule needs to be set to Expedited.
	
	.PARAMETER ZDToken
		Zendesk API token
	
	.PARAMETER ZDURL
		Zendesk API URL
	
	.PARAMETER ZDSubmitEmail
		Email used to submit Zendesk tickets
	
	.PARAMETER ConfluenceCredSecureString
		A description of the ConfluenceCredSecureString parameter. (In progress)
	
	.EXAMPLE
				PS C:\> .\Create-WikiAndCCTickets.ps1 -ZDToken 'asdklfhasdifhfoihfeoawiefdsf' -ZDURL 'http://domain.zendesk.com/api/v2' -ZDSubmitEmail 'name@domain.com'
	
	.NOTES
		Additional information about the file.
#>
[CmdletBinding()]
PARAM
(
	[switch]$EmergencySchedule = $false,
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$ZDSubmitEmail = $null,
    [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$CyberArkUserName = 'nhkystar35',
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$CyberArkName_ZD = 'Token-API-Zendesk-EUCE',
    [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$CyberArkName_Slack = 'Token-API-Slack-EUCE',
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$CyberArkSafeName = 'Team-EUCENG-Passwords',
    [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][System.IO.DirectoryInfo]$contosoCyberArkPath = "C:\Modules\contoso.cyberark",
    [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$Confluence_UserName = 'nhkystar35',
    [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][int]$Confluence_ParentPageID = '46478898',
    [switch]$CreateTickets = $false
)
BEGIN {
	$InvocationInfo = $MyInvocation
	[System.IO.FileInfo]$Global:ScriptFileInfo = $InvocationInfo.MyCommand.Path
	[string]$Global:ScriptFullPath = $ScriptFileInfo.FullName
	[string]$Global:ScriptNameFileExt = $ScriptFileInfo.Name
	[string]$Global:ScriptName = $ScriptFileInfo.BaseName
	[string]$Global:scriptRoot = Split-Path $ScriptFileInfo
	
	# Set Paths for CyberArk module and credman
	$contosoCyberArkPath_Module = Join-Path $contosoCyberArkPath 'Source\contoso.CyberArk.psm1'
	$contosoCyberArkPath_CredMan = Join-Path $contosoCyberArkPath 'Source\CredMan.ps1'
    Test-Path $contosoCyberArkPath_Module -PathType Leaf -ErrorAction Stop
    Test-Path $contosoCyberArkPath_CredMan -PathType Leaf -ErrorAction Stop

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
		Import-Module -Name $env:SMS_ADMIN_UI_PATH.Replace('\bin\i386', '\bin\ConfigurationManager.psd1')
		$SiteCode = Get-PSDrive -PSProvider CMSITE
		Write-Log -Message "Changing location to $($SiteCode.Name):\"
		Set-Location -Path "$($SiteCode.Name):\"
		Write-Log -Message "done."
	} CATCH {
		Write-Log -Message 'Could not import SCCM module' -Level Warn
		Set-Location -Path $StartingLocation
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log -Message "Error: $_"
		Write-Log -Message "Error: on line $line"
		#Send-ErrorEmail -Message "Could not import SCCM module.`nError on line $line.`nError: $_"
		THROW "Error: $_"
	}
	#endregion Set SCCM cmdlet location	

	#region Import CyberArk Module
	$GetModule = Get-Module -Name contoso.CyberArk -ErrorAction SilentlyContinue
	IF (!$GetModule) {
		Write-Log -Message "contoso.CyberArk module not imported."
		#$contosoCyberArk = Find-Module -Name contoso.CyberArk -ErrorAction Stop
		#$contosoCyberArk | Import-Module -Force -ErrorAction Stop
		#Install-Module -Name contoso.cyberark -Repository
		Import-Module $contosoCyberArkPath_Module -Force -Cmdlet:$false -ErrorAction Stop
		TRY {
			$GetModule = Get-Module -Name contoso.CyberArk -ErrorAction Stop
			Write-Log -Message "contoso.CyberArk module found: $($GetModule.Name)."
		} CATCH {
			Write-Log -Message 'Could not import CyberArk module' -Level Warn
			Set-Location -Path $StartingLocation
			$Line = $_.InvocationInfo.ScriptLineNumber
			Write-Log -Message "Error: $_"
			Write-Log -Message "Error: on line $line"
			Send-ErrorEmail -Message "Could not import CyberArk module.`nError on line $line.`nError: $_"
			THROW "Error: $_"
		}
	}
	IF ($GetModule) {
		Write-Log -Message "Installed and imported: $($GetModule.Name)"
	}
	#endregion Import CyberArk Module

	#region Import Modules
    $ModuleNames = 'ConfluencePS','PSSlack'
    $LocalSource = '' #If not in PSGallery
	foreach($ModuleName in $ModuleNames){
        $GetModule = Get-Module -Name $ModuleName -ErrorAction SilentlyContinue
	    IF (!$GetModule) {
		    Write-Log -Message "$ModuleName module not imported."
		    Install-Module -Name $ModuleName -Force -ErrorAction Stop
		    Import-Module $ModuleName -Force -Cmdlet:$false -ErrorAction Stop
		    TRY {
			    $GetModule = Get-Module -Name $ModuleName -ErrorAction Stop
			    Write-Log -Message "$ModuleName module found: $($GetModule.Name)."
		    } CATCH {
			    Write-Log -Message "Could not import $ModuleName module" -Level Warn
			    Set-Location -Path $StartingLocation
			    $Line = $_.InvocationInfo.ScriptLineNumber
			    
			    Write-Log -Message "Error: on line $line"
			    Send-ErrorEmail -Message "Could not import $ModuleName module.`nError on line $line.`nError: $_"
			    THROW "Error: $_"
		    }
	    }
	    IF ($GetModule) {
		    Write-Log -Message "Installed and imported: $($GetModule.Name)"
	    }
    }
	#endregion Import ConfluencePS Module

	Write-Log -Message " ----- BEGIN $($Global:ScriptNameFileExt) execution ----- "
}
PROCESS {
	TRY {

    Write-Log -Message "CreateTickets switch is $CreateTickets" -Level Warn
    #region Get creds and tokens before proceeding
    TRY {
		Write-Log -Message "Getting credentials for $CyberArkUserName"
		$RegularCreds = & $contosoCyberArkPath_CredMan -GetCred -Target $env:COMPUTERNAME -User "contoso\$($CyberArkUserName)"
        $RegularCreds_Confluence = & $contosoCyberArkPath_CredMan -GetCred -Target $env:COMPUTERNAME -User "$($CyberArkUserName)"
		IF(!$RegularCreds -or !$RegularCreds_Confluence){
            THROW "Credentials not found for $CyberArkUserName"
        }
        $MyCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CyberArkUserName, ($RegularCreds.Password | ConvertTo-SecureString -AsPlainText -Force)
        $MyCredential_Confluence = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CyberArkUserName, ($RegularCreds.Password | ConvertTo-SecureString -AsPlainText -Force)
		Write-Log -Message "Connecting to CyberArk for API tokens"
        contoso.CyberArk\Connect-CyberArk -Credential $MyCredential -Url 'https://cyberark.contoso.com'
		$Slack = contoso.CyberArk\Get-Account -SafeName $CyberArkSafeName -Name $CyberArkName_Slack
        $SlackToken = $Slack.Password
		$Zendesk = contoso.CyberArk\Get-Account -SafeName $CyberArkSafeName -Name $CyberArkName_ZD
        $ZDToken = $Zendesk.Password
        $ZDURL = $Zendesk.Properties.accounts.Properties | ?{$_.key -like "*address*"} | select -ExpandProperty value
        [string]$ZDSubmitEmail = $Confluence_UserName + '@contoso.com'
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ConfluenceConnect = Set-ConfluenceInfo -BaseURI 'https://wiki.contoso.com' -Credential $MyCredential_Confluence
        
		IF($SlackToken -and $SlackToken.Length -gt 10){
			Write-Log -Message "API token reteived successfully"
		}ELSEIF(!$SlackToken){
			$errormessage = "Token not found or incorrect. Cannot continue."
			Write-Log -Message $errormessage
			THROW $errormessage
		}
			
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
		THROW "Slack API Error info: $TestAPI"
	}

	# Assigning creds Don't use UPN

	$RegularCreds = & $contosoCyberArkPath_CredMan -GetCred -Target $env:COMPUTERNAME -User "contoso\$($Confluence_UserName)"
    IF(!$RegularCreds){
        THROW "Credentials not found for $Confluence_UserName"
    }
    $MyCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Confluence_UserName, ($RegularCreds.Password | ConvertTo-SecureString -AsPlainText -Force)

    #endregion Get creds and tokens before proceeding
		SWITCH ($EmergencySchedule) {
			$true {
				$ticketbody = @"
Requesting approval to release most recent windows updates to the Group(s) in the title and install in accordance with EXPEDITED schedule linked below.

Monthly Updates from Microsoft have been synchronized to the WSUS server AH-SCCM-01
Monthly Updates from Patch My PC for 3rd Party applications have been synchronized to the WSUS server AH-SCCM-01

New updates have been added to this month's Software Update Group


https://wiki.contoso.com/display/EUCENG/Out-of-Band+Patch+Schedule

**Note:**
This change is deploying an update, application, script, or baseline against the designated workstations. It is feasible, and entirely normal, for it to take 2 weeks to get reporting back that the changes have succeeded or failed for each machine. The Change Advisory Board has asked that this ticket remain Open until reporting is sufficient. Thank you!
"@
				$collaborator_ids = @(115981848292, 371641719632, 114172853931, 8776750448, 373951295331)
				Write-Log -Message "Emergency Schedule in use" -Level Warn
			}
			
			$false {
				$ticketbody = @"
Requesting approval to release most recent windows updates to the Group(s) in the title and install in accordance with schedule linked below.

Monthly Updates from Microsoft have been synchronized to the WSUS server AH-SCCM-01
Monthly Updates from Patch My PC for 3rd Party applications have been synchronized to the WSUS server AH-SCCM-01

New updates have been added to this month's Software Update Group


https://wiki.contoso.com/display/EUCENG/Windows+Updates

**Note:**
This change is deploying an update, application, script, or baseline against the designated workstations. It is feasible, and entirely normal, for it to take 2 weeks to get reporting back that the changes have succeeded or failed for each machine. The Change Advisory Board has asked that this ticket remain Open until reporting is sufficient. Thank you!
"@
				$collaborator_ids = @(115981848292, 371641719632, 114172853931)
				Write-Log -Message "Regular schedule in use."
			}
		}
		
		#
		# Getting unique datetime for file names. example: Jul102019140226
		$date = Get-Date -UFormat "%b%d%Y%H%M%S"
		# Getting most recently created SUGs
		$SUGWindows = Get-CMSoftwareUpdateGroup -Name WorkstationUpdates_Last28Days_Microsoft* | Sort-Object DateLastModified -Descending | Select-Object -First 1

		$SUG3rdparty = Get-CMSoftwareUpdateGroup -Name WorkstationUpdates_last30Days_PMP* | Sort-Object DateLastModified -Descending | Select-Object -First 1
		
		# Getting list of updates in each SUG
		$WinUpdates = Get-CMSoftwareUpdate -UpdateGroupId $SUGWindows.CI_ID -Fast
		$3rdPartyUpdates = Get-CMSoftwareUpdate -UpdateGroupId $SUG3rdparty.CI_ID -Fast
		
		Write-Log -Message "Found Windows updates SUG: $($SUGWindows.LocalizedDisplayName) with $($WinUpdates.count) updates."
		Write-Log -Message "Found Third Party updates SUG: $($SUG3rdparty.LocalizedDisplayName) with $($3rdPartyUpdates.count) updates."
		# Getting Windows patches
		$WinUpdatesFormat = @(FOREACH ($update IN $WinUpdates) {
				IF (!$update.SeverityName) {
					$Severity = "None"
				} ELSE {
					$Severity = $update.SeverityName
				}
				$ob = [PSCustomObject]@{
					Severity	 = $Severity
					"Article ID" = $update.ArticleID
					Title	     = $update.LocalizedDisplayName
					Product	     = [string]($update.LocalizedCategoryInstanceNames | Where-Object{
							$_
						})
					"Bundle Update?" = $update.IsBundle
					"Bulletin ID" = $update.BulletinID
					Required	 = $update.NumMissing
					Installed    = $update.NumPresent
					"% Complete" = [int](($update.NumNotApplicable + $update.NumPresent) / $update.NumTotal * 100)
					Downloaded   = 'Yes'
					Deployed	 = 'Yes'
					Vendor	     = 'Microsoft'
					Notes	     = $update.LocalizedInformativeURL
				}
				$ob
			})
		# Getting 3rd party patches
		$3rdPartyUpdatesFormat = @(FOREACH ($update IN $3rdPartyUpdates) {
				IF (!$update.SeverityName) {
					$Severity = "None"
				} ELSE {
					$Severity = $update.SeverityName
				}
				$ob = [PSCustomObject]@{
					Severity	 = $Severity
					"Article ID" = $update.ArticleID
					Title	     = $update.LocalizedDisplayName
					Product	     = [string]($update.LocalizedCategoryInstanceNames | Where-Object{
							$_
						})
					"Bundle Update?" = $update.IsBundle
					"Bulletin ID" = $update.BulletinID
					Required	 = $update.NumMissing
					Installed    = $update.NumPresent
					"% Complete" = [int](($update.NumNotApplicable + $update.NumPresent) / $update.NumTotal * 100)
					Downloaded   = 'Yes'
					Deployed	 = 'Yes'
					Vendor	     = 'Patch My PC'
					Notes	     = $update.LocalizedInformativeURL
				}
				$ob
			})
		# Change locations in order to access the Kirk share
		Set-Location $HOME
		# Export csv files with unique datetime file name
		$WinUpdatesCSVpath = "\\kirk\IT\EUC-ENG\Updates\WinUpdatesFormat-$date.csv"
		$3rdPartyUpdatesCSVpath = "\\kirk\IT\EUC-ENG\Updates\3rdPartyUpdatesFormat-$date.csv"
		$WinUpdatesFormat | Export-csv -LiteralPath $WinUpdatesCSVpath -NoTypeInformation
		$3rdPartyUpdatesFormat | Export-csv -LiteralPath $3rdPartyUpdatesCSVpath -NoTypeInformation
		Write-Log -Message "Exported CSV to $WinUpdatesCSVpath"
		Write-Log -Message "Exported CSV to $3rdPartyUpdatesCSVpath"
		#
		### Start Section - Requires ConfluencePS Module ###
		

		

		#
		Write-Log -Message "Importing CSV Files to variable"
		$windowsupdates = Import-csv -LiteralPath $WinUpdatesCSVpath
		$3rdPartyUpdates = Import-csv -LiteralPath $3rdPartyUpdatesCSVPath
		# Get unique Update Counts
		$UniqueWinArticles = ($WinUpdatesFormat.'Article ID' | select -Unique).count
		$Unique3rdPartyArticles = ($3rdPartyUpdatesFormat.'Article ID' | Select-Object -Unique).count
		$UniqueArticlesTotal = $Unique3rdPartyArticles + $UniqueWinArticles
		$TotalUpdateCount = $WinUpdates.count + $3rdPartyUpdates.count
		Write-Log -Message "Total Updates: $TotalUpdateCount | Microsoft: $($WinUpdates.count) | Third Party: $($3rdPartyUpdates.count)"
		Write-Log -Message "Total Unique Article IDs: $UniqueArticlesTotal | Microsoft: $UniqueArticlesTotal | Third Party: $Unique3rdPartyArticles"

		#
		$conftable = "Total Count: Unique Articles: $UniqueArticlesTotal

Microsoft Patches (Count: $($WinUpdates.count), Unique: $UniqueWinArticles)
"
		$conftable += $windowsupdates | ConvertTo-ConfluenceTable
		$conftable += "

3rd Party Patches (Count: $($3rdPartyUpdates.count), Unique: $Unique3rdPartyArticles)
"
		$conftable += $3rdPartyUpdates | ConvertTo-ConfluenceTable
		#
		$Basedate = Get-Date -Day 12
        IF($CreateTickets){
		    New-ConfluencePage -SpaceKey EUCENG -ParentID 46478898 -Title "$($Basedate.year) $($Basedate | Get-Date -UFormat %m) - Workstation Patches" -Body $conftable -Convert -OutVariable conflvar
		    Write-Log -Message "Confluence page created. URL:$($conflvar.URL)"
        }ELSE{
            Write-Log -Message "Confluence page creation SKIPPED with Title $($Basedate.year) $($Basedate | Get-Date -UFormat %m) - Workstation Patches" -Level Warn
        }
		#


		#Change Control 2.0 > 360000283152
		
		$Username = $ZDSubmitEmail + '/token'
		$Token = $ZDToken
		$URL = 'https://contoso.zendesk.com/api/v2'
		
		
		#
		$creds = @{
			Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Username):$($Token)"))
		}
		#
		FOR ($i = 2; $i -le 9; $i++) {
			# Getting Patch Tuesday
			#$Basedate = Get-Date -Day 12
			$Month = Get-date -UFormat %B
			$Month2Digits = Get-Date -UFormat %m
			SWITCH ($Basedate.DayOfWeek) {
				"Sunday" {
					$PatchTuesday = $BaseDate.AddDays(2)
				}
				"Monday" {
					$PatchTuesday = $BaseDate.AddDays(1)
				}
				"Tuesday" {
					$PatchTuesday = $BaseDate
				}
				"Wednesday" {
					$PatchTuesday = $BaseDate.AddDays(-1)
				}
				"Thursday" {
					$PatchTuesday = $BaseDate.AddDays(-2)
				}
				"Friday" {
					$PatchTuesday = $BaseDate.AddDays(-3)
				}
				"Saturday" {
					$PatchTuesday = $BaseDate.AddDays(-4)
				}
			}
			#
			$Year = $PatchTuesday.Year.ToString()
			SWITCH ($EmergencySchedule) {
				$true { <# Expedited schedule https://wiki.contoso.com/display/EUCENG/Out-of-Band+Patch+Schedule #>
					SWITCH ($i) {
						2 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(3) -UFormat %Y-%m-%d
						}
						3 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(6) -UFormat %Y-%m-%d
						}
						4 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(8) -UFormat %Y-%m-%d
						}
						5 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(10) -UFormat %Y-%m-%d
						}
						6 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(13) -UFormat %Y-%m-%d
						}
						7 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(15) -UFormat %Y-%m-%d
						}
						8 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(16) -UFormat %Y-%m-%d
						}
						9 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(17) -UFormat %Y-%m-%d
						}
					}
				}
				$false { <# Regular schedule https://wiki.contoso.com/display/EUCENG/Windows+Updates#WindowsUpdates-ScheduleTables #>
					SWITCH ($i) {
						2 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(6) -UFormat %Y-%m-%d
						}
						3 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(7) -UFormat %Y-%m-%d
						}
						4 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(13) -UFormat %Y-%m-%d
						}
						5 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(15) -UFormat %Y-%m-%d
						}
						6 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(20) -UFormat %Y-%m-%d
						}
						7 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(22) -UFormat %Y-%m-%d
						}
						8 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(23) -UFormat %Y-%m-%d
						}
						9 {
							$deployDate = Get-Date -Date $Patchtuesday.AddDays(24) -UFormat %Y-%m-%d
						}
					}
				}
			}
			
			#
			$body = [PSCustomObject]@{
				ticket = [PSCustomObject]@{
					subject = "Microsoft Updates - Workstations - $Month $Year | Group $i"
					comment = [PSCustomObject]@{
						body = $ticketbody
					}
					ticket_form_id = 389788
					collaborator_ids = $collaborator_ids
					
					fields  = [PSCustomObject]@{
						114094622752 = '1'
						31247267 = 'https://wiki.contoso.com/display/EUCENG/Windows+Updates#WindowsUpdates-RollbackPlan'
						33025407 = "$($conflvar.url)"
						30330248 = 'cc_risk_medium'
						31213927 = 'N/A'
						42880248 = 'https://wiki.contoso.com/display/EUCENG/Windows+Updates#WindowsUpdates-ValidationandMonitoring'
						33025387 = 'N/A'
						32282328 = 'N/A'
						45903487 = 'cc_risk_calc_field1_5points'
						45806028 = 'cc_risk_calc_field2_0points'
						45904827 = 'cc_risk_calc_field3_1points'
						45904987 = 'cc_risk_calc_field4_2points'
						45807548 = 'cc_risk_calc_field5_1points'
						114094622772 = 'cc_int_time_0800'
						114094638271 = "$deployDate"
						114094071531 = 'N/A'
						360018173212 = 'cc_type_workstation_windows_updates'
						360014094751 = 'cc_complete-method_na'
					}
				}
			} | ConvertTo-Json
			#
			IF($CreateTickets){
                $CcTicket = Invoke-RestMethod -Uri "$URL/tickets.json" -Method POST -Headers $creds -ContentType "application/json" -Body $body
			    Write-Log -Message "Zendesk ticket [$($CcTicket.ticket.id)] created with Subject [$($CcTicket.ticket.subject)] and Deployment Date [$deployDate]"
			    # Waiting for ticket to be created
			    Start-Sleep -Seconds 7
            }ELSE{
                Write-Log -Message "Zendesk ticket creation SKIPPED with Subject [$($body.ticket.subject)] and Deployment Date [$deployDate]" -Level Warn
            }
			# Clean-Up
			Clear-Variable CcTicket, body, deployDate -ErrorAction SilentlyContinue
		}
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		"Error was in Line $line"
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
	}
}
END {
	Write-Log -Message " ----- END $($Global:ScriptNameFileExt) execution ----- "
}

