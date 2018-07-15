#variables to be modified to suite your site configuration
$sccm_module = "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
$site_code = "PAY:"
$LimitingCollectionId = 'PAY0000B'
$ExcludeServers = 'PAY0000A'

Import-Module $sccm_module
Set-Location $site_code

#create schedule variables
$schedule01 = New-CMSchedule -RecurCount 3 -RecurInterval Days -Start 21:00


# Create collections

$CollVariables = "Lenovo;ThinkCentre;M700;10HY",
"Lenovo;ThinkCentre;M710q;10MR",
"Lenovo;ThinkCentre;M73;10AY",
"Lenovo;ThinkCentre;M90p;3282",
"Lenovo;ThinkCentre;M91p;7052",
"Lenovo;ThinkCentre;M92p;2992",
"Lenovo;ThinkCentre;M93p;10A7",
"Lenovo;ThinkStation;P300;30AH",
"Lenovo;ThinkPad;P50;20EN",
"Lenovo;ThinkPad;P51s;20HB",
"Lenovo;ThinkPad;T450s;20BX",
"Lenovo;ThinkPad;T460s;20F9",
"Lenovo;ThinkPad;T470s;20HF",
"Lenovo;ThinkPad;W530;2438",
"Lenovo;ThinkPad;W531;2438",
"Lenovo;ThinkPad;W532;2438",
"Lenovo;ThinkPad;W540;20BG",
"Lenovo;ThinkPad;W541;20EF",
"Lenovo;ThinkPad;X1 Carbon 1st Gen;3444",
"Lenovo;ThinkPad;X1 Carbon 2nd Gen;20A7",
"Lenovo;ThinkPad;X1 Carbon 3rd Gen;20BS",
"Lenovo;ThinkPad;X1 Yoga 1st Gen;20FQ",
"Lenovo;ThinkPad;Yoga 12 Laptop;20DL",
"Lenovo;ThinkPad;Yoga 260 Laptop;20FD"
#"Lenovo;ThinkPad;P51;20HH",

$CollVariables | Foreach{
    $Split = $_ -split (";")
    
    $CollName = "All $($split[0]) $($split[1]) $($split[2]) ($($split[3])) Workstations"
    $Query = "select SMS_R_System.Name, SMS_G_System_COMPUTER_SYSTEM.Manufacturer, SMS_G_System_COMPUTER_SYSTEM.Model, SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version from  SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceID = SMS_R_System.ResourceId inner join SMS_G_System_COMPUTER_SYSTEM_PRODUCT on SMS_G_System_COMPUTER_SYSTEM_PRODUCT.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version like `"%$($split[2])%`" and SMS_G_System_COMPUTER_SYSTEM.Model like `"$($split[3])%`" and SMS_G_System_COMPUTER_SYSTEM.Manufacturer like `"%LENOVO%`""
    New-CMDeviceCollection -Name "$CollName" -RefreshType Periodic -RefreshSchedule $schedule01 -LimitingCollectionId $LimitingCollectionId
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$CollName" -QueryExpression "$Query" -RuleName "$CollName"
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$CollName" -ExcludeCollectionId $ExcludeServers
}