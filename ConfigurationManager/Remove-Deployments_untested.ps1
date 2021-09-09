$CollectionName = 'EUC.Test Applications.Leadership'
$EUCADeployments = Get-CMDeployment -CollectionName $CollectionName
Write-Host "Count of deployments: $($EUCADeployments.count) BEFORE"
$RemoveCount = 0
foreach($EUCADeployment in $EUCADeployments){
    IF(Get-CMDeployment -SoftwareName $EUCADeployment.ApplicationName | where {($_.CollectionID -eq 'SMS00002') -or ($_.CollectionID -eq 'SMS00004') -or ($_.CollectionID -eq 'PAY0024C')} | select -Property ApplicationName,CollectionID,CollectionName){
        $RemoveCount += 1
        $RemoveDeployment = Remove-CMDeployment -DeploymentId $EUCADeployment.DeploymentID -ApplicationName $EUCADeployment.ApplicationName -Force
    
        Write-Host "Removing $($EUCADeployment.ApplicationName) from collection $($EUCADeployment.CollectionName)"

    }
}
Write-Host "Count of deployments removed: $RemoveCount"
$EUCADeploymentsafter = Get-CMDeployment -CollectionName $CollectionName
Write-Host "Count of deployments: $($EUCADeploymentsafter.count) AFTER"
#$RemoveDeployment = Remove-CMDeployment -DeploymentId $EUCADeployments[1].DeploymentID -ApplicationName $EUCADeployments[1].ApplicationName -ErrorAction SilentlyContinue