
$RollupCollections = Get-CMCollection -Name "WindowsUpdates_Rollup_*"
#$RollupSUGS = Get-CMSoftwareUpdateGroup -Name "* FY Rollup - *"
$RollupSUGS = Get-CMSoftwareUpdateGroup -Name "2014 FY Rollup - Windows 8.1"
$StartDate = 'January 11, 2019 08:00' | Get-Date
$DeadlineDate = 'January 11, 2019 14:00' | Get-Date
$DeploymentsCreated = @()
$DeploymentsModified = @()


foreach($SUG in $RollupSUGS){
    $SUGYear = $($SUG.LocalizedDisplayName).substring(0,4)
    $SUGProduct = ($($SUG.LocalizedDisplayName).split('-')[1]).trim() -replace ' ',''
    foreach($Collection in $RollupCollections){
        $CollProd = ($Collection.Name -split '_')[2]
        $Collyear = ($Collection.Name -split '_')[3] -replace 'FY',''
        IF([string]$SUGYear -eq [string]$Collyear -and [string]$SUGProduct -eq [string]$CollProd){
            "Match"
            $Schedule = @{
                "SoftwareUpdateGroupName" = $($SUG.LocalizedDisplayName)
                "AllowRestart" = $true
                "AllowUseMeteredNetwork" = $true
                "AvailableDateTime" = 'January 11, 2019 08:00' 
                "CollectionName" = $Collection.Name
                "DeploymentName" = "$($SUG.LocalizedDisplayName)_Deployment"
                "DeploymentType" = 'Required'
                "Description" = "All 2013 updates for Office 2013 - $GroupNumber"
                "DisableOperationsManagerAlert" = $true
                "DownloadFromMicrosoftUpdate" = $false
                "Enable" = $false
                "RequirePostRebootFullScan" = $true
                "RestartServer" = $false
                "RestartWorkstation" = $true
                "SendWakeupPacket" = $false
                "SoftwareInstallation" = $true <#install ouside Maint window#> 
                "TimeBasedOn" = 'LocalTime'
                "UserNotification" = 'DisplaySoftwareCenterOnly'
                "VerbosityLevel" = 'OnlyErrorMessages'
                "WhatIf" = $true
            }
            $Schedule.GetEnumerator() | sort-object name

            #Set-CMSoftwareUpdateDeployment @Schedule
            IF(Get-CMSoftwareUpdateDeployment -Name "$($SUG.LocalizedDisplayName)" -ErrorAction SilentlyContinue){
                $Deployment = New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName "$($SUG.LocalizedDisplayName)" `
                -AllowRestart $true `
                -AvailableDateTime 'January 11, 2019 08:00' `
                -CollectionName "$($Collection.Name)" `
                -DeploymentName "$($SUG.LocalizedDisplayName)_Deployment" `
                -DeploymentType 'Required' `
                -Description "All 2013 updates for Office 2013 - $GroupNumber" `
                -DisableOperationsManagerAlert $true `
                -DownloadFromMicrosoftUpdate $false `
                -RequirePostRebootFullScan $true `
                -RestartServer $false `
                -RestartWorkstation $true `
                -SendWakeupPacket $false `
                -SoftwareInstallation $true <#install ouside Maint window#>  `
                -TimeBasedOn 'LocalTime' `
                -UserNotification 'DisplaySoftwareCenterOnly' `
                -VerbosityLevel 'OnlyErrorMessages' `
                -WhatIf -Verbose
                $DeploymentsCreated += $Deployment
            }ELSE{
                $DeploymentsModified += $Deployment
            }
            #$Deployment | Set-CMSoftwareUpdateDeployment -Enable $false -DeploymentExpireDateTime 'January 11, 2019 14:00' -WhatIf
        }
    }
}