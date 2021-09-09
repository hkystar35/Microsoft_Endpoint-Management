Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" # Import the ConfigurationManager.psd1 module 

$sitecode = (Get-PSDrive -PSProvider CMSite).Name
Set-Location ($sitecode + ":") # Set the current location to be the site code.

$dynamicpkgname = "Modern Driver Management Script Package" #PAY006ED
$dynamicDriverPkgPath = ((Get-CMPackage -Name $dynamicpkgname).Pkgsourcepath)

$statusfilterrulename = "Dynamic Driver Package Insert"
New-CMStatusFilterRule -Name $statusfilterrulename -MessageType Audit -MessageId 30000 -SeverityType Informational -RunProgram $true -ProgramPath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -command `"Get-WmiObject -class sms_package -Namespace root\sms\site_$sitecode | Select-Object pkgsourcepath, Description, ISVData, ISVString, Manufacturer, MifFileName, MifName, MifPublisher, MIFVersion, Name, PackageID, ShareName, Version | export-clixml -path '$dynamicDriverPkgPath\packages.xml' -force; (Get-WmiObject -class sms_package -Namespace root\sms\site_$sitecode | Where-Object {`$_.Name -eq '$dynamicpkgname'}).RefreshPkgSource()`""

$statusfilterrulename = "Dynamic Driver Package Update"
New-CMStatusFilterRule -Name $statusfilterrulename -MessageType Audit -MessageId 30001 -SeverityType Informational -RunProgram $true -ProgramPath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -command `"Get-WmiObject -class sms_package -Namespace root\sms\site_$sitecode | Select-Object pkgsourcepath, Description, ISVData, ISVString, Manufacturer, MifFileName, MifName, MifPublisher, MIFVersion, Name, PackageID, ShareName, Version | export-clixml -path '$dynamicDriverPkgPath\packages.xml' -force; (Get-WmiObject -class sms_package -Namespace root\sms\site_$sitecode | Where-Object {`$_.Name -eq '$dynamicpkgname'}).RefreshPkgSource()`""

$statusfilterrulename = "Dynamic Driver Package Delete"
New-CMStatusFilterRule -Name $statusfilterrulename -MessageType Audit -MessageId 30002 -SeverityType Informational -RunProgram $true -ProgramPath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -command `"Get-WmiObject -class sms_package -Namespace root\sms\site_$sitecode | Select-Object pkgsourcepath, Description, ISVData, ISVString, Manufacturer, MifFileName, MifName, MifPublisher, MIFVersion, Name, PackageID, ShareName, Version | export-clixml -path '$dynamicDriverPkgPath\packages.xml' -force; (Get-WmiObject -class sms_package -Namespace root\sms\site_$sitecode | Where-Object {`$_.Name -eq '$dynamicpkgname'}).RefreshPkgSource()`""