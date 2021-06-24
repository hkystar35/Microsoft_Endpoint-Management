<#
	.SYNOPSIS
		Updates OSD FrontEnd's HWModels.txt for validating hardware models
	
	.DESCRIPTION
		OSD FrontEnd uses a Pre-Flight check to validate the hardware being imaged is approved by
		using a text file hosted on a file share or web service.
		
		This script will update that text file based on the following criteria:
		- Gathering all Packages from ConfigMgr that match the Package Name starting with "Drivers - "
		- Taking all the MIFName properties from the above package list and updating the HWModels.txt file
		- Currently accounts for a known bug where model names in the file are case-sensitive, so this attempts to creat
		as many case iterations as mossible to ensure valid hardware isn't falsely rejected
		Bug Report: https://github.com/MSEndpointMgr/ConfigMgrOSDFrontEnd/issues/4
		- Archives the previous HWModels.txt files for retention
		- Supports ShouldProcess to identify models needing updated
		
		This is designed to be triggered off of a Status Filter Rule. I like using messageID 2330 from SMS_DISTRIBUTION_MANAGER because it triggers
		on completion of distribution to each DP and the script is very quick to dismiss non-Driver packages  and unfinished Driver packages.
		For more Status messages to try, check out https://github.com/KlausBilger/SCCM_MsgID for a great Excel sheet
		
		THIS COULD CAUSE ISSUES IN LARGE ENVIRONMENTS. I use this in a flat hierarchy with <4k endpionts and 4 DPs. TEST TEST TEST.
	
	.PARAMETER statusFilterDescription
		Captures the full message description from Status Filter Rule.
		Status Filter value for Message ID 2330: "%msgdesc"
		NOTE: Not used in this script yet. Haven't found a good use for it other than logging.
	
	.PARAMETER packageName
		Name of the ConfigMgr Package.
		Status Filter value for Message ID 2330: %msgis01
	
	.PARAMETER packageID
		PackageID of the ConfigMgr Package.
		Status Filter value for Message ID 2330: %msgis02
	
	.PARAMETER CM_SiteCode
		Site code.
		Status Filter value for Message ID 2330: %sc
	
	.PARAMETER CM_ProviderMachineName
		Machine Name of AdminService provider.
		Status Filter value for Message ID 2330: %sitesvr
		NOTE: If your SMS Provider is on another machine, use that instead of %sitesvr
	
	.PARAMETER IISHWmodelsFile
		UNC path to the HWModels.txt file
	
	.PARAMETER Model_cases
		Array of Model lines used to mitigate the case-sensitive issue in OSD FronEnd.
		Set this inside the script, it's much easier than adding it to the command line string for Status Filter Rules
		Once the bug is fixed, this paramter will no longer be needed.
	
	.EXAMPLE
		.\Update-OSDFE_hwmodels.ps1 -packageName 'Drivers - Dell OptiPlex 3040 - Windows 10 x64' -packageID 'P0100111'
		Checks that the name matches '^Drivers *', that the Package ID exists, validates the package is fully distributed, then updates HWModels.txt by adding all missing models from package list (not just the one passed in parameters).
	
	.EXAMPLE
		.\Update-OSDFE_hwmodels.ps1 -packageName 'Drivers - Dell OptiPlex 3040 - Windows 10 x64' -packageID 'P0100111' -Whatif
		Checks that the name matches '^Drivers *', that the Package ID exists, validates the package is fully distributed, then logs that the HWModels.txt would be updated if the WHATIF parameter was not used.
	
	.EXAMPLE
		.\Update-OSDFE_hwmodels.ps1 -packageName 'BIOS - Dell OptiPlex 3040' -packageID 'P0100555'
		Checks that the name matches '^Drivers *', match fails, script exits.
	
	.EXAMPLE
		.\Update-OSDFE_hwmodels.ps1 -packageName 'Drivers - Dell OptiPlex 3040 - Windows 10 x64' -packageID 'P0100xxx'
		Checks that the name matches '^Drivers *', that the Package ID exists, package does not exist, script exits.
	
	.EXAMPLE
		.\Update-OSDFE_hwmodels.ps1 -packageName 'Drivers - Dell OptiPlex 3040 - Windows 10 x64' -packageID 'P0100111'
		(Assuming package distribution still in progress)
		Checks that the name matches '^Drivers *', that the Package ID exists, validates the package is fully distributed, distribution incomplete, script exits.
	
	.EXAMPLE
		Status Filter Rule Sample
		Create a new Status Filter Rule
		General
		Component: SMS_DISTRIBUTION_MANAGER
		Message ID: 2330
		Actions > Run a Program:
		C:\Windows\system32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File C:\StatusFilterScripts\Update-OSDFE_hwmodels.ps1 -CM_ProviderMachineName %sitesvr -CM_SiteCode %sc -statusFilterDescription "%msgdesc" -packageID %msgis02 -packageName %msgis01
	
	.NOTES
		2021/06/22  - Updated Get-CMASPackageStatus function. Uses $_.OverallStatus property to tell if package is fully distributed to all targeted DPs
		            - Removed Set-Location, not needed since ConfigMgr PowerShell module not in use
		            - Updated description info
                - Updated AdminService function descriptions
		2021/06/11  - Modifying to use new Status Filter Message ID - 2301 for completed distribution of package
		2021/04/02  - Script checks for "Drivers *" in name and skips update if it's a different Package naming convention
		            - Checks that discovered Package is distributed to at least 1 DP, else skip update
		            - Waits up to 1 hour for distribution to complete before timing out on update
		2021/04/01  - Fixed Write-Log function
		            - Added functions to use AdminService instead of ConfigMgr PowerShell module
		
		===========================================================================
		
		Created on:   	2020-06-09 11:12:47
		Updated on:   	2021-06-23 10:46:06
		Created by:   	Nicolas Wendlowsky

    Filename:		    Update-OSDFE_hwmodels.ps1
		===========================================================================
#>
[CmdletBinding(DefaultParameterSetName = 'packageInfoName',
	SupportsShouldProcess = $true)]
PARAM
(
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]$statusFilterDescription,
	
	[Parameter(ParameterSetName = 'packageInfoName',
		Mandatory = $true)][ValidateNotNullOrEmpty()]$packageName,
	
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()]$packageID,
	
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$CM_SiteCode = 'P01',
	
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$CM_ProviderMachineName = 'AdminService-01.contoso.com',
	
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$IISHWmodelsFile = '\\WebServer.contoso.com\c$\inetpub\ConfigMgr WebService\bin\OSDFE\HWModels.txt',
	
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string[]]$Model_cases = @(
		'Latitude',
		'OptiPlex',
		'Optiplex',
		'Precision',
		'Surface',
		'surface',
		'ThinkCentre',
		'Thinkcentre',
		'ThinkPad',
		'Thinkpad',
		'ThinkStation',
		'Thinkstation',
		'Virtual Machine',
		'Virtual machine',
		'VMware7,1',
		'VMWare7,1',
		'VMware Virtual Platform',
		'VMware virtual Platform',
		'VMware virtual platform',
		'Vmware Virtual Platform',
		'Vmware virtual Platform',
		'Vmware virtual platform'
	)
)
BEGIN {
	$InvocationInfo = $MyInvocation
	[System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
	[string]$ScriptFullPath = $ScriptFileInfo.FullName
	[string]$ScriptNameFileExt = $ScriptFileInfo.Name
	[string]$ScriptName = $ScriptFileInfo.BaseName
	[string]$scriptRoot = Split-Path $ScriptFileInfo
	
	# Set TLS
	[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
	

  [string]$Script:Component = 'Begin-Script'
	#region FUNCTION Write-Log
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
				HelpMessage = 'Value added to the log file.')][ValidateNotNullOrEmpty()][string]$Message,
			
			[Parameter(Mandatory = $false,
				HelpMessage = 'Severity for the log entry.')][ValidateSet('Error', 'Warn', 'Info')][ValidateNotNullOrEmpty()][string]$Level = "Info",
			
			[Parameter(Mandatory = $false,
				HelpMessage = 'Name of the log file that the entry will written to.')][ValidateNotNullOrEmpty()][string]$FileName = "$($ScriptName).log",
			
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
			"Warn" {
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
	#endregion FUNCTION Write-Log
	
	Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
	
	#region FUNCTION Get-CMASPackages
	FUNCTION Get-CMASPackages {
    <#
	.SYNOPSIS
		Get Packages from AdminService
	
	.DESCRIPTION
		Get all packages from AdminService
	
	.PARAMETER AdminServerLocalFQDN
		ConfigMgr AdminService hostname FQDN
	
	.PARAMETER All
		Default: $true
		Gets all packages
	
	.PARAMETER nameStartsWith
		Filters start of package name.
		Implies wildcard (*) used on end of input string
	
	.PARAMETER nameContains
		Filters content of package name.
		Implies wildcard (*) at beginning and end of input string.
	
	.EXAMPLE
		PS C:\> Get-CMASPackages -All
	
	.EXAMPLE
		PS C:\> Get-CMASPackages -filteName "Drivers *"
	
	.NOTES
		Additional information about the function.
	#>
		
		[CmdletBinding(DefaultParameterSetName = 'packagesAll')]
		PARAM
		(
			[ValidateNotNullOrEmpty()][string]$AdminServerLocalFQDN = $CM_ProviderMachineName,
			
			[Parameter(ParameterSetName = 'packagesAll',
				Mandatory = $true)][switch]$All = $true,
			
			[Parameter(ParameterSetName = 'pacakgesNameStartsWith',
				Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameStartsWith,
			
			[Parameter(ParameterSetName = 'pacakgesNameContains',
				Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameContains
		)
		
		# Set logging component name
		$Component = $MyInvocation.MyCommand
		
		# AdminService URI
		$URI = 'https://{0}/AdminService/wmi/SMS_Package' -f $AdminServerLocalFQDN
		
		#$filter = (Name eq 'NORxxx123')
		IF ($nameContains) {
			$filterstring = '?$filter=contains(Name,''{0}'')' -f $nameContains
		}
		IF ($nameStartsWith) {
			$filterstring = '?$filter=startswith(Name,''{0}'')' -f $nameStartsWith
		}
		
		# Add filter to URI
		$URI = $URI + $filterstring
		
		Write-Log -Message "Querying REST API at $URI"
		$response = Invoke-RestMethod -Uri $URI -Method Get -UseDefaultCredentials -ErrorAction Stop
		IF ($response.value) {
			Write-Log -Message "   Found $($response.value.count) items"
			$response.value
		}
		ELSE {
			return $false
		}
	}
	#endregion FUNCTION Get-CMASPackages
	
	#region FUNCTION Get-CMASPackageStatus
	FUNCTION Get-CMASPackageStatus {
    <#
	.SYNOPSIS
		Gets distribution status of Packages using PackageID
	
	.DESCRIPTION
		Gets distribution status of Packages using PackageID
	
	.PARAMETER AdminServerLocalFQDN
		A description of the AdminServerLocalFQDN parameter.
	
	.PARAMETER PackageIDs
		String array of PackageIDs to query
	
	.EXAMPLE
			PS C:\> Get-CMASPackageStatus -PackageIDs $value1
	
	.NOTES
		Additional information about the function.
	#>
		
		[CmdletBinding()][OutputType([pscustomobject])]
		PARAM
		(
			[ValidateNotNullOrEmpty()][string]$AdminServerLocalFQDN = $CM_ProviderMachineName,
			
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$PackageIDs
		)
		
		# Set logging component name
		$Component = $MyInvocation.MyCommand
		
		# AdminService URI
		$URI = 'https://{0}/AdminService/wmi/SMS_PackageStatus' -f $AdminServerLocalFQDN
		
		# Create string for multiple PackageIDs
		$filterPackages = @(
			FOREACH ($PackageID IN $PackageIDs) {
				'PackageID eq ''{0}''' -f $PackageID
			}
		) -join ' or '
		$filterstring = '?$filter=({0})' -f $filterPackages
		
		# Add filter to URI
		$URI = $URI + $filterstring
		
		# Query AdminService
		Write-Log -Message "Querying REST API at $URI"
		$response = Invoke-RestMethod -Uri $URI -Method Get -UseDefaultCredentials -ErrorAction Stop
		
		# Hashtable for status values
		$packageStatusValue = @{
			0 = 'NONE'
			1 = 'SENT'
			2 = 'RECEIVED'
			3 = 'INSTALLED'
			4 = 'RETRY'
			5 = 'FAILED'
			6 = 'REMOVED'
			7 = 'PENDING_REMOVE'
		}
		
		# If there's a reponse, parse each PackageID
		FOREACH ($PackageID IN $PackageIDs) {
			Write-Log -Message "   Checking Distribution Status for PackageID $PackageID"
			IF ($response.value) {
				
				Write-Log -Message "   Content targeted to at least 1 Distribution Point"
				
				# Set Status values to custom properties
				$DPStatus = $response.value | Where-Object { $_.PackageID -eq $PackageID } | Select-Object -Property PackageID, `
				@{
					Label = "DistributionPoint";
					Expression = { (($_.PkgServer -split '\\\\')[1] -split '\\')[0] }
				}, `
				@{
					Label = "Status";
					Expression = { $packageStatusValue[$_.Status] }
				} `
				| Where-Object { -not [string]::IsNullOrEmpty($_.DistributionPoint) }
				
				# Check status
				IF (!$DPStatus) {
					# If null, not distributed
					$OverallStatus = 'CONTENT NOT DISTRIBUTED'
					Write-Log -Message "   Overall status $OverallStatus"
				}
				ELSEIF (![bool]($DPStatus | Where-Object { $_.Status -ne $packageStatusValue[3] })) {
					# If all DP status equal to "INSTALLED", consider the package 'INSTALLED'
					$OverallStatus = $packageStatusValue[3]
					Write-Log -Message "   Overall status $OverallStatus"
				}
				ELSE {
					# If any DP status is not "INSTALLED", consider the package 'NONE' (In Progress)
					$OverallStatus = $packageStatusValue[0]
					Write-Log -Message "   Overall status $OverallStatus"
				}
				
				[pscustomobject]@{
					PackageID = $PackageID
					OverallStatus = $OverallStatus
					DPStatus = $DPStatus
				}
			}
			ELSE {
				# If no valid response, set default and null values
				Write-Log -Message "   Package not found. Check PackageID."
				[pscustomobject]@{
					PackageID = $null
					OverallStatus = 'PACKAGEIDs NOT FOUND'
					DPStatus = $null
				}
			}
		}
	}
	#endregion FUNCTION Get-CMASPackageStatus
	
}
PROCESS {
	TRY {
		
		$Script:Component = 'Test-PackageInfo'
		
		# Filter for package names
		[regex]$packageNamePrefix = '^Drivers *'
		
		# Identify triggering package
		Write-Log -Message "Package Info: [$($packageName)] | [$($packageID)]"
		
		#region Check package name for name match
		IF ($packageName -match $packageNamePrefix) {
			Write-Log -Message "   Name matches filter, will query AdminService."
			# Query AdminService for all Packages
			
			$Script:Component = 'Query-AdminService'
			Write-Log -Message 'Getting existing CMPackages from AdminService'
			$cmPackages = Get-CMASPackages -nameStartsWith 'Drivers '
			
			# Check packgeID is found
			IF ($cmPackages.packageID -notcontains $packageID) {
				THROW "Package ID [$packageID] not found in package list. Exiting."
			}
			
			# Check that triggering package is finished distributing
			$packageStatus = Get-CMASPackageStatus -PackageIDs $packageID
			IF ($packageStatus.OverallStatus -eq 'INSTALLED') {
				Write-Log -Message "   Package content is fully distributed."
				# Get existing HWModels.txt file    
				$Script:Component = 'Get-FileContent'
				# Convert to Upper Case and get unique values
				[string[]]$HWModels_Current = (Get-Content -Path $IISHWmodelsFile.FullName).ToUpper() | Select-Object -Unique | Sort-Object
				Write-Log -Message "Current file found: $($IISHWmodelsFile.FullName)"
				Write-Log -Message "Current $($IISHWmodelsFile.Name) list of $($HWModels_Current.Count) supported models:"
				
				# Log each model for records, try grouping by model line   
				$UniquePrefixes = $HWModels_Current | ForEach-Object { ($_ -split ' ')[0] } | Get-Unique
				FOREACH ($UniquePrefix IN $UniquePrefixes) {
					$string = "[$UniquePrefix]`:`n"
					$string += ($HWModels_Current | Where-Object { $_ -match $UniquePrefix }) -join "`n"
					Write-Log -Message "   $string"
					Remove-Variable -Name String -ErrorAction SilentlyContinue -WhatIf:$false
				}
				
				$Script:Component = 'Parse-Packages'
				
				# Parse Packages for mifname values only, which house the computer model name
				$DriverPackageMifnames = ($cmPackages | Where-Object { $_.mifname -ne $null -and $_.mifname -ne '' -and $_.name -like "Drivers *" } | Select-Object -Unique -Property @{ L = "model"; E = { ($_.mifname -split ' Type')[0].Trim() } }).model | Sort-Object
				Write-Log -Message "Found $($DriverPackageMifnames.count) matching Driver Packages...(Note: these are NOT Driver Packs)"
				
				# Filter for unique mifname values
				Write-Log -Message "Gathering currently supported models"
				[string[]]$HWModels_New = $DriverPackageMifnames | Get-Unique
				Write-Log -Message "Found $($HWModels_New.count) unique Driver Packages"
				
				# Ensure that VM platform models are always added since they don't all have driver Packages
				[string[]]$ManulaAdd = ('Virtual Machine', 'VMware Virtual Platform', 'VMWare7,1').ToUpper() # Add Virtual Machine to ensure it's always there
				IF ($Compare = (Compare-Object $HWModels_New $ManulaAdd.ToUpper() | Where-Object { $_.SideIndicator -eq '=>' })) {
					$HWModels_New += $Compare.InputObject
					$UpdateList = $true
				}
				
				# Start creation of massive list of mixed-case model names
				$Script:Component = 'Set-TextCase'
				Write-Log -Message "Creating mixed-case list to handle known bug in OSD FrontEnd.`nSee 'https://github.com/MSEndpointMgr/ConfigMgrOSDFrontEnd/issues/4' for more."
				
				# lower case
				$HWModels_lower = $HWModels_New.ToLower()
				# UPPER case
				$HWModels_UPPER = $HWModels_New.ToUpper()
				# mIXeD CaSE
				$HWModels_New += FOREACH ($case IN $Model_cases) {
					$HWModels_New -replace "$case", "$case"
				}
				# Add them together
				$HWModels_New += $HWModels_lower
				$HWModels_New += $HWModels_UPPER
				
				# Remove case-matching duplcates
				$HWModels_New = $HWModels_New | Get-Unique
				Write-Log -Message "   List of $($HWModels_New.Count) created."
				
				# Start comparison for logging purposes
				$Script:Component = 'Parse-Models'
				Write-Log -Message "Parsing Model names"
				$Comparison = Compare-Object $HWModels_Current $HWModels_New -IncludeEqual | Sort-Object inputobject
				# Models found in existing HWModels.txt and newly generated list
				$Models_Equal = ($Comparison | Where-Object { $_.SideIndicator -like '==' }).InputObject
				# Models found only in newly generated list
				$Models_Adding = ($Comparison | Where-Object { $_.SideIndicator -like '=>' }).InputObject
				# Models found only in HWModels.txt, being removed
				$models_Removing = ($Comparison | Where-Object { $_.SideIndicator -like '<=' -and $ManulaAdd -notcontains $_.InputObject }).InputObject
				Write-Log -Message "   Count Models not changing: $($Models_Equal.count)"
				Write-Log -Message "   Count Models adding: $($Models_Adding.count)"
				SWITCH ($models_Removing.Count) {
					0
					{
						Write-Log -Message "   Count Models removing: $($models_Removing.count)"
					}
					
					{ $_ -ge 1 }
					{
						Write-Log -Message "   Count Models removing: $($models_Removing.count)" -Level Warn
						$models_Removing | ForEach-Object {
							Write-Log -Message "      $_" -Level Warn
						}
					}
				}
				
				# Update HWModels.txt file with new content
				$Script:Component = 'Modify-Files'
				IF ($Models_Equal.count -ne $HWModels_Current.count -or $UpdateList) {
					Write-Log -Message "$($IISHWmodelsFile.FullName) should be updated"
					IF ($PSCmdlet.ShouldProcess($($IISHWmodelsFile.FullName), $("Write file"; Write-Log -Message "What if: Performing the operation `"Write file`" on target `"$($IISHWmodelsFile.FullName)`"" -Level Warn))) {
						# Create new file name for archiving
						$IISHWModelsFile_ArchiveName = $IISHWmodelsFile.BaseName + '_{0}.old.txt' -f $(Get-Date -Format 'yyyyMMdd-HHmmss')
						$IISHWModelsFile_ArchiveFullName = Join-Path -Path $IISHWmodelsFile.Directory -ChildPath $IISHWModelsFile_ArchiveName
						
						# Copy current file to archive name
						Write-Log -Message "   Archiving $($IISHWmodelsFile.FullName) to $IISHWModelsFile_ArchiveFullName"
						
						$CopyOperation = Copy-Item -Path $($IISHWmodelsFile.FullName) -Destination $IISHWModelsFile_ArchiveFullName -PassThru -ErrorAction SilentlyContinue
						IF ($CopyOperation) {
							Write-Log -Message "   File successfully archived"
							
							# Write changes to file
							Write-Log -Message "   Writing changes to $($IISHWmodelsFile.FullName)"
							[System.IO.File]::WriteAllLines($IISHWmodelsFile.FullName, $HWModels_New)
							
							Write-Log -Message "   Changes complete: $($IISHWmodelsFile.FullName)"
						}
						ELSE {
							Write-Log -Message "   could not archive file. No changes being made to $($IISHWmodelsFile.Name)." -Level Error
						}
					}
				}
				ELSE {
					Write-Log -Message "   No changes needed for $($IISHWmodelsFile.FullName)"
				}
			}
			ELSE {
				Write-Log -Message "   Package content is either still in progress or needs to be distributed to at least 1 Distribution Point. Exiting." -Level Warn
			}
		}
		ELSE {
			Write-Log -Message "   Name does not match name filter [$packagenamePrefix], skipping update."
		}
		#endregion Check package name for name match
	}
	CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
	}
}
END {
	$Script:Component = 'End-Script'
	Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}