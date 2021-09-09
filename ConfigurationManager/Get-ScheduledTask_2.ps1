$Machine = Read-Host "Machine Name"
Start-Process -FilePath "$env:HOMEDRIVE\tools\pstools\psexec.exe" -ArgumentList "-A -Accepteula \\$Machine Powershell.exe -command Enable-PSRemoting -Force" -Verbose -Wait
Invoke-Command -ComputerName $Machine  {Get-ScheduledTask | Where-Object TaskName -like "*redis*" | Get-ScheduledTaskInfo}