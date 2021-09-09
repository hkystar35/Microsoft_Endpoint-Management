#Compares current time (less 5 minutes) against Modified Time of the file the Config Update scripts drops
#Changed from Created time to Modified time on 3/16/15 to bypass a weird bug
#The error action line supresses error messages which would choke up the deployment process
$ErrorActionPreference = "SilentlyContinue"
If (([DateTime]::Now.AddMinutes(-5)) -le ((Get-ItemProperty -Path C:\Windows\temp\converterconfig.txt).LastWriteTime)) {return $true}