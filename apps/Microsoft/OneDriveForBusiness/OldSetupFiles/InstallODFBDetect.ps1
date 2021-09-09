#This script detects whether or not OneDrive for Business installed
#If the paths below don't exist then this is considered "installed" and it's ok to proceed with the user script

#The error action line supresses error messages which would choke up the detection process
$ErrorActionPreference = "SilentlyContinue"

#Get locally logged on username
$loggedOnUser = (Get-WmiObject Win32_ComputerSystem | Select-Object Username | Select -ExpandProperty Username).Split("\")[1]

$OneDrive = Test-Path "C:\Users\$loggedOnUser\AppData\Local\Microsoft\OneDrive\settings\"
if ($OneDrive -eq $true) {return $true}