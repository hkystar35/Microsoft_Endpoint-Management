'//----------------------------------------------------------------------------
'// Purpose: Check Warranty Information for Lenovo Computers
'// Usage: cscript Lenovo.vbs
'// Version: 1.1 - April 23, 2014 - Odd-Magne Kristoffersen
'//
'// This script is provided "AS IS" with no warranties
'//
'// Modified for Paylocity use on 5/13/15 by Ken Christianson
'// Changed sCompanyName to "Paylocity" (line 18) and reformatted dates output from DMY to MDY (lines 148, 160, 161)
'//
'//----------------------------------------------------------------------------

'//----------------------------------------------------------------------------
'// Variable Declarations
'//----------------------------------------------------------------------------

EnableLogging = True
sCompanyName = "Paylocity"

'//----------------------------------------------------------------------------
'// Set Logging Information
'//----------------------------------------------------------------------------

Set oShell = CreateObject("wscript.Shell")
Set fso = CreateObject("scripting.filesystemobject")
If EnableLogging Then
    Set oLogFile = fso.OpenTextFile("C:\Windows\Temp\WarrantyInfo.log", 8, True)
    oLogFile.WriteLine "*********************************************************"
End If

'//----------------------------------------------------------------------------
'// Set Warranty WebSite Variables
'//----------------------------------------------------------------------------

'sWebServiceHost = "https://services.lenovo.com/ibapp/il"
'sWebServiceURL = "WarrantyStatus.jsp"
'sWebService = sWebServiceHost & "/" & sWebServiceURL
'sWebService = "https://csp.lenovo.com/ibapp/il/WarrantyStatus.jsp"
sWebServiceHost = "https://csp.lenovo.com/ibapp/il"
sWebServiceURL = "WarrantyStatus.jsp"
sWebService = sWebServiceHost & "/" & sWebServiceURL


'//----------------------------------------------------------------------------
'// Get the system's serial number from WMI
'//----------------------------------------------------------------------------

WriteLog "Beginning warranty information lookup."
Set oWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set colItems = oWMIService.ExecQuery("Select SerialNumber from Win32_BIOS",,48)
For Each objItem in colItems
    sSerialNumber = objItem.SerialNumber
Next

WriteLog "Serial number of system is " & sSerialNumber

'//----------------------------------------------------------------------------
'// Get the Product ID from WMI
'//----------------------------------------------------------------------------

Set oWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set colItems = oWMIService.ExecQuery("Select Model from Win32_ComputerSystem",,48)
For Each objItem in colItems
    sProductNumber = objItem.Model
Next

If Len(sProductNumber) = 0 Then
    WriteLog "ERROR: Product Number could not be determined."
    oLogFile.WriteLine "*********************************************************"
    oLogFile.Close
    WScript.Quit(9)
Else
    WriteLog "Product number of the system is " & sProductNumber
End If

'//----------------------------------------------------------------------------
'// Get the OS Architecture
'//----------------------------------------------------------------------------

Set colItems = oWMIService.ExecQuery("Select AddressWidth from Win32_Processor",,48)
For Each objItem in colItems
    sAddressWidth = objItem.AddressWidth
Next

WriteLog "Operating system is " & sAddressWidth & " bit."

'//----------------------------------------------------------------------------
'// Define the parameters string to send to the web site
'//----------------------------------------------------------------------------

sParameters = "serial=" & sSerialNumber
' & "&type=" & sProductNumber 
WriteLog "Opening the web site URL " & sWebService & "?" & sParameters

'//----------------------------------------------------------------------------
'// Define and call the web site
'//----------------------------------------------------------------------------

set xmlhttp = createobject ("msxml2.xmlhttp.3.0")
 xmlhttp.open "get", sWebService & "?" & sParameters, False
 xmlhttp.send
 
 If xmlhttp.Status = 200 Then
    WriteLog "Successful response from the web site."
    Process xmlhttp.ResponseText
Else
    WriteLog "ERROR: the web site returned status code " & xmlhttp.Status
    WriteLog "Returning exit code 1."
    nExitCode = 1
End If

If EnableLogging Then
    oLogFile.WriteLine "*********************************************************"
    oLogFile.Close
End If

WScript.Quit (nExitCode)

'//----------------------------------------------------------------------------
'// Functions
'//----------------------------------------------------------------------------

Function Process (HTML)
    WriteLog "Processing the HTML returned from the site."
    
    const HKLM = &H80000002
    Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")

    sKeyPath = "SOFTWARE\" & sCompanyName & "\WarrantyInformation"
    
    WriteLog "Registry key path is HKLM\" & sKeyPath
    
    oReg.CreateKey HKLM,sKeyPath

    WriteLog "Setting registry values."
	
	SerialNumber = split(xmlhttp.responseText,"Serial number:")(1)
	SerialNumber = split(SerialNumber,"colspan")(0)
	SerialNumber = replace(replace(SerialNumber,vbcr,""),vblf,"")
	SerialNumber = split(SerialNumber,"140")(1)
	SerialNumber = split(SerialNumber,"</td>")(0)
	SerialNumber = split(SerialNumber,">")(1)
	WriteLog "Serial Number is : " & SerialNumber
	oReg.SetStringValue HKLM, sKeyPath, "SerialNumber", SerialNumber
	
	ProductNumber = split(xmlhttp.responseText,"Product ID:")(1)
	ProductNumber = split(ProductNumber,"159")(1)
	ProductNumber = replace(replace(ProductNumber,vbcr,""),vblf,"")
	ProductNumber = split(ProductNumber,"</td>")(0)
	ProductNumber = split(ProductNumber,">")(1)
	WriteLog "Product Number is : " & ProductNumber
    oReg.SetStringValue HKLM, sKeyPath, "ProductNumber", ProductNumber

	WarrantyCheckDate = Right("0" & Month(Date), 2) & "." & Right("0" & Day(Date), 2) & "." & Year(Date)
    WriteLog "Warranty Check Date is : " & WarrantyCheckDate
    oReg.SetStringValue HKLM, sKeyPath, "WarrantyCheckDate", WarrantyCheckDate	
	
	WarrantyEndDate = split(xmlhttp.responseText,"Expiration date:")(1)
	WarrantyEndDate = split(WarrantyEndDate,"120")(1)
	WarrantyEndDate = replace(replace(WarrantyEndDate,vbcr,""),vblf,"")
	WarrantyEndDate = split(WarrantyEndDate,"</td>")(0)
	WarrantyEndDate = split(WarrantyEndDate,">")(1)
	WarrantyEndYear = split(WarrantyEndDate,"-")(0)
	WarrantyEndMonth = split(WarrantyEndDate,"-")(1)
	WarrantyEndDay = split(WarrantyEndDate,"-")(2)
	WriteLog "Expiration Date is : " & WarrantyEndMonth & "." & WarrantyEndDay & "." & WarrantyEndYear
	oReg.SetStringValue HKLM, sKeyPath, "ExpirationDate", WarrantyEndMonth & "." & WarrantyEndDay & "." & WarrantyEndYear	
	
	WarrantyStatus = split(xmlhttp.responseText,"Status:")(1)
	WarrantyStatus = split(WarrantyStatus,"159")(1)
	WarrantyStatus = replace(replace(WarrantyStatus,vbcr,""),vblf,"")
	WarrantyStatus = split(WarrantyStatus,"</td>")(0)
	WarrantyStatus = split(WarrantyStatus,">")(1)	
	WriteLog "Warranty Status is : " & WarrantyStatus
	oReg.SetStringValue HKLM, sKeyPath, "WarrantyStatus", WarrantyStatus

 End Function	

 Function WriteLog (sText)
    If EnableLogging Then
        oLogfile.WriteLine Now() & "     " & sText
    End If
End Function