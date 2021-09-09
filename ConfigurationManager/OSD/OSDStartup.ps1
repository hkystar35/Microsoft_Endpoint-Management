#region FUNCTIONS

FUNCTION Connect-ConfigMgrWebService {
  <#
      .SYNOPSIS
      Session connection to web service
	
      .DESCRIPTION
      A detailed description of the Connect-ConfigMgrWebService function.
	
      .PARAMETER URI
      A description of the URI parameter.
	
      .EXAMPLE
      PS C:\> Connect-ConfigMgrWebService -URI $value1 -Secret $value2
	
      .NOTES
      Additional information about the function.
  #>
	
	[CmdletBinding()]
	[OutputType()]
	PARAM
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$URI
	)
	
	New-WebServiceProxy -Uri $URI
}

FUNCTION Release-COMObject ($ref) {
	
	[System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) | out-null
	[System.GC]::Collect()
	[System.GC]::WaitForPendingFinalizers()
	
}

FUNCTION Write-Log {
  <#
      .SYNOPSIS
      Create log file
	
      .DESCRIPTION
      Logs messages in Configuration Manager-specific format for easy cmtrace.exe reading
	
      .PARAMETER Message
      Value added to the log file.
	
      .PARAMETER Level
      Severity for the log entry.
	
      .PARAMETER FileName
      Name of the log file that the entry will written to.
	
      .PARAMETER LogsDirectory
      A description of the LogsDirectory parameter.
	
      .EXAMPLE
        PS C:\> Write-Log -Message 'Value1'
	
      .NOTES
      Additional information about the function.
  #>
	
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true,
			HelpMessage = 'Value added to the log file.')]
		[ValidateNotNullOrEmpty()]
		[string]$Message,
		
		[Parameter(Mandatory = $false,
			HelpMessage = 'Severity for the log entry.')]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('Error', 'Warn', 'Info')]
		[string]$Level = "Info",
		
		[Parameter(Mandatory = $false,
			HelpMessage = 'Name of the log file that the entry will written to.')]
		[ValidateNotNullOrEmpty()]
		[string]$FileName = "$($ScriptName).log",
		
		[string]$LogsDirectory = "$env:windir\Logs"
	)
	
	# Determine log file location
	IF ($FileName.Length -le 4) {
		$FileName = "GenericScriptLog_$(Get-Date -Format yyyy-MM-dd)$FileName"
	}
	$LogFilePath = Join-Path -Path $LogsDirectory -ChildPath $FileName
	
	# Construct time stamp for log entry
	IF (-not (Test-Path -Path 'variable:global:TimezoneBias')) {
		[string]$global:TimezoneBias = [System.TimeZoneInfo]::Local.GetUtcOffset((Get-Date)).TotalMinutes
		IF ($TimezoneBias -match "^-") {
			$TimezoneBias = $TimezoneBias.Replace('-', '+')
		}
		ELSE {
			$TimezoneBias = '-' + $TimezoneBias
		}
	}
	$Time = -join @((Get-Date -Format "HH:mm:ss.fff"), $TimezoneBias)
	
	# Construct date for log entry
	$Date = (Get-Date -Format "MM-dd-yyyy")
	
	# Construct context for log entry
	$Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
	
	# Switch Severity to number
	SWITCH ($Level) {
		"Info"	{
			$Severity = 1
		}
		"Warn"  {
			$Severity = 2
		}
		"Error" {
			$Severity = 3
		}
		default {
			$Severity = 1
		}
	}
	
	# Construct final log entry
	$LogText = "<![LOG[$($Message)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""$($component)"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	
	# Add value to log file
	TRY {
		Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop -WhatIf:$false
	}
	CATCH [System.Exception] {
		Write-Warning -Message "Unable to append log entry to $($FileName) file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
	}
}

FUNCTION Set-TSEnvironment {
	[CmdletBinding()]
	[OutputType([System.MarshalByRefObject])]
	PARAM ()
	
	New-Object -ComObject Microsoft.SMS.TSEnvironment
}

FUNCTION Get-NextComputerName {
  <#
      .SYNOPSIS
      Gets next available computer name from ConfigMgr
	
      .DESCRIPTION
      A detailed description of the Get-NextComputerName function.
	
      .PARAMETER WebService
      A description of the WebService parameter.
	
      .PARAMETER Secret
      A description of the Secret parameter.
	
      .PARAMETER Device_SerialNumber
      A description of the Device_SerialNumber parameter.
	
      .EXAMPLE
      PS C:\> Get-NextComputerName
	
      .NOTES
      Additional information about the function.
  #>
	
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $false,
			ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		$WebService = $WebService,
		
		[ValidateNotNullOrEmpty()]
		[string]$Secret = $secret,
		
		[string]$Device_SerialNumber = $Device_Info.Device_SerialNumber,
		
		[string]$Device_VirtualMachine = $Device_Info.Device_VirtualMachine
	)
	
	# Get location prefix
	$Prefix = Get-DeviceLocationPrefix
	Write-Verbose -Message "Device Prefix: $Prefix"
	
	# Truncate Serial Number
	$SerialNumber = $Device_SerialNumber.Substring(0, $(IF ($Device_SerialNumber.Length -lt 8) {
				$Device_SerialNumber.Length
			}
			ELSE {
				8
			}))
	Write-Verbose -Message "Serial Number: $SerialNumber"
	# Set Serial Number to virtual platform if needed
	IF ($Device_VirtualMachine -eq $true) {
		Write-Verbose -Message "Device is virtual: TRUE"
		$SerialNumber = $Device_VirtualMachine
		Write-Verbose -Message "Virtual Serial Number: $SerialNumber"
	}
	ELSE {
		Write-Verbose -Message "Device is virtual: FALSE"
	}
	
	# Set starting name
	$StartingName = $Prefix + '-' + $SerialNumber
	Write-Verbose -Message "Starting Name: $StartingName"
	
	# Get next available increment number from ConfigMgr
	$NextAvailableIncrement = $WebService.GetCMFirstAvailableNameSequence($Secret, 2, $StartingName)
	## if above returns value, use it. Otherwise skip. 
	IF ($NextAvailableIncrement) {
		Write-Verbose -Message "Found existing machine name: $StartingName"
		$NextComputerName = $StartingName + '-' + $NextAvailableIncrement
		Write-Verbose -Message "Next available machine name: $NextComputerName"
	}
	ELSE {
		$NextComputerName = $StartingName
	}
	
	$NextComputerName.ToUpper()
	Write-Verbose -Message "Final machine name: $NextComputerName"
}

FUNCTION Get-DeviceInfo {
  <#
      .SYNOPSIS
      Gets hardware info for local device
	
      .DESCRIPTION
      A detailed description of the Get-DeviceInfo function.
	
      .EXAMPLE
        PS C:\> Get-DeviceInfo
	
      .NOTES
      Additional information about the function.
  #>
	
	[OutputType([pscustomobject])]
	PARAM ()
	
	$BIOS = Get-CimInstance -ClassName Win32_BIOS
	$ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
	$ComputerSystemProduct = Get-CimInstance -ClassName Win32_ComputerSystemProduct
	
	[pscustomobject]@{
		Device_SerialNumber = $BIOS.SerialNumber
		Device_Manufacturer = $BIOS.Manufacturer
		Device_SKU		    = $ComputerSystem.SystemSKUNumber
		Device_BIOSversion  = $BIOS.SMBIOSBIOSVersion
		Device_ModelName    = SWITCH ($BIOS.Manufacturer) {
			{
				$_ -match 'Lenovo'
			} {
				$ComputerSystemProduct.Version
			}
			default {
				$ComputerSystem.Model
			}
		}
		Device_ModelNumber  = SWITCH ($BIOS.Manufacturer) {
			{
				$_ -match 'Lenovo'
			} {
				$ComputerSystem.Model.Substring(0, 4)
			}
			default {
				$ComputerSystem.Model
			}
		}
		Device_VirtualMachine = SWITCH ($ComputerSystem.Model) {
			{
				$_ -match 'Virtual Machine'
			} 	{
				'HyperV'
			}
			{
				$_ -match 'VMware'
			} 			{
				'VMware'
			}
			{
				$_ -match 'VirtualBox'
			} 		{
				'VBox'
			}
			default {
				$false
			}
		}
	}
}

FUNCTION Get-DeviceLocationPrefix {
  <#
      .SYNOPSIS
      Get device name prefix based on AD Site name
	
      .DESCRIPTION
      Get device name prefix based on AD Site name
	
      .PARAMETER WebService
      A description of the WebService parameter.
	
      .PARAMETER Secret
      A description of the Secret parameter.
	
      .PARAMETER ForestName
      A description of the ForestName parameter.
	
      .EXAMPLE
      PS C:\> Get-DeviceLocationPrefix
	
      .NOTES
      Additional information about the function.
  #>
	
	[CmdletBinding()]
	[OutputType([string])]
	PARAM
	(
		[Parameter(Mandatory = $false,
			ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		$WebService = $WebService,
		
		[ValidateNotNullOrEmpty()]
		[string]$Secret = $secret,
		
		[ValidateNotNullOrEmpty()]
		[string]$ForestName = $DNSsuffix
	)
	
	BEGIN {
		
	}
	PROCESS {
		
		$IPv4 = Get-CimInstance -ClassName win32_networkadapterconfiguration | Where-Object {
			$_.IPEnabled -eq $true
		} | Sort-Object -Property ipconnectionmetric -Descending | Select-Object -First 1 -Property @{
			L			    = "IPv4"; E = {
				$_.IPAddress[0]
			}
		}
		
		$ADSiteName = $WebService.GetADSiteNameByIPAddress($Secret, $ForestName, $IPv4.IPv4)
		SWITCH ($ADSiteName) {
			'Norwich' {
				'NOR'
			}
			'SouthED' {
				'SED'
			}
			'NYCSohoCafe' {
				'NYC'
			}
			'NYCSohoSalesOffice' {
				'NYC'
			}
			'TwinFalls' {
				'TWF'
			}
			'Australia' {
				'AUS'
			}
			'Azure' {
				'AZ'
			}
			default {
				'REM' # Remote
			}
		}
	}
	END {
	}
}

FUNCTION Validate-UserName {
	[CmdletBinding()]
	PARAM
	(
		[ValidateNotNullOrEmpty()]
		$UserName
	)
	
	#TODO: Place script here
}

FUNCTION Get-CMASApplications {
  <#
      .SYNOPSIS
      Get applications via Admin Service
	
      .DESCRIPTION
      Queries the admin service for a list of all applications
	
      .PARAMETER AdminServiceURI
      FQDN of the Primary Site server.
	
      .PARAMETER Creds
      A description of the Creds parameter.
	
      .EXAMPLE
      PS C:\> Get-CMASApplication
	
      .NOTES
      Additional information about the function.
  #>
	
	[CmdletBinding()]
	[OutputType([pscustomobject])]
	PARAM
	(
		[ValidateNotNullOrEmpty()]
		[string]$AdminServiceURI = $AdminServiceURI,
		
		[ValidateNotNullOrEmpty()]
		[pscredential]$Creds
	)
	
	$FullURI = $AdminServiceURI + 'Application'
	Invoke-RestMethod -Method GET -Uri $FullURI -UseDefaultCredentials
}

FUNCTION Get-AdminSvcAccountCreds {
	[CmdletBinding()]
	[OutputType([pscredential])]
	PARAM
	(
		[ValidateNotNullOrEmpty()]
		$UserName = (Get-TSvariableValue -TSvariable '__AdminSvc_UserName'),
		
		[ValidateNotNullOrEmpty()]
		$Password = (Get-TSvariableValue -TSvariable '__AdminSvc_Password')
	)
	
	
	New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, (ConvertTo-SecureString -String $Password -AsPlainText -Force)
}

FUNCTION Set-TSAppInstallVariable {
	[CmdletBinding()]
	PARAM
	(
		[string[]]$Names
	)
	
	
	FOREACH ($Name IN $Names) {
		
	}
}

FUNCTION Set-MSOfficeInstall {
	[CmdletBinding()]
	PARAM ()
	
	#TODO: Place script here
}

FUNCTION Test-DomainPSCredentials {
  <#
      .SYNOPSIS
      Tests PScredentials against specified domain
		
      .DESCRIPTION
      A detailed description of the Test-DomainPSCredentials function.
		
      .PARAMETER PSCredential
      A description of the PSCredential parameter.
		
      .PARAMETER Domain
      Domain name
		
      .PARAMETER TopLevelDomain
      Top Level Domain
		
      .EXAMPLE
      $Creds = Get-Credentil
      $Creds | Test-DomainPSCredentials -Domain 'AF' -TLD 'LAN'
      $true
		
      .NOTES
		
	
  #>
	
	[CmdletBinding()]
	[OutputType([bool])]
	PARAM
	(
		[Parameter(Mandatory = $true,
			ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[pscredential]$PSCredential,
		
		[Parameter(Mandatory = $true,
			HelpMessage = 'Domain name without suffix, like google or yahoo')]
		[ValidatePattern('[a-zA-Z0-9]')]
		[ValidateNotNullOrEmpty()]
		[string]$Domain,
		
		[Parameter(Mandatory = $true,
			HelpMessage = 'suffix to a domain, like com, org, gov')]
		[ValidatePattern('[a-zA-Z0-9]')]
		[ValidateNotNullOrEmpty()]
		[Alias('TLD')]
		[string]$TopLevelDomain
	)
	
	BEGIN {
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
	}
	PROCESS {
		TRY {
			$ADSIstring = "LDAP://DC=$($Domain), DC=$($TopLevelDomain)"
			$ADSI = New-Object system.DirectoryServices.DirectoryEntry($ADSIstring, $($PSCredential.UserName), $($PSCredential.GetNetworkCredential().password))
			IF ($ADSI.Name -eq $Domain) {
				RETURN $true
			}
			ELSE {
				RETURN $false
			}
		}
		CATCH {
			Write-Log -Message "<error message>" -Severity 3 -Source ${CmdletName}
		}
	}
	END {
		Release-COMObject -ref $ADSI
	}
}

FUNCTION Set-OSDCOMPUTERNAME {
  <#
      .SYNOPSIS
      Sets 'OSDCOMPUTERNAME' Task Sequence Variable
	
      .DESCRIPTION
      A detailed description of the Set-OSDCOMPUTERNAME function.
	
      .PARAMETER OSDCOMPUTERNAME
      Value for computer name
	
      .PARAMETER TSEnv
      TSEnv com-object variable
	
      .EXAMPLE
      PS C:\> Set-OSDCOMPUTERNAME -ComputerName 'bobsPC'
	
      .NOTES
      Additional information about the function.
  #>
	
	[CmdletBinding()]
	PARAM
	(
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
		
		$TSEnv = $TSEnv
	)
	
	$TSEnv.Value('OSDCOMPUTERNAME') = $ComputerName
}

FUNCTION Get-OSDCOMPUTERNAME {
  <#
      .SYNOPSIS
      Gets 'OSDCOMPUTERNAME' Task Sequence Variable
	
      .PARAMETER TSEnv
      TSEnv com-object variable
	
      .EXAMPLE
      PS C:\> Get-OSDCOMPUTERNAME -TSEnv $TSEnv
	
      .NOTES
  #>
	
	[CmdletBinding()]
	PARAM
	(
		[ValidateNotNullOrEmpty()]
		$TSEnv = $TSenv
	)
	
	$TSEnv.Value('OSDCOMPUTERNAME')
}

FUNCTION Get-TSvariableValue {
  <#
      .SYNOPSIS
      Gets value of sepcified Task Sequence variable
	
      .DESCRIPTION
      A detailed description of the Get-TSvariableValue function.
	
      .PARAMETER TSvariable
      A description of the TSvariable parameter.
	
      .PARAMETER TSEnv
      A description of the TSEnv parameter.
	
      .EXAMPLE
      PS C:\> Get-TSvariableValue
	
      .NOTES
      Additional information about the function.
  #>
	
	[CmdletBinding()]
	[OutputType([string])]
	PARAM
	(
		[ValidateNotNullOrEmpty()]
		[string]$TSvariable,
		
		[ValidateNotNullOrEmpty()]
		$TSEnv = $TSenv
	)
	
	$TSEnv.Value("$($TSvariable)")
}

FUNCTION Set-TSvariableValue {
  <#
      .SYNOPSIS
      Sets value of sepcified Task Sequence variable
	
      .DESCRIPTION
      A detailed description of the Get-TSvariableValue function.
	
      .PARAMETER TSvariable
      A description of the TSvariable parameter.
	
      .PARAMETER Value
      A description of the Value parameter.
	
      .PARAMETER TSEnv
      A description of the TSEnv parameter.
	
      .EXAMPLE
      PS C:\> Get-TSvariableValue
	
      .NOTES
      Additional information about the function.
  #>
	
	[CmdletBinding()]
	PARAM
	(
		[ValidateNotNullOrEmpty()]
		[string]$TSvariable,
		
		[ValidateNotNullOrEmpty()]
		$Value,
		
		[ValidateNotNullOrEmpty()]
		$TSEnv = $TSenv
	)
	
	$TSEnv.Value = $TSvariable
	$TSEnv.Value("$($TSvariable)") = $Value
}

#endregion FUNCTIONS

#region Variables

#Global
$global:CMPrimaryServer = 'sccm-no-01.contoso.com'
$global:AdminServiceURI = "https://$($global:CMPrimaryServer)/AdminService/v1.0/"
$global:CMSiteCode = 'NOR'
$global:WebserviceURI = "http://sccmdp-no-01.contoso.com/ConfigMgrWebService/ConfigMgr.asmx"
#$global:Secret = '135de552-fd0b-4234-92d5-332ce44e3fc8'
$global:DNSsuffix = 'contoso.com'
$global:WebService = Connect-ConfigMgrWebService -URI $global:WebserviceURI
$global:Device_Info = Get-DeviceInfo
#$global:TSEnv = Set-TSEnvironment
$global:AdminSvc_Creds = Get-AdminSvcAccountCreds -UserName dd -Password dd

#temp delete these
#Set-TSvariableValue -TSvariable '__AdminSvc_UserName' -Value 'sccm.adminsvc.ro'
#Set-TSvariableValue -TSvariable '__AdminSvc_Password' -Value '8t]E-C}3+5_n[z/"'

#Other

#endregion Variables

#Device Name - handle empty prefix string, just in case

# Manual Device Name override

# Shared or Assigned
