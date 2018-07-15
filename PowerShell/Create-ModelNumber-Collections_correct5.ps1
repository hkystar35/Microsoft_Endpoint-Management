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

$CollVariables = "Lenovo;ThinkPad;S1 Yoga 12;20DL",
"Lenovo;ThinkPad;X1 Carbon 2nd;20A7",
"Lenovo;ThinkPad;X1 Carbon 3rd;20BS",
"Lenovo;ThinkPad;X1 Yoga 1st;20FQ",
"Lenovo;ThinkPad;Yoga 260;20FD",


$CollVariables | Foreach{
    $Split = $_ -split (";")
    
    $CollName = "All $($split[0]) $($split[1]) $($split[2]) ($($split[3])) Workstations"
    $Query = "select SMS_R_System.Name, SMS_G_System_COMPUTER_SYSTEM.Manufacturer, SMS_G_System_COMPUTER_SYSTEM.Model, SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version from  SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceID = SMS_R_System.ResourceId inner join SMS_G_System_COMPUTER_SYSTEM_PRODUCT on SMS_G_System_COMPUTER_SYSTEM_PRODUCT.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version like `"%$($split[2])%`" and SMS_G_System_COMPUTER_SYSTEM.Model like `"$($split[3])%`" and SMS_G_System_COMPUTER_SYSTEM.Manufacturer like `"%LENOVO%`""
    New-CMDeviceCollection -Name "$CollName" -RefreshType Periodic -RefreshSchedule $schedule01 -LimitingCollectionId $LimitingCollectionId
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$CollName" -QueryExpression "$Query" -RuleName "$CollName"
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$CollName" -ExcludeCollectionId $ExcludeServers
}