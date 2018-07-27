<#	
    .NOTES
    ===========================================================================
    Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.150
    Created on:   	4/12/2018 12:29 PM
    Created by:   	
    Organization: 	
    Filename:     	
    ===========================================================================
    .DESCRIPTION
    A description of the file.
#>
#FUNCTION New-ICSEvent {
  <#
        .SYNOPSIS
        A brief description of the Create-ICSEvent function.
	
        .DESCRIPTION
        A detailed description of the Create-ICSEvent function.
	
        .PARAMETER StartDate
        A description of the StartDate parameter.
	
        .PARAMETER EndDate
        A description of the EndDate parameter.
	
        .PARAMETER Subject
        A description of the Subject parameter.
	
        .PARAMETER Description
        A description of the Description parameter.
	
        .PARAMETER Location
        A description of the Location parameter.
	
        .PARAMETER FileName
        Must be .ics file name
	
        .PARAMETER Frequency
        A description of the Frequency parameter.
	
        .PARAMETER Cycle
        A description of the Cycle parameter.
	
        .PARAMETER Interval
        A description of the Interval parameter.
	
        .EXAMPLE
        PS C:\> Create-ICSEvent -StartDate $value1 -EndDate $value2 -Subject 'Value3' -Description $value4 -Location 'Value5' -FileName $value6
	
        .NOTES
        Additional information about the function.
    #>
	
  PARAM
  (
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][datetime]$StartDate,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Subject,
    [Parameter(Mandatory = $true)][ValidatePattern('^.*\.(ics)$')][ValidateNotNullOrEmpty()]$FilePathAndName,
    [switch]$Frequency = $false,
    [ValidateSet('YEARLY', 'MONTHLY', 'WEEKLY', 'DAILY', 'HOURLY', 'MINUTELY', 'SECONDLY')]$Cycle,
    [ValidatePattern('\d')]$Interval = '1'
  )
  # Set Variables
  [datetime]$EndDate = $StartDate.AddHours(2)
  $Location = "At my desk"
  #$FileName = Split-Path $FilePathAndName -Leaf
  $FilePath = Split-Path $FilePathAndName -Parent
  
  #region Custom date formats that we want to use
  $dateFormat = "yyyyMMdd"
  $longDateFormat = "yyyyMMdd'T'HHmmss'Z'"
  $StartDate = $StartDate.ToUniversalTime()
  $EndDate = $EndDate.ToUniversalTime()
  $StartDateFormatted = $StartDate.ToString($longDateFormat)
  $EndDateFormatted = $EndDate.ToString($longDateFormat)
  #endregion
    
  #region Machine info
  $MachineInfo = Get-WmiObject -Class Win32_ComputerSystem
  $OSInfo = Get-WmiObject -Class Win32_OperatingSystem
  $Serial = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber
  $MachineName = $machineinfo.Name
  SWITCH ($OSInfo.Version) {
    6.3.9600 {
      $OSVersion = ('Windows 8.1 ({0})' -f $OSInfo.Version)
    }
    10.0.16299 {
      $OSVersion = ('Windows 10 1709 ({0})' -f $OSInfo.Version)
    }
    10.0.15063 {
      $OSVersion = ('Windows 10 1703 ({0})' -f $OSInfo.Version)
    }
    10.0.14393 {
      $OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
    }
    10.0.10586 {
      $OSVersion = ('Windows 10 1511 ({0})' -f $OSInfo.Version)
    }
    10.0.16299 {
      $OSVersion = ('Windows 10 1709 ({0})' -f $OSInfo.Version)
    }
    10.0.15063 {
      $OSVersion = ('Windows 10 1703 ({0})' -f $OSInfo.Version)
    }
    10.0.14393 {
      $OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
    }
    10.0.10586 {
      $OSVersion = ('Windows 10 1511 ({0})' -f $OSInfo.Version)
    }
    10.0.14393 {
      $OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
    }
    10.0.10240 {
      $OSVersion = ('Windows 10 1507 (RTM) ({0})' -f $OSInfo.Version)
    }
  }
  $OSArch = $OSInfo.OSArchitecture
  $MachineManuf = $machineinfo.Manufacturer
  $MachineModelNo = $machineinfo.Model
  $MachineModelName = $machineinfo.SystemFamily
  $NICIndex = Get-CimInstance -ClassName Win32_IP4RouteTable | Where-Object {
    $_.Destination -eq '0.0.0.0' -and $_.Mask -eq '0.0.0.0'
  } | Sort-Object Metric1 | Select-Object -First 1 | Select-Object -ExpandProperty InterfaceIndex
  $AdapterConfig = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object {
    $_.InterfaceIndex -eq $NICIndex
  } | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration
  $IPAddress = $AdapterConfig.IPAddress
  $MachineInfoText = @"
Here's my machine info:
Machine Name: $MachineName
OS: $OSVersion $OSArch
Manufacturer: $MachineManuf
Model: $MachineModelName ($($MachineModelNo))
Serial Number: $Serial
Last IP address: $IPAddress
"@
  $MachineInfoTextCalString = "Here's my machine info:\nMachine Name: $MachineName\nOS: $OSVersion $OSArch\nManufacturer: $MachineManuf\nModel: $MachineModelName ($MachineModelNo)\nSerial Number: $Serial\nLast IP address: $IPAddress"
  #endregion
  $Description = $MachineInfoTextCalString
  
  TRY {
    
    
    
    #region .NET StringBuilder
      #$sb = [System.Text.StringBuilder]::new()
    # Use this because Windows 8.1 sucks
      $sb = New-Object Text.StringBuilder
    #endregion
    
    #region ICS Properties. See RFC2445 specs at http://www.ietf.org/rfc/rfc2445.txt
    [void]$sb.AppendLine('BEGIN:VCALENDAR')
    [void]$sb.AppendLine('VERSION:2.0')
    [void]$sb.AppendLine('METHOD:PUBLISH')
    [void]$sb.AppendLine('X-PRIMARY-CALENDAR:TRUE')
    [void]$sb.AppendLine('PRODID:-//Domain//Department//EN')
    [void]$sb.AppendLine('BEGIN:VEVENT')
    [void]$sb.AppendLine("UID:" + [guid]::NewGuid())
    [void]$sb.AppendLine("CREATED:" + [datetime]::Now.ToUniversalTime().ToString($longDateFormat))
    [void]$sb.AppendLine("DTSTAMP:" + [datetime]::Now.ToUniversalTime().ToString($longDateFormat))
    [void]$sb.AppendLine("LAST-MODIFIED:" + [datetime]::Now.ToUniversalTime().ToString($longDateFormat))
    [void]$sb.AppendLine("SEQUENCE:0")
    [void]$sb.AppendLine("DTSTART:" + $StartDateFormatted)
    [void]$sb.AppendLine("DTEND:" + $EndDateFormatted)
    # If Frequency param used, sets values
    IF ($Frequency) {
      IF ($Cycle -and $Interval) {
        [void]$sb.AppendLine("RRULE:FREQ=$Cycle;INTERVAL=$interval")
      } ELSEIF (!$Cycle -or !$Interval) {
        Write-Output "Missing Cycle or Interval values. Exiting"
        $ExitCode = '1'
        BREAK
      }
    }
    [void]$sb.AppendLine("DESCRIPTION:" + $MachineInfoTextCalString)
    [void]$sb.AppendLine("SUMMARY:" + $Subject)
    [void]$sb.AppendLine("LOCATION:" + $Location)
    [void]$sb.AppendLine("TRANSP:TRANSPARENT")
    [void]$sb.AppendLine('END:VEVENT')
		
    [void]$sb.AppendLine('END:VCALENDAR')
    #endregion
    
    #region Create Folder if needed
    IF (!(Test-Path -Path "$FilePath" -PathType Container)) {
      New-Item -Path "$FilePath" -ItemType Directory -Force
      $ExitCode = $LASTEXITCODE
    }
    #endregion
		
    #region Test path created. If so, create ICS File
    IF (Test-Path -Path "$FilePath" -PathType Container) {
      $sb.ToString() | Out-File -FilePath "$FilePathAndName" -Force -ErrorAction Stop
    } ELSEIF (!(Test-Path -Path "$FilePath" -PathType Container)) {
      Write-Output 'Failed to create directory' -ErrorAction Stop
    }
    #endregion
    
    #region Output to custom PSObject  
    $Output = New-Object -TypeName PSObject
    $Properties = @{
      'FilePath' = $FilePathAndName
    }
    $Output | Add-Member -NotePropertyMembers $Properties
    $Output
    #endregion
		
  } CATCH {
    THROW $_
  }
#}