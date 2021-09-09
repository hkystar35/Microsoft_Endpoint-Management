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

$Date = (Get-Date) #.AddMonths(-1)
$SearchString = @()
$SearchString += $Date | Get-Date -Format 'yyyy-MM'
$SearchString += $Date.AddMonths(-1) | Get-Date -Format 'yyyy-MM'

Measure-Command {
    $CMDeployments = @(foreach($string in $SearchString){Get-CMDeployment -FeatureType SoftwareUpdate | ?{$_.SoftwareName -like "WorkstationUpdates_Last*$($String)*"}})
    $Deployments = @(
        $CMDeployments | %{
            New-Object -TypeName psobject -Property @{
                #"Deployment Name" = {$n = $_.SoftwareName -split (' ',2);(($n[0].Split('_'))[$n[0].Split('_').count -1]) + ' - ' + ([datetime]$n[1] | Get-Date -Format 'yyyy-MM')}
                "Deployment Name" = (($($_.SoftwareName -split (' ',2))[0].Split('_'))[$($_.SoftwareName -split (' ',2))[0].Split('_').count -1]) + ' - ' + ([datetime]$($_.SoftwareName -split (' ',2))[1] | Get-Date -Format 'yyyy-MM')
                "Group Name" = Get-CMCollection -Id $_.CollectionID -ErrorAction SilentlyContinue | select -ExpandProperty comment -ErrorAction SilentlyContinue
                "Group Number" = ($_.CollectionName.split('_'))[$_.CollectionName.split('_').count -1]
                "NumberTargeted" = $_.NumberTargeted
                "NumberSuccess" = $_.NumberSuccess
                "NumberInProgress" = $_.NumberInProgress
                "NumberErrors" = $_.NumberErrors
                "NumberOther" = $_.NumberOther
                "NumberUnknown" = $_.NumberUnknown
                "Percent Success" = ($_.NumberSuccess/($_.NumberTargeted - $_.NumberUnknown)).ToString("P")
                "Percent InProgress" = ($_.NumberInProgress/($_.NumberTargeted - $_.NumberUnknown)).ToString("P")
                "Percent Errors" = ($_.NumberErrors/($_.NumberTargeted - $_.NumberUnknown)).ToString("P")
                "Percent Other" = ($_.NumberOther/($_.NumberTargeted - $_.NumberUnknown)).ToString("P")
                "Percent Unknown" = ($_.NumberUnknown/($_.NumberTargeted - $_.NumberUnknown)).ToString("P")
                "EnforcementDeadline" = $_.EnforcementDeadline
            }
        }
    )
    
} -OutVariable TimeTaken


$Deployments | Select-Object `
"Deployment Name",`
"Group Name",`
"Group Number",`
"NumberTargeted",`
"NumberSuccess",`
"NumberInProgress",`
"NumberErrors",`
"NumberOther",`
"NumberUnknown",`
"Percent Success",`
"Percent InProgress",`
"Percent Errors",`
"Percent Other",`
"Percent Unknown",`
"EnforcementDeadline" `
 | Sort-Object -Property EnforcementDeadline | Out-GridView -Title "Monthly Updates"

'Time to complete: Hours: {0}, Minutes: {1}, Seconds: {3}, Milliseconds: {3}' -f $betterloop.Hours,$betterloop.Minutes,$betterloop.Seconds,$betterloop.Milliseconds

Remove-Variable date,SearchString,Deployments,String,CMDeployment,Gridview -ErrorAction SilentlyContinue -Force