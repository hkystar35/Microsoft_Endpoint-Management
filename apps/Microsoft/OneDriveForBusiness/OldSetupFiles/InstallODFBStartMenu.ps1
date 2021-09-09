# This script must be run first to clean up the Start Menu and do the machine install

# Kill start menu shortcut for Office’s ODFB
# At "C:\Program Files (x86)\Microsoft Office\Office1[5/6]\GROOVE.EXE"
del "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\OneDrive for Business.lnk"

# Kill start menu shortcut for Windows’ built-in OneDrive (Metro)
# At "C:\Windows\FileManager\FileManager.exe"
# del "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\FileManager.lnk" -- can't delete
attrib "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\FileManager.lnk" -S
move "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\FileManager.lnk" "C:\ProgramData\Microsoft"

# Add some registry values
reg import "ODFB ShellIconOverlayIdentifiers.reg"

# Get SID of logged on user
#$loggedOnUser = (Get-WmiObject Win32_ComputerSystem | Select-Object Username | Select -ExpandProperty Username).Split("\")[1]
$loggedOnUser = $env:USERNAME
$SID = (Get-WmiObject Win32_UserAccount -Filter "Name = '$loggedOnUser'").SID

# Setup ODFB for the machine
#.\OneDriveSetup.exe /silent /permachine /cusid:$SID #/peruser
Start-Process OneDriveSetup.exe -Wait -ArgumentList "/silent /cusid:$SID" #/permachine

# Setup ODFB for the user
#.\OneDriveSetup.exe /silent /cusid:$SID
#Start-Process OneDriveSetup.exe -Wait -ArgumentList "/silent /cusid:$SID"

# Update the ACL for the ODFB folder in SYSTEM's AppData (Detection script will fail otherwise)
$ACL = Get-Acl "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\Microsoft\OneDrive"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","Read","Allow")
$ACL.SetAccessRule($accessRule)
Set-Acl "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\Microsoft\OneDrive" $ACL

<# Moving to ODFB user install batch script
# Create ODFB desktop shortcut
# POSH doesn't do this natively so we need to use COM objects
$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut("C:\Users\$loggedOnUser\Desktop\OneDrive for Business.lnk")
$shortcut.TargethPath = "C:\Users\$loggedOnUser\AppData\Local\Microsoft\OneDrive\OneDrive.exe"
$shortcut.Save()
#>