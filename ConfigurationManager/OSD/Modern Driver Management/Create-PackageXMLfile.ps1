<#
		.SYNOPSIS
		Creates XML file of SCCM Package list for Modern Driver Management.
	
		.DESCRIPTION
		Creates XML file of SCCM Package list for Modern Driver Management.
	
		.PARAMETER SCCMComputer
		FQDN of SCCM server to query.

		.PARAMETER SCCMSiteCode
		SCCM Site Code.

		.PARAMTER ModelsToModify
		String value separating two elements by a semi-colon (;) for modifying mismatched WMI values
		Exmaple:
		Lenovo writes "ThinkPad X1 Yoga" as the Win32_CopmuterSystemProduct value of the Version property to Windows
		Lenovo publishes the same model in their public XML as "ThinkPad X1 Yoga 1st"
		This conflict results in the script not finding a matching package ID

		Parametr value follows this format: "Bad String;Good String"
		Example: 'ThinkPad X1 Yoga;ThinkPad X1 Yoga 1st'
		Script will do a Find and Replace of the values in the XML created byu this script
	
		.NOTES
		===========================================================================

		Created on:   	8/20/2019 9:40:33 AM
		Created by:   	NWendlowsky@paylocity.com
		Organization: 	Paylocity
		Filename:	
		===========================================================================
#>
[CmdletBinding()]
PARAM
(
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$SCCMComputer = 'ah-sccm-01.paylocity.com',
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$SCCMSiteCode = 'PAY',
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$PackageIDupdate = 'PAY006EE',
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string[]]$ModelsToModify
)
BEGIN {
	$InvocationInfo = $MyInvocation
	[System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
	[string]$ScriptFullPath = $ScriptFileInfo.FullName
	[string]$ScriptNameFileExt = $ScriptFileInfo.Name
	[string]$ScriptName = $ScriptFileInfo.BaseName
	[string]$ScriptRoot = Split-Path $ScriptFileInfo
	
	#region FUNCTION Write-Log
	FUNCTION Write-Log {
		[CmdletBinding()]
		PARAM
		(
			[Parameter(Mandatory = $true,
			ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][Alias("LogContent")][string]$Message,
			[Parameter(Mandatory = $false)][Alias('LogPath')][string]$Path = "$ScriptRoot\$($ScriptName).log",
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
			IF (Test-Path -Path $Path) {
				$FilePath = Get-Item -Path $Path
				IF ($NoClobber) {
					Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
					RETURN
				}
				IF ($FilePath.Length -gt $MaxLogSize) {
					Rename-Item -Path $FilePath.FullName -NewName $($FilePath.BaseName).log_ -Force
				}
			} ELSEIF (!(Test-Path $Path)) {
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
			"$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
		}
		END {
		}
	}
	#endregion FUNCTION Write-Log	
	
	#region Function Update-PackageContent
	Function Update-PackageContent {
		[CmdletBinding()]
		Param(    
			[String]
			[Parameter(
					Mandatory = $true,
					Position=0,
			HelpMessage="Package ID to trigger content update in SCCM.")]
			[ValidateNotNullOrEmpty()]
			[Alias("ID")]
			$PackageID,
		
			[String]
			[Parameter(
					Mandatory = $false,
					Position=0,
			HelpMessage="Site Code for SCCM Server.")]
			[ValidateNotNullOrEmpty()]
			[Alias("SiteCode")]
			$SCCMSiteCode = 'PAY',

			[String]
			[Parameter(
					Mandatory = $false,
					Position=0,
			HelpMessage="FQDN of SCCM Site Server.")]
			[ValidateNotNullOrEmpty()]
			[Alias("Server")]
			$SCCMSiteServer = 'AH-SCCM-01.paylocity.com'
		)
		Begin{
			Write-Log -message "********* Attempting to update package id $($PackageID) on $SCCMSiteServer"
		}
		Process{
			TRY{
				$pkgOnDP = Get-WmiObject -Namespace "root\sms\site_$SCCMSiteCode" -ComputerName $SCCMSiteServer -class SMS_DistributionPoint | where {$_.PackageID -eq $PackageID -and $_.SiteCode -eq $SCCMSiteCode}
				Write-Log -Message "Found PackageID $($pkgOnDP|select -First 1 -Property PackageID) on $($pkgOnDP.count) Distribution Points"
				$pkgOnDP|%{
					$_.RefreshNow = $true
					$_.Put()
					$DPName = ($_.Path.RelativePath -split '\\\\')[2]
					Write-Log -message "********* Successfully triggered an update of package id: $($PackageID) on DP $DPName"
				}
			}CATCH {
				$Line = $_.InvocationInfo.ScriptLineNumber
				Write-Log -message "######### Failed to update package id:$($PackageID) on DP $DPName. Script will attempt to continue." -Level Error
				Write-Log -Message "Error: $_" -Level Error
				Write-Log -Message "Error: on line $line" -Level Error
			}
		}
		End{ # clean objects up or return any complex data structures
			Write-Log -Message "Done updating package."
		}
	}
	#endregion Function Update-PackageContent
	
	Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
	Write-Log -Message "ScriptFullPath $ScriptFullPath"
	Write-Log -Message "ScriptNameFileExt $ScriptNameFileExt"
	Write-Log -Message "ScriptName $ScriptName"
	Write-Log -Message "ScriptRoot $ScriptRoot"
}
PROCESS {
	TRY {
		
		## Main Script Block
		$XMLPackagesFile = "$($ScriptRoot)\Script\packages.xml"	
		Write-Log -Message "Path is $XMLPackagesFile"

		Write-Log -Message "Querying server $SCCMComputer for all Package names."
		$XMLPackages = Get-WmiObject -class sms_package -Namespace root\sms\site_$($SCCMSiteCode) -ComputerName $SCCMComputer | Select-Object pkgsourcepath, Description, ISVData, ISVString, Manufacturer, MifFileName, MifName, MifPublisher, MIFVersion, Name, PackageID, ShareName, Version
		IF($XMLPackages.count -ge 1){
			
			$XMLPackages | Export-Clixml -Path "$XMLPackagesFile" -Force -OutVariable XMLPath
			Write-Log -Message "XML successfully created: $XMLPackagesFile"
		}ELSE{
			$ExceptionMessage = "No packages found. Check WMI parameters."
			Write-Log -Message $ExceptionMessage -Level Error
		}
				
		## Modify Model names that don't match in the xml
		Write-Log -Message "Switch value is $ModelsToModify"
		TRY {
			IF($ModelsToModify -and (Test-Path -Path $XMLPackagesFile)){
				Write-Log -Message "SWITCH ModelsToModify is True. Starting find-and-replace."
				IF($ModelsToModify[0].Length -gt 8){
					foreach ($Model in $ModelsToModify){
						$BadModel = $Model.Split(';')[0]
						$GoodModel = $Model.Split(';')[1]
						$SearchString = '<S N="MifName">{0}</S>' -f $BadModel
						$NewString = '<S N="MifName">{0}</S>' -f $GoodModel
						$File = Get-Content -Path $XMLPackagesFile
						$UpdatedFile = $File -replace "$SearchString","$NewString" | Set-Content -Path "$XMLPackagesFile" -PassThru
						Write-Log -Message "Replaced `"$BadModel`" with `"$GoodModel`" in $($UpdatedFile[0].PSPath)"
					}
				}ELSE{
					$ExceptionMessage = "Array length is too short to be valid."
					Write-Log -Message $ExceptionMessage -Level Error
					Write-Error $ExceptionMessage
				}
			}ELSE{
				Write-Log -Message "No model names to correct."
			}

			## Update script package
			Update-PackageContent -PackageID $PackageIDupdate
			
		} CATCH {
			$Line = $_.InvocationInfo.ScriptLineNumber
			Write-Log -Message "Error: $_" -Level Error
			Write-Log -Message "Error: on line $line" -Level Error
		}

	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
	}
}
END {
	Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}