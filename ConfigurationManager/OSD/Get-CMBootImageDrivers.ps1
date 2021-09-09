<# 
.SYNOPSIS
	List all drivers that has been added to a specific Boot Image in ConfigMgr 2012 

.DESCRIPTION
	This script will list all the drivers added to a Boot Image in ConfigMgr 2012. It's also possible to list Microsoft standard drivers by specifying the All parameter. 

.PARAMETER SiteServer
	Site server name with SMS Provider installed .PARAMETER BootImageName Specify the Boot Image name as a string or an array of strings 

.PARAMETER MountPath
	Default path to where the script will temporarly mount the Boot Image .PARAMETER All When specified all drivers will be listed, including default Microsoft drivers 

.PARAMETER ShowProgress
	Show a progressbar displaying the current operation 

.EXAMPLE 
	.\Get-CMBootImageDrivers.ps1 -SiteServer CM01 -BootImageName "Boot Image (x64)" -MounthPath C:\Temp\MountFolder List all drivers in a Boot Image named 'Boot Image (x64)' on a Primary Site server called CM01: 

.NOTES
	Script name: Get-CMBootImageDrivers.ps1 Author: Nickolaj Andersen Contact: @NickolajA DateCreated: 2015-05-06 

#>

[CmdletBinding(SupportsShouldProcess = $true)]
PARAM (
	[parameter(Mandatory = $true, HelpMessage = "Site server where the SMS Provider is installed")][ValidateNotNullOrEmpty()][ValidateScript({
			Test-Connection -ComputerName $_ -Count 1 -Quiet
		})][string]$SiteServer = 'sccm-no-01.contoso.com',
	
	[parameter(Mandatory = $true, HelpMessage = "Specify the Boot Image name as a string or an array of strings")][ValidateNotNullOrEmpty()][string[]]$BootImageName = @('OSDFE_X64','OSDFE_X64_A23'),
	
	[parameter(Mandatory = $false, HelpMessage = "Default path to where the script will temporarly mount the Boot Image")][ValidateNotNullOrEmpty()][ValidatePattern("^[A-Za-z]{1}:\\\w+")][string]$MountFolderPath = "C:\MountFolder",
	
	[parameter(Mandatory = $false, HelpMessage = "When specified all drivers will be listed, including default Microsoft drivers")][switch]$All,
	
	[parameter(Mandatory = $false, HelpMessage = "Show a progressbar displaying the current operation")][switch]$ShowProgress
)

BEGIN {
	# Determine SiteCode from WMI 
	TRY {
		Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
		$SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
		FOREACH ($SiteCodeObject IN $SiteCodeObjects) {
			IF ($SiteCodeObject.ProviderForLocalSite -eq $true) {
				$SiteCode = $SiteCodeObject.SiteCode
				Write-Debug "SiteCode: $($SiteCode)"
			}
		}
	}
	CATCH [System.Exception] {
		Write-Warning -Message "Unable to determine SiteCode"; BREAK
	}
	
	# Determine if we need to load the Dism PowerShell module 
	IF (-not (Get-Module -Name Dism)) {
		TRY {
			Import-Module Dism -ErrorAction Stop -Verbose:$false
		}
		CATCH [System.Exception] {
			Write-Warning -Message "Unable to load the Dism PowerShell module"; BREAK
		}
	}
	
	
}
PROCESS {
	IF ($PSBoundParameters["ShowProgress"]) {
		$ProgressCount = 0
	}
	
	# Enumerate trough all specified boot image names 
	FOREACH ($BootImageItem IN $BootImageName) {
		TRY {
			
			Write-Verbose -Message "Querying for boot image: $($BootImageItem)"
			$BootImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_BootImagePackage -ComputerName $SiteServer -Filter "Name like '$($BootImageItem)'" -ErrorAction Stop
			
			$MountPath = Join-Path $MountFolderPath $BootImage.Name
			# Determine if temporary mount folder is accessible, if not create it 
			IF (-not (Test-Path -Path $MountPath -PathType Container -ErrorAction SilentlyContinue -Verbose:$false)) {
				New-Item -Path $MountPath -ItemType Directory -Force -Verbose:$false | Out-Null
			}
			
			IF ($BootImage -ne $null) {
				$BootImagePath = $BootImage.PkgSourcePath
				Write-Verbose -Message "Located boot image wim file: $($BootImagePath)"
				# Mount Boot Image to temporary mount folder 
				IF ($PSCmdlet.ShouldProcess($BootImagePath, "Mount")) {
					Mount-WindowsImage -ImagePath $BootImagePath -Path $MountPath -Index 1 -ErrorAction Stop -Verbose:$false | Out-Null
				}
				
				# Get all drivers in the mounted Boot Image 
				$WindowsDriverArguments = @{
					Path = $MountPath
					ErrorAction = "Stop"
					Verbose = $false
				}
				IF ($PSBoundParameters["All"]) {
					$WindowsDriverArguments.Add("All", $true)
				}
				IF ($PSCmdlet.ShouldProcess($MountPath, "ListDrivers")) {
					$Drivers = Get-WindowsDriver @WindowsDriverArguments
					IF ($Drivers -ne $null) {
						$DriverCount = ($Drivers | Measure-Object).Count
            FOREACH ($Driver IN $Drivers) {
              IF ($PSBoundParameters["ShowProgress"]) {
                $ProgressCount++
                Write-Progress -Activity "Enumerating drivers in '$($BootImage.Name)'" -Id 1 -Status "Processing $($ProgressCount) / $($DriverCount)" -PercentComplete (($ProgressCount / $DriverCount) * 100)
              }
             <# 
			  $PSObject = [PSCustomObject]@{
                Driver = ([System.IO.FileInfo]$Driver.OriginalFileName).Name
                wimDriverName = $Driver.Driver
                Version = $Driver.Version
                Manufacturer = $Driver.ProviderName
                ClassName = $Driver.ClassName
                Date = $Driver.Date
                BootImageName = $BootImage.Name
              }
			  #>
              Write-Output $Driver
            } 
            IF ($PSBoundParameters["ShowProgress"]) {
							Write-Progress -Activity "Enumerating drivers in '$($BootImage.Name)'" -Id 1 -Completed
						}
					}
					ELSE {
						Write-Warning -Message "No drivers was found"
					}
				}
			}
			ELSE {
				Write-Warning -Message "Unable to locate a boot image called '$($BootImageName)'"
			}
		}
		CATCH [System.UnauthorizedAccessException] {
			Write-Warning -Message "Access denied"; BREAK
		}
		CATCH [System.Exception] {
			Write-Warning -Message $_.Exception.Message; BREAK
		}
		
		# Dismount the boot image 
		IF ($PSCmdlet.ShouldProcess($BootImagePath, "Dismount")) {
			Dismount-WindowsImage -Path $MountPath -Discard -ErrorAction Stop -Verbose:$false | Out-Null
		}
	}
}
END {
	# Clean up mount folder 
	TRY {
		Remove-Item -Path $MountPath -Force -ErrorAction Stop -Verbose:$false
	}
	CATCH [System.UnauthorizedAccessException] {
		Write-Warning -Message "Access denied"
	}
	CATCH [System.Exception] {
		Write-Warning -Message $_.Exception.Message
	}
}
