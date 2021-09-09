$MeltdownSUG = 'Meltdown Patches - 2018-01-04'
$Description = 'Meltdown OS patches for Windows 8.1 and 10. See ticket https://paylocity.zendesk.com/agent/tickets/74849 for more.'
$ThawedCollections = Get-CMDeviceCollection -Name "ZeroDayUpdates_*"
$ThawedCollections | foreach{
    $NameSplit = $_.Name -split ('_')
    $GroupNumber = $NameSplit[2]
  
  switch($GroupNumber){
    Group01{$AvailDate = '1/18/2018 08:00:00 AM';$DeadlineDate = '1/18/2018 02:00:00 PM'}
    Group02{$AvailDate = '1/19/2018 08:00:00 AM';$DeadlineDate = '1/19/2018 02:00:00 PM'}
    Group03{$AvailDate = '1/22/2018 08:00:00 AM';$DeadlineDate = '1/22/2018 02:00:00 PM'}
    Group04{$AvailDate = '1/24/2018 08:00:00 AM';$DeadlineDate = '1/24/2018 02:00:00 PM'}
    Group05{$AvailDate = '1/26/2018 08:00:00 AM';$DeadlineDate = '1/26/2018 02:00:00 PM'}
    Group06{$AvailDate = '1/29/2018 08:00:00 AM';$DeadlineDate = '1/29/2018 02:00:00 PM'}
    Group07{$AvailDate = '1/31/2018 08:00:00 AM';$DeadlineDate = '1/31/2018 02:00:00 PM'}
    Group08{$AvailDate = '2/02/2018 08:00:00 AM';$DeadlineDate = '2/02/2018 02:00:00 PM'}
    Group09{$AvailDate = '2/02/2018 08:00:00 AM';$DeadlineDate = '2/02/2018 02:00:00 PM'}
    }
    Write-host 'Name: ' $_.Name
    Write-host ' Number: ' $GroupNumber
    Write-Host '  AvailDate: ' $AvailDate
    Write-Host '  DeadlineDate: ' $DeadlineDate
    New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $MeltdownSUG -CollectionName $($_.Name) -DeploymentName "$MeltdownSUG $($_.Name)" -Description "$Description" -DeploymentType Required -TimeBasedOn LocalTime -UserNotification DisplaySoftwareCenterOnly -AllowRestart $true -RestartServer $false -RequirePostRebootFullScan $true -AvailableDateTime $AvailDate -DeadlineDateTime $DeadlineDate
    if($GroupNumber -ne 'Group01'){
        Set-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName $MeltdownSUG -CollectionName $($_.Name) -Enable $false
    }
}