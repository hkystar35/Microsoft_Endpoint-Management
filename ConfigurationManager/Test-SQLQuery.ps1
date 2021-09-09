$ModelNum4 = "20HH"
$Manufacturer = "Lenovo"
$test = @"
select SMS_R_System.Name,
SMS_G_System_COMPUTER_SYSTEM.Manufacturer,
SMS_G_System_COMPUTER_SYSTEM.Model,
SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version
from  SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceID = SMS_R_System.ResourceId
inner join SMS_G_System_COMPUTER_SYSTEM_PRODUCT on SMS_G_System_COMPUTER_SYSTEM_PRODUCT.ResourceID = SMS_R_System.ResourceId
where SMS_G_System_COMPUTER_SYSTEM.Model like `"$($ModelNum4)%`" and SMS_G_System_COMPUTER_SYSTEM.Manufacturer like `"%$($Manufacturer)%`"
"@

<#
$test = @"
select SMS_R_System.Name,
SMS_G_System_COMPUTER_SYSTEM.Manufacturer,
SMS_G_System_COMPUTER_SYSTEM.Model,
SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version
from  SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceID = SMS_R_System.ResourceId
inner join SMS_G_System_COMPUTER_SYSTEM_PRODUCT on SMS_G_System_COMPUTER_SYSTEM_PRODUCT.ResourceID = SMS_R_System.ResourceId
where SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version like `"%$($ModelName)%`" and SMS_G_System_COMPUTER_SYSTEM.Model like `"$($ModelNum4)%`" and SMS_G_System_COMPUTER_SYSTEM.Manufacturer like `"%$($Manufacturer)%`"
"@
#>
