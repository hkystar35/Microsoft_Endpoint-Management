#This script detects whether or not SCCM needs to prep a computer for its OneDrive for Business installation
#If the paths below don't exist then this is considered "installed" and it's ok to proceed with the user script

#The error action line supresses error messages which would choke up the detection process
$ErrorActionPreference = "SilentlyContinue"

#Check for Microsoft's OneDrive for Business
$Office = Test-Path 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\OneDrive for Business.lnk'

#Check for Modern OneDrive app
$Modern = Test-Path 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\FileManager.lnk'

#Get locally logged on username
#$loggedOnUser = (Get-WmiObject Win32_ComputerSystem | Select-Object Username | Select -ExpandProperty Username).Split("\")[1]

#Check for ODFB Next Generation Sync Client
#$OneDrive = Test-Path "C:\Users\$loggedOnUser\AppData\Local\Microsoft\OneDrive\OneDrive.exe"
#$OneDrive = Test-Path "C:\Program Files (x86)\Microsoft OneDrive\OneDriveSetup.exe"
$OneDrive = Test-Path "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\Microsoft\OneDrive"

#Test the results
if ($Office -eq $false -and $Modern -eq $false -and $OneDrive -eq $true) {return $true}