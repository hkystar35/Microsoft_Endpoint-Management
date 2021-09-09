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

$ApplicationName = Read-Host -Prompt "App name"
$CollectionName = $false

$CMApplication = Get-CMApplication -Name "$($ApplicationName)*" -Fast | sort -Descending DateCreated | select -First 1

IF($CollectionName){
    $Collection = Get-CMCollection -Name "$($CollectionName)"
    $Deployments = Get-CMDeployment -CollectionName $Collection.Name | ?{$_.SoftwareName -eq $CMApplication.LocalizedDisplayName}
}ELSE{
    $Deployments = Get-CMDeployment | ?{$_.SoftwareName -eq $CMApplication.LocalizedDisplayName}
}

$Gridview = $Deployments | select @{L="Deployment Name";E={$_.SoftwareName}},
    @{L="Collection Name";E={$_.CollectionName}},
    @{L="Collection ID";E={$_.CollectionID}},AssignmentID,
    NumberTargeted,NumberSuccess,NumberInProgress,NumberErrors,NumberOther,NumberUnknown,
    @{L="Percent Success";E={($_.NumberSuccess/($_.NumberTargeted - $_.NumberUnknown)).ToString("P")}},
    @{L="Percent InProgress";E={($_.NumberInProgress/($_.NumberTargeted - $_.NumberUnknown)).ToString("P")}},
    @{L="Percent Errors";E={($_.NumberErrors/($_.NumberTargeted - $_.NumberUnknown)).ToString("P")}},
    @{L="Percent Other";E={($_.NumberOther/($_.NumberTargeted - $_.NumberUnknown)).ToString("P")}},
    @{L="Percent Unknown";E={($_.NumberUnknown/($_.NumberTargeted - $_.NumberUnknown)).ToString("P")}},
    EnforcementDeadline | Sort-Object EnforcementDeadline,"Deployment Name",CollectionName
        

$Gridview | Sort-Object -Property EnforcementDeadline | Out-GridView -Title $CMApplication.LocalizedDisplayName
# Columns
# SoftwareName,CollectionName,NumberTargeted,NumberSuccess,NumberInProgress,NumberErrors,NumberOther,NumberUnknown,"Percent Success","Percent InProgress","Percent Errors","Percent Other","Percent Unknown","Group Name","Group Number"
