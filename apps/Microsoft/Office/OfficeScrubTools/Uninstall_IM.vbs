' Removes IM Applications
' Written By: Keith Holland
' Written on : 29 Feb 2016
' Updated On: 
' Modified By:
' Modified Date:

Set WSHShell = CreateObject("WScript.Shell")
sCurPath = CreateObject("Scripting.FileSystemObject").GetAbsolutePathName(".")
cQuotes = CHR(34)

Dim fso
Set fso = WScript.CreateObject("Scripting.Filesystemobject")
Set f = fso.CreateTextFile("c:\temp\IMApp.log", 2)

f.WriteLine NOW & ":  Stop running Application Processes"
strComputer = "."
strProcessToKill1 = "Lync.exe"
strProcessToKill2 = "Communicator.exe"
strProcessToKill3 = "Outlook.exe" 
Set objWMIService = GetObject("winmgmts:" _
                & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2") 
Set colProcess = objWMIService.ExecQuery _
                ("Select * from Win32_Process Where Name = '" & strProcessToKill1 & "' OR Name = '" & strProcessToKill2 & "' OR Name = '" & strProcessToKill3 & "'")
count = 0
For Each objProcess in colProcess
                objProcess.Terminate
                count = count + 1
Next
f.WriteLine NOW & ": Processes Terminated"

'f.WriteLine "Uninstall Lync Basic"
'sInstaller = "setup.exe"
'sParams = "/uninstall LYNCENTRY /config UninstallLyncBasic.xml"
'sCommandLine = cQuotes & sCurPath & "\" & sInstaller & cQuotes & sParams
'LyncBasicErrCode = WshShell.Run(sCommandLine, 1, True)
'f.WriteLine "Lync Basic Removal Result:" & LyncBasicErrCode

f.WriteLine NOW & ":  Uninstall IM Applications"
UninstallLyncComm()
f.WriteLine NOW & ":  IM Uninstalls Complete"


f.Close

'''''' All Required Functions

'Function to uninstall Lync and Communicator by GUID
Function UninstallLyncComm()
	Uninstall1 = WshShell.Run("msiexec.exe /x {E84D1C9D-6669-4156-992B-17557D64F1D3} /quiet /norestart", 1, True)
	Uninstall2 = WshShell.Run("msiexec.exe /x {81BE0B17-563B-45D4-B198-5721E6C665CD} /qn /norestart", 1, True)
	Uninstall3 = WshShell.Run("msiexec.exe /x {0d1cbbb9-f4a8-45b6-95e7-202ba61d7af4} /qn /norestart", 1, True)
	Uninstall4 = WshShell.Run("msiexec.exe /x {54b5c8b2-4de9-4055-9dfe-d1fe8b889f65} /qn /norestart", 1, True)
	Uninstall5 = WshShell.Run("msiexec.exe /x {be5ad430-9e0c-4243-ab3f-593835869855} /qn /norestart", 1, True)
End Function

'''''' End of All Required Functions








