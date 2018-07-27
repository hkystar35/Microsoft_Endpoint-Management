<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.152
	 Created on:   	5/29/2018 12:21 PM
	 Created by:   	
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

$RegPath = 'hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate'
$Names = 'PingID', 'AccountDomainSid', 'SusClientID'

$services = 'ccmexec', 'wuauserv'
$Output = $null

FOREACH ($service IN $services) {
	Stop-Service -Name $service -Force
}

FOREACH ($Name IN $Names) {
	$var1 = (Get-ItemProperty $RegPath).$($Name) -eq $null
	$old = (Get-ItemProperty $RegPath).$($Name)
	IF ($var1 -eq $False) {
		Remove-ItemProperty -path $RegPath -name $Name
		$Output += "Old:$($old)/"
	} ELSE {
		Write-Host "The value does not exist"
	}
	
}

FOREACH ($service IN $services) {
	Restart-Service -Name $service
}

Start-Process -FilePath "$env:SystemRoot\system32\wuauclt.exe" -ArgumentList '/resetauthorization /detectnow' -Wait
$Output += "resest-wuauclt/"

Start-Sleep -Seconds 15
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000113}" | Out-Null
Start-Sleep -Seconds 15
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000108}" | Out-Null
$Output += "triggeredscans/"



$new = (Get-ItemProperty $RegPath).SusClientID
$Output += "New:$($new)"

Write-Output $Output