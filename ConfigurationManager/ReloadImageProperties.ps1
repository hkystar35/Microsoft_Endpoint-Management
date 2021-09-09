$SiteCode = "PAY"
$PackageID = "PAY002AA"
$BootImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_BootImagePackage -Filter "PackageID = '$($PackageID)'" -ErrorAction Stop
$BootImage.ReloadImageProperties()