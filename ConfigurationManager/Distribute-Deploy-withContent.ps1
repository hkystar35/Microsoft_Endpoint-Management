#region Set SCCM cmdlet location
TRY {
	$StartingLocation = Get-Location
	Import-Module -Name $env:SMS_ADMIN_UI_PATH.Replace('\bin\i386', '\bin\ConfigurationManager.psd1')
	#Write-Log -Message "Changing location to $($SiteCode.Name):\"
	$SiteCode = Get-PSDrive -PSProvider CMSITE
	Set-Location -Path "$($SiteCode.Name):\"
	#Write-Log -Message "done."
} CATCH {
	#Write-Log -Message 'Could not import SCCM module' -Level Warn
	Set-Location -Path $StartingLocation
	$Line = $_.InvocationInfo.ScriptLineNumber
	#Write-Log -Message "Error: $_"
	#Write-Log -Message "Error: on line $line"
	Send-ErrorEmail -Message "Could not import SCCM module.`nError on line $line.`nError: $_"
	BREAK
}
#endregion Set SCCM cmdlet location

# prompt for name
[string]$AppInput = Read-Host -Prompt "`nApp Name? (Uses wildcard search)"

# find apps matching search, filter expired/retired
$CMAppNames = Get-CMApplication -Name "*$AppInput*" -Fast | Where-Object {
	$_.IsExpired -eq $false
} | Select-Object LocalizedDisplayName, SoftwareVersion, IsEnabled, IsExpired, PackageID, ModelName

#$appLocalLink
#ModelName                          : ScopeId_43D1A905-8317-46D2-92F2-77786D454A8A/Application_b8992b41-4ce6-43af-abec-1f9ecdfc128e
#CI_UniqueID                        : ScopeId_43D1A905-8317-46D2-92F2-77786D454A8A/Application_b8992b41-4ce6-43af-abec-1f9ecdfc128e/2
# softwarecenter:SoftwareID=ScopeId_43D1A905-8317-46D2-92F2-77786D454A8A/Application_b8992b41-4ce6-43af-abec-1f9ecdfc128e

IF (!$CMAppNames) {
	Write-Host "`nNo results. Re-run script" -foregroundColor Yellow
	BREAK
}
# new psobject with choices for prompt
$i = 0
$Choices = @()
$CMAppNames | ForEach-Object{
	$i = $i + 1
	$Choices += New-Object -TypeName 'PSObject' -Property @{
		Choice = $i
		Name   = $($_.LocalizedDisplayName)
		Version = $($_.SoftwareVersion)
		PackageID = $($_.PackageID)
		AppLink = 'softwarecenter:SoftwareID=' + $($_.ModelName)
	}
}
Write-Host ""
$Choices | ForEach-Object{
	Write-Host "$($_.Choice) - $($_.Name) ($($_.Version) - PkgID=$($_.PackageID)) (Link: $($_.Applink))"
}


DO {
	write-host -NoNewline "`nType your choice and press Enter: "
	
	$choice = read-host
	
	$ok = $choice -match '^[0-9]+$'
	
	IF (-not $ok) {
		write-host "Invalid selection"
	}
} UNTIL ($ok)
$Choice = $Choices | Where-Object {
	$_.Choice -eq $Choice
}

$DeploymentTarget = Read-Host "`n1 EUC Testing`n2 All Users`n3 All Workstations`n4 All Workstations HelpDesk`nDeploy to"
SWITCH ($DeploymentTarget) {
	1{
		$CollectionNames = 'U.EUC.Test Applications.Analysts', 'U.EUC.Test Applications.Leadership'
	}
	2{
		$CollectionNames = 'All Users and User Groups'
	}
	3{
		$CollectionNames = 'All Windows Workstations'
	}
	4{
		$CollectionNames = 'All Windows Workstations_HelpDesk'
	}
}

$DistroGroup = Get-CMDistributionPointGroup | Select-Object Name, Description
$DistroGroup | ForEach-Object{
	Write-Host "Distributing $($Choice.name) content to $($_.Name) ..." -NoNewline
	Start-CMContentDistribution -ApplicationName "$($Choice.name)" -DistributionPointGroupName $_.Name
	Write-Host " done!"
}

$CollectionNames | ForEach-Object{
	Write-Host "Deploying $($Choice.name) to collection $_ ..." -NoNewline
	New-CMApplicationDeployment -CollectionName "$_" -Name "$($Choice.name)" -ApprovalRequired $False -DeployAction Install -DeployPurpose Available -UserNotification DisplaySoftwareCenterOnly
	Write-Host " done!"
}

# Email Data   
$CC = "EUCEngineers@contoso.com"
$To = "EUC@contoso.com"
$From = 'hkystar35@contoso.com'
$SMTP = 'post.contoso.com'
$Subject = "New App Testing - $($Choice.name)"

IF ($DeploymentTarget -eq 1) {
	$Email = Read-Host -Prompt "Send Email to EUC? Y/N"
	$JIRA = Read-Host -Prompt "Create JIRA cards for EUC? Y/N"
	IF ($Email -eq 'y') {
		$Notes = Read-Host -Prompt "Notes"
		$Begin = @"
<p><span style="font-family: times new roman, times; font-size: 10pt;">All,</span></p>
<p><span style="font-family: times new roman, times; font-size: 10pt;">Please go to the <a title="Software Center" href="$($choice.AppLink)" target="_blank">Software Center</a> and install this application and report back.</span></p>
<p><span style="font-family: times new roman, times; font-size: 10pt;"><strong>Name:</strong> $($Choice.name)<br /></span></p>
<p><span style="font-family: times new roman, times; font-size: 10pt;"><strong>Version:</strong> $($Choice.version)<br /></span></p>
<p><span style="font-family: times new roman, times; font-size: 10pt;"><strong>Deployed To:</strong> EUC Analysts, Admins, TLs, Engineers only</span></p>
<p><span style="font-family: times new roman, times; font-size: 10pt;"><strong>Expected Behavior:</strong> Will prompt to close existing processes before installing, if detected.<br /></span></p>
"@
		
		$End = @"
<p><span style="font-family: times new roman, times;">Thank you!</span></p>
<p><span style="font-size: 10pt; font-family: times new roman, times;">____________________________</span></p>
<p><span style="font-family: times new roman, times;"><span style="font-size: 10pt;"><strong>Nic hkystar35</strong> | End User Computing Engineer</span></span></p>
<p><span style="font-family: times new roman, times; font-size: 10pt;">contoso | <a href="mailto:hkystar35@contoso.com"><span style="color: #0563c1;">hkystar35@contoso.com</span></a></span></p>
<p><span style="font-family: times new roman, times; font-size: 10pt;"><strong>C: 208.972.1757</strong> | EUC: 888-729-5624 (4526 &ndash;internal)</span></p>
<p><span style="font-family: times new roman, times; font-size: 10pt;"><a href="mailto:askeuc@contoso.com"><span style="color: #0563c1;">askeuc@contoso.com</span></a></span></p>
<p><span style="font-family: times new roman, times; font-size: 10pt;"><a href="https://employee.contoso.com"><span style="color: #0563c1;">EUC Self-Help</span></a></span></p>
"@
		
		$BodyEUC = $Begin
		IF ($Notes -ne $null -and $Notes) {
			$BodyNotes = @"
<p><span style="font-family: times new roman, times;"><strong><span style="font-size: 10pt;">Notes:</span></strong></span></p>
<p><span style="font-family: times new roman, times; font-size: 10pt;">$($Notes)</span></p>
<p>&nbsp;</p>
"@
			$BodyEUC += $BodyNotes
		}
		$BodyEUC += $End
		Send-MailMessage -Body $BodyEUC -Cc $CC -From $From -SmtpServer $SMTP -Subject $Subject -To $To -Bcc $From -BodyAsHtml
	}
	IF ($JIRA -eq 'y') {
		#region Create JIRA cards
		Install-Module JIRAPS -Force
		Import-Module jiraPS -Force
		Set-JiraConfigServer -Server 'https://jira.contoso.com'
		$MyCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "nhkystar35", ((E:\git\_contoso\contoso.cyberark\Source\CredMan.ps1 -GetCred -Target $env:COMPUTERNAME -User 'contoso\nhkystar35').password | ConvertTo-SecureString -AsPlainText -Force)
		New-JiraSession -Credential $MyCredential
		
		$AllEUCAnalysts = Get-ADGroupMember "EUC Analysts" | ForEach-Object{
			Get-ADUser $_.SamAccountName -Properties * | Select-Object samaccountname, EmailAddress
		}
		$AllEUCAdmins = Get-ADGroupMember "EUC Admins" | ForEach-Object{
			Get-ADUser $_.SamAccountName -Properties * | Select-Object samaccountname, EmailAddress
		}
		$AllEUCLeadership = Get-ADGroupMember "EUC Leadership" | ForEach-Object{
			Get-ADUser $_.SamAccountName -Properties * | Select-Object samaccountname, EmailAddress
		}
		
		$Project = Get-JiraProject -Project "END"
		#$Project = Get-JiraProject -Project "EUCENG"
		#$JIRAissues = Get-JiraIssue -Query "Project = $($Project.Key) AND Status != Done"
		
		#$JIRAissues | select -First 1 | ft
		
		$Priority = 'Medium'
		SWITCH ($Priority) {
			Highest {
				$PriorityLevel = 1
			}
			High {
				$PriorityLevel = 2
			}
			Medium {
				$PriorityLevel = 3
			}
			Low {
				$PriorityLevel = 4
			}
			Lowest {
				$PriorityLevel = 5
			}
			default {
				$PriorityLevel = 3
			}
		}
		$reporter = 'nhkystar35'
		$AllCards = @()
		FOREACH ($User IN $AllEUCAnalysts) {
			$IssueHashTable = @{
				Project = $Project.Key
				IssueType = "Story"
				Summary = "New or Updated Application - Test installation of $($Choice.Name) $($Choice.Version)"
				Priority = $PriorityLevel
				Description = @"
Please go to the Software Center and install this application and report back.

Name: $($Choice.Name)
Version: $(IF(!$Choice.Version){"n/a"})

Expected Behavior: Will prompt to close existing processes before installing, if detected.

Notes:
$Notes

"@
				#Reporter = $reporter
				Labels  = "EUCENG_SCCM_Application_MAC_Test"
				#Parent = ""
			}
			New-JiraIssue @IssueHashTable -OutVariable NewCard
			$NewCard | Set-JiraIssue -Assignee $User.samaccountname
			$AllCards += $NewCard
		}
		#endregion Create JIRA cards
	}
}
