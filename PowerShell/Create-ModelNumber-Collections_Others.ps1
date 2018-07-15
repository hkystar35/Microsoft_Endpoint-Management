#variables to be modified to suite your site configuration
$sccm_module = "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
$site_code = "CAS:"
$LimitingCollectionId = 'CAS00001'
$ExcludeServers = 'CAS00002'

Import-Module $sccm_module
Set-Location $site_code

#create schedule variables
$schedule01 = New-CMSchedule -RecurCount 3 -RecurInterval Days -Start 21:00


# Create collections

$CollVariables = "Microsoft;Surface Book",
"Microsoft;Virtual Machine",
"Microsoft;Surface Pro 3",
"Parallels;Parallels Virtual Platform",
"Vmware;VMware Virtual Platform",


$CollVariables | Foreach{
    $Split = $_ -split (";")
    
    $CollName = "All $($split[0]) $($split[1]) Workstations"
    $Query = "select SMS_R_System.Name, SMS_G_System_COMPUTER_SYSTEM.Manufacturer, SMS_G_System_COMPUTER_SYSTEM.Model, SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version from  SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceID = SMS_R_System.ResourceId inner join SMS_G_System_COMPUTER_SYSTEM_PRODUCT on SMS_G_System_COMPUTER_SYSTEM_PRODUCT.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.Model like `"$($split[1])%`" and SMS_G_System_COMPUTER_SYSTEM.Manufacturer like `"$($split[0])%`""
    $Query = "select SMS_R_System.Name, SMS_G_System_COMPUTER_SYSTEM.Manufacturer, SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version, SMS_G_System_COMPUTER_SYSTEM.Model from  SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceID = SMS_R_System.ResourceId inner join SMS_G_System_COMPUTER_SYSTEM_PRODUCT on SMS_G_System_COMPUTER_SYSTEM_PRODUCT.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM.Model like `"$($split[1])%`" and SMS_G_System_COMPUTER_SYSTEM.Manufacturer like `"$($split[0])%`""
    New-CMDeviceCollection -Name "$CollName" -RefreshType Periodic -RefreshSchedule $schedule01 -LimitingCollectionId $LimitingCollectionId
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$CollName" -QueryExpression "$Query" -RuleName "$CollName"
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$CollName" -ExcludeCollectionId $ExcludeServers
}