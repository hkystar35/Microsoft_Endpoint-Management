#Lenovo Warranty Check script
#Replaces the old version which is apparently deprecated.  It seems we haven't successfully pulled data from there since July 2015.
#Originally inspired by https://social.technet.microsoft.com/Forums/office/en-US/76d24b85-7ce3-497c-973e-beece6c68ed3/get-lenovo-warranty-info-automatically?forum=winserverpowershell
#Improved upon by https://www.reddit.com/r/PowerShell/comments/4cbrxy/question_help_getting_div_elements/
#Created 4/28/16
#Updated 5/3/16

Start-Transcript -Path "$($env:userprofile)\AppData\Local\WarrantyInformationTRANSCRIPT.log" -Force -Append

#Warn user not to close window (SCCM must run it in the user context so pop-up PowerShell window is unavoidable)
Clear-Host
Write-Host "Running warranty check script..."
Write-Host "Please do not close this window!"

#Variables
#Path must end with a \
$logPath = "$($env:userprofile)\AppData\Local\"
$logName = "WarrantyInfo.log"
#Hive must end with a :
$regPath = "HKLM:\Software\Paylocity\WarrantyInformation"
$logFullPath = $logPath + $logName

#Start logging
. .\Logging_Functions.ps1 #import logging functions
Log-Start -LogPath $logPath -LogName $logName -ScriptVersion "2.0"
Log-Write -LogPath $logFullPath -LineValue "Beginning warranty check script"

#Get serial and model numbers
$serialNumber = Get-WmiObject -Namespace root\cimv2 -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber
Log-Write -LogPath $logFullPath -LineValue "Serial number of system is $($serialNumber)"
$modelNumber = Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model
Log-Write -LogPath $logFullPath -LineValue "Product number of the system is $($modelNumber)"

#Grab data from Lenovo
Log-Write -LogPath $logFullPath -LineValue "Opening the web site URL http://support.lenovo.com/us/en/warrantylookup"
$test = Invoke-WebRequest -uri http://support.lenovo.com/us/en/warrantylookup -SessionVariable ln
If ($test.StatusCode -eq 200){
    Log-Write -LogPath $logFullPath -LineValue "Successful response from the web site"
}
Else{
    Log-Write -LogPath $logFullPath -LineValue "ERROR: the web site returned status code $($test.StatusCode)"
    Log-Write -LogPath $logFullPath -LineValue "Returning exit code 1"
    Log-Finish -LogPath $logFullPath -NoExit $True
    Exit 1
}
Log-Write -LogPath $logFullPath -LineValue "Parsing and populating form"
$form = $test.forms[0]
$form.Fields["serialCode"]="$($serialNumber)"
Log-Write -LogPath $logFullPath -LineValue "Submitting warranty query to web site"
$answer = Invoke-WebRequest -Uri ("http://support.lenovo.com" + $form.Action) -WebSession $ln -Method $form.Method -Body $form.Fields
If ($answer.StatusCode -eq 200){
    Log-Write -LogPath $logFullPath -LineValue "Successful response from the web site"
}
Else{
    Log-Write -LogPath $logFullPath -LineValue "ERROR: the web site returned status code $($test.StatusCode)"
    Log-Write -LogPath $logFullPath -LineValue "Returning exit code 1"
    Log-Finish -LogPath $logFullPath -NoExit $True
    Exit 1
}
Log-Write -LogPath $logFullPath -LineValue "Processing the HTML returned from the site"
$warrantyinfo = $answer.ParsedHtml.getElementsByTagName('div') | select -f 1 | % {$_.innertext -split "`n"}

#Drop Lenovo data into an array
$hash = @{}
$warrantyinfo | ? {$_ -match ':'} | % {
    $id = $_.substring(0, $_.indexof(':')).trim()
    $info = $_.substring($_.indexof(':')+1).trim()
    $hash.Add($id, $info)
}
[pscustomobject]$hash

#New variables from array data
$endDate = $hash.'End Date'
$warrantyStatus = $hash.'Base WarrantyStatus'

#Save warranty data to registry
Log-Write -LogPath $logFullPath -LineValue "Registry key path is $($regPath)"
Log-Write -LogPath $logFullPath -LineValue "Expiration Date is: $($hash.'End Date')"
Set-ItemProperty -Path $regPath -Name ExpirationDate -Value $endDate
Log-Write -LogPath $logFullPath -LineValue "Product number is $($modelNumber)"
Set-ItemProperty -Path $regPath -Name ProductNumber -Value $modelNumber
Log-Write -LogPath $logFullPath -LineValue "Serial number is $($serialNumber)"
Set-ItemProperty -Path $regPath -Name SerialNumber -Value $serialNumber
Log-Write -LogPath $logFullPath -LineValue "Warranty check date is today, $(Get-Date)"
Set-ItemProperty -Path $regPath -Name WarrantyCheckDate -Value $(Get-Date)
Log-Write -LogPath $logFullPath -LineValue "Warranty status is $($hash.'Base WarrantyStatus')"
Set-ItemProperty -Path $regPath -Name WarrantyStatus -Value $warrantyStatus

#All done
Log-Write -LogPath $logFullPath -LineValue "Completed warranty check script"
Log-Finish -LogPath $logFullPath -NoExit $True
Stop-Transcript