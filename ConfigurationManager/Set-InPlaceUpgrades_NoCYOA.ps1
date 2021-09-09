<#
	.SYNOPSIS
		Sets up deadlines and deployments for In Place Upgrades to WIndows 10
	
	.DESCRIPTION
		Must be run on a machine with SMS cmdlets and connection to Primary Site, as well as WinRM connections to machines.
		
		Using CSV of First+Last and Deadline:
		parses names,
		matches with SCCM machine affinity,
		sets Deadline regkey,
		Creates Collection,
		Adds successful members to Collection,
		Deploys Staging, Upgrade, and Upgrade Picker to Collection(s)
	
	.PARAMETER CSV
		Full path to CSV file
	
	.PARAMETER InternalOrIBCM
		Adds to Staging OS and Drivers or Upgrade to Windows 10 - Internal Only.

	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.152
		Created on:   	6/22/2018 8:30 AM
		Created by:   	NWendlowsky
		Organization: 	Paylocity
		Filename:
		===========================================================================
#>
#[CmdletBinding()]
#region FUNCTION Set-InPlaceUpgrades
#FUNCTION Set-InPlaceUpgrades {
PARAM
(
	[Parameter(Mandatory = $true)][ValidateScript({
			Test-Path -Path $_ -PathType Leaf
		})][ValidateNotNullOrEmpty()][string]$CSV,
	[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][ValidateSet('Internal', 'IBCM')][string]$InternalOrIBCM,
	[switch]$NoAddToCollection = $false
    #[Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-zA-Z]{3}[0-9a-fA-F]{5}$')][ValidateNotNullOrEmpty()][string]$UpgradeTS
)

#region FUNCTION Enable-WinRM
FUNCTION Enable-WinRM {
<#
	.SYNOPSIS
		A brief description of the Enable-WinRM function.
	
	.DESCRIPTION
		Usgin Psexec to enable WinRM
	
	.PARAMETER PCName
		A description of the PCName parameter.
	
	.EXAMPLE
				PS C:\> Enable-WinRM -PCName 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$PCName
	)
	
	$WinRM = Start-Process -FilePath '.\PStools\psexec.exe' -ArgumentList "-S -AcceptEULA \\$PCName WinRM.cmd quickconfig -force" -Wait -PassThru
	$WinRM.ExitCode
}
#endregion FUNCTION Enable-WinRM

FUNCTION Convert-FromUnixDate ([string]$UnixDate) {
		[timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
}

#region FUNCTION Get-WarrantyEndDate
FUNCTION Get-WarrantyEndDate {
<#
	.SYNOPSIS
		A brief description of the Get-WarrantyEndDate function.
	
	.DESCRIPTION
		API to Oomnitza to get warranty end date
	
	.PARAMETER ComputerName
		A description of the ComputerName parameter.
	
	.EXAMPLE
				PS C:\> Get-WarrantyEndDate -ComputerName $value1
	
	.NOTES
		Additional information about the function.
#>
	
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$ComputerName
	)
	
	
	$apiKey = "4a523e4883ba4f90ab61af00f056c091"
	$response = Invoke-RestMethod -Uri "https://paylocity.oomnitza.com/api/v3/assets?filter=device_name eq '$($ComputerName)'" -Method GET -Headers @{
		"Authorization2" = $apiKey
	}
    IF($response.count -gt '1'){
        $output = 'multiple entries'
    }ELSEIF($response.count -lt '1'){
        $output = 'no entry'
    }ELSE{
    	$output = Convert-FromUnixDate -UnixDate $response.warranty_end_date | Get-Date -Format "yyyy-MM-dd"
    }
       Write-Output $output
}
#endregion FUNCTION Get-WarrantyEndDate

TRY {
	TRY {
		$StartingLocation = Get-Location
		Import-Module -Name $env:SMS_ADMIN_UI_PATH.Replace('\bin\i386', '\bin\ConfigurationManager.psd1')
		Write-Output "Changing location to $($SiteCode.Name):\"
		$SiteCode = Get-PSDrive -PSProvider CMSITE
		Set-Location -Path "$($SiteCode.Name):\"
		Write-Output "done."
	} CATCH {
		Write-Output 'Could not import SCCM module'
		Set-Location -Path $StartingLocation
		BREAK
	}
	
	#importing txt files with usernames
	TRY {
		Write-Output "Importing CSV $CSV"
		$Users = Import-Csv -Path $CSV
		Write-Output "Gathering CM Users"
		$AllUsers = Get-CMUser | Select-Object -Property Name, SMSID
		Write-Output "Gathering CM devices"
		$AllMachines = Get-CMDevice | Select-Object -Property Name, UserName, IsActive, LastDDR, ResourceID, DeviceOS
		Write-Output "Parsing CSV to get user names and primary devices"
		$Results = @()
		FOREACH ($user IN $Users) {
			IF (($user -ne $null) -or ($user -ne '') -or (!$user)) {
				$DeadlineDate = Get-Date $user.DeadlineDate -Format 'yyyy-MM-dd 23:59:59'
				$user = $user.Name
				Write-Output "Getting info for $($user) with Deadline of $($DeadlineDate)"
				$usrname = $AllUsers | Where-Object -FilterScript {
					$_.name -like "*$user*" -and $_.name -notcontains '_'
				}
				IF ($usrname) {
					IF ($usrname.count -gt 1) {
						$smsid = ($usrname[0].SMSID).Replace('PAYLOCITY\', '')
					} ELSE {
						$smsid = $usrname.SMSID.Replace('PAYLOCITY\', '')
					}
					IF ($smsid) {
						Write-Output "Getting machine info for $($user)."
						$computer = $AllMachines | Where-Object -FilterScript {
							$_.UserName -eq "$smsid"
						} | Sort-Object -Property LastDDR | Select-Object -Property Name, UserName, IsActive, LastDDR, ResourceID, DeviceOS -Last 1
						IF ($computer) {
							Write-Output "Found machine info for $($user): $($computer.Name)"
							$warrantydate = Get-WarrantyEndDate -ComputerName $($computer.name)
                            SWITCH ($computer.DeviceOS) {
								'Microsoft Windows NT Workstation 6.3' {$OS = 'Windows8.1'}
								'Microsoft Windows NT Workstation 10.0' {$OS = 'Windows10'}
							}
							IF ($OS -eq 'Windows10') {
								$Results += New-Object -TypeName 'PSObject' -Property @{
									UserName	 = $smsid
									ComputerName = $($computer.name)
									ResourceID   = $($computer.resourceID)
									DeadlineDateReq = ''
									Note		 = 'Already on Win10'
									WarrantyEnd  = $warrantydate
									OS		     = $OS
								}
							} ELSE {
								$Results += New-Object -TypeName 'PSObject' -Property @{
									UserName	 = $smsid
									ComputerName = $($computer.name)
									ResourceID   = $($computer.resourceID)
									DeadlineDateReq = $DeadlineDate
									Note		 = ''
									WarrantyEnd  = $warrantydate
									OS		     = $OS
								}
							}
							
						} ELSEIF (!$smsid) {
							Write-Output "No machine info for $($user)."
							$Results += New-Object -TypeName 'PSObject' -Property @{
								UserName	    = ($user)
								ComputerName    = ''
								DeadlineDateReq = $DeadlineDate
								Note		    = 'ComputerNotFound'
							}
						}
					}
				} ELSEIF (!$usrname) {
					Write-Output "No info for $($user)."
					$Results += New-Object -TypeName 'PSObject' -Property @{
						UserName	    = $user
						ComputerName    = ''
						DeadlineDateReq = $DeadlineDate
						Note		    = 'UserNotFound'
					}
				}
				# Garbage cleanup
				# Clear-Variable -Name smsid, computer, usrname, DeadlineDate, user
			}
		}
	} CATCH {
		Write-Output 'Could not parse CSV.'
		$Error
		Write-Output "error above"
		Set-Location -Path $StartingLocation
		BREAK
	}

	# Create Collections based on unique Deadline Dates
	#PAUSE
IF(!$NoAddToCollection){
	TRY {
		Set-Location -Path "$($SiteCode.Name):\"
		#region Deployment Variables
		#Add to collection

        Switch($InternalOrIBCM){
            Internal {$NewCollection = Get-CMCollection -Id 'PAY0019F'} # "Upgrade to Windows 10 - Internal Network Only"
            IBCM {$NewCollection = Get-CMCollection -Id 'PAY00251'} # "Upgrade to Windows 10 - Remote or VPN" (IBCM)

        }
			$Results | ForEach-Object{
                IF(($_.ResourceID -match '^[0-9]{8,8}') -and ($_.DeviceOS -ne 'Windows10')){
                    Write-Output "Adding $($_.ComputerName) to $($NewCollection.Name)"
					Add-CMDeviceCollectionDirectMembershipRule -CollectionName $NewCollection.Name -ResourceId $_.ResourceID
					Add-Member -InputObject $_ -MemberType NoteProperty -Name 'CollectionAddedTo' -Value "$($NewCollection.Name) - $($NewCollection.CollectionID)"
                }
			}
		
		    # Email Gun if managers schedule install date

            # Trigger computer policy on collection
            Invoke-CMClientNotification -DeviceCollectionId $NewCollection.CollectionID -NotificationType RequestMachinePolicyNow

		 #end of create collections

		
		
	} CATCH {
		Write-Host 'Collections failed'
		Set-Location -Path $StartingLocation
		BREAK
	}
}
$Results | ft
	
} CATCH {
	Write-Output 'Something went wrong in the body'
	BREAK
}
#} #end function block
#endregion FUNCTION Set-InPlaceUpgrades

#$Results2 = Set-InPlaceUpgrades -CSV C:\temp\2018-09-10.csv -InternalOrIBCM IBCM -NoAddToCollection

#$Results2 | Sort-Object OS,Computername | Format-Table ComputerName,ResourceID,UserName,WarrantyEnd,OS,Note,CollectionAddedTo -AutoSize