$Baseline = 'Windows_Updates'
$ThawedCollections = Get-CMDeviceCollection -Name "ZeroDayUpdates_thawed*"
$ThawedCollections | foreach{
    New-CMBaselineDeployment -Name $Baseline -CollectionName $_.Name -EnableEnforcement $true
}
$FREEZECollections = Get-CMDeviceCollection -Name "ZeroDayUpdates_FREEZE*"
$FREEZECollections | foreach{
    New-CMBaselineDeployment -Name $Baseline -CollectionName $_.Name -EnableEnforcement $false
}

#Set-CMBaselineDeployment -BaselineName windows_updates -CollectionName 'ZeroDayUpdates_thawed_Group01_AutoDL-PreTesting' -EnableEnforcement $true