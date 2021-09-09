$Collections = "DAF.Biscom.Phase1,10/2/2018 14:00,10/4/2018 14:00",
"DAF.Biscom.Phase2,10/5/2018 14:00,10/7/2018 14:00",
"DAF.Biscom.Phase3,10/16/2018 14:00,10/18/2018 14:00",
"DAF.Biscom.Phase4,10/19/2018 14:00,10/21/2018 14:00"

$AppName = 'Biscom SFT Outlook Add-In'

$Collections | foreach{
    $CollectionName = $($_ -split ',')[0]
    $AvailDate = [string]$($_ -split ',')[1] | Get-Date
    $DeadlineDate = [string]$($_ -split ',')[2] | Get-Date
    
    $Comment = "Deploying Biscom to all machines needing an upgrade or are missing it altogether. Deadline is on $DeadlineDate."
    Get-CMApplicationDeployment -CollectionName $CollectionName | Remove-CMApplicationDeployment -Force
    New-CMApplicationDeployment -Name $AppName -CollectionName $CollectionName -Comment $Comment -AvailableDateTime $AvailDate -DeadlineDateTime $DeadlineDate -DeployAction Install -DeployPurpose Required -OverrideServiceWindow $true -PreDeploy $true -TimeBaseOn LocalTime -UserNotification DisplaySoftwareCenterOnly
    #Remove-CMTaskSequenceDeployment -CollectionName $CollectionName -TaskSequenceId $TSID -Force
}




