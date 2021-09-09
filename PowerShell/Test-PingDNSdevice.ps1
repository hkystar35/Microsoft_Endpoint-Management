FUNCTION Find-FirstOnlineMachine {
	param(
		[string[]]$Machines
	)
	foreach ($Machine in $Machines){
		Write-Host "Testing $Machine" -NoNewline
		IF(Test-NetConnection -ComputerName $Machine -CommonTCPPort WINRM -ErrorAction SilentlyContinue -InformationLevel Quiet -WarningAction SilentlyContinue){
			$onlinemachine = $Machine
			Write-Host '...is online' -NoNewline
			Write-Host "...trying Invoke-Command on $onlinemachine" -NoNewline
			IF(Invoke-Command -ComputerName $onlinemachine -ScriptBlock {
				Get-CimInstance -ClassName win32_computersystem
				Get-CimInstance -ClassName win32_bios
			} -OutVariable Output$($onlinemachine)){
				Write-Host '...success!' -BackgroundColor Green
				(Get-Variable -Name "Output$($onlinemachine)").Value | Format-List
				BREAK
			}ELSE{
				Write-Host 'failed to connect' -BackgroundColor Red -ForegroundColor White
			}
			
		}ELSE{
			Write-Host '...offline'
		}
	}
}