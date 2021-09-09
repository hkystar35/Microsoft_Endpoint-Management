$InvocationInfo = $MyInvocation
[System.IO.FileInfo]$Global:ScriptFileInfo = $InvocationInfo.MyCommand.Path
[string]$Global:ScriptFullPath = $ScriptFileInfo.FullName
[string]$Global:ScriptNameFileExt = $ScriptFileInfo.Name
[string]$Global:ScriptName = $ScriptFileInfo.BaseName
[string]$Global:scriptRoot = Split-Path $ScriptFileInfo

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

#region FUNCTION Get-CMAppsNoDeployment
Function Get-CMAppsNoDeployment {
	Param(
		[ValidateNotNullOrEmpty()][string]$ApplicationName
	)
	# Function Body
	Begin{ # specifying variables and arrays
    
	}
	Process{ # where the work is done
		TRY{
			$Applications = Get-CMApplication | Where-Object {$_.IsDeployed -eq $false -and $_.NumberOfDependentDTs -le 0 -and $_.NumberOfDependentTS -le 0} 
                <#
                $Applications | ft localizeddisplayname,LocalizedDescription,IsExpired,IsDeployed,hascontent,NumberOfDependentDTs,NumberOfDependentTS
                NumberOfDependentDTs
                NumberOfDependentTS
                NumberOfDeployments
                NumberOfDeploymentTypes
                NumberOfDevicesWithApp
                NumberOfDevicesWithFailure
                NumberOfSettings
                NumberOfUsersWithApp
                NumberOfUsersWithFailure
                NumberOfUsersWithRequest
                NumberOfVirtualEnvironments
                #>
            Write-Log -Message "Found $($Applications.count) applications with NO deployments and NO Task Sequence dependencies."
			foreach ($Application in $Applications) {
 
				$AppMgmt = ([xml]$Application.SDMPackageXML).AppMgmtDigest
				$AppName = $AppMgmt.Application.DisplayInfo.FirstChild.Title
 
				foreach ($DeploymentType in $AppMgmt.DeploymentType) {
 
					# Calculate Size and convert to MB
					$size = 0
					foreach ($MyFile in $DeploymentType.Installer.Contents.Content.File) {
						$size += [int]($MyFile.GetAttribute("Size"))
					}
					$size = [math]::truncate($size/1MB)
 
					# Fill properties
					$AppData = @{            
						AppName            = $AppName
						Location           = $DeploymentType.Installer.Contents.Content.Location
						DeploymentTypeName = $DeploymentType.Title.InnerText
						Technology         = $DeploymentType.Installer.Technology
						ContentId          = $DeploymentType.Installer.Contents.Content.ContentId
						SizeMB             = $size
					}                           
 
					# Create object
					$Object = New-Object PSObject -Property $AppData
    
					# Return it
					$Object
				}
			}
		}
		CATCH {
			$Line = $_.InvocationInfo.ScriptLineNumber
			Write-Log -Message "Error: $_" -Level Error
			Write-Log -Message "Error: on line $line" -Level Error
		}
	}
	End{ # clean objects up or return any complex data structures
    
	}
}
#endregion FUNCTION Get-CMAppsNoDeployment

$StaleApps = Get-CMAppsNoDeployment
cd $HOME
$StaleApps | Export-Excel -Path \\kirk\it\EUC-ENG\