#Creates registry key for warranty info if missing and grants users full control
#Created 5/3/16

Start-Transcript -Path "C:\Windows\Temp\Set-RegistryPermissionsTRANSCRIPT.log" -Force -Append

#Variables
$regPrePath = "HKLM:\Software\"
$company = "Paylocity"
$regPath = $regPrePath + $company
$newSDDL = 'O:BAG:DUD:AI(A;CI;KA;;;BU)(A;CIID;KR;;;BU)(A;CIID;KA;;;BA)(A;CIID;KA;;;SY)(A;CIIOID;KA;;;CO)(A;CIID;KR;;;AC)'
$logPath = "C:\Windows\Temp\"
$logName = "Set-RegistryPermissions.log"
$logFullPath = $logPath + $logName

#Start logging
. .\Logging_Functions.ps1 #import logging functions
Log-Start -LogPath $logPath -LogName $logName -ScriptVersion "1.0"
Log-Write -LogPath $logFullPath -LineValue "Beginning registry permission script"

#If the key already exists, delete it
Log-Write -LogPath $logFullPath -LineValue "Checking if the registry key $($regpath) already exists"
If (Test-Path $regPath){
    Log-Write -LogPath $logFullPath -LineValue "Key exists, deleting it"
    Remove-Item $regPath -Recurse
}
Else{
    Log-Write -LogPath $logFullPath -LineValue "Key doesn't exist"
}

#If the first reg key doesn't exist, create it
If (-Not(Test-Path $regPath)){
    Log-Write -LogPath $logFullPath -LineValue "Creating $($regPath)"
    New-Item -Path $regPrePath -Name $company -Force
}
#If the second reg key doesn't exist, create it
If (-Not(Test-Path $regPath\WarrantyInformation)){
    Log-Write -LogPath $logFullPath -LineValue "Creating $($regPath)\WarrantyInformation"
    New-Item -Path $regPath -Name WarrantyInformation -Force
}

#Update permissions for registry key
Log-Write -LogPath $logFullPath -LineValue "Grabbing permissions for $($regpath)"
$acl = Get-Acl -Path $regPath
$acl.SetSecurityDescriptorSddlForm($newSDDL)
Log-Write -LogPath $logFullPath -LineValue "Setting new permissions for $($regpath)"
Set-Acl -Path $regPath -AclObject $acl

#All done
Log-Write -LogPath $logFullPath -LineValue "Completed registry permission script"
Log-Finish -LogPath $logFullPath -NoExit $True
Stop-Transcript