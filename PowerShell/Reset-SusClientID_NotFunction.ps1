<#	
.NOTES
===========================================================================
Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.152
Created on:   	5/30/2018 5:20 PM
Created by:   	NWendlowsky
Organization: 	
Filename:     	
===========================================================================
.DESCRIPTION
Resets susclientID to repair duplicates in WSUS SUSDB.
#>

# Set variables
$RegPath = 'hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate'
$Names = 'PingID', 'AccountDomainSid', 'SusClientID'
$Service = 'wuauserv'
$Output = $null

# get service settings, then stop and temp set to manual, if needed.
$ServiceStart = Get-WmiObject -Class Win32_Service -Property StartMode, State -Filter ("Name=`'{0}`'" -f $Service)
IF ($ServiceStart.StartMode -eq 'Automatic') {
	Set-Service -Name $Service -StartupType Manual
}
IF ($ServiceStart.State -eq 'running') {
	Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
}


# get process then stop, if needed. No restart of process
$ProcessStart = Get-Process -Name CcmExec
IF ($ProcessStart) {
	Stop-Process -Name SCClient -Force -ErrorAction SilentlyContinue
}

# Test for key properties, capture old value, then delete
FOREACH ($Name IN $Names) {
	$var1 = (Get-ItemProperty $RegPath).$($Name) -eq $null
	$old = (Get-ItemProperty $RegPath).$($Name)
	IF ($var1 -eq $False) {
		Remove-ItemProperty -path $RegPath -name $Name -ErrorAction SilentlyContinue
		$Output += "Old:$($old)/"
	}
}

Start-Sleep -Seconds 10 -ErrorAction SilentlyContinue

# return service to original state
IF ($ServiceStart.StartMode -eq 'Automatic') {
	Set-Service -Name $Service -StartupType Automatic
}
IF ($ServiceStart.State -eq 'running') {
	Start-Service -Name $Service -ErrorAction SilentlyContinue
}

# Reset WUAUclt to generate new SusClientID, capture for output
Start-Process -FilePath "$env:SystemRoot\system32\wuauclt.exe" -ArgumentList '/resetauthorization /detectnow' -ErrorAction SilentlyContinue -Wait
$Output += "resest-wuauclt/"

Start-Sleep -Seconds 10 -ErrorAction SilentlyContinue

# Trigger Update Scan
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000113}" -ErrorAction SilentlyContinue | Out-Null

Start-Sleep -Seconds 10 -ErrorAction SilentlyContinue

# Trigger Update Deployment Scan
Invoke-WMIMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule "{00000000-0000-0000-0000-000000000108}" -ErrorAction SilentlyContinue | Out-Null
$Output += "triggeredscans/"

Start-Sleep -Seconds 10 -ErrorAction SilentlyContinue

# Get new SusClientID
$new = (Get-ItemProperty $RegPath).SusClientID
$Output += "New:$($new)"

# Ouput
Write-Output $Output