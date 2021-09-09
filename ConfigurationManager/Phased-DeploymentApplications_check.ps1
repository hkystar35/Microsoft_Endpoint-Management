<#
$CollMembers = Get-CMCollectionMember -CollectionName 'DAF.Biscom' | select -Property Name
$Results = @()
foreach($CollMember in $CollMembers){
    $Results += Get-ADComputer $CollMember.Name | select -Property Name,@{N="distinguishedname";E={$_.distinguishedname -replace "CN=$($_.name),",''}}
}
$Results  | Sort-Object distinguishedname,Name | Format-Table -AutoSize
$Results | Export-Excel -Path C:\temp\biscom_machines.xlsx
#>

$BiscomMachines = Import-Excel -Path 'C:\temp\Biscom Computer Software Rollout.xlsx' -WorksheetName 'All Assets' -HeaderName 'Phase #','Name'
$CMMachines = Get-CMDevice | select -Property Name, UserName, IsActive, LastDDR, ResourceID

foreach($BiscomMachine in $BiscomMachines){
        #($BiscomMachine = $BiscomMachines | Where-Object {$_.Name -eq 'ZACKGAUCK'})
        #($ResourceID = $CMMachines | Where-Object {$_.Name -eq 'ZACKGAUCK'} | select -ExpandProperty ResourceID -Last 1)
        IF($ResourceID = $CMMachines | Where-Object {$_.Name -eq $BiscomMachine.Name} | select -ExpandProperty ResourceID -Last 1){
            Add-Member -InputObject $BiscomMachine -MemberType NoteProperty -Name 'ResourceID' -Value $ResourceID
            Clear-Variable ResourceID 
        }
}


$BiscomCollections = @()
$Phases = $BiscomMachines | select -ExpandProperty 'Phase #' -Unique
$LimitingCollection = Get-CMCollection -Name 'DAF.Biscom'
foreach($Phase in $Phases){
    $CollectionName = "DAF.Biscom.Phase$($Phase)"
    $Collection = Get-CMCollection -Name $CollectionName
    IF(!$Collection){
        $BiscomCollections += New-CMCollection -CollectionType Device -Comment "Biscom Remediation Phase $Phase" -Name $CollectionName -LimitingCollectionId $LimitingCollection.CollectionID -ErrorAction Stop
    }ELSEIF($Collection){
        Write-Output "Collection $CollectionName already exists: CollectionID - $($CollectionName.CollectionID)"
        $BiscomCollections += $Collection
    }
    foreach($Machine in $BiscomMachines){
        IF($Machine.'Phase #' -eq $Phase){
            Add-CMDeviceCollectionDirectMembershipRule -CollectionName $CollectionName -ResourceId $Machine.ResourceID -ErrorAction SilentlyContinue
        }
    }
}
$BiscomCollections
$BiscomApplication = Get-CMApplication -Name "Biscom SFT Outlook Add-In"
$BiscomCollections | foreach{
    #Get-CMCollection -Name $_.Name |  Move-CMObject -FolderPath ".\DeviceCollection\Software Deployments\Biscom"

    #Deploy Biscom
    #($BiscomCollections[0].Name).Substring($BiscomCollections[0].Name.Length -1,1)
    $Phasenumber = ($_.Name).Substring($_.Name.Length -1,1)
    Write-Host "Phase number: $Phasenumber"
    Switch($Phasenumber){
        1 {$DeadlineDate = Get-Date -Year 2018 -Month 09 -Day 10 -Hour 14 -Minute 00 -Second 00 -Millisecond 00}
        2 {$DeadlineDate = Get-Date -Year 2018 -Month 09 -Day 13 -Hour 14 -Minute 00 -Second 00 -Millisecond 00}
        3 {$DeadlineDate = Get-Date -Year 2018 -Month 09 -Day 17 -Hour 14 -Minute 00 -Second 00 -Millisecond 00}
        4 {$DeadlineDate = Get-Date -Year 2018 -Month 09 -Day 20 -Hour 14 -Minute 00 -Second 00 -Millisecond 00} 
    }
    Write-Host "DeadlineDate: $DeadlineDate"
    Write-Host "AvailableDate: $($DeadlineDate.AddDays(-2))"
    Write-Host "Collection Name: $($_.Name) CollectionID: $($_.CollectionID)"
    New-CMApplicationDeployment -Name $BiscomApplication.LocalizedDisplayName -DeployAction Install -DeployPurpose Required `
        -OverrideServiceWindow $true -PreDeploy $true -UserNotification DisplaySoftwareCenterOnly -AvailableDateTime ($DeadlineDate.AddDays(-2)) `
        -DeadlineDateTime $DeadlineDate -CollectionId $_.CollectionID -TimeBaseOn LocalTime
}

New-CMApplicationDeployment -DeployPurpose Required