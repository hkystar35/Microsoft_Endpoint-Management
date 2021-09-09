$ScriptName = 'AddCSdevcesToCollections'
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
FUNCTION Add-CMMembersToCollection {
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$collectionName,
		[Parameter(Mandatory = $true)][ValidateSet('DEVICE', 'USER')][string]$collectionType,
		$existingMembers,
		[ValidateNotNullOrEmpty()][array]$newMembers
	)
	
	TRY {
		Write-Log -Message "$($newMembers.count) members to add to collection $CollectionName"
		
		#NEW 
		SWITCH ($collectionType) {
			'DEVICE' {
				$collectionId = Get-CMDeviceCollection -Name $collectionName | Select-Object -ExpandProperty CollectionID | Select-Object -first 1
				$ResourceClassName = "SMS_R_System"
			}
			
			'USER' {
				$collectionId = Get-CMUserCollection -Name $collectionName | Select-Object -ExpandProperty CollectionID | Select-Object -first 1
				$ResourceClassName = "SMS_R_User"
			}
		}
		Write-Log -Message "Collection Type: $collectionType,  Name $($collectionName), and ID: $collectionId"
		
		$SccmServer = 'AH-SCCM-01'
		$SCCMSiteCode = 'PAY'
		$SccmNamespace = "root\sms\site_$($SCCMSiteCode)"
		$coll = [wmi]"\\$($SccmServer)\root\sms\site_$($SCCMSiteCode):SMS_Collection.CollectionId='$collectionId'"
		$ruleClass = [WMICLASS]"\\$($SccmServer)\root\sms\site_$($SCCMSiteCode):SMS_CollectionRuleDirect"
		[array]$rules = $null
		#END NEW
		
		$count = 0
		FOREACH ($newMember IN $newMembers.GetEnumerator()) {
			
			IF ($newMember -ne $null) {
				Write-Log -Message "Device Name: $($newMember.name) and ResourceID: $($newMember.resourceid)"
					#NEW
					$newRule = $ruleClass.CreateInstance()
					$newRule.RuleName = $($newMember.name)
					$newRule.ResourceClassName = $ResourceClassName
					$newRule.ResourceID = $($newMember.resourceid)
					$rules += $newRule
					#END NEW
				
				Write-Log -Message " $($newMember.name) added to collection"
				$count++
			} ELSE {
				Write-Log -Message " $($newMember.name) was not found in SCCM, skipping" -Level Warn
				Write-Log -Message " $($newMember) was not found in SCCM, skipping" -Level Warn
			}
		}
		
		#NEW
		IF ($rules.Count -gt 0) {
			#Add all the rules in the array    
			#See: http://msdn.microsoft.com/en-us/library/hh949023.aspx         
			$coll.AddMembershipRules($rules) | Out-Null
			
			#Refresh the collection
			$coll.requestrefresh() | Out-Null
		}
		#END NEW
		Write-Host $count" new members added to collection "$collectionName
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log -Message "Error: $_" -Level Error
		Write-Log -Message "Error: on line $line" -Level Error
	}
	
}

TRY {
	$CollectionNames = 'DAF.CrowdStrike.Phase3',
	'DAF.CrowdStrike.Phase4',
	'DAF.CrowdStrike.Phase5',
	'DAF.CrowdStrike.Phase6'
	
	$Date = Get-Date
	$LimitingCollection = Get-CMCollection -Name 'All Windows Workstations' -CollectionType Device
	$RefreshSchedule = New-CMSchedule -DayOfWeek Monday
	$NeedsCrowdStrikeCollection = Get-CMCollectionMember -CollectionName 'CrowdStrike_NotInstalled' # | select -ExpandProperty Name
	
	
	$MemberCount = $NeedsCrowdStrikeCollection.count
	#$MemberCount
	$Parts = 4
	$PartSize = [Math]::Ceiling($MemberCount / $Parts)
	#$PartSize
	$outArray = @()
	#$outArray
	FOR ($i = 1; $i -le $Parts; $i++) {
		$Start = (($i - 1) * $PartSize)
		$End = (($i) * $PartSize) - 1
		IF ($End -ge $MemberCount) {
			$End = $MemberCount
		}
		$outArray += ,@($NeedsCrowdStrikeCollection[$start .. $end])
	}
	
	#$outArray | %{"$_"}
	
	$NewCollections = @()
	FOREACH ($CollectionName IN $CollectionNames) {
		$Comment = @"
Forced Device Deployment for $($CollectionName.split('.')[2])
Collection created via script on $(Get-Date -Format yyyyMMdd-HHmmss)
"@
		$NewCollectionArgs = @{
			Name				   = $CollectionName
			CollectionType		   = 'Device'
			Comment			       = $Comment
			LimitingCollectionName = $LimitingCollection.Name
			RefreshSchedule	       = $RefreshSchedule
			RefreshType		       = 'Periodic'
		}
		$CollectionExist = Get-CMCollection -Name $NewCollectionArgs.Name -CollectionType $NewCollectionArgs.CollectionType -ErrorAction SilentlyContinue
        IF(!$CollectionExist){
            $NewCollections += New-CMCollection @NewCollectionArgs
        }ELSE{
            Write-Log -Message "Collection $($NewCollectionArgs.Name) already exists."
            $NewCollections += $CollectionExist
        }
        Clear-Variable CollectionExist -ErrorAction SilentlyContinue
	}
} CATCH {
	$Line = $_.InvocationInfo.ScriptLineNumber
	Write-host "Error: $_"
	Write-Host "Error: on line $line"
}

$i = 0
FOREACH ($Collection IN $NewCollections) {
	TRY {
		IF ($outArray[$($i)]) {
			Add-CMMembersToCollection -collectionName $Collection.Name -collectionType 'Device' -newMembers $outArray[$($i)]
			$i++
		} ELSE {
			Write-Host "Array $i does not exist" -ForegroundColor Red
		}
	} CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-host "Error: $_"
		Write-Host "Error: on line $line"
	}
}


$NewCollections | %{
    $Phase = $($_.name.split('.')[2])
    Switch($Phase){
        'Phase1' {$DeadlineDate = '9/10/2019 09:00am'| Get-Date}
        'Phase2' {$DeadlineDate = '9/12/2019 09:00am'| Get-Date}
        'Phase3' {$DeadlineDate = '9/17/2019 09:00am'| Get-Date}
        'Phase4' {$DeadlineDate = '9/19/2019 09:00am'| Get-Date}
    }
    $DeploymentArgs = @{
        Name = "CrowdStrike Falcon"
        CollectionId = $_.CollectionID
        DeployAction = 'Install'
        DeployPurpose = 'Required'
        PreDeploy = $true
        TimeBaseOn = 'LocalTime'
        ReplaceToastNotificationWithDialog = $true
        AvailableDateTime = '9/3/2019 09:00am'| Get-Date
        DeadlineDateTime = $DeadlineDate
        UserNotification = 'DisplaySoftwareCenterOnly'
    }
    Write-host $Phase $DeadlineDate $_.Name
    New-CMApplicationDeployment @DeploymentArgs #-WhatIf
    #Remove-Variable deadlinedate,phase,deploymentargs -ErrorAction SilentlyContinue
}