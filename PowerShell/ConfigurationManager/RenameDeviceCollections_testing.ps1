$DeviceCollections = Get-CMCollection

$DeviceCollections | foreach{
    #if(!($_.Name.startswith("DAO.")) -or !($_.Name.startswith("All Windows")) -or !($_.Name.startswith("Windows")) -or !($_.Name.startswith("Mac"))){
    if($_.Name.startswith("ALL")){
        $Deployments = Get-CMDeployment -CollectionName $_.Name
        Write-Host "Collection: "$_.Name""
        if($Deployments.Count -gt 0){
            foreach($Deployment in $Deployments){
                $FeatureType = $Deployment.FeatureType
                    Switch ($FeatureType){1{$FeatureType = "Application"} 2{$FeatureType = "Package"} 5{$FeatureType = "SoftwareUpdate"} 6{$FeatureType = "Baseline"} 7{$FeatureType = "TaskSequence"}}
                 $CollType = $_.CollectionType
                    Switch ($CollType){1{$CollType = "User"} 2{$CollType = "Device"}}
                $Action = $Deployment.DesiredConfigType
                    Switch ($Action){1{$Action = "Add"} 2{$Action = "Remove"}}
                $Purpose = $Deployment.DeploymentIntent
                    Switch ($Purpose){1{$Purpose = "Forced"} 2{$Purpose = "Optional"}}
        
                Write-Host "     Software: "$Deployment.ApplicationName" `n        FeatureType: $FeatureType`n        CollType: $CollType`n        ConfigType: $Action`n        Intent: $Purpose"
                if(($CollType -eq "User") -and ($Action -eq "Add") -and ($Purpose -eq "Forced")){$Prefix = "UAF"}
                if(($CollType -eq "User") -and ($Action -eq "Add") -and ($Purpose -eq "Optional")){$Prefix = "UAO"}
                if(($CollType -eq "User") -and ($Action -eq "Remove") -and ($Purpose -eq "Forced")){$Prefix = "URF"}
                if(($CollType -eq "User") -and ($Action -eq "Remove") -and ($Purpose -eq "Optional")){$Prefix = "URO"}
                if(($CollType -eq "Device") -and ($Action -eq "Add") -and ($Purpose -eq "Forced")){$Prefix = "DAF"}
                if(($CollType -eq "Device") -and ($Action -eq "Add") -and ($Purpose -eq "Optional")){$Prefix = "DAO"}
                if(($CollType -eq "Device") -and ($Action -eq "Remove") -and ($Purpose -eq "Forced")){$Prefix = "DRF"}
                if(($CollType -eq "Device") -and ($Action -eq "Remove") -and ($Purpose -eq "Optional")){$Prefix = "DRO"}

            $NewName = $Prefix + "." + $_.name
            Write-Host "New Name: $NewName"
            Set-CMCollection -Name $_.name -NewName $NewName -Whatif
        }
        }
    }

}