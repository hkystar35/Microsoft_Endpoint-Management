<#
	.SYNOPSIS
		Generates a unique machine name for Active Directory
	
	.DESCRIPTION
		This can be used for OSD, Inventory, or Renaming of computers.
	
	.PARAMETER Email
		Provide valid email address.
	
	.PARAMETER Inventory
		Switch parameter to designate an Inventory name should be generated.
	
	.PARAMETER Location
		Validation Set to designate site where inventory machine is located.
	
	.PARAMETER Rename
		Designates attempt to rename current computer. Will prompt for credentials.
	
	.PARAMETER Reboot
		Force reboot without prompting.
	
	.PARAMETER TSVar
		A description of the TSVar parameter.
	
	.OUTPUTS
		string, string, string
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.155
		Created on:   	05/21/2019 11:06 AM
		Created by:   	Nhkystar35
		Organization: 	contoso
		Filename:		Create-NewADComputerName.ps1
		===========================================================================
#>
[CmdletBinding(DefaultParameterSetName = 'Email')]
[OutputType([string], ParameterSetName='Email')]
[OutputType([string], ParameterSetName='Inventory')]
param
(
	[Parameter(ParameterSetName = 'Email',
			   Mandatory = $true)][ValidatePattern('^[a-zA-Z0-9.!£#$%&''^_`{}~-]+@contoso.com$')][ValidateNotNullOrEmpty()][string]$Email,
	[Parameter(ParameterSetName = 'Inventory',
			   Mandatory = $false)][switch]$Inventory,
	[Parameter(ParameterSetName = 'Inventory',
			   Mandatory = $true)][ValidateSet('FL', 'ID', 'IL')][ValidateNotNullOrEmpty()][string]$Location,
	[Parameter(ParameterSetName = 'Rename')][switch]$Rename = $false,
	[Parameter(ParameterSetName = 'Rename')][switch]$Reboot = $false,
	[switch]$TSVar = $false
)

BEGIN {
	$InvocationInfo = $MyInvocation
    [System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
    #[string]$ScriptFullPath = $ScriptFileInfo.FullName
    #[string]$ScriptNameFileExt = $ScriptFileInfo.Name
    [string]$ScriptName = $ScriptFileInfo.BaseName
    #[string]$scriptRoot = Split-Path $ScriptFileInfo
    $testPath = "$($env:windir)\Logs\$($ScriptName).log"
	
	#region FUNCTION Write-Log
	FUNCTION Write-Log {
		[CmdletBinding()]
		PARAM
		(
			[Parameter(Mandatory = $true,
					   ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][Alias("LogContent")][string]$Message,
			[Parameter(Mandatory = $false)][Alias('LogPath')][string]$Path = "$($env:windir)\Logs\$($ScriptName).log",
			[Parameter(Mandatory = $false)][ValidateSet("Error", "Warn", "Info")][string]$Level = "Info",
			[Parameter(Mandatory = $false)][switch]$NoClobber,
			[Parameter(Mandatory = $false)][int]$MaxLogSize = '2097152'
		)
		
		BEGIN {
			# Set VerbosePreference to Continue so that verbose messages are displayed. 
			$VerbosePreference = 'SilentlyContinue'
			$FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		}
		PROCESS {
			
			# Test if log exists
			IF (Test-Path -Path $Path -PathType Leaf) {
				$FilePath = Get-Item -Path $Path
				IF ($NoClobber) {
					Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
					RETURN
				}
				IF ($FilePath.Length -gt $MaxLogSize) {
					Rename-Item -Path $FilePath.FullName -NewName $($FilePath.BaseName).log_ -Force
				}
			} ELSEIF (!(Test-Path $Path -PathType Leaf)) {
				Write-Verbose "Creating $Path."
				$NewLogFile = New-Item $Path -Force -ItemType File
			}
			# Write message to error, warning, or verbose pipeline and specify $LevelText 
			SWITCH ($Level) {
				'Error' {
					Write-Error $Message
					$LevelText = 'ERROR:'
				}
				'Warn' {
					Write-Warning $Message
					$LevelText = 'WARNING:'
				}
				'Info' {
					Write-Verbose $Message
					$LevelText = 'INFO:'
				}
			}
			
			# Write log entry to $Path 
			"$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append -Force
		}
		END {
		}
	}
	#endregion FUNCTION Write-Log$Variable1$
	
}
PROCESS {
	Write-Log -Message "----------------------- Begin Script $($ScriptName) -----------------------"
	
	#region FUNCTION New-ADComputerNameUser
	FUNCTION New-ADComputerNameUser {
<#
	.SYNOPSIS
		Creates AD Computer name based on User's email address and AD info
	
	.DESCRIPTION
		Uses email input for target user to query AD and generate next-available machine name
	
	.PARAMETER Email
		Provide valid email address.
	
	.PARAMETER MaxNameLength
		Maximum length of name to return.
	
	.PARAMETER Pattern
		Regex pattern for valid characters in name.
	
	.EXAMPLE
		PS C:\> Create-NewADComputerName -Email 'hkystar35@contoso.com' -Pattern '[^a-zA-Z0-9]' -MaxNameLength 15
		Returns output string NIChkystar35
	
	.OUTPUTS
		string
	
	.NOTES
		Additional information about the function.
#>
		
		[CmdletBinding()]
		PARAM
		(
			[Parameter(Mandatory = $true)][ValidatePattern('^[a-zA-Z0-9.!£#$%&''^_`{}~-]+@contoso.com$')][ValidateNotNullOrEmpty()][string]$Email,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][int]$MaxNameLength,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][regex]$Pattern
		)
		Write-Log -Message "Creating Machine Name based off Email Address."
		TRY {
			# Query AD for user info based on email
			Write-Log -Message "Searching for email $($Email) in AD via WMI LDAP query."
			$DisplayName = Get-WmiObject -Namespace 'root\directory\ldap' -Query "Select DS_displayName from DS_User where DS_mail = '$Email'" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DS_displayName -ErrorAction SilentlyContinue
			IF ($DisplayName) {
				Write-Log -Message "Found $DisplayName. Creating machine name."
				# Parse name and query AD for dupilicate; increment if needed
				# Use Display Name and remove invalid characters
				$MachineName = (($DisplayName -replace $pattern, '') -replace ' ', '').ToUpper()
				# Trim string to max length	
				$MachineName = $MachineName.Substring(0, [math]::Min($MaxNameLength, $MachineName.Length))
				# set counter	
				$i = 1
				# Set starting machine name
				$t = $MachineName
				# loop through names until a valid name is found
				WHILE (Get-WmiObject -Namespace 'root\directory\ldap' -Query "Select DS_cn from DS_computer where DS_cn = '$t'" -ErrorAction SilentlyContinue) {
					IF ($MachineName.Length -ge $MaxNameLength) {
						$t = $MachineName.Substring(0, $MachineName.Length - ($MachineName.Length - $MaxNameLength + $i.ToString().Length)) + $i
					} ELSEIF ($MachineName.Length -lt $MaxNameLength) {
						$t = $MachineName + $i
					}
					$i++
				}
				$MachineName = $t
				Write-Log -Message "Unique Machine Name: $MachineName"
				
				$MachineName
				
			} ELSEIF (!$DisplayName) {
				$NoEmailFound_Error = "No user found with email address $($Email). Exiting."
				Write-Log -Message "$NoEmailFound_Error" -Level Error
				THROW $NoEmailFound_Error
			}
		} CATCH {
			$Line = $_.InvocationInfo.ScriptLineNumber
			Write-Log -Message "Error: $_" -Level Error
			Write-Log -Message "Error: on line $line" -Level Error
		}
	}
	#endregion FUNCTION New-ADComputerNameUser
	
	#region FUNCTION New-ADComputerNameInventory
	FUNCTION New-ADComputerNameInventory {
<#
	.SYNOPSIS
		A brief description of the Create-NewADComputerName function.
	
	.DESCRIPTION
		Uses Location and local WMI computer info to generate name.
	
	.PARAMETER Location
		Sets location of Inventory machine
	
	.PARAMETER MaxNameLength
		Maximum length of name to return.
	
	.EXAMPLE
		PS C:\> Create-NewADComputerName -L IL -MaxNameLength 15
		Returns output string IL-
	
	.OUTPUTS
		string
	
	.NOTES
		Additional information about the function.
#>
		
		[CmdletBinding()]
		PARAM
		(
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][ValidateSet('IL', 'FL', 'ID')][Alias('L')][string]$Location,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][int]$MaxNameLength
		)
		Write-Log -Message "Creating Inventory Machine Name."
		# Get Machine info
		
		$ModelInfo = Get-WmiObject -Class Win32_ComputerSystemProduct
		$ModelNumber = ($ModelInfo.Name).substring(0, 4)
		$ModelName = $ModelInfo.Version -split (' ')
		Write-Log -Message "Found Model Name and Number: $ModelName & $ModelNumber. Searching for unique name."
		IF ($ModelName[0] -like "*Think*" -and $ModelName.count -eq 2) {
			$ModelName = $ModelName[1 .. $($ModelName.count - 1)]
		} ELSEIF ($ModelName[0] -like "*Think*" -and $ModelName.count -ge 3) {
			$ModelName_Build = ''
			$ModelName | Where-Object{
				$_ -notlike "*think*"
			} | ForEach-Object{
				$ModelName_Build += $_.substring(0, 1)
			}
			$ModelName = $ModelName_Build
		}
		
		$MachineName = 'INV-' + $ModelName + '-' + $Location + '-'
		
		$i = 1
		$t = $MachineName + $i.ToString('00')
		
		WHILE (Get-WmiObject -Namespace 'root\directory\ldap' -Query "Select DS_cn from DS_computer where DS_cn = '$t'" -ErrorAction SilentlyContinue) {
			IF ($MachineName.Length -ge $MaxNameLength) {
				$t = $MachineName.Substring(0, $MachineName.Length - ($MachineName.Length - $MaxNameLength + $i.ToString().Length)) + $i.ToString('00')
			} ELSEIF ($MachineName.Length -lt $MaxNameLength) {
				$t = $MachineName + $i.ToString('00')
			}
			$i++
		}
		$MachineName = $t
		
		Write-Log -Message "Unique Machine Name: $MachineName"
		$MachineName
	}
	#endregion FUNCTION New-ADComputerNameInventory
	TRY{
	# Variables
	$MaxNameLength = '15'
	$pattern = '[^a-zA-Z0-9]'
	
	IF ($Email) {
		Write-Log -Message "Email switch used, calling User function."
		$ADMachineName = New-ADComputerNameUser -Email $Email -MaxNameLength $MaxNameLength -Pattern $pattern
	} ELSEIF ($Inventory) {
		Write-Log -Message "Inventory switch used, calling Inventory function."
		$ADMachineName = New-ADComputerNameInventory -Location $Location -MaxNameLength $MaxNameLength
	}
		
	IF ($TSVar) {
		$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment; 
  		$tsenv.Value('SystemName') = $ADMachineName
        Write-Log -Message "Making TSvar Name: `"SystemName`" with value: `"$($ADMachineName)`""
	}
		
	# Return value to pipeline
	$ADMachineName
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
	    Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
	}
}
END {
	Write-Log -Message "----------------------- End Script $($ScriptName) -----------------------"
}
