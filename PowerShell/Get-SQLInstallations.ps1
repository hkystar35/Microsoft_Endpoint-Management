<#
	.SYNOPSIS
		A brief description of the !Template.ps1 file.
	
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER ServerNameList
		comma-separated list of machine names
	
	.PARAMETER ServerNameFileContent
		Full path to CSV file containing ServerNames paired to IPAddresses
	
	.PARAMETER OutputFolder
		Destination folder for output file. File name is auto-generated.
	
	.PARAMETER SMTPServer
		A description of the SMTPServer parameter.
	
	.PARAMETER EmailAddresses
		Email addresses like 'you@domain.com','them@domain.com'
	
	.PARAMETER Input
		A description of the Input parameter.
	
	.NOTES
		===========================================================================
		
		Created on:   	4/16/2020 11:39:44
		Created by:   	hkystar35@contoso.com
		Organization: 	contoso
		Filename:	      Get-SQLInstallations.ps1
		===========================================================================
#>
[CmdletBinding(DefaultParameterSetName = 'ServerNameFile')]
PARAM
(
	[Parameter(ParameterSetName = 'ServerNamelist',
			   Mandatory = $true,
			   HelpMessage = 'List machine names like ''name1'',''name2''')][ValidateNotNullOrEmpty()][string[]]$ServerNameList = 'SCCM-NO-01',
	[Parameter(ParameterSetName = 'ServerNameFile',
			   Mandatory = $true,
			   HelpMessage = 'Must be a CSV file')][ValidateNotNullOrEmpty()][ValidatePattern('^.*\.(csv)$')][System.IO.FileInfo]$ServerNameFileContent,
	[Parameter(ParameterSetName = 'Output',
			   HelpMessage = 'Destination folder for output file. File name is auto-generated.')][ValidateNotNullOrEmpty()][System.IO.DirectoryInfo]$OutputFolder,
	[Parameter(ParameterSetName = 'Email',
			   Mandatory = $true)][ValidateNotNullOrEmpty()][string]$SMTPServer,
	[Parameter(ParameterSetName = 'Email',
			   Mandatory = $true,
			   HelpMessage = 'Email addresses like ''you@domain.com'',''them@domain.com''')][ValidateNotNullOrEmpty()][string[]]$EmailAddresses
)
BEGIN {
	$InvocationInfo = $MyInvocation
	[System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
	[string]$ScriptFullPath = $ScriptFileInfo.FullName
	[string]$ScriptNameFileExt = $ScriptFileInfo.Name
	[string]$ScriptName = $ScriptFileInfo.BaseName
	[string]$scriptRoot = Split-Path $ScriptFileInfo
	
	#region FUNCTION Write-Log
	FUNCTION Write-Log {
		PARAM (
			[parameter(Mandatory = $true, HelpMessage = "Value added to the log file.")][ValidateNotNullOrEmpty()][string]$Message,
			[parameter(Mandatory = $false, HelpMessage = "Severity for the log entry.")][ValidateNotNullOrEmpty()][ValidateSet("Error", "Warn", "Info")][string]$Level = "Info",
			[parameter(Mandatory = $false, HelpMessage = "Name of the log file that the entry will written to.")][ValidateNotNullOrEmpty()][string]$FileName = "$($ScriptName).log",
			[string]$LogsDirectory = "$env:windir\Logs",
			[string]$component = ''
		)
		# Determine log file location
		IF ($FileName2.Length -le 4) {
			$FileName2 = "GenericScriptLog_$(Get-Date -Format yyyy-MM-dd)$FileName2"
		}
		$LogFilePath = Join-Path -Path $LogsDirectory -ChildPath $FileName
		
		# Construct time stamp for log entry
		IF (-not (Test-Path -Path 'variable:global:TimezoneBias')) {
			[string]$global:TimezoneBias = [System.TimeZoneInfo]::Local.GetUtcOffset((Get-Date)).TotalMinutes
			IF ($TimezoneBias -match "^-") {
				$TimezoneBias = $TimezoneBias.Replace('-', '+')
			} ELSE {
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
			Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop -Whatif:$false
		} CATCH [System.Exception] {
			Write-Warning -Message "Unable to append log entry to $($FileName) file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
		}
	}
	#endregion FUNCTION Write-Log
	
	#region Function Get-InstalledApplication
	FUNCTION Get-InstalledApplication {
	<#
			.SYNOPSIS
			Retrieves information about installed applications.
			.DESCRIPTION
			Retrieves information about installed applications by querying the registry. You can specify an application name, a product code, or both.
			Returns information about application publisher, name & version, product code, uninstall string, install source, location, date, and application architecture.
			.PARAMETER Name
			The name of the application to retrieve information for. Performs a contains match on the application display name by default.
			.PARAMETER Exact
			Specifies that the named application must be matched using the exact name.
			.PARAMETER WildCard
			Specifies that the named application must be matched using a wildcard search.
			.PARAMETER RegEx
			Specifies that the named application must be matched using a regular expression search.
			.PARAMETER ProductCode
			The product code of the application to retrieve information for.
			.PARAMETER IncludeUpdatesAndHotfixes
			Include matches against updates and hotfixes in results.
			.EXAMPLE
			Get-InstalledApplication -Name 'Adobe Flash'
			.EXAMPLE
			Get-InstalledApplication -ProductCode '{1AD147D0-BE0E-3D6C-AC11-64F6DC4163F1}'
			.NOTES
			.LINK
			http://psappdeploytoolkit.com
	#>
		[CmdletBinding()]
		PARAM (
			[Parameter(Position=0,Mandatory = $false)][ValidateNotNullorEmpty()][string[]]$Name,
			[Parameter(Mandatory = $false)][switch]$Exact = $false,
			[Parameter(Position=1,Mandatory = $false)][switch]$WildCard = $false,
			[Parameter(Mandatory = $false)][switch]$RegEx = $false,
			[Parameter(Mandatory = $false)][ValidateNotNullorEmpty()][string]$ProductCode,
			[Parameter(Mandatory = $false)][switch]$IncludeUpdatesAndHotfixes
		)
		
		BEGIN {
			[boolean]$Is64Bit = [boolean]((Get-WmiObject -Class 'Win32_Processor' -ErrorAction 'SilentlyContinue' | Where-Object { $_.DeviceID -eq 'CPU0' } | Select-Object -ExpandProperty 'AddressWidth') -eq 64)
			[string[]]$regKeyApplications = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
			[string]$MSIProductCodeRegExPattern = '^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$'
		}
		PROCESS {
			IF ($name) {
			}
			IF ($productCode) {
			}
			
			## Enumerate the installed applications from the registry for applications that have the "DisplayName" property
			[psobject[]]$regKeyApplication = @()
			FOREACH ($regKey IN $regKeyApplications) {
				IF (Test-Path -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath') {
					[psobject[]]$UninstallKeyApps = Get-ChildItem -LiteralPath $regKey -ErrorAction 'SilentlyContinue' -ErrorVariable '+ErrorUninstallKeyPath'
					FOREACH ($UninstallKeyApp IN $UninstallKeyApps) {
						TRY {
							[psobject]$regKeyApplicationProps = Get-ItemProperty -LiteralPath $UninstallKeyApp.PSPath -ErrorAction 'Stop'
							IF ($regKeyApplicationProps.DisplayName) {
								[psobject[]]$regKeyApplication += $regKeyApplicationProps
							}
						} CATCH {
							CONTINUE
						}
					}
				}
			}
			IF ($ErrorUninstallKeyPath) {
			}
			
			## Create a custom object with the desired properties for the installed applications and sanitize property details
			[psobject[]]$installedApplication = @()
			FOREACH ($regKeyApp IN $regKeyApplication) {
				TRY {
					[string]$appDisplayName = ''
					[string]$appDisplayVersion = ''
					[string]$appPublisher = ''
					
					## Bypass any updates or hotfixes
					IF (-not $IncludeUpdatesAndHotfixes) {
						IF ($regKeyApp.DisplayName -match '(?i)kb\d+') {
							CONTINUE
						}
						IF ($regKeyApp.DisplayName -match 'Cumulative Update') {
							CONTINUE
						}
						IF ($regKeyApp.DisplayName -match 'Security Update') {
							CONTINUE
						}
						IF ($regKeyApp.DisplayName -match 'Hotfix') {
							CONTINUE
						}
					}
					
					## Remove any control characters which may interfere with logging and creating file path names from these variables
					$appDisplayName = $regKeyApp.DisplayName -replace '[^\u001F-\u007F]', ''
					$appDisplayVersion = $regKeyApp.DisplayVersion -replace '[^\u001F-\u007F]', ''
					$appPublisher = $regKeyApp.Publisher -replace '[^\u001F-\u007F]', ''
					
					## Determine if application is a 64-bit application
					[boolean]$Is64BitApp = IF (($is64Bit) -and ($regKeyApp.PSPath -notmatch '^Microsoft\.PowerShell\.Core\\Registry::HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node')) {
						$true
					} ELSE {
						$false
					}
					
					IF ($ProductCode) {
						## Verify if there is a match with the product code passed to the script
						IF ($regKeyApp.PSChildName -match [regex]::Escape($productCode)) {
							$installedApplication += New-Object -TypeName 'PSObject' -Property @{
								UninstallSubkey = $regKeyApp.PSChildName
								ProductCode	    = IF ($regKeyApp.PSChildName -match $MSIProductCodeRegExPattern) {
									$regKeyApp.PSChildName
								} Else {
									[string]::Empty
								}
								DisplayName	    = $appDisplayName
								DisplayVersion  = $appDisplayVersion
								UninstallString = $regKeyApp.UninstallString
								InstallSource   = $regKeyApp.InstallSource
								InstallLocation = $regKeyApp.InstallLocation
								InstallDate	    = $regKeyApp.InstallDate
								Publisher	    = $appPublisher
								Is64BitApplication = $Is64BitApp
							}
						}
					}
					
					IF ($name) {
						## Verify if there is a match with the application name(s) passed to the script
						FOREACH ($application IN $Name) {
							$applicationMatched = $false
							IF ($exact) {
								#  Check for an exact application name match
								IF ($regKeyApp.DisplayName -eq $application) {
									$applicationMatched = $true
								}
							} ELSEIF ($WildCard) {
								#  Check for wildcard application name match
								IF ($regKeyApp.DisplayName -like $application) {
									$applicationMatched = $true
								}
							} ELSEIF ($RegEx) {
								#  Check for a regex application name match
								IF ($regKeyApp.DisplayName -match $application) {
									$applicationMatched = $true
								}
							}
							#  Check for a contains application name match
ELSEIF ($regKeyApp.DisplayName -match [regex]::Escape($application)) {
								$applicationMatched = $true
							}
							
							IF ($applicationMatched) {
								$installedApplication += New-Object -TypeName 'PSObject' -Property @{
									UninstallSubkey = $regKeyApp.PSChildName
									ProductCode	    = IF ($regKeyApp.PSChildName -match $MSIProductCodeRegExPattern) {
										$regKeyApp.PSChildName
									} Else {
										[string]::Empty
									}
									DisplayName	    = $appDisplayName
									DisplayVersion  = $appDisplayVersion
									UninstallString = $regKeyApp.UninstallString
									InstallSource   = $regKeyApp.InstallSource
									InstallLocation = $regKeyApp.InstallLocation
									InstallDate	    = $regKeyApp.InstallDate
									Publisher	    = $appPublisher
									Is64BitApplication = $Is64BitApp
								}
							}
						}
					}
				} CATCH {
					CONTINUE
				}
			}
			
			Write-Output -InputObject $installedApplication
		}
		END {
		}
	}
	#endregion
	
	[string[]]$regKeyApplications = 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', 'HKLM:SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
	[string]$MSIProductCodeRegExPattern = '^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$'
	
	Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
}
PROCESS {
	TRY {
		
		$Results = @(
			FOREACH ($Server IN $ServerNameList) {
				TRY {
					$IPAddress = (Resolve-DnsName -Name $Server -TcpOnly -QuickTimeout).IPAddress
				} CATCH {
					$IPAddress = (Test-Connection -ComputerName $Server -Count 1).IPV4Address.ToString()
				}
				IF ($IPAddress) {
					$InstalledApps =  Invoke-Command -ComputerName $Server -ScriptBlock ${function:Get-InstalledApplication} -ArgumentList 'Microsoft SQL Server 20?? (??-bit)',$true -OutVariable SQLApps
					$InstalledApps += Invoke-Command -ComputerName $Server -ScriptBlock ${function:Get-InstalledApplication} -ArgumentList 'Microsoft SQL Server 20??',$true -OutVariable SQLApps2
					$SQLApps += $SQLApps2
					IF($SQLApps.count -ge 1){
						$SQLInstalled = $true
					}ELSE{
						$SQLInstalled = $false
					}
				}ELSE{
					$SQLInstalled = 'Offline'
				}
				
				
				New-Object -TypeName psobject -Property @{
					ServerName = $Server
					IPAddress  = $IPAddress
					SQLinstall = $SQLInstalled
				}
			}
		)
		
		
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
	}
}
END {
	Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}
