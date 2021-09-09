$SearchTerm = Read-Host -Prompt "App name"
$appnames = Get-CMApplication -Name "$SearchTerm*"
    Foreach($appname in $appnames){
        $DTNames = Get-CMDeploymentType -ApplicationName "$($appname.LocalizedDisplayName)"
        $DTNames | foreach{Update-CMDistributionPoint -ApplicationName $($appname.LocalizedDisplayName) -DeploymentTypeName $($_.LocalizedDisplayName)}
    }