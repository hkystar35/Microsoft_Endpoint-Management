$ScriptName = 'Remove-PackageAndContent'
#region FUNCTION Write-Log
		FUNCTION Write-Log {
				[CmdletBinding()]
				PARAM
				(
						[Parameter(Mandatory = $true,
								ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][Alias("LogContent")][string]$Message,
						[Parameter(Mandatory = $false)][Alias('LogPath')][string]$Path = "$env:windir\Logs\$($ScriptName).log",
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
						}
						ELSEIF (!(Test-Path $Path)) {
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

#region Set SCCM cmdlet location
TRY {
		$StartingLocation = Get-Location
		Import-Module -Name $env:SMS_ADMIN_UI_PATH.Replace('\bin\i386', '\bin\ConfigurationManager.psd1')
		#Write-Log -Message "Changing location to $($SiteCode.Name):\"
		$SiteCode = Get-PSDrive -PSProvider CMSITE
		Set-Location -Path "$($SiteCode.Name):\"
		#Write-Log -Message "done."
}
CATCH {
		#Write-Log -Message 'Could not import SCCM module' -Level Warn
		Set-Location -Path $StartingLocation
		$Line = $_.InvocationInfo.ScriptLineNumber
		#Write-Log -Message "Error: $_"
		#Write-Log -Message "Error: on line $line"
		#Send-ErrorEmail -Message "Could not import SCCM module.`nError on line $line.`nError: $_"
		BREAK
}
#endregion Set SCCM cmdlet location

#region BIOSDriverPackagesDelete
$BIOSDriverPackagesDelete = 'PAY005A7',
'PAY0062A',
'PAY0055B',
'PAY0062B',
'PAY005A9',
'PAY0062C',
'PAY0040E',
'PAY005DB',
'PAY0062D',
'PAY006F2',
'PAY005AB',
'PAY0062F',
'PAY005AC',
'PAY00630',
'PAY005AD',
'PAY00631',
'PAY005AE',
'PAY00632',
'PAY005AF',
'PAY00633',
'PAY005B0',
'PAY005B1',
'PAY00634',
'PAY005B2',
'PAY00635',
'PAY005B3',
'PAY00636',
'PAY005B4',
'PAY00637',
'PAY006E9',
'PAY006F4',
'PAY0055C',
'PAY0055D',
'PAY00560',
'PAY0055F',
'PAY005B5',
'PAY005B7',
'PAY005B8',
'PAY006F5',
'PAY005B9',
'PAY003C9',
'PAY003CA',
'PAY003E1',
'PAY003E2',
'PAY003E3',
'PAY003E4',
'PAY003E5',
'PAY003E6',
'PAY003E7',
'PAY003E8',
'PAY003E9',
'PAY00401',
'PAY0040C',
'PAY00410',
'PAY00413',
'PAY00415',
'PAY00417',
'PAY00419',
'PAY0041B',
'PAY0041D',
'PAY0041F',
'PAY00421',
'PAY00423',
'PAY00425',
'PAY00427',
'PAY00439',
'PAY00461',
'PAY00466',
'PAY0046F',
'PAY00470',
'PAY00478',
'PAY00479',
'PAY0047A',
'PAY0047B',
'PAY0047C',
'PAY0047D',
'PAY0047E',
'PAY0047F',
'PAY00481',
'PAY00482',
'PAY004BD',
'PAY004C3',
'PAY004FD',
'PAY004FF',
'PAY00500',
'PAY00502',
'PAY00504',
'PAY00506',
'PAY00507',
'PAY00509',
'PAY0050B',
'PAY0050D',
'PAY0050F',
'PAY00511',
'PAY00513',
'PAY00515',
'PAY00516',
'PAY00518',
'PAY00519',
'PAY0051B',
'PAY0051D',
'PAY0051E',
'PAY0051F',
'PAY00520',
'PAY0053B',
'PAY0053C',
'PAY0053D',
'PAY0053E',
'PAY0053F',
'PAY00540',
'PAY00541',
'PAY00542',
'PAY00543',
'PAY00544',
'PAY00545',
'PAY00546',
'PAY00547',
'PAY0054C',
'PAY0054D',
'PAY0054E',
'PAY0054F',
'PAY00550',
'PAY0055A',
'PAY0055E',
'PAY00561',
'PAY00562',
'PAY00563',
'PAY00564',
'PAY00565',
'PAY00566',
'PAY00567',
'PAY00568',
'PAY0056A',
'PAY0056B',
'PAY005A8'
#endregion BIOSDriverPackagesDelete

$Packages = Get-CMPackage -Fast
$DeleteItems = @()
$PackageSize = 0
foreach ($Package in $Packages){
    IF($BIOSDriverPackagesDelete -contains $Package.PackageID){
        Clear-Variable DeleteDirectory -ErrorAction SilentlyContinue
        $DeleteDirectory = $Package.PkgSourcePath.TrimEnd('\')

        Write-Log -Message "Found Package for DELETION: $($Package.Name) ($($Package.PackageID))"
        Set-Location -Path "$($SiteCode.Name):\"
        Write-Log -Message "Removing $($Package.Name) ($($Package.PackageID)) from SCCM."
        Remove-CMPackage -Id $Package.PackageID -Force -Confirm:$false
        Set-Location c:
        IF(Test-Path $DeleteDirectory -PathType Container){
            Write-Log -Message "Removing $($Package.Name) ($($Package.PackageID)) content from $($Package.PkgSourcePath)."
            
            Remove-Item -Path $DeleteDirectory -Recurse -Force -Confirm:$false
            $PackageSize = $PackageSize + $Package.PackageSize
            Write-Log -Message "Running total space saved: $($PackageSize/1024) MB"
        }ELSE{
            Write-Log -Message "Cannot find content $($Package.PkgSourcePath) source from $($Package.Name) ($($Package.PackageID))." -Level Warn
        }
    }
}
Write-Log -Message "Total space saved: $($PackageSize/1024) MB" -Level Warn