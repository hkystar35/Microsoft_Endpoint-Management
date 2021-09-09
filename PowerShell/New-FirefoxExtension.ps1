FUNCTION New-FirefoxExtension {
<#
	.SYNOPSIS
		Add extensions to Firefox. Does not enable them
	
	.DESCRIPTION
		A detailed description of the New-FirefoxExtension function.
	
	.PARAMETER ExtensionUriFileSource
		The extension download uri found by right-clicking download in the app store --> copy link address
	
	.PARAMETER ExtensionLocalFileSource
		Local or UNC path to pre-downloaded XPI file
	
	.PARAMETER Hive
		Controls whether you write changes to HKEY_LOCAL_MACHINE, or HKEY_CURRENT_USER.
		HKLM affects every user of a machine, HKCU will affect only the primary user.
		Shared machines should use HKLM, whereas single-user machines are fine with HKCU.
	
	.PARAMETER ExtensionDestinationFolder
		The path you wish to store extensions on the system
	
	.EXAMPLE
		#Installs the uBlock Origin Add-On
		New-FirefoxExtension -ExtensionUri 'https://addons.mozilla.org/firefox/downloads/file/985780/ublock_origin-1.16.10-an+fx.xpi?src=dp-btn-primary' -ExtensionPath 'C:\FirefoxExtensions' -Hive HKLM
	
	.EXAMPLE
		#Use splatting to shorten the scroll of the parameters
		$params = @{
		'ExtensionUri' = 'https://addons.mozilla.org/firefox/downloads/file/985780/ublock_origin-1.16.10-an+fx.xpi?src=dp-btn-primary'
		'ExtensionPath' = 'C:\FirefoxExtensions'
		'Hive' = 'HKLM'
		}
		
		New-FirefoxExtension @params
	
	.EXAMPLE
		#Load Uri's from a file
		$Params = @{
		'ExtensionUri' = @(Get-Content C:\addons.txt)
		'ExtensionPath = 'C:\FirefoxExtensions'
		'Hive' = 'HKLM'
		}
	
	.EXAMPLE
		#Load function into scope
		Import-Module C:\Scripts\New-FirefoxExtension.ps1
		$params = @{
		'ExtensionUri' = 'https://addons.mozilla.org/firefox/downloads/file/985780/ublock_origin-1.16.10-an+fx.xpi?src=dp-btn-primary'
		'ExtensionPath' = 'C:\FirefoxExtensions'
		'Hive' = 'HKLM'
		}
		
		New-FirefoxExtension @params
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding(DefaultParameterSetName = 'ExtensionURI')]
	PARAM
	(
		[Parameter(ParameterSetName = 'ExtensionURI',
				   Mandatory = $false)][ValidateNotNullOrEmpty()][string[]]$ExtensionUriFileSource = 'https://addons.mozilla.org/firefox/downloads/file/3623778/sponsorblock_skip_sponsorships_on_youtube-2.0.5-an+fx.xpi?src=rating',
		[Parameter(ParameterSetName = 'ExtensionFile',
				   Mandatory = $false)][ValidateNotNullOrEmpty()][ValidatePattern('(\.xpi)$')][string[]]$ExtensionLocalFileSource,
		[Parameter(Mandatory = $false)][ValidateSet('HKCU', 'HKLM')][string]$Hive
	)
	
	IF (-not ($Destination_Folder_Staging = Get-Item -Path "$env:APPDATA\Mozilla\Firefox\Profiles\*default*\extensions\staged" | Where-Object{
				$_.PSIsContainer -eq $true
			} | Select-Object -First 1)) {
		$Destination_Folder_Staging = (New-Item -ItemType Directory $env:windir\Temp\FirefoxExtensions).FullName
	}
	
	# Download file from URI
	IF ($PSBoundParameters.ContainsKey('ExtensionUriFileSource')) {
		$Destination_File_Staging_XPIs = @(
			FOREACH ($URI IN $ExtensionUriFileSource) {
				#Store just the extension filename for later use
				#Thanks reddit user /u/ta11ow for the regex help!
				[regex]$Regex_ExentionNameFromURI = '(?<=\/)(?<ExtensionName>[^\/]+)(?=\?)'
				$URI -match $Regex_ExentionNameFromURI
				$Extension = $matches['ExtensionName']
				
				#Download the Extension and save it to the FireFoxExtensions folder
				$ExtensionFileFullname = "$Destination_Folder_Staging\$Extension"
				Invoke-WebRequest -Uri $Uri -OutFile $ExtensionFileFullname | Out-Null
				#output file name to array
				[string]$ExtensionFileFullname
			}
		)
	}
	
	# Copy file from local source
	IF ($PSBoundParameters.ContainsKey('ExtensionLocalFileSource')) {
		$Destination_File_Staging_XPIs = @(
			FOREACH ($File IN $ExtensionLocalFileSource) {
				#output file name to array  
				[string](Copy-Item -Path $File -Destination $Destination_Folder_Staging -PassThru).fullname
			}
		)
	}
	
	FOREACH ($XPI IN $Destination_File_Staging_XPIs) {
		
		# Create a zip file from the xpi
		$XPIFile = [System.IO.FileInfo]$XPI
		$ZIPfile = Copy-Item -Path $XPI -Destination $($XPIFile.Fullname -replace '.xpi', '.zip') -PassThru
		$Expanded = "$Destination_Folder_Staging\$($ZIPfile.BaseName)"
		
		# Expand the zip file
		SWITCH ($PSVersionTable.PSVersion.Major) {
			{
				$_ -gt 4
			} {
				Expand-Archive -Path $ZIPfile.FullName -DestinationPath $Expanded
			}
			default {
				[System.IO.Compression.ZipFile]::ExtractToDirectory($ZIPfile.FullName, $Expanded)
			}
		}
		
		# Capture manifest JSON
		$JSON = Get-Content "$Expanded\manifest.json" | ConvertFrom-Json
		# Get Author ID for new name
		IF (!($authorValue = $JSON.applications.gecko.id)) {
			$authorValue = $JSON.browser_specific_settings.gecko.id
		}
		
		$XPI_RenameAuthor = Rename-Item -Path $XPIFile.FullName -NewName "$authorValue.xpi" -PassThru
		#Cleanup all the junk, leaving only the extension pack file behind
		Remove-Item -Path $Expanded -Force -Recurse
		Remove-Item -Path $ZIPfile -Force
		
		
		
		$FirefoxX64 = [bool](Test-Path -Path "$env:ProgramFiles\Mozilla Firefox\firefox.exe" -PathType Leaf)
		
		# HKCU
		
		
			SWITCH ([environment]::Is64BitOperatingSystem) {
				$true {
					IF ($FirefoxX64) {
						$regKey = "$($Hive):\Software\Mozilla\Firefox\Extensions"
						New-ItemProperty -Path $regKey -Name $authorValue -Value "$Destination_Folder_Staging\$authorValue.xpi" -PropertyType String
					}
					ELSE {
						$regKey = "$($Hive):\Software\Wow6432Node\Mozilla\Firefox\Extensions"
						New-ItemProperty -Path $regKey -Name $authorValue -Value "$Destination_Folder_Staging\$authorValue.xpi" -PropertyType String
					}
				}
				$false {
					$regKey = "$($Hive):\Software\Mozilla\Firefox\Extensions"
				
					New-ItemProperty -Path $regKey -Name $authorValue -Value "$Destination_Folder_Staging\$authorValue.xpi" -PropertyType String
					New-ItemProperty -Path $regKey -Name $matches['ExtensionName'] -Value "$Destination_Folder_Staging\$($matches['ExtensionName'])" -PropertyType String
				}
			} #$Hive switch
		
		# HKLM
		
		#Modify registry based on which Hive you selected
		SWITCH ($Hive) {
			'HKCU' {
				SWITCH ([environment]::Is64BitOperatingSystem) {
					$true {
						IF ($FirefoxX64) {
							$regKey = "HKCU:\Software\Mozilla\Firefox\Extensions"
							New-ItemProperty -Path $regKey -Name $authorValue -Value "$Destination_Folder_Staging\$authorValue.xpi" -PropertyType String
						}
						ELSE {
							$regKey = "HKCU:\Software\Wow6432Node\Mozilla\Firefox\Extensions"
							New-ItemProperty -Path $regKey -Name $authorValue -Value "$Destination_Folder_Staging\$authorValue.xpi" -PropertyType String
						}
					}
					$false {
						$regKey = "HKCU:\Software\Mozilla\Firefox\Extensions"
						New-ItemProperty -Path $regKey -Name $authorValue -Value "$Destination_Folder_Staging\$authorValue.xpi" -PropertyType String
					}
				} #hkcu switch
			} #hkcu
			'HKLM' {
				SWITCH ([environment]::Is64BitOperatingSystem) {
					$true {
						IF ($FirefoxX64) {
							$regKey = "HKLM:\Software\Mozilla\Firefox\Extensions"
							New-ItemProperty -Path $regKey -Name $authorValue -Value "$Destination_Folder_Staging\$authorValue.xpi" -PropertyType String
						}
						ELSE {
							$regKey = "HKLM:\Software\Wow6432Node\Mozilla\Firefox\Extensions"
							New-ItemProperty -Path $regKey -Name $authorValue -Value "$Destination_Folder_Staging\$authorValue.xpi" -PropertyType String
						}
					}
					$false {
						$regKey = "HKLM:\Software\Mozilla\Firefox\Extensions"
						New-ItemProperty -Path $regKey -Name $matches['ExtensionName'] -Value "$Destination_Folder_Staging\$($matches['ExtensionName'])" -PropertyType String
					}
				} #hklm switch
			} #hklm 
		} #end outer switch
	} #foreach
} #function