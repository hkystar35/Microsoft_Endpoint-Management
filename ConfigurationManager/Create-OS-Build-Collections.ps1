#variables to be modified to suite your site configuration
$sccm_module = "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
$site_code = "PAY:"
$client_version = "5.00.8498.1711"
$client_version_friendly_name = "SCCM CB 1702"
$AllWorkstationsCollectionId = "SMS00001"
$ExcludeServers = "CAS00001"
$threshold = "14"

Import-Module $sccm_module
Set-Location $site_code

#create schedule variables
$schedule01 = New-CMSchedule -RecurCount 3 -RecurInterval Days -Start 21:00
$schedule02 = New-CMSchedule -RecurCount 3 -RecurInterval Days -Start 21:15
$schedule03 = New-CMSchedule -RecurCount 3 -RecurInterval Days -Start 21:30

<#set variables for creating rule names
$Windows10Ent = "All Windows 10 $Version, Build $Build"
$Windows10Pro = "All Windows 10 Pro Versions"
$Windows10All = "All Windows 10 Versions and Builds"
$Windows81Ent = "All Windows 8.1 $Version, Build $Build"
$Windows81Pro = "All Windows 8.1 Pro Versions"
$Windows81All = "All Windows 8.1 Versions and Builds"
$Windows8Ent = "All Windows 8 $Version, Build $Build"
$Windows8Pro = "All Windows 8 Pro Versions"
$Windows8All = "All Windows 8 Versions and Builds"
$Windows8AllVersions = "All Windows 8 and 8.1 Versions and Builds"

#>
<# Create collections

$w10VerBuilds = "1709;16299",
"1703;15063",
"1607;14393",
"1511;10586",
"1703;15063",
"1607;14393",
"1511;10586",
"1607;14393",
"1507;10240"

Foreach($w10VerBuild in $w10VerBuilds){
    $Split = $w10VerBuild -split (";")
    $W10Name = "All Windows 10 $($split[0]), Build $($split[1])"
    $w10Query = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_OPERATING_SYSTEM.BuildNumber = `"$($split[1])`""
    New-CMDeviceCollection -Name "$W10Name" -RefreshType Periodic -RefreshSchedule $schedule01 -LimitingCollectionId $AllWorkstationsCollectionId
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$W10Name" -QueryExpression "$w10Query" -RuleName "$W10Name"
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$W10Name" -ExcludeCollectionId $ExcludeServers
}

$w81VerBuilds = "6.3.9600;9600"
Foreach($w81VerBuild in $w81VerBuilds){
    $Split = $w81VerBuild -split (";")
    $W81Name = "All Windows 8.1 $($split[0]), Build $($split[1])"
    $w81Query = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_OPERATING_SYSTEM.BuildNumber = `"$($split[1])`""
    New-CMDeviceCollection -Name "$W81Name" -RefreshType Periodic -RefreshSchedule $schedule02 -LimitingCollectionId $AllWorkstationsCollectionId
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$W81Name" -QueryExpression "$w81Query" -RuleName "$W81Name"
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$W81Name" -ExcludeCollectionId $ExcludeServers
}

$w8VerBuilds = "6.2.9200;9200"
Foreach($w8VerBuild in $w8VerBuilds){
    $Split = $w8VerBuild -split (";")
    $W8Name = "All Windows 8 $($split[0]), Build $($split[1])"
    $w8Query = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_OPERATING_SYSTEM.BuildNumber = `"$($split[1])`""
    New-CMDeviceCollection -Name "$W8Name" -RefreshType Periodic -RefreshSchedule $schedule03 -LimitingCollectionId $AllWorkstationsCollectionId
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$W8Name" -QueryExpression "$w8Query" -RuleName "$W8Name"
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$W8Name" -ExcludeCollectionId $ExcludeServers
}
#>
$w8VerBuilds = "6.1.7.7601;7601"
Foreach($w8VerBuild in $w8VerBuilds){
    $Split = $w8VerBuild -split (";")
    $W8Name = "All Windows 7 $($split[0]), Build $($split[1])"
    $w8Query = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_OPERATING_SYSTEM on SMS_G_System_OPERATING_SYSTEM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_OPERATING_SYSTEM.BuildNumber = `"$($split[1])`""
    New-CMDeviceCollection -Name "$W8Name" -RefreshType Periodic -RefreshSchedule $schedule03 -LimitingCollectionId $AllWorkstationsCollectionId
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$W8Name" -QueryExpression "$w8Query" -RuleName "$W8Name"
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$W8Name" -ExcludeCollectionId $ExcludeServers
}



<#
New-CMDeviceCollection -Name $Windows10Pro -RefreshType Periodic -RefreshSchedule $schedule01 -LimitingCollectionId $AllWorkstationsCollectionId
New-CMDeviceCollection -Name $Windows10All -RefreshType Periodic -RefreshSchedule $schedule02 -LimitingCollectionName $healthy_assigned
New-CMDeviceCollection -Name $Windows81Pro -RefreshType Periodic -RefreshSchedule $schedule03 -LimitingCollectionName $healthy_client
New-CMDeviceCollection -Name $Windows81All -RefreshType Periodic -RefreshSchedule $schedule03 -LimitingCollectionName $healthy_client
New-CMDeviceCollection -Name $Windows8Pro -RefreshType Periodic -RefreshSchedule $schedule04 -LimitingCollectionName $healthy_client_not_obsolete
New-CMDeviceCollection -Name $Windows8All -RefreshType Periodic -RefreshSchedule $schedule05 -LimitingCollectionName $healthy_DDR_within_threshold
New-CMDeviceCollection -Name $Windows8AllVersions -RefreshType Periodic -RefreshSchedule $schedule05 -LimitingCollectionName $healthy_DDR_within_threshold

# create query rules 
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Windows10Ent -QueryExpression $query01a -RuleName $healthy_assigned
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Windows10Pro -QueryExpression $query01b -RuleName $suspect_notassigned
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Windows10All -QueryExpression $query02a -RuleName $healthy_client
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Windows81Ent -QueryExpression $query02b -RuleName $healthy_no_client
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Windows81Pro -QueryExpression $query03a -RuleName $healthy_client_not_obsolete
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Windows81All -QueryExpression $query03b -RuleName $healthy_client_obsolete
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Windows8Ent -QueryExpression $query04a -RuleName $healthy_DDR_within_threshold
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Windows8Pro -QueryExpression $query04b -RuleName $healthy_DDR_not_within_threshold
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Windows8All -QueryExpression $query05a -RuleName $healthy_hw_inventory_current
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Windows8AllVersions -QueryExpression $query05b -RuleName $healthy_hw_inventory_not_current
#>