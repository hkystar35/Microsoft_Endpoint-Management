#variables to be modified to suite your site configuration
$sccm_module = "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
$site_code = "CAS:"

$ExcludeServers = 'CAS00001'
$ExcludeWin8 = 'CAS00002'
$ExcludeWin7 = 'CAS00003'

Import-Module $sccm_module
Set-Location $site_code

#create schedule variables
$schedule01 = New-CMSchedule -RecurCount 3 -RecurInterval Days -Start 21:00


# Create collections
<#
$CollVariables = "Lenovo;ThinkCentre;M700;10HY;PAY001D7",
"Lenovo;ThinkCentre;M710q;10MR;PAY001D8",
"Lenovo;ThinkCentre;M73;10AY;PAY001D9",
"Lenovo;ThinkCentre;M90p;3282;PAY001DA",
"Lenovo;ThinkCentre;M91p;7052;PAY001DB",
"Lenovo;ThinkCentre;M92p;2992;PAY001DC",
"Lenovo;ThinkCentre;M93p;10A7;PAY001DD",
"Lenovo;ThinkStation;P300;30AH;PAY001DE",
"Lenovo;ThinkPad;P50;20EN;PAY001DF",
"Lenovo;ThinkPad;P51;20HH;PAY001D6",
"Lenovo;ThinkPad;P51s;20HB;PAY001E0",
"Lenovo;ThinkPad;T450s;20BX;PAY001E1",
"Lenovo;ThinkPad;T460s;20F9;PAY001E2",
"Lenovo;ThinkPad;T470s;20HF;PAY001E3",
"Lenovo;ThinkPad;W530;24382HU;PAY001E4",
"Lenovo;ThinkPad;W531;24384CU;PAY001E4",
"Lenovo;ThinkPad;W532;243852U;PAY001E4",
"Lenovo;ThinkPad;W540;20BG;PAY001E7",
"Lenovo;ThinkPad;W541;20EF;PAY001E8",
"Lenovo;ThinkPad;X1 Carbon 1st Gen;3444;PAY001E9",
"Lenovo;ThinkPad;X1 Carbon 2nd Gen;20A7;PAY001F0",
"Lenovo;ThinkPad;X1 Carbon 3rd Gen;20BS;PAY001F1",
"Lenovo;ThinkPad;X1 Yoga 1st Gen;20FQ;PAY001F2",
"Lenovo;ThinkPad;Yoga 12 Laptop;20DL;PAY001EF",
"Lenovo;ThinkPad;Yoga 260 Laptop;20FD;PAY001F3"
#>
$CollVariables = "Microsoft;Surface Book;2;;CAS00004"

$CollVariables | Foreach{
    $Split = $_ -split (";")
    
    $CollName = "Upgrade to Windows 10 - $($split[0]) $($split[1]) $($split[2])"
    #$Query = "select SMS_R_System.Name, SMS_G_System_COMPUTER_SYSTEM.Manufacturer, SMS_G_System_COMPUTER_SYSTEM.Model, SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version from  SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceID = SMS_R_System.ResourceId inner join SMS_G_System_COMPUTER_SYSTEM_PRODUCT on SMS_G_System_COMPUTER_SYSTEM_PRODUCT.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version like `"%$($split[2])%`" and SMS_G_System_COMPUTER_SYSTEM.Model like `"$($split[3])%`" and SMS_G_System_COMPUTER_SYSTEM.Manufacturer like `"%LENOVO%`""
    $NewCollection = New-CMDeviceCollection -Name "$CollName" -RefreshType Periodic -RefreshSchedule $schedule01 -LimitingCollectionId $split[4]
    #Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$CollName" -QueryExpression "$Query" -RuleName "$CollName"
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$CollName" -ExcludeCollectionId $ExcludeServers
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$CollName" -ExcludeCollectionId $ExcludeWin7
    Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$CollName" -ExcludeCollectionId $ExcludeWin8
    
    Write-Host "$_ ;newcolID;$($NewCollection.CollectionID)"
}