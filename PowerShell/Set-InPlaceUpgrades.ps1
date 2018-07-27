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
	
	.PARAMETER StagingTS
		Package ID for TS to stage OS and drivers.
	
	.PARAMETER UpgradeTS
		Package ID for TS to run upgrade based on cached OS and drivers.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.152
		Created on:   	6/22/2018 8:30 AM
		Created by:   	
		Organization: 	
		Filename:
		===========================================================================
#>
[CmdletBinding()]
PARAM
(
	[Parameter(Mandatory = $true)][ValidateScript({
			Test-Path -Path $_ -PathType Leaf
		})][ValidateNotNullOrEmpty()][string]$CSV
	#[Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-zA-Z]{3}[0-9a-fA-F]{5}$')][ValidateNotNullOrEmpty()][string]$StagingTS,
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
	
	FUNCTION Convert-FromUnixDate ($UnixDate) {
		[timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
	}
	$apiKey = "key"
	$response = Invoke-RestMethod -Uri "https://domain.oomnitza.com/api/v3/assets?filter=device_name eq '$($ComputerName)'" -Method GET -Headers @{
		"Authorization2" = $apiKey
	}
	Convert-FromUnixDate -UnixDate $response.warranty_end_date | Get-Date -Format "yyyy-MM-dd"
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
						$smsid = ($usrname[0].SMSID).Replace('domain\', '')
					} ELSE {
						$smsid = $usrname.SMSID.Replace('domain\', '')
					}
					IF ($smsid) {
						Write-Output "Getting machine info for $($user)."
						$computer = $AllMachines | Where-Object -FilterScript {
							$_.UserName -eq "$smsid"
						} | Sort-Object -Property LastDDR | Select-Object -Property Name, UserName, IsActive, LastDDR, ResourceID -Last 1
						IF ($computer) {
							Write-Output "Found machine info for $($user): $($computer.Name)"
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
									WarrantyEnd  = Get-WarrantyEndDate -ComputerName $($computer.name)
									OS		     = $OS
								}
							} ELSE {
								$Results += New-Object -TypeName 'PSObject' -Property @{
									UserName	 = $smsid
									ComputerName = $($computer.name)
									ResourceID   = $($computer.resourceID)
									DeadlineDateReq = $DeadlineDate
									Note		 = ''
									WarrantyEnd  = Get-WarrantyEndDate -ComputerName $($computer.name)
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
				Clear-Variable -Name smsid, computer, usrname, DeadlineDate, user
			}
		}
	} CATCH {
		Write-Output 'Could not parse CSV.'
		$Error
		Write-Output "error above"
		Set-Location -Path $StartingLocation
		BREAK
	}
	
	Set-Location -Path $StartingLocation
	IF ((Get-Location) -like "*$($SiteCode.Name):*") {
		BREAK
	}
	TRY {
		#$Results | Format-Table -AutoSize
		# Set Deadline key
		$Results | ForEach-Object -Process {
			$Ping = Test-Connection -ComputerName $_.ComputerName -Count 1 -ErrorAction SilentlyContinue -Quiet
			IF ($Ping) {
				IF (!(Test-WSMan -ComputerName $_.ComputerName)) {
					$EnableWinRM = Enable-WinRM -PCName $_.ComputerName
				}
				Add-Member -InputObject $_ -MemberType NoteProperty -Name 'Online' -Value 'True'
				$DeadlineDate = Get-Date $_.DeadlineDateReq -Format 'yyyy-MM-dd 23:59:59'
				$NewValue = ''
				$KeyValue = Invoke-Command -ComputerName $_.ComputerName -ArgumentList $DeadlineDate, $NewValue -ScriptBlock {
					PARAM ($DeadlineDate,
						$NewValue)
					$InPlaceUpgradeKey = 'HKLM:\SOFTWARE\Domain\InPlaceUpgrade'
					IF (!(Test-Path $InPlaceUpgradeKey)) {
						New-Item -Path $InPlaceUpgradeKey -Force -ErrorAction SilentlyContinue
						New-ItemProperty -Path $InPlaceUpgradeKey -Name 'DeadlineDate' -Value "$DeadlineDate" -Force -ErrorAction SilentlyContinue
					} ELSEIF (Test-Path $InPlaceUpgradeKey) {
						New-ItemProperty -Path $InPlaceUpgradeKey -Name 'DeadlineDate' -Value "$DeadlineDate" -Force -ErrorAction SilentlyContinue
					}
					IF ((Get-ItemProperty -Path $InPlaceUpgradeKey).DeadlineDate -eq $DeadlineDate) {
						$NewValue = (Get-ItemProperty -Path $InPlaceUpgradeKey).DeadlineDate
						$NewValue
					} ELSE {
						$NewValue = 'FailedRegKeyWrite'
						$NewValue
					}
				}
				Write-Output "Value should be: $($KeyValue)"
				Add-Member -InputObject $_ -MemberType NoteProperty -Name 'DeadlineSet' -Value $($KeyValue.DeadlineDate)
			} ELSEIF (!$Ping) {
				Add-Member -InputObject $_ -MemberType NoteProperty -Name 'Online' -Value 'False'
			}
			# Garbage Cleanup
			Clear-Variable -Name Ping,KeyValue
		}
	} CATCH {
		Write-Output 'Could not set Deadline registry keys.'
	}
	
	# Create Collections based on unique Deadline Dates
	PAUSE
	TRY {
		Set-Location -Path "$($SiteCode.Name):\"
		#region Deployment Variables
        $TaskSequences = @()
        $Applications = @()
		$TaskSequences += New-Object -TypeName 'PSObject' -Property @{
            Name = 'Staging OS and Drivers'
            ID = 'PAY004DD'
            Type = 'Required'
        }
        $TaskSequences += New-Object -TypeName 'PSObject' -Property @{
            Name = 'Upgrade to Windows 10 1709 - IBCM - Staged'
            ID = 'PAY004E1'
            Type = 'Available'
        }
        $Applications += New-Object -TypeName 'PSObject' -Property @{
		    Name = 'Windows 10 In-Place Upgrade - IBCM PAY004E1'
            ID = 'PAY00526'
            Type = 'Required'
        }
		$LimitColID_AllWinWork = 'PAY0000B' #All Windows Workstations
		$ExclColIDs = @('PAY00198', #All Windows 10
			'PAY0028D' #All_WindowsUpdates_Groups
		)
		
		
		#Create Collection(s)
		#get unique deadline dates
		$UniqueDeadlines = $Results | foreach{$_.DeadlineDateReq} | Get-Unique
		FOREACH ($UniqueDeadline IN $UniqueDeadlines) {
			$CollDate = $UniqueDeadline | Get-Date -Format "yyyy-MM-dd"
            $CollName = "DAF.Windows10Upgrade.$($CollDate)"
            $TaskSequences|%{$CommentDepl += "`n$($_.Name) ($($_.ID))" }
            $Applications|%{$CommentDepl += "`n$($_.Name) ($($_.ID))" }
            $CollComment = "InPlace Upgrades Deployed with Deadline of $($CollDate).`nDeployments:`n$CommentDepl"
			$NewCollection = New-CMCollection -CollectionType Device -Comment "$CollComment" -LimitingCollectionId $LimitColID_AllWinWork -Name $CollName 
			$NewCollection | Move-CMObject -FolderPath ".\DeviceCollection\OSD\WindowsUpgrade\Upgrade - Deadlines"
			
			$ExclColIDs | ForEach-Object{
				Add-CMDeviceCollectionExcludeMembershipRule -CollectionName $NewCollection.Name -ExcludeCollectionId $_
			}
			
			$Results | ForEach-Object{
                IF($_.ResourceID -match '^[0-9]{8,8}' -and $_.DeviceOS -ne 'Windows10' -and $_.DeadlineDateReq -eq $UniqueDeadline){
                    Write-Output "Adding $($_.ComputerName) to $($NewCollection.Name)"
					Add-CMDeviceCollectionDirectMembershipRule -CollectionName $NewCollection.Name -ResourceId $_.ResourceID
					Add-Member -InputObject $_ -MemberType NoteProperty -Name 'CollectionAddedTo' -Value "$($NewCollection.Name) - $($NewCollection.CollectionID)"
                }
			}
		    #Set Staging TS deployment, required, asap, Internet ok
            $CollDate = $CollDate|Get-Date -Format "yyyy-MM-dd 16:00:00"
            $DeplComment = "InPlace Upgrades Deployed with Deadline of $($CollDate)."
		    $TaskSequences | foreach{
                $GetTS = Get-CMTaskSequence -Name $($_.Name)
                IF($_.Type -eq 'available'){
                    $GetTS | New-CMTaskSequenceDeployment -CollectionId $NewCollection.CollectionID -AvailableDateTime (Get-Date).AddDays(1) -DeadlineDateTime $CollDate -AllowFallback $True -AllowSharedContent $True -Availability Clients -DeploymentOption DownloadAllContentLocallyBeforeStartingTaskSequence -DeployPurpose Available -InternetOption $True -RerunBehavior RerunIfFailedPreviousAttempt -RunFromSoftwareCenter $True -ShowTaskSequenceProgress $True -SoftwareInstallation $True -SystemRestart $True
                }ELSEIF($_.Type -eq 'required'){
                    $GetTS | New-CMTaskSequenceDeployment -CollectionId $NewCollection.CollectionID -AllowFallback $True -AllowSharedContent $True -Availability Clients -DeploymentOption DownloadContentLocallyWhenNeededByRunningTaskSequence -DeployPurpose Required -InternetOption $True -RerunBehavior RerunIfFailedPreviousAttempt -RunFromSoftwareCenter $False -ShowTaskSequenceProgress $False -SoftwareInstallation $True -SystemRestart $False
                }
            }
		    #Set upgrade, available, pre-stage, internet ok
		
		    #Set CYOA, Required +1 Day, internet ok
            $AppCommnt = "InPlace Upgrades Deployed with Deadline of $($CollDate)."
            $Applications | foreach{
                $GetApp = Get-CMApplication -Name $_.Name
                $GetApp | New-CMApplicationDeployment -ApprovalRequired $false -DeployAction Install -DeployPurpose Required -PreDeploy $true -UserNotification DisplaySoftwareCenterOnly -Comment $AppCommnt -CollectionId $NewCollection.CollectionID -AvailableDateTime (Get-Date).AddDays(1) -RebootOutsideServiceWindow $true
            }
		
		    # Email Gun if managers schedule install date

            # Trigger computer policy on collection
            Invoke-CMClientNotification -DeviceCollectionId $NewCollection.CollectionID -NotificationType RequestMachinePolicyNow

		} #end of create collections

		
		
	} CATCH {
		Write-Host 'Collections failed'
		Set-Location -Path $StartingLocation
		BREAK
	}
	
} CATCH {
	Write-Output 'Something went wrong in the body'
	BREAK
}
