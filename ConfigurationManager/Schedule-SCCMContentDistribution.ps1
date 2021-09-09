#region Source: Startup.pss
#----------------------------------------------
#region Import Assemblies
#----------------------------------------------
[void][Reflection.Assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.Data, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
[void][Reflection.Assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
[void][Reflection.Assembly]::Load('System.DirectoryServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
#endregion Import Assemblies

#Define a Param block to use custom parameters in the project
#Param ($CustomParameter)

function Main {
<#
    .SYNOPSIS
        The Main function starts the project application.
    
    .PARAMETER Commandline
        $Commandline contains the complete argument string passed to the script packager executable.
    
    .NOTES
        Use this function to initialize your script and to call GUI forms.
		
    .NOTES
        To get the console output in the Packager (Forms Engine) use: 
		$ConsoleOutput (Type: System.Collections.ArrayList)
#>
	Param ([String]$Commandline)
		
	If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		[void][System.Windows.Forms.MessageBox]::Show("This must be run as administrator!`nPlease restart as administrator", "", 'OK', 'Error')
		Break
	}
	if (!(Get-Item -Path $script:LogPath))
	{
		New-Item -Path $script:LogPath -ItemType Directory
	}
	if((Show-MainForm_psf) -eq 'OK')
	{
		
	}
	
	$script:ExitCode = 0 #Set the exit code for the Packager
}
#endregion Source: Startup.pss

#region Source: Globals.ps1
	#--------------------------------------------
	# Declare Global Variables and Functions here
	#--------------------------------------------
	
	#region variables
	$script:Credentials = Get-Credential
	
	#region defaults
	$FromEmail = "$($env:COMPUTERNAME)@paylocity.com"
	$SMTPServer = "post.paylocity.com"
	$PrimarySiteServer = "AH-SCCM-01.paylocity.com"
	$script:DefaultTimezone = "(UTC-06:00) Central Time (US & Canada)" #must be in the "Display Name" format so it matches an item on the form
	$script:DPTableType = "DPGroup" #"DP" or "DPGroup" - Sets the default for the form, radio button allows to change
	$script:Action = "Distribute Content" #"Distribute Content", "Redistribute Content", or "Update Content" - Sets the default for the form, combobox allows to change
	$script:DistributionCheckInterval = "60" #Check interval in seconds for WMI query to see if package distribution in progress.
	$script:LogPath = "c:\ScheduleContent" #Log file location, it will be named ContentDistributionScheduler.log in the folder specified below
	#endregion defaults
	
	$script:ServerCIMSession = New-CimSession -ComputerName $PrimarySiteServer -Credential $script:Credentials -Name "ServerCIMSession"
	$MachineCIMSession = New-CimSession -Name "MachineCIMSession"
	$SiteCode = (Get-CimInstance -CimSession $script:ServerCIMSession -Namespace "root\sms" -ClassName "__Namespace").Name.Substring(5, 3)
	$Namespace = "root\sms\site_$SiteCode"
	$TimeZones = [system.timezoneinfo]::GetSystemTimeZones()
	$script:DPTable = @()
	$script:ContentTable = @()
	$script:ContentTableUpdated = $false
	$script:JobsComplete = $false
	$script:DetectedDependencies = $false
	$script:CheckDependencies = $false
	$script:WMITablesGenerated = $false
	
	$script:ContentTypes = @{
		Package				      = '0'
		DriverPackage			  = '3'
		TaskSequence			  = '4'
		SoftwareUpdatePackage	  = '5'
		Application			      = '8'
		OSImage				      = '257'
		BootImage				  = '258'
		OSUpgradeImage		      = '259'
	}
	
	#Arry for the 'job tracking' functions to add / check / remove jobs
	$JobTrackerList = New-Object System.Collections.ArrayList
	#endregion variables
	
	#region functions
	#region form functions
	function Test-WizardPage
	{
	<#
		Add TabPages and place the validation code in this function
	#>
		[OutputType([boolean])]
		param ([System.Windows.Forms.TabPage]$tabPage)
		if ($tabPage -eq $tabpage_Configuration)
		{
			if (!($errorprovider.GetError($textbox_NotificationRecipient)) -and ($combobox_Action.SelectedIndex -ge "0"))
			{
				return $true
			}
		}
		elseif ($tabPage -eq $tabpage_DPSelection)
		{
			if (($listview_SelectedDPGroups.Items.Count -ne 0) -or ($combobox_Action.SelectedItem.ToString() -eq "Update Content"))
			{
				return $true
			}
		}
		elseif ($tabPage -eq $tabpage_Content)
		{
			if ($listview_SelectedContent.Items.Count -ne 0)
			{
				return $true
			}
		}
		elseif ($tabPage -eq $tabpage_Summary)
		{
			return $true
		}
		#Add more pages here
		
		return $false
	}
	
	function Update-NavButtons
	{
		<# 
			.DESCRIPTION
			Validates the current tab and Updates the Next, Prev and Finish buttons.
		#>
		$enabled = Test-WizardPage $tabcontrolWizard.SelectedTab
		$buttonNext.Enabled = $enabled -and ($tabcontrolWizard.SelectedIndex -lt $tabcontrolWizard.TabCount - 1)
		$buttonBack.Enabled = $tabcontrolWizard.SelectedIndex -gt 0
		$buttonSchedule.Enabled = $enabled -and ($tabcontrolWizard.SelectedIndex -eq $tabcontrolWizard.TabCount - 1)
		#Uncomment to Hide Buttons
		#$buttonNext.Visible = ($tabcontrolWizard.SelectedIndex -lt $tabcontrolWizard.TabCount - 1)
		#$buttonFinish.Visible = ($tabcontrolWizard.SelectedIndex -eq $tabcontrolWizard.TabCount - 1)
	}
	
	function Update-DPGroupListviews
	{
		param
		(
			[parameter(Mandatory = $true)]
			$AvailableListview,
			[parameter(Mandatory = $true)]
			$SelectedListview
		)
		
		$AvailableListview.BeginUpdate()
		$AvailableListview.Items.Clear()
		foreach ($Group in $script:DPTable)
		{
			if (($Group.IsVisible) -and !($Group.IsSelected))
			{
				$AvailableListview.Items.Add($Group.Name).SubItems.Add($Group.Description)
			}
		}
		$AvailableListview.AutoResizeColumns('HeaderSize')
		$AvailableListview.EndUpdate()
		
		$SelectedListview.BeginUpdate()
		$SelectedListview.Items.Clear()
		foreach ($Group in $script:DPTable)
		{
			if ($Group.IsSelected)
			{
				$SelectedListview.Items.Add($Group.Name).SubItems.Add($Group.Description)
			}
		}
		$SelectedListview.AutoResizeColumns('HeaderSize')
		$SelectedListview.EndUpdate()
	}
	
	function Update-ContentListviews
	{
		param
		(
			[parameter(Mandatory = $true)]
			[System.Windows.Forms.ListView]$AvailableListview,
			[parameter(Mandatory = $true)]
			[System.Windows.Forms.ListView]$SelectedListview
		)
		
		$AvailableListview.BeginUpdate()
		$AvailableListview.Items.Clear()
		foreach ($Package in $script:ContentTable)
		{
			if (($Package.IsVisible) -and !($Package.IsSelected))
			{
				$Item = $AvailableListview.Items.Add($Package.Name)
				$Item.SubItems.Add($Package.ID)
				$Item.SubItems.Add($Package.Size)
			}
		}
		$AvailableListview.AutoResizeColumns('HeaderSize')
		$AvailableListview.EndUpdate()
		
		$SelectedListview.BeginUpdate()
		$SelectedListview.Items.Clear()
		foreach ($Package in $script:ContentTable)
		{
			if ($Package.IsSelected)
			{
				$Item = $SelectedListview.Items.Add($Package.Name)
				$Item.SubItems.Add($Package.ID)
				$Item.SubItems.Add($Package.Size)
			}
		}
		$SelectedListview.AutoResizeColumns('HeaderSize')
		$SelectedListview.EndUpdate()
		
	}
	#endregion form functions
	
	#region misc functions
	function Write-CMLogEntry
	{
		param (
			[parameter(Mandatory = $true, HelpMessage = "Value added to the log file.")]
			[ValidateNotNullOrEmpty()]
			[string]$Value,
			[parameter(Mandatory = $false, HelpMessage = "Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
			[ValidateNotNullOrEmpty()]
			[ValidateSet("1", "2", "3")]
			[string]$Severity = 1,
			[parameter(Mandatory = $false, HelpMessage = "Stage that the log entry is occuring in, log refers to as 'component'.")]
			[ValidateNotNullOrEmpty()]
			[string]$Component = "DistributionScheduler",
			[parameter(Mandatory = $false, HelpMessage = "Name of the log file that the entry will written to.")]
			[ValidateNotNullOrEmpty()]
			[string]$FileName = "ContentDistributionScheduler.log",
			[parameter(Mandatory = $false, HelpMessage = "Switch to return full log path.")]
			[switch]$ReturnLogPath
		)
		# Determine log file location
		$LogFilePath = Join-Path -Path $script:LogPath -ChildPath $FileName
		if ($ReturnLogPath)
		{
			return $LogFilePath
		}
		else
		{
			# Construct time stamp for log entry
			$Bias = Get-CimInstance -CimSession $MachineCIMSession -ClassName Win32_TimeZone | Select-Object -ExpandProperty Bias
			if ($Bias -match "-")
			{
				$Time = -join @((Get-Date -Format "HH:mm:ss.fff"), $Bias)
			}
			else
			{
				$Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", $Bias)
			}
			# Construct date for log entry
			$Date = (Get-Date -Format "MM-dd-yyyy")
			
			# Construct context for log entry
			$Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
			
			# Construct final log entry
			$LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""$($Component)"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
			
			# Add value to log file
			try
			{
				Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
			}
			catch [System.Exception] {
				Write-Warning -Message "Unable to append log entry to $FileName file. Error message: $($_.Exception.Message)"
			}
		}
	}
	
	function Reset-Log
	{
		#function checks to see if file in question is larger than the paramater specified if it is it will roll a log and delete the oldes log if there are more than x logs. 
		param ([string]$fileName,
			[int64]$filesize = 1mb,
			[int]$logcount = 5)
		
		$logRollStatus = $true
		if (test-path $filename)
		{
			$file = Get-ChildItem $filename
			if ((($file).length) -ige $filesize) #this starts the log roll 
			{
				$fileDir = $file.Directory
				$fn = $file.name #this gets the name of the file we started with 
				$files = Get-ChildItem $filedir | Where-Object{ $_.name -like "$fn*" } | Sort-Object lastwritetime
				$filefullname = $file.fullname #this gets the fullname of the file we started with 
				#$logcount +=1 #add one to the count as the base file is one more than the count 
				for ($i = ($files.count); $i -gt 0; $i--)
				{
					#[int]$fileNumber = ($f).name.Trim($file.name) #gets the current number of the file we are on 
					$files = Get-ChildItem $filedir | Where-Object{ $_.name -like "$fn*" } | Sort-Object lastwritetime
					$operatingFile = $files | Where-Object{ ($_.name).trim($fn) -eq $i }
					if ($operatingfile)
					{ $operatingFilenumber = ($files | Where-Object{ ($_.name).trim($fn) -eq $i }).name.trim($fn) }
					else
					{ $operatingFilenumber = $null }
					
					if (($operatingFilenumber -eq $null) -and ($i -ne 1) -and ($i -lt $logcount))
					{
						$operatingFilenumber = $i
						$newfilename = "$filefullname.$operatingFilenumber"
						$operatingFile = $files | Where-Object{ ($_.name).trim($fn) -eq ($i - 1) }
						write-host "moving to $newfilename"
						move-item ($operatingFile.FullName) -Destination $newfilename -Force
					}
					elseif ($i -ge $logcount)
					{
						if ($operatingFilenumber -eq $null)
						{
							$operatingFilenumber = $i - 1
							$operatingFile = $files | Where-Object{ ($_.name).trim($fn) -eq $operatingFilenumber }
							
						}
						write-host "deleting " ($operatingFile.FullName)
						remove-item ($operatingFile.FullName) -Force
					}
					elseif ($i -eq 1)
					{
						$operatingFilenumber = 1
						$newfilename = "$filefullname.$operatingFilenumber"
						write-host "moving to $newfilename"
						move-item $filefullname -Destination $newfilename -Force
					}
					else
					{
						$operatingFilenumber = $i + 1
						$newfilename = "$filefullname.$operatingFilenumber"
						$operatingFile = $files | Where-Object{ ($_.name).trim($fn) -eq ($i - 1) }
						write-host "moving to $newfilename"
						move-item ($operatingFile.FullName) -Destination $newfilename -Force
					}
					
				}
				
				
			}
			else
			{ $logRollStatus = $false }
		}
		else
		{
			$logrollStatus = $false
		}
		$LogRollStatus
	}
	
	function Get-TotalPackageSize
	{
		$TotalSizeInKB = 0
		$SelectedPackages = $script:ContentTable.where{ $_.IsSelected -eq $true }
		foreach ($Package in $SelectedPackages)
		{
			$TotalSizeInKB += $Package.RawSize
		}
		if ($TotalSizeInKB -le 1023)
		{
			$PackageSize = "$TotalSizeInKB KB"
		}
		elseif ($TotalSizeInKB -gt 1023 -and $TotalSizeInKB -le 1048575)
		{
			$PackageSize = "$(Convert-Size -From KB -To MB -Value $TotalSizeInKB) MB"
		}
		else
		{
			$PackageSize = "$(Convert-Size -From KB -To GB -Value $TotalSizeInKB) GB"
		}
		return $PackageSize
	}
	
	function Convert-Size
	{
		[cmdletbinding()]
		param (
			[validateset("Bytes", "KB", "MB", "GB", "TB")]
			[string]$From,
			[validateset("Bytes", "KB", "MB", "GB", "TB")]
			[string]$To,
			[Parameter(Mandatory = $true)]
			[double]$Value,
			[int]$Precision = 4
		)
		switch ($From)
		{
			"Bytes" { $value = $Value }
			"KB" { $value = $Value * 1024 }
			"MB" { $value = $Value * 1024 * 1024 }
			"GB" { $value = $Value * 1024 * 1024 * 1024 }
			"TB" { $value = $Value * 1024 * 1024 * 1024 * 1024 }
		}
		
		switch ($To)
		{
			"Bytes" { return $value }
			"KB" { $Value = $Value/1KB }
			"MB" { $Value = $Value/1MB }
			"GB" { $Value = $Value/1GB }
			"TB" { $Value = $Value/1TB }
			
		}
		
		return [Math]::Round($value, $Precision, [MidPointRounding]::AwayFromZero)
		
	}
	
	function New-LoopAction
	{
		<#
		.SYNOPSIS
			This function allows you to create a looping script with an exit condition
		#>
		[cmdletbinding(SupportsShouldProcess)]
		param
		(
			[parameter(Mandatory = $true)]
			# Provides the integer value that is part of the exit condition of the loop
			[int32]$LoopTimeout,
			[parameter(Mandatory = $true)]
			[ValidateSet('Seconds', 'Minutes', 'Hours', 'Days')]
			# Provides the time increment type for the loop timeout that is part of the exit condition of the loop
			[string]$LoopTimeoutType,
			[parameter(Mandatory = $true)]
			# Provides the integer delay in seconds between loops ($LoopDelayType defaults to seconds)
			[int32]$LoopDelay,
			[parameter(Mandatory = $false)]
			[ValidateSet('Milliseconds', 'Seconds')]
			# Provides the time increment type for the LoopDelay between loops (defaults to seconds)
			[string]$LoopDelayType = 'Seconds',
			[parameter(Mandatory = $true)]
			# A script block that will run inside the do-until loop, recommend encapsulating inside { }
			[scriptblock]$ScriptBlock,
			[parameter(Mandatory = $true)]
			# A script block that will act as the exit condition for the do-until loop, recommend encapsulating inside { }
			[scriptblock]$ExitCondition,
			[parameter(Mandatory = $false)]
			# A script block that will act as the script to run if the timeout occurs, recommend encapsulating inside { }
			[scriptblock]$IfTimeoutScript,
			[parameter(Mandatory = $false)]
			# A script block that will act as the script to run if the condition succeeds, recommend encapsulating inside { }
			[scriptblock]$IfSucceedScript
		)
		$paramNewTimeSpan = @{
			$LoopTimeoutType	 = $LoopTimeout
		}
		
		$TimeSpan = New-TimeSpan @paramNewTimeSpan
		$StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
		do
		{
			. $ScriptBlock
			
			$paramStartSleep = @{
				$LoopDelayType	   = $LoopDelay
			}
			Start-Sleep @paramStartSleep
		}
		until ((. $ExitCondition) -or $StopWatch.Elapsed -ge $TimeSpan)
		if (!(. $ExitCondition) -and $StopWatch.Elapsed -ge $TimeSpan -and $PSBoundParameters.ContainsKey('IfTimeoutScript'))
		{
			. $IfTimeoutScript
		}
		if ((. $ExitCondition) -and $PSBoundParameters.ContainsKey('IfSucceedScript'))
		{
			. $IfSucceedScript
		}
		$StopWatch.Reset()
	}
	#endregion misc functions
	
	#region jobtracker functions
	function Add-JobTracker
	{
	    <#
	        .SYNOPSIS
	            Add a new job to the JobTracker and starts the timer.
	    
	        .DESCRIPTION
	            Add a new job to the JobTracker and starts the timer.
	    
	        .PARAMETER  Name
	            The name to assign to the Job
	    
	        .PARAMETER  JobScript
	            The script block that the Job will be performing. 
	            Important: Do not access form controls from this script block.
	    
	        .PARAMETER ArgumentList
	            The arguments to pass to the job
	    
	        .PARAMETER  CompleteScript
	            The script block that will be called when the job is complete.
	            The job is passed as an argument. The Job argument is null when the job fails.
	    
	        .PARAMETER  UpdateScript
	            The script block that will be called each time the timer ticks. 
	            The job is passed as an argument. Use this to get the Job's progress.
	    
	        .EXAMPLE
	            Job-Begin -Name "JobName" `
	            -JobScript {    
	                Param($Argument1)#Pass any arguments using the ArgumentList parameter
	                #Important: Do not access form controls from this script block.
	                Get-WmiObject Win32_Process -Namespace "root\CIMV2"
	            }`
	            -CompletedScript {
	                Param($Job)        
	                $results = Receive-Job -Job $Job        
	            }`
	            -UpdateScript {
	                Param($Job)
	                #$results = Receive-Job -Job $Job -Keep
	            }
	    
	        .LINK
	            
	    #>
		
		Param (
			[ValidateNotNull()]
			[Parameter(Mandatory = $true)]
			[string]$Name,
			[ValidateNotNull()]
			[Parameter(Mandatory = $true)]
			[ScriptBlock]$JobScript,
			$ArgumentList = $null,
			[ScriptBlock]$CompletedScript,
			[ScriptBlock]$UpdateScript)
		
		#Start the Job
		$job = Start-Job -Name $Name -ScriptBlock $JobScript -ArgumentList $ArgumentList
		
		if ($job -ne $null)
		{
			#Create a Custom Object to keep track of the Job & Script Blocks
			$psObject = New-Object System.Management.Automation.PSObject
			
			Add-Member -InputObject $psObject -MemberType 'NoteProperty' -Name Job -Value $job
			Add-Member -InputObject $psObject -MemberType 'NoteProperty' -Name CompleteScript -Value $CompletedScript
			Add-Member -InputObject $psObject -MemberType 'NoteProperty' -Name UpdateScript -Value $UpdateScript
			
			[void]$JobTrackerList.Add($psObject)
			
			#Start the Timer
			if (-not $timer_JobTracker.Enabled)
			{
				$timer_JobTracker.Start()
			}
		}
		elseif ($CompletedScript -ne $null)
		{
			#Failed
			Invoke-Command -ScriptBlock $CompletedScript -ArgumentList $null
		}
		
	}
	
	function Update-JobTracker
	{
	    <#
	        .SYNOPSIS
	            Checks the status of each job on the list.
	    #>
		
		#Poll the jobs for status updates
		param
		(
			[System.Windows.Forms.ProgressBar]$ProgressBar,
			[System.Windows.Forms.GroupBox]$GroupBox1,
			[System.Windows.Forms.GroupBox]$GroupBox2
		)
		$timer_JobTracker.Stop() #Freeze the Timer
		
		for ($index = 0; $index -lt $JobTrackerList.Count; $index++)
		{
			$psObject = $JobTrackerList[$index]
			
			if ($psObject -ne $null)
			{
				if ($psObject.Job -ne $null)
				{
					if ($psObject.Job.State -ne "Running")
					{
						#Call the Complete Script Block
						if ($psObject.CompleteScript -ne $null)
						{
							#$results = Receive-Job -Job $psObject.Job
							Invoke-Command -ScriptBlock $psObject.CompleteScript -ArgumentList $psObject.Job
						}
						
						$JobTrackerList.RemoveAt($index)
						Remove-Job -Job $psObject.Job
						$index-- #Step back so we don't skip a job
					}
					elseif ($psObject.UpdateScript -ne $null)
					{
						#Call the Update Script Block
						Invoke-Command -ScriptBlock $psObject.UpdateScript -ArgumentList $psObject.Job
					}
				}
			}
			else
			{
				$JobTrackerList.RemoveAt($index)
				$index-- #Step back so we don't skip a job
			}
		}
		
		if ($JobTrackerList.Count -gt 0 -and !$script:WMITablesGenerated)
		{
			$timer_JobTracker.Start() #Resume the timer    
		}
		else
		{
			$script:WMITablesGenerated = $true
		}
		
		if ($script:WMITablesGenerated)
		{
			if ($script:ContentTableCreation -ne "Creating")
			{
				$script:ContentTableCreation = "Creating"
				$allFunctionDefs = "function Get-CMPackageInfo { ${function:Get-CMPackageInfo} }; function Convert-Size { ${function:Convert-Size} }"
				Add-JobTracker -Name "ContentTableGeneration" -JobScript {
					param
					(
						$allFunctionDefs,
						$script:Results,
						$script:CIIDs,
						$script:TaskSequenceReferences,
						$script:AppDependenceRelationships
					)
					.([System.Management.Automation.ScriptBlock]::Create($allFunctionDefs))
					Get-CMPackageInfo | Sort-Object -Property Name
				} -ArgumentList $allFunctionDefs, $script:Results, $script:CIIDs, $script:TaskSequenceReferences, $script:AppDependenceRelationships -CompletedScript {
					$script:JobsComplete = $true
					Receive-Job -Name "ContentTableGeneration" -OutVariable script:ContentTable
					$ProgressBar.Style = 'Continuous'
					$ProgressBar.Increment(100)
					$ProgressBar.TextOverlay = "Content Table Generated"
					$GroupBox1.Enabled = $true
					$GroupBox2.Enabled = $true
				}
			}
			if (!$script:JobsComplete)
			{
				$timer_JobTracker.Start() #Resume the timer    
			}
		}
		
		if ($script:JobsComplete -and $script:CheckDependencies -and !$script:ContentTableUpdated)
		{
			if ($script:DependencyCheck -ne "Started")
			{
				$ProgressBar.Style = 'Marquee'
				$script:DependencyCheck = "Started"
				$ProgressBar.TextOverlay = "Content Dependency Check in Progress"
				$GroupBox1.Enabled = $false
				$GroupBox2.Enabled = $false
				$allFunctionDefs = "function Get-CMDependencyChains { ${function:Get-CMDependencyChains} }; function Convert-Size { ${function:Convert-Size} }"
				Add-JobTracker -Name "ContentDependencyCheck" -JobScript {
					param
					(
						$allFunctionDefs,
						$script:Results,
						$script:CIIDs,
						$script:TaskSequenceReferences,
						$script:AppDependenceRelationships,
						$script:ContentTable
					)
					.([System.Management.Automation.ScriptBlock]::Create($allFunctionDefs))
					foreach ($Item in $script:ContentTable)
					{
						if ($Item.Type -eq "8")
						{
							$CIID = $script:CIIDs.where{ $_.ModelName -eq $Item.SecurityKey }.CI_ID
							$Item.CIID = $CIID
							$Item.Dependencies = $script:AppDependenceRelationships.where{ $_.FromApplicationCIID -eq $CIID }.ToApplicationCIID
						}
					}
					return $script:ContentTable
				} -ArgumentList $allFunctionDefs, $script:Results, $script:CIIDs, $script:TaskSequenceReferences, $script:AppDependenceRelationships, $script:ContentTable -CompletedScript {
					$script:ContentTableUpdated = $true
					Receive-Job -Name "ContentDependencyCheck" -OutVariable script:ContentTable
					$ProgressBar.Style = 'Continuous'
					$ProgressBar.Increment(100)
					$ProgressBar.TextOverlay = "Content Table Generated with Dependencies"
					$GroupBox1.Enabled = $true
					$GroupBox2.Enabled = $true
				}
			}
			if (!$script:ContentTableUpdated)
			{
				$timer_JobTracker.Start() #Resume the timer    
			}
		}
	}
	
	function Stop-JobTracker
	{
	   <#
	        .SYNOPSIS
	            Stops and removes all Jobs from the list.
	    #>
		#Stop the timer
		$timer_JobTracker.Stop()
		
		#Remove all the jobs
		while ($JobTrackerList.Count -gt 0)
		{
			$job = $JobTrackerList[0].Job
			$JobTrackerList.RemoveAt(0)
			Stop-Job $job
			Remove-Job $job
		}
	}
	#endregion jobtracker functions
	
	#region SCCM functions - WMI/CIM based 
	function Get-CMDistributionPoints
	{
		$ReturnValue = @()
		$DPs = Get-CimInstance -CimSession $script:ServerCIMSession -Namespace $Namespace -ClassName SMS_DistributionPointInfo -Property Name, Description, NALPath | Sort-Object Name
		foreach ($DP in $DPs)
		{
			$ReturnValue += [pscustomobject] @{
				Name			  = $($DP.Name);
				Description	      = $($DP.Description);
				IsSelected	      = $false;
				IsVisible		  = $true;
				NALPath		      = $($DP.NALPath);
			}
		}
		return $ReturnValue
	}
	
	function Get-CMDistributionPointGroups
	{
		$ReturnValue = @()
		$DPGroups = Get-CimInstance -CimSession $script:ServerCIMSession -Namespace $Namespace -ClassName SMS_DistributionPointGroup -Property Name, Description, GroupID | Sort-Object Name
		foreach ($Group in $DPGroups)
		{
			$ReturnValue += [pscustomobject] @{
				Name			  = $($Group.Name);
				Description	      = $($Group.Description);
				IsSelected	      = $false;
				IsVisible		  = $true;
				GroupID		      = $($Group.GroupID);
			}
		}
		return $ReturnValue
	}
	
	function Get-CMPackageInfo
	{
		$ReturnValue = @()
		$CIID = $null
		$TSRef = $null
		$Dependencies = $null
		
		foreach ($Result in $Results)
		{
			#region determine package size in a digestable format
			if ($Result.PackageType -ne "4")
			{
				if ($Result.PackageSize -le 1023)
				{
					$PackageSize = "$($Result.PackageSize) KB"
				}
				elseif ($Result.PackageSize -gt 1023 -and $Result.PackageSize -le 1048575)
				{
					$PackageSize = "$(Convert-Size -From KB -To MB -Value $Result.PackageSize) MB"
				}
				else
				{
					$PackageSize = "$(Convert-Size -From KB -To GB -Value $Result.PackageSize) GB"
				}
			}
			#endregion determine package size in a digestable format
			$ReturnValue += [pscustomobject] @{
				Name			    = $($Result.Name);
				ID				    = $($Result.PackageID);
				Size			    = $PackageSize;
				RawSize			    = $($Result.PackageSize);
				IsSelected		    = $false;
				IsVisible		    = $false;
				Type			    = $($Result.PackageType);
				SecurityKey		    = $($Result.SecurityKey);
				CIID			    = $CIID;
				TSRef			    = $TSRef;
				Dependencies	    = $Dependencies;
			}
			$CIID = $null
			$TSRef = $null
			$Dependencies = $null
			$PackageSize = $null
		}
		return $ReturnValue
	}
	
	function Get-CMTaskSequenceReferencedContent ($TSPackageID)
	{
		$TSRef = $script:TaskSequenceReferences.where{ $_.PackageID -eq $TSPackageID }.RefPackageID
		foreach ($Item in $script:ContentTable)
		{
			if ($TSRef -contains $Item.ID)
			{
				$Item.IsSelected = $true
			}
		}
	}
	
	function Get-CMDependencyChains
	{
		param
		(
			[parameter(Mandatory = $true)]
			[string]$PackageID
		)
		do
		{
			$Dependencies = $script:ContentTable.where{ $_.ID -eq $PackageID }.Dependencies
			foreach ($D in $Dependencies)
			{
				$CIID = $D
				$PackageID = $script:ContentTable.where{ $_.CIID -eq $D }.Id
				foreach ($App in $script:ContentTable)
				{
					if ($App.ID -eq $PackageID)
					{
						$App.IsSelected = $true
					}
				}
			}
		}
		until (!$Dependencies)
	}
	
	function Start-ContentDistribution
	{
		param
		(
			[parameter(Mandatory = $true)]
			[array]$PackageIDs,
			[parameter(Mandatory = $true)]
			[array]$DPArray,
			[parameter(Mandatory = $true)]
			[string]$SiteCode,
			[parameter(Mandatory = $true)]
			[string]$PrimarySiteServer,
			[parameter(Mandatory = $true)]
			[string]$Namespace,
			[parameter(Mandatory = $true)]
			[ValidateSet("DP", "DPGroup")]
			[string]$DPTableType,
			[parameter(Mandatory = $false)]
			[Microsoft.Management.Infrastructure.CimSession]$CimSession
		)
		if (!$CimSession)
		{
			$CimSession = New-CimSession -ComputerName $PrimarySiteServer
		}
		$DPArraySplit = $DPArray.Name -split ";"
		$PackageIDsSplit = $PackageIDs -split ";"
		Write-CMLogEntry -Value "Start-ContentDistribution [PackageIDs=$PackageIDsSplit] [DPArray=$DPArraySplit] [SiteCode=$SiteCode] [PrimarySiteServer=$PrimarySiteServer] [DPTableType=$DPTableType] [Namespace=$Namespace]" -Component "ScheduledJob"
		switch ($DPTableType)
		{
			DP {
				foreach ($DP in $DPArray)
				{
					foreach ($Package in $PackageIDs)
					{
						if (!($CIMObject = Get-CimInstance -CimSession $CimSession -Namespace "$Namespace" -ClassName SMS_DistributionPoint -Filter "ServerNALPath LIKE '%$($DP.Name)%' and PackageID='$Package'"))
						{
							try
							{
								$Properties = @{ PackageID = "$Package"; ServerNALPath = "$($DP.NALPath)"; SiteCode = "$SiteCode" }
								New-CimInstance -CimSession $CimSession -Namespace "$Namespace" -ClassName SMS_DistributionPoint -Property $Properties
								Write-CMLogEntry -Value "Content Distribution Started for $Package to $($DP.Name)" -Component "ScheduledJob"
							}
							catch
							{
								$ErrorMessage = $_.Exception.Message
								Write-CMLogEntry -Value "Failed to start Content Distribution for $Package to $($DP.Name)" -Severity 3 -Component "ScheduledJob"
								Write-CMLogEntry -Value "$ErrorMessage" -Severity 3 -Component "ScheduledJob"
							}
						}
						else
						{
							try
							{
								Write-CMLogEntry -Value "Content Distribution was requested for $Package to $($DP.Name), but the content already exists, skipping this instance of content <--> DP." -Component "ScheduledJob" -Severity 2
							}
							catch
							{
								$ErrorMessage = $_.Exception.Message
								Write-CMLogEntry -Value "Failed to start Content Redistribution for $Package to $($DP.Name)" -Severity 3 -Component "ScheduledJob"
								Write-CMLogEntry -Value "$ErrorMessage" -Severity 3 -Component "ScheduledJob"
							}
						}
					}
				}
			}
			DPGroup {
				foreach ($DPGroup in $DPArray)
				{
					foreach ($Package in $PackageIDs)
					{
						if (!(Get-CimInstance -CimSession $CimSession -Namespace "$Namespace" -ClassName SMS_DPGroupPackages -Filter "GroupID='$($DPGroup.GroupID)' and PkgID='$Package'"))
						{
							try
							{
								$paramInvokeCimMethod = @{
									Query	  = "Select * from sms_distributionpointgroup where Name='$($DPGroup.Name)'"
									CimSession = $CimSession
									Namespace = "$Namespace"
									MethodName = "AddPackages"
									Arguments = @{ PackageIDs = @("$Package") }
								}
								$Invocation = Invoke-CimMethod @paramInvokeCimMethod
								if ($Invocation.ReturnValue -eq 0)
								{
									Write-CMLogEntry -Value "Content Distribution Started for $Package to $($DPGroup.Name)" -Component "ScheduledJob"
								}
								else
								{
									throw "ERROR: Failed to start Content Distribution for $Package to $($DPGroup.Name)"
								}
							}
							catch
							{
								$ErrorMessage = $_.Exception.Message
								Write-CMLogEntry -Value "$ErrorMessage" -Severity 3 -Component "ScheduledJob"
							}
						}
						else
						{
							try
							{
								Write-CMLogEntry -Value "Content Distribution was requested for $Package to $($DPGroup.Name), but the content already exists. skipping this instance of content <--> DPgroup." -Component "ScheduledJob" -Severity 2
							}
							catch
							{
								$ErrorMessage = $_.Exception.Message
								Write-CMLogEntry -Value "Failed to start Content Redistribution for $Package to $($DPGroup.Name)" -Severity 3 -Component "ScheduledJob"
								Write-CMLogEntry -Value "$ErrorMessage" -Severity 3 -Component "ScheduledJob"
							}
						}
					}
				}
			}
		}
	}
	
	function Start-ContentRedistribution
	{
		param
		(
			[parameter(Mandatory = $true)]
			[array]$PackageIDs,
			[parameter(Mandatory = $true)]
			[array]$DPArray,
			[parameter(Mandatory = $true)]
			[string]$SiteCode,
			[parameter(Mandatory = $true)]
			[string]$PrimarySiteServer,
			[parameter(Mandatory = $true)]
			[string]$Namespace,
			[parameter(Mandatory = $true)]
			[ValidateSet("DP", "DPGroup")]
			[string]$DPTableType,
			[parameter(Mandatory = $false)]
			[Microsoft.Management.Infrastructure.CimSession]$CimSession
		)
		if (!$CimSession)
		{
			$CimSession = New-CimSession -ComputerName $PrimarySiteServer
		}
		Write-CMLogEntry -Value "Start-ContentRedistribution [PackageIDs=$PackageIDsSplit] [DPArray=$DPArraySplit] [SiteCode=$SiteCode] [PrimarySiteServer=$PrimarySiteServer] [DPTableType=$DPTableType] [Namespace=$Namespace]" -Component "ScheduledJob"
		switch ($DPTableType)
		{
			DP {
				foreach ($DP in $DPArray)
				{
					foreach ($Package in $PackageIDs)
					{
						if ($CIMObject = Get-CimInstance -CimSession $CimSession -Namespace "$Namespace" -ClassName SMS_DistributionPoint -Filter "ServerNALPath LIKE '%$($DP.Name)%' and PackageID='$Package'")
						{
							try
							{
								$CIMObject | Set-CimInstance -CimSession $CimSession -Property @{ RefreshNow = $true }
								Write-CMLogEntry -Value "Content Redistribution Started for $Package to $($DP.Name)" -Component "ScheduledJob"
							}
							catch
							{
								$ErrorMessage = $_.Exception.Message
								Write-CMLogEntry -Value "Failed to start Content Redistribution for $Package to $($DP.Name)" -Severity 3 -Component "ScheduledJob"
								Write-CMLogEntry -Value "$ErrorMessage" -Severity 3 -Component "ScheduledJob"
							}
						}
						else
						{
							try
							{
								$Properties = @{ PackageID = "$Package"; ServerNALPath = "$($DP.NALPath)"; SiteCode = "$SiteCode" }
								New-CimInstance -CimSession $CimSession -Namespace "$Namespace" -ClassName SMS_DistributionPoint -Property $Properties
								Write-CMLogEntry -Value "Content Redistribution was requested for $Package to $($DP.Name), but the content was not found. Distributing the content instead." -Component "ScheduledJob" -Severity 2
							}
							catch
							{
								$ErrorMessage = $_.Exception.Message
								Write-CMLogEntry -Value "Failed to start Content Distribution for $Package to $($DP.Name)" -Severity 3 -Component "ScheduledJob"
								Write-CMLogEntry -Value "$ErrorMessage" -Severity 3 -Component "ScheduledJob"
							}
						}
					}
				}
			}
			DPGroup {
				foreach ($DPGroup in $DPArray)
				{
					foreach ($Package in $PackageIDs)
					{
						if (Get-CimInstance -CimSession $CimSession -Namespace "$Namespace" -ClassName SMS_DPGroupPackages -Filter "GroupID='$($DPGroup.GroupID)' and PkgID='$Package'")
						{
							try
							{
								$paramInvokeCimMethod = @{
									Query    = "Select * from sms_distributionpointgroup where Name='$($DPGroup.Name)'"
									CimSession = $CimSession
									Namespace = "$Namespace"
									MethodName = "ReDistributePackage"
									Arguments = @{ PackageID = $Package }
								}
								$Invocation = Invoke-CimMethod @paramInvokeCimMethod
								if ($Invocation.ReturnValue -eq 0)
								{
									Write-CMLogEntry -Value "Content Redistribution Started for $Package to $($DPGroup.Name)" -Component "ScheduledJob"
								}
								else
								{
									throw "ERROR: Failed to start Content Redistribution for $Package to $($DPGroup.Name)"
								}
							}
							catch
							{
								$ErrorMessage = $_.Exception.Message
								Write-CMLogEntry -Value "Failed to start Content Redistribution for $Package to $($DPGroup.Name)" -Severity 3 -Component "ScheduledJob"
								Write-CMLogEntry -Value "$ErrorMessage" -Severity 3 -Component "ScheduledJob"
							}
						}
						else
						{
							try
							{
								$paramInvokeCimMethod = @{
									Query    = "Select * from SMS_DistributionPointGroup where Name='$($DPGroup.Name)'"
									CimSession = $CimSession
									Namespace = "$Namespace"
									MethodName = "AddPackages"
									Arguments = @{ PackageIDs = @($Package) }
								}
								$Invocation = Invoke-CimMethod @paramInvokeCimMethod
								if ($Invocation.ReturnValue -eq 0)
								{
									Write-CMLogEntry -Value "Content Redistribution was requested for $Package to $($DPGroup.Name), but the content was not found. Distributing the content instead." -Component "ScheduledJob" -Severity 2
								}
								else
								{
									throw "ERROR: Failed to start Content Distribution for $($PackageIDs -join "; ") to $($DPGroup.Name)"
								}
							}
							catch
							{
								$ErrorMessage = $_.Exception.Message
								Write-CMLogEntry -Value "$ErrorMessage" -Severity 3 -Component "ScheduledJob"
							}
						}
					}
				}
			}
		}
	}
	
	function Start-ContentUpdate
	{
		param
		(
			[parameter(Mandatory = $true)]
			[array]$Packages,
			[parameter(Mandatory = $true)]
			[string]$SiteCode,
			[parameter(Mandatory = $true)]
			[string]$PrimarySiteServer,
			[parameter(Mandatory = $false)]
			[Microsoft.Management.Infrastructure.CimSession]$CimSession
		)
		if (!$CimSession)
		{
			$CimSession = New-CimSession -ComputerName $PrimarySiteServer
		}
		foreach ($Package in $Packages)
		{
			$PackageType = @{
				0 = 'SMS_Package'
				3 = 'SMS_DriverPackage'
				5 = 'SMS_SoftwareUpdatesPackage'
				8 = 'SMS_ContentPackage'
				257 = 'SMS_ImagePackage'
				258 = 'SMS_BootImagePackage'
			}
			$ClassName = $PackageTypes[$Package.Type]
			try
			{
				$paramInvokeCimMethod = @{
					Query    = "Select * from $ClassName where PackageID='$($Package.ID)'"
					CimSession = $CimSession
					Namespace = "$Namespace"
					MethodName = "RefreshPkgSource"
				}
				Invoke-CimMethod @paramInvokeCimMethod
				Write-CMLogEntry -Value "Update Content Started for $($Package.Name)" -Component "ScheduledJob"
			}
			catch
			{
				Write-CMLogEntry -Value "Failed to start Update Content for $($Package.Name)" -Severity 3 -Component "ScheduledJob"
				Write-CMLogEntry -Value "$ErrorMessage" -Severity 3 -Component "ScheduledJob"
			}
		}
	}
	#endregion SCCM functions - WMI/CIM based 
	#endregion functions
	
#endregion Source: Globals.ps1

#region Source: MainForm.psf
function Show-MainForm_psf
{
	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Data, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	[void][reflection.assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	#endregion Import Assemblies

	#----------------------------------------------
	#region Define SAPIEN Types
	#----------------------------------------------
	try{
		[ProgressBarOverlay] | Out-Null
	}
	catch
	{
		Add-Type -ReferencedAssemblies ('System.Windows.Forms', 'System.Drawing') -TypeDefinition  @" 
		using System;
		using System.Windows.Forms;
		using System.Drawing;
        namespace SAPIENTypes
        {
		    public class ProgressBarOverlay : System.Windows.Forms.ProgressBar
	        {
                public ProgressBarOverlay() : base() { SetStyle(ControlStyles.OptimizedDoubleBuffer | ControlStyles.AllPaintingInWmPaint, true); }
	            protected override void WndProc(ref Message m)
	            { 
	                base.WndProc(ref m);
	                if (m.Msg == 0x000F)// WM_PAINT
	                {
	                    if (Style != System.Windows.Forms.ProgressBarStyle.Marquee || !string.IsNullOrEmpty(this.Text))
                        {
                            using (Graphics g = this.CreateGraphics())
                            {
                                using (StringFormat stringFormat = new StringFormat(StringFormatFlags.NoWrap))
                                {
                                    stringFormat.Alignment = StringAlignment.Center;
                                    stringFormat.LineAlignment = StringAlignment.Center;
                                    if (!string.IsNullOrEmpty(this.Text))
                                        g.DrawString(this.Text, this.Font, Brushes.Black, this.ClientRectangle, stringFormat);
                                    else
                                    {
                                        int percent = (int)(((double)Value / (double)Maximum) * 100);
                                        g.DrawString(percent.ToString() + "%", this.Font, Brushes.Black, this.ClientRectangle, stringFormat);
                                    }
                                }
                            }
                        }
	                }
	            }
              
                public string TextOverlay
                {
                    get
                    {
                        return base.Text;
                    }
                    set
                    {
                        base.Text = value;
                        Invalidate();
                    }
                }
	        }
        }
"@ -IgnoreWarnings | Out-Null
	}
	#endregion Define SAPIEN Types

	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$formContentDistribution = New-Object 'System.Windows.Forms.Form'
	$progressbar_ContentTable = New-Object 'SAPIENTypes.ProgressBarOverlay'
	$linklabel_OpenLog = New-Object 'System.Windows.Forms.LinkLabel'
	$buttonCancel = New-Object 'System.Windows.Forms.Button'
	$buttonBack = New-Object 'System.Windows.Forms.Button'
	$buttonSchedule = New-Object 'System.Windows.Forms.Button'
	$tabcontrolWizard = New-Object 'System.Windows.Forms.TabControl'
	$tabpage_Configuration = New-Object 'System.Windows.Forms.TabPage'
	$checkbox_DetectDependencies = New-Object 'System.Windows.Forms.CheckBox'
	$radiobutton_TargetDPs = New-Object 'System.Windows.Forms.RadioButton'
	$radiobutton_TargetDPGroups = New-Object 'System.Windows.Forms.RadioButton'
	$combobox_Action = New-Object 'System.Windows.Forms.ComboBox'
	$label_Action = New-Object 'System.Windows.Forms.Label'
	$groupbox_DateTime = New-Object 'System.Windows.Forms.GroupBox'
	$label_TimeZone = New-Object 'System.Windows.Forms.Label'
	$combobox_TimeZone = New-Object 'System.Windows.Forms.ComboBox'
	$datetimepicker_ScheduledTime = New-Object 'System.Windows.Forms.DateTimePicker'
	$datetimepicker_ScheduleDay = New-Object 'System.Windows.Forms.DateTimePicker'
	$label_ScheduleDay = New-Object 'System.Windows.Forms.Label'
	$label_ScheduleTime = New-Object 'System.Windows.Forms.Label'
	$label_NotificationRecipient = New-Object 'System.Windows.Forms.Label'
	$textbox_NotificationRecipient = New-Object 'System.Windows.Forms.TextBox'
	$textbox_ScheduleInfo = New-Object 'System.Windows.Forms.TextBox'
	$tabpage_DPSelection = New-Object 'System.Windows.Forms.TabPage'
	$button_DeselectDPGroups = New-Object 'System.Windows.Forms.Button'
	$button_SelectDPGroups = New-Object 'System.Windows.Forms.Button'
	$groupbox_DPs = New-Object 'System.Windows.Forms.GroupBox'
	$listview_AvailableDPGroups = New-Object 'System.Windows.Forms.ListView'
	$label_AvailableDPGroupsFilter = New-Object 'System.Windows.Forms.Label'
	$textbox_AvailableDPGroupsFilter = New-Object 'System.Windows.Forms.TextBox'
	$groupbox_SelectedDPs = New-Object 'System.Windows.Forms.GroupBox'
	$button_ResetSelectedDPGroups = New-Object 'System.Windows.Forms.Button'
	$listview_SelectedDPGroups = New-Object 'System.Windows.Forms.ListView'
	$tabpage_Content = New-Object 'System.Windows.Forms.TabPage'
	$button_DeselectContent = New-Object 'System.Windows.Forms.Button'
	$button_SelectContent = New-Object 'System.Windows.Forms.Button'
	$groupbox_SelectedContent = New-Object 'System.Windows.Forms.GroupBox'
	$textbox_TotalContentSize = New-Object 'System.Windows.Forms.TextBox'
	$label_TotalContentSize = New-Object 'System.Windows.Forms.Label'
	$listview_SelectedContent = New-Object 'System.Windows.Forms.ListView'
	$button_ResetSelectedContent = New-Object 'System.Windows.Forms.Button'
	$groupbox_AvailableContent = New-Object 'System.Windows.Forms.GroupBox'
	$textbox_AvailableContentFilter = New-Object 'System.Windows.Forms.TextBox'
	$label_AvailableContentFilter = New-Object 'System.Windows.Forms.Label'
	$listview_AvailableContent = New-Object 'System.Windows.Forms.ListView'
	$combobox_AvailableContentType = New-Object 'System.Windows.Forms.ComboBox'
	$label_AvailableContentType = New-Object 'System.Windows.Forms.Label'
	$tabpage_Summary = New-Object 'System.Windows.Forms.TabPage'
	$groupbox_SummaryConfiguration = New-Object 'System.Windows.Forms.GroupBox'
	$textbox_SummaryTimezone = New-Object 'System.Windows.Forms.TextBox'
	$label_SummaryTimezone = New-Object 'System.Windows.Forms.Label'
	$textbox_SummaryAction = New-Object 'System.Windows.Forms.TextBox'
	$textbox_SummaryRecipients = New-Object 'System.Windows.Forms.TextBox'
	$textbox_SummaryScheduledTime = New-Object 'System.Windows.Forms.TextBox'
	$label_SummaryAction = New-Object 'System.Windows.Forms.Label'
	$label_SummaryRecipients = New-Object 'System.Windows.Forms.Label'
	$label_SummaryScheduledTime = New-Object 'System.Windows.Forms.Label'
	$groupbox_SummaryContent = New-Object 'System.Windows.Forms.GroupBox'
	$listview_SelectedContentSummary = New-Object 'System.Windows.Forms.ListView'
	$textbox_SummaryTotalContentSize = New-Object 'System.Windows.Forms.TextBox'
	$label_SummaryTotalContentSize = New-Object 'System.Windows.Forms.Label'
	$groupbox_SummaryDPs = New-Object 'System.Windows.Forms.GroupBox'
	$listview_SelectedDPSummary = New-Object 'System.Windows.Forms.ListView'
	$buttonNext = New-Object 'System.Windows.Forms.Button'
	$AvailDPGroupsName = New-Object 'System.Windows.Forms.ColumnHeader'
	$AvailDPGroupsDescription = New-Object 'System.Windows.Forms.ColumnHeader'
	$SelectedDPGroupsName = New-Object 'System.Windows.Forms.ColumnHeader'
	$SelectedDPGroupsDescription = New-Object 'System.Windows.Forms.ColumnHeader'
	$AvailContentName = New-Object 'System.Windows.Forms.ColumnHeader'
	$AvailContentID = New-Object 'System.Windows.Forms.ColumnHeader'
	$AvailContentSize = New-Object 'System.Windows.Forms.ColumnHeader'
	$SelectedContentName = New-Object 'System.Windows.Forms.ColumnHeader'
	$SelectedContentID = New-Object 'System.Windows.Forms.ColumnHeader'
	$SelectedContentSize = New-Object 'System.Windows.Forms.ColumnHeader'
	$SummaryDPGroupsName = New-Object 'System.Windows.Forms.ColumnHeader'
	$SummaryDPGroupsDescription = New-Object 'System.Windows.Forms.ColumnHeader'
	$SummaryContentName = New-Object 'System.Windows.Forms.ColumnHeader'
	$SummaryContentID = New-Object 'System.Windows.Forms.ColumnHeader'
	$SummaryContentSize = New-Object 'System.Windows.Forms.ColumnHeader'
	$errorprovider = New-Object 'System.Windows.Forms.ErrorProvider'
	$timer_JobTracker = New-Object 'System.Windows.Forms.Timer'
	$openfiledialog_CMTrace = New-Object 'System.Windows.Forms.OpenFileDialog'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	$formContentDistribution_Load = {
		#region create jobs to generate our arrays for all things packages! references, dependencies, etc
		$paramAddJobTracker = @{
			Name		  = "SMS_PackageBaseclass"
			JobScript	  = {
				Param (
					$Namespace,
					$PrimarySiteServer,
					$script:Credentials
				)
				$CimSession = New-CimSession -ComputerName $PrimarySiteServer -Credential $script:Credentials
				Get-CimInstance -Namespace $Namespace -CimSession $CimSession -ClassName SMS_PackageBaseclass
			}
			CompletedScript = { Receive-Job -Name "SMS_PackageBaseclass" -OutVariable script:Results }
			ArgumentList  = $Namespace, $PrimarySiteServer, $script:Credentials
		}
		Add-JobTracker @paramAddJobTracker
		$paramAddJobTracker = @{
			Name		  = "SMS_ApplicationLatest"
			JobScript	  = {
				Param (
					$Namespace,
					$PrimarySiteServer,
					$script:Credentials
				)
				$CimSession = New-CimSession -ComputerName $PrimarySiteServer -Credential $script:Credentials
				Get-CimInstance -Namespace $Namespace -CimSession $CimSession -ClassName SMS_ApplicationLatest
			}
			CompletedScript = { Receive-Job -Name "SMS_ApplicationLatest" -OutVariable script:CIIDs }
			ArgumentList  = $Namespace, $PrimarySiteServer, $script:Credentials
		}
		Add-JobTracker @paramAddJobTracker
		$paramAddJobTracker = @{
			Name		 = "SMS_TaskSequencePackageReference_Flat"
			JobScript    = {
				Param ($Namespace,
					$PrimarySiteServer,
					$script:Credentials
				)
				$CimSession = New-CimSession -ComputerName $PrimarySiteServer -Credential $script:Credentials
				Get-CimInstance -Namespace $Namespace -CimSession $CimSession -ClassName SMS_TaskSequencePackageReference_Flat
			}
			CompletedScript = { Receive-Job -Name "SMS_TaskSequencePackageReference_Flat" -OutVariable script:TaskSequenceReferences }
			ArgumentList = $Namespace, $PrimarySiteServer, $script:Credentials
		}
		Add-JobTracker @paramAddJobTracker
		$paramAddJobTracker = @{
			Name		 = "SMS_AppDependenceRelation"
			JobScript    = {
				Param ($Namespace,
					$PrimarySiteServer,
					$script:Credentials
				)
				$CimSession = New-CimSession -ComputerName $PrimarySiteServer -Credential $script:Credentials
				Get-CimInstance -Namespace $Namespace -CimSession $CimSession -ClassName SMS_AppDependenceRelation
			}
			CompletedScript = { Receive-Job -Name "SMS_AppDependenceRelation" -OutVariable script:AppDependenceRelationships }
			ArgumentList = $Namespace, $PrimarySiteServer, $script:Credentials
		}
		Add-JobTracker @paramAddJobTracker
		$progressbar_ContentTable.Style = 'Marquee'
		$progressbar_ContentTable.MarqueeAnimationSpeed = '100'
		$progressbar_ContentTable.TextOverlay = "Content Table Generation in Progress"
		#endregion create jobs to generate our arrays for all things packages! references, dependencies, etc
		
		Write-CMLogEntry -Value "$("-" * 170)"
		Write-CMLogEntry -Value "Form opened"
		if ($combobox_Timezone.Items.Count -eq 0)
		{
			foreach ($TimeZone in $TimeZones)
			{
				Update-ComboBox -ComboBox $combobox_Timezone -Items $TimeZone -Append
			}
		}
		$combobox_TimeZone.SelectedIndex = $combobox_TimeZone.FindString($script:DefaultTimezone)
		$combobox_Action.SelectedIndex = $combobox_Action.FindString($script:Action)
		$errorprovider.SetError($textbox_NotificationRecipient, "You must specify at least one email address")
		switch ($script:DPTableType)
		{
			DP {
				$script:DPTable = Get-CMDistributionPoints
				$radiobutton_TargetDPs.Checked = $true
			}
			DPGroup {
				$script:DPTable = Get-CMDistributionPointGroups
				$radiobutton_TargetDPGroups.Checked = $true
			}
		}
		Update-DPGroupListviews -AvailableListview $listview_AvailableDPGroups -SelectedListview $listview_SelectedDPGroups
		Update-NavButtons
	}
	
	$script:DeselectedIndex = -1
	
	$tabcontrolWizard_Deselecting = [System.Windows.Forms.TabControlCancelEventHandler]{
		#Event Argument: $_ = [System.Windows.Forms.TabControlCancelEventArgs]
		# Store the previous tab index
		$script:DeselectedIndex = $_.TabPageIndex
	}
	
	$tabcontrolWizard_Selecting = [System.Windows.Forms.TabControlCancelEventHandler]{
		#Event Argument: $_ = [System.Windows.Forms.TabControlCancelEventArgs]
		# We only validate if we are moving to the Next TabPage. 
		# Users can move back without validating
		if ($script:DeselectedIndex -ne -1 -and $script:DeselectedIndex -lt $_.TabPageIndex)
		{
			#Validate each page until we reach the one we want
			for ($index = $script:DeselectedIndex; $index -lt $_.TabPageIndex; $index++)
			{
				$_.Cancel = -not (Test-WizardPage $tabcontrolWizard.TabPages[$index])
				
				if ($_.Cancel)
				{
					# Cancel and Return if validation failed.
					return;
				}
			}
		}
		
		Update-NavButtons
	}
	
	$linklabel_OpenLog_LinkClicked = [System.Windows.Forms.LinkLabelLinkClickedEventHandler]{
		$Log = (Write-CMLogEntry -Value "n/a" -ReturnLogPath)
		$LogParent = (Get-Item -Path $Log).Directory
		$CMTrace = Join-Path -Path $LogParent -ChildPath "CMTrace.exe"
		if (!(Test-Path -Path $CMTrace))
		{
			[void][System.Windows.Forms.MessageBox]::Show("Please point to a copy of CMTrace.exe `nIt will be copied to the ScriptLogs directory", 'Copy CMTrace', 'OK', 'Information')
			if (($openfiledialog_CMTrace.ShowDialog()) -eq 'OK')
			{
				Copy-Item -Path $openfiledialog_CMTrace.FileName -Destination $LogParent
			}
		}
		& $CMTrace $Log
	}
	
	$timer_JobTracker_Tick = {
		Update-JobTracker -ProgressBar $progressbar_ContentTable -GroupBox1 $groupbox_AvailableContent -GroupBox2 $groupbox_SelectedContent
	}
	
	#region Control Helper Functions
	function Update-ComboBox
	{
	<#
		.SYNOPSIS
			This functions helps you load items into a ComboBox.
		
		.DESCRIPTION
			Use this function to dynamically load items into the ComboBox control.
		
		.PARAMETER ComboBox
			The ComboBox control you want to add items to.
		
		.PARAMETER Items
			The object or objects you wish to load into the ComboBox's Items collection.
		
		.PARAMETER DisplayMember
			Indicates the property to display for the items in this control.
		
		.PARAMETER Append
			Adds the item(s) to the ComboBox without clearing the Items collection.
		
		.EXAMPLE
			Update-ComboBox $combobox1 "Red", "White", "Blue"
		
		.EXAMPLE
			Update-ComboBox $combobox1 "Red" -Append
			Update-ComboBox $combobox1 "White" -Append
			Update-ComboBox $combobox1 "Blue" -Append
		
		.EXAMPLE
			Update-ComboBox $combobox1 (Get-Process) "ProcessName"
		
		.NOTES
			Additional information about the function.
	#>
		
		param
		(
			[Parameter(Mandatory = $true)]
			[ValidateNotNull()]
			[System.Windows.Forms.ComboBox]$ComboBox,
			[Parameter(Mandatory = $true)]
			[ValidateNotNull()]
			$Items,
			[Parameter(Mandatory = $false)]
			[string]$DisplayMember,
			[switch]$Append
		)
		
		if (-not $Append)
		{
			$ComboBox.Items.Clear()
		}
		
		if ($Items -is [Object[]])
		{
			$ComboBox.Items.AddRange($Items)
		}
		elseif ($Items -is [System.Collections.IEnumerable])
		{
			$ComboBox.BeginUpdate()
			foreach ($obj in $Items)
			{
				$ComboBox.Items.Add($obj)
			}
			$ComboBox.EndUpdate()
		}
		else
		{
			$ComboBox.Items.Add($Items)
		}
		
		$ComboBox.DisplayMember = $DisplayMember
	}
	
	function Update-ListViewColumnSort
	{
	<#
		.SYNOPSIS
			Sort the ListView's item using the specified column.
		
		.DESCRIPTION
			Sort the ListView's item using the specified column.
			This function uses Add-Type to define a class that sort the items.
			The ListView's Tag property is used to keep track of the sorting.
		
		.PARAMETER ListView
			The ListView control to sort.
		
		.PARAMETER ColumnIndex
			The index of the column to use for sorting.
		
		.PARAMETER SortOrder
			The direction to sort the items. If not specified or set to None, it will toggle.
		
		.EXAMPLE
			Update-ListViewColumnSort -ListView $listview1 -ColumnIndex 0
		
		.NOTES
			Additional information about the function.
	#>
		
		param
		(
			[Parameter(Mandatory = $true)]
			[ValidateNotNull()]
			[System.Windows.Forms.ListView]$ListView,
			[Parameter(Mandatory = $true)]
			[int]$ColumnIndex,
			[System.Windows.Forms.SortOrder]$SortOrder = 'None'
		)
		
		if (($ListView.Items.Count -eq 0) -or ($ColumnIndex -lt 0) -or ($ColumnIndex -ge $ListView.Columns.Count))
		{
			return;
		}
		
		#region Define ListViewItemComparer
		try
		{
			[ListViewItemComparer] | Out-Null
		}
		catch
		{
			Add-Type -ReferencedAssemblies ('System.Windows.Forms') -TypeDefinition @" 
	using System;
	using System.Windows.Forms;
	using System.Collections;
	public class ListViewItemComparer : IComparer
	{
	    public int column;
	    public SortOrder sortOrder;
	    public ListViewItemComparer()
	    {
	        column = 0;
			sortOrder = SortOrder.Ascending;
	    }
	    public ListViewItemComparer(int column, SortOrder sort)
	    {
	        this.column = column;
			sortOrder = sort;
	    }
	    public int Compare(object x, object y)
	    {
			if(column >= ((ListViewItem)x).SubItems.Count)
				return  sortOrder == SortOrder.Ascending ? -1 : 1;
		
			if(column >= ((ListViewItem)y).SubItems.Count)
				return sortOrder == SortOrder.Ascending ? 1 : -1;
		
			if(sortOrder == SortOrder.Ascending)
	        	return String.Compare(((ListViewItem)x).SubItems[column].Text, ((ListViewItem)y).SubItems[column].Text);
			else
				return String.Compare(((ListViewItem)y).SubItems[column].Text, ((ListViewItem)x).SubItems[column].Text);
	    }
	}
"@ | Out-Null
		}
		#endregion
		
		if ($ListView.Tag -is [ListViewItemComparer])
		{
			#Toggle the Sort Order
			if ($SortOrder -eq [System.Windows.Forms.SortOrder]::None)
			{
				if ($ListView.Tag.column -eq $ColumnIndex -and $ListView.Tag.sortOrder -eq 'Ascending')
				{
					$ListView.Tag.sortOrder = 'Descending'
				}
				else
				{
					$ListView.Tag.sortOrder = 'Ascending'
				}
			}
			else
			{
				$ListView.Tag.sortOrder = $SortOrder
			}
			
			$ListView.Tag.column = $ColumnIndex
			$ListView.Sort() #Sort the items
		}
		else
		{
			if ($SortOrder -eq [System.Windows.Forms.SortOrder]::None)
			{
				$SortOrder = [System.Windows.Forms.SortOrder]::Ascending
			}
			
			#Set to Tag because for some reason in PowerShell ListViewItemSorter prop returns null
			$ListView.Tag = New-Object ListViewItemComparer ($ColumnIndex, $SortOrder)
			$ListView.ListViewItemSorter = $ListView.Tag #Automatically sorts
		}
	}
	
	function Add-ListViewItem
	{
	<#
		.SYNOPSIS
			Adds the item(s) to the ListView and stores the object in the ListViewItem's Tag property.
	
		.DESCRIPTION
			Adds the item(s) to the ListView and stores the object in the ListViewItem's Tag property.
	
		.PARAMETER ListView
			The ListView control to add the items to.
	
		.PARAMETER Items
			The object or objects you wish to load into the ListView's Items collection.
			
		.PARAMETER  ImageIndex
			The index of a predefined image in the ListView's ImageList.
		
		.PARAMETER  SubItems
			List of strings to add as Subitems.
		
		.PARAMETER Group
			The group to place the item(s) in.
		
		.PARAMETER Clear
			This switch clears the ListView's Items before adding the new item(s).
		
		.EXAMPLE
			Add-ListViewItem -ListView $listview1 -Items "Test" -Group $listview1.Groups[0] -ImageIndex 0 -SubItems "Installed"
	#>
		
		Param (
			[ValidateNotNull()]
			[Parameter(Mandatory = $true)]
			[System.Windows.Forms.ListView]$ListView,
			[ValidateNotNull()]
			[Parameter(Mandatory = $true)]
			$Items,
			[int]$ImageIndex = -1,
			[string[]]$SubItems,
			$Group,
			[switch]$Clear)
		
		if ($Clear)
		{
			$ListView.Items.Clear();
		}
		
		$lvGroup = $null
		if ($Group -is [System.Windows.Forms.ListViewGroup])
		{
			$lvGroup = $Group
		}
		elseif ($Group -is [string])
		{
			#$lvGroup = $ListView.Group[$Group] # Case sensitive
			foreach ($groupItem in $ListView.Groups)
			{
				if ($groupItem.Name -eq $Group)
				{
					$lvGroup = $groupItem
					break
				}
			}
			
			if ($null -eq $lvGroup)
			{
				$lvGroup = $ListView.Groups.Add($Group, $Group)
			}
		}
		
		if ($Items -is [Array])
		{
			$ListView.BeginUpdate()
			foreach ($item in $Items)
			{
				$listitem = $ListView.Items.Add($item.ToString(), $ImageIndex)
				#Store the object in the Tag
				$listitem.Tag = $item
				
				if ($null -ne $SubItems)
				{
					$listitem.SubItems.AddRange($SubItems)
				}
				
				if ($null -ne $lvGroup)
				{
					$listitem.Group = $lvGroup
				}
			}
			$ListView.EndUpdate()
		}
		else
		{
			#Add a new item to the ListView
			$listitem = $ListView.Items.Add($Items.ToString(), $ImageIndex)
			#Store the object in the Tag
			$listitem.Tag = $Items
			
			if ($null -ne $SubItems)
			{
				$listitem.SubItems.AddRange($SubItems)
			}
			
			if ($null -ne $lvGroup)
			{
				$listitem.Group = $lvGroup
			}
		}
	}
	
	#endregion
	
	#region tab - Configuration
	$textbox_NotificationRecipient_TextChanged = {
		if ($textbox_NotificationRecipient.Text -eq "" -or $textbox_NotificationRecipient.Text -eq $null)
		{
			$errorprovider.SetError($textbox_NotificationRecipient, "You must specify at least one email address")
		}
		elseif ($textbox_NotificationRecipient.Text -match "^(([a-zA-Z0-9_\-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([a-zA-Z0-9\-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)(\s*;\s*|\s*`$))*`$")
		{
			$errorprovider.SetError($textbox_NotificationRecipient, $null)
		}
		else
		{
			$errorprovider.SetError($textbox_NotificationRecipient, "Email address(es) not valid.")
		}
		Update-NavButtons
	}
	
	$combobox_Action_SelectedIndexChanged = {
		$script:Action = $combobox_Action.SelectedItem.ToString()
		if ($script:Action -eq "Update Content")
		{
			$tabpage_DPSelection.Enabled = $false
			$radiobutton_TargetDPGroups.Enabled = $false
			$radiobutton_TargetDPs.Enabled = $false
		}
		else
		{
			$tabpage_DPSelection.Enabled = $true
			$radiobutton_TargetDPGroups.Enabled = $true
			$radiobutton_TargetDPs.Enabled = $true
		}
		Update-NavButtons
	}
	
	$radiobutton_TargetDPGroups_CheckedChanged = {
		if ($radiobutton_TargetDPGroups.Checked -eq $true)
		{
			$groupbox_DPs.Text = "Available DP Groups"
			$groupbox_SelectedDPs = "Selected DP Groups"
			$groupbox_SummaryDPs.Text = "Summary of Selected DP Groups"
			$script:DPTableType = "DPGroup"
			$script:DPTable = Get-CMDistributionPointGroups
			Update-DPGroupListviews -AvailableListview $listview_AvailableDPGroups -SelectedListview $listview_SelectedDPGroups
		}
	}
	
	$radiobutton_TargetDPs_CheckedChanged = {
		if ($radiobutton_TargetDPs.Checked -eq $true)
		{
			$groupbox_DPs.Text = "Available DPs"
			$groupbox_SelectedDPs = "Selected DPs"
			$groupbox_SummaryDPs.Text = "Summary of Selected DPs"
			$script:DPTableType = "DP"
			$script:DPTable = Get-CMDistributionPoints
			Update-DPGroupListviews -AvailableListview $listview_AvailableDPGroups -SelectedListview $listview_SelectedDPGroups
		}
	}
	
	$checkbox_DetectDependencies_CheckedChanged = {
		if ($checkbox_DetectDependencies.Checked)
		{
			$script:CheckDependencies = $true
		}
		else
		{
			$script:CheckDependencies = $false
		}
		
		if (!$script:ContentTableUpdated -or !$script:JobsComplete)
		{
			Update-JobTracker -ProgressBar $progressbar_ContentTable -GroupBox1 $groupbox_AvailableContent -GroupBox2 $groupbox_SelectedContent
		}
	}
	
	$tabpage_Configuration_Validated = {
		Write-CMLogEntry -Value "Configuration tab exited" -Component "Configuration"
		Write-CMLogEntry -Value "Selected Datetime: $($datetimepicker_ScheduleDay.Value.Date.ToShortDateString()) $(($datetimepicker_ScheduledTime).Value.TimeOfDay.Hours):$(($datetimepicker_ScheduledTime).Value.TimeOfDay.Minutes)" -Component "Configuration"
		Write-CMLogEntry -Value "Selected Timezone: $($combobox_TimeZone.SelectedItem.ToString())" -Component "Configuration"
		Write-CMLogEntry -Value "Specified Recipients: $($textbox_NotificationRecipient.Text)" -Component "Configuration"
		Write-CMLogEntry -Value "Specified Action: $($combobox_Action.SelectedItem.ToString())" -Component "Configuration"
		Write-CMLogEntry -Value "DP Target Type: $script:DPTableType" -Component "Configuration"
	}
	
	#endregion tab - Configuration
	
	#region tab - DP Selection
	$button_SelectDPGroups_Click = {
		foreach ($Group in $script:DPTable)
		{
			if ($listview_AvailableDPGroups.FindItemWithText($Group.Name, $false, 0, $false).Checked)
			{
				$Group.IsSelected = $true
			}
		}
		Update-DPGroupListviews -AvailableListview $listview_AvailableDPGroups -SelectedListview $listview_SelectedDPGroups
		Update-NavButtons
	}
	
	$button_DeselectDPGroups_Click = {
		foreach ($Group in $script:DPTable)
		{
			if ($listview_SelectedDPGroups.FindItemWithText($Group.Name, $false, 0, $false).Checked)
			{
				$Group.IsSelected = $false
			}
		}
		Update-DPGroupListviews -AvailableListview $listview_AvailableDPGroups -SelectedListview $listview_SelectedDPGroups
		Update-NavButtons
	}
	
	$textbox_AvailableDPGroupsFilter_TextChanged = {
		$Filter = $textbox_AvailableDPGroupsFilter.Text
		if ($Filter -ne "" -and $Filter -ne $null)
		{
			foreach ($Group in $script:DPTable)
			{
				if ($Group.Name -notmatch $Filter -and $Group.Description -notmatch $Filter)
				{
					$Group.IsVisible = $false
				}
				else
				{
					$Group.IsVisible = $true
				}
			}
		}
		else
		{
			foreach ($Group in $script:DPTable)
			{
				$Group.IsVisible = $true
			}
		}
		Update-DPGroupListviews -AvailableListview $listview_AvailableDPGroups -SelectedListview $listview_SelectedDPGroups
	}
	
	$listview_AvailableDPGroups_MouseDoubleClick = [System.Windows.Forms.MouseEventHandler]{
		#Event Argument: $_ = [System.Windows.Forms.MouseEventArgs]
		$hit = $listview_AvailableDPGroups.HitTest($_.Location)
		if ($hit.Item)
		{
			foreach ($Group in $script:DPTable)
			{
				if ($Group.Name -eq $hit.Item.Text)
				{
					$Group.IsSelected = $true
				}
			}
		}
		Update-DPGroupListviews -AvailableListview $listview_AvailableDPGroups -SelectedListview $listview_SelectedDPGroups
		Update-NavButtons
	}
	
	$listview_SelectedDPGroups_MouseDoubleClick = [System.Windows.Forms.MouseEventHandler]{
		#Event Argument: $_ = [System.Windows.Forms.MouseEventArgs]
		$hit = $listview_SelectedDPGroups.HitTest($_.Location)
		if ($hit.Item)
		{
			foreach ($Group in $script:DPTable)
			{
				if ($Group.Name -eq $hit.Item.Text)
				{
					$Group.IsSelected = $false
				}
			}
		}
		Update-DPGroupListviews -AvailableListview $listview_AvailableDPGroups -SelectedListview $listview_SelectedDPGroups
		Update-NavButtons
	}
	
	$button_ResetSelectedDPGroups_Click = {
		$textbox_AvailableDPGroupsFilter.Text = $null
		foreach ($Group in $script:DPTable)
		{
			$Group.IsVisible = $true
			$Group.IsSelected = $false
		}
		Update-DPGroupListviews -AvailableListview $listview_AvailableDPGroups -SelectedListview $listview_SelectedDPGroups
		Update-NavButtons
	}
	
	$tabpage_DPSelection_Validated = {
		Write-CMLogEntry -Value "DP Selection tab exited" -Component "DPSelection"
		foreach ($DP in $script:DPTable)
		{
			if ($DP.IsSelected)
			{
				Write-CMLogEntry -Value "Selected $script:DPTableType`: $($DP.Name)" -Component "DPSelection"
			}
		}
	}
	#endregion tab - DP Selection
	
	#region tab - Content
	$combobox_AvailableContentType_SelectedIndexChanged = {
		$textbox_AvailableContentFilter.Clear()
		$ContentType = $combobox_AvailableContentType.SelectedItem.ToString()
		$script:Type = $script:ContentTypes[$ContentType]
		
		foreach ($Item in $script:ContentTable)
		{
			if ($Item.IsSelected)
			{
				$Item.IsSelected = $false
			}
			if ($Item.Type -eq $script:Type)
			{
				$Item.IsVisible = $true
			}
			else
			{
				$Item.IsVisible = $false
			}
		}
		Update-ContentListviews -AvailableListview $listview_AvailableContent -SelectedListview $listview_SelectedContent
		Update-NavButtons
	}
	
	$button_SelectContent_Click = {
		foreach ($Package in $script:ContentTable)
		{
			if ($listview_AvailableContent.FindItemWithText($Package.ID, $true, 0, $false).Checked)
			{
				$Package.IsSelected = $true
				$script:DependenciesChecked = $false
			}
		}
		Update-ContentListviews -AvailableListview $listview_AvailableContent -SelectedListview $listview_SelectedContent
		Update-NavButtons
		$textbox_TotalContentSize.Text = Get-TotalPackageSize
	}
	
	$button_DeselectContent_Click = {
		foreach ($Package in $script:ContentTable)
		{
			if ($listview_SelectedContent.FindItemWithText($Package.ID, $true, 0, $false).Checked)
			{
				$Package.IsSelected = $false
				$script:DependenciesChecked = $false
			}
		}
		Update-ContentListviews -AvailableListview $listview_AvailableContent -SelectedListview $listview_SelectedContent
		Update-NavButtons
		$textbox_TotalContentSize.Text = Get-TotalPackageSize
	}
	
	$textbox_AvailableContentFilter_TextChanged = {
		$Filter = $textbox_AvailableContentFilter.Text
		if ($Filter -ne "" -and $Filter -ne $null)
		{
			foreach ($Package in $script:ContentTable.where{ $_.Type -eq $script:Type })
			{
				if ($Package.Name -notmatch $Filter -and $Package.Description -notmatch $Filter)
				{
					$Package.IsVisible = $false
				}
				else
				{
					$Package.IsVisible = $true
				}
			}
		}
		else
		{
			foreach ($Package in $script:ContentTable.where{ $_.Type -eq $script:Type })
			{
				$Package.IsVisible = $true
			}
		}
		Update-ContentListviews -AvailableListview $listview_AvailableContent -SelectedListview $listview_SelectedContent
	}
	
	$button_ResetSelectedContent_Click = {
		$textbox_AvailableContentFilter.Text = $null
		foreach ($Package in $script:ContentTable)
		{
			if ($Package.Type -eq $script:Type)
			{
				$Package.IsVisible = $true
			}
			else
			{
				$Package.IsVisible = $false
			}
			$Package.IsSelected = $false
		}
		Update-ContentListviews -AvailableListview $listview_AvailableContent -SelectedListview $listview_SelectedContent
		Update-NavButtons
		$textbox_TotalContentSize.Text = Get-TotalPackageSize
		$script:DependenciesChecked = $false
	}
	
	$listview_AvailableContent_MouseDoubleClick = [System.Windows.Forms.MouseEventHandler]{
		#Event Argument: $_ = [System.Windows.Forms.MouseEventArgs]
		$hit = $listview_AvailableContent.HitTest($_.Location)
		if ($hit.Item)
		{
			foreach ($Package in $script:ContentTable)
			{
				if ($Package.ID -eq $hit.Item.SubItems[1].Text)
				{
					$Package.IsSelected = $true
					$script:DependenciesChecked = $false
				}
			}
		}
		Update-ContentListviews -AvailableListview $listview_AvailableContent -SelectedListview $listview_SelectedContent
		Update-NavButtons
		$textbox_TotalContentSize.Text = Get-TotalPackageSize
	}
	
	$listview_SelectedContent_MouseDoubleClick = [System.Windows.Forms.MouseEventHandler]{
		#Event Argument: $_ = [System.Windows.Forms.MouseEventArgs]
		$hit = $listview_SelectedContent.HitTest($_.Location)
		if ($hit.Item)
		{
			foreach ($Package in $script:ContentTable)
			{
				if ($Package.ID -eq $hit.Item.SubItems[1].Text)
				{
					$Package.IsSelected = $false
					$script:DependenciesChecked = $false
				}
			}
		}
		Update-ContentListviews -AvailableListview $listview_AvailableContent -SelectedListview $listview_SelectedContent
		Update-NavButtons
		$textbox_TotalContentSize.Text = Get-TotalPackageSize
	}
	
	$tabpage_Content_Validated = {
		Write-CMLogEntry -Value "Content tab exited" -Component "Content"
		$ContentType = $combobox_AvailableContentType.SelectedItem.ToString()
		foreach ($Package in $script:ContentTable)
		{
			if ($Package.IsSelected)
			{
				Write-CMLogEntry -Value "Selected $($ContentType): $($Package.Name); $($Package.ID)" -Component "Content"
			}
		}
	}
	
	#endregion tab - Content
	
	#region tab - Summary
	$tabpage_Summary_Enter = {
		#region determine scheduled starttime based on input
		$ScheduledStartDate = $datetimepicker_ScheduleDay.Value.Date.ToShortDateString()
		$ScheduledStartTime = "$(($datetimepicker_ScheduledTime).Value.TimeOfDay.Hours):$(($datetimepicker_ScheduledTime).Value.TimeOfDay.Minutes)"
		[datetime]$SelectedTime = "$ScheduledStartDate $ScheduledStartTime"
		$fromTimeZone = [System.TimeZone]::CurrentTimeZone | Select-Object -ExpandProperty StandardName
		$toTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($combobox_TimeZone.SelectedItem.ID)
		$script:StartTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($SelectedTime, $fromTimeZone, $toTimeZone.Id)
		#endregion determine scheduled starttime based on input
		
		#region populate summary info
		$textbox_SummaryScheduledTime.Text = "$($SelectedTime.ToShortTimeString()) -- $($SelectedTime.ToShortDateString())"
		$textbox_SummaryTimezone.Text = $toTimeZone.DisplayName
		$textbox_SummaryRecipients.Text = $textbox_NotificationRecipient.Text
		$textbox_SummaryAction.Text = $script:Action
		
		$listview_SelectedDPSummary.BeginUpdate()
		$listview_SelectedDPSummary.Items.Clear()
		$listview_SelectedContentSummary.BeginUpdate()
		$listview_SelectedContentSummary.Items.Clear()
		
		#region populate summary tab with selected DP / Groups
		foreach ($DP in $script:DPTable)
		{
			if ($DP.IsSelected)
			{
				$listview_SelectedDPSummary.Items.Add($DP.Name).SubItems.Add($DP.Description)
			}
		}
		#endregion populate summary tab with selected DP / Groups
		
		#region populate summary tab with selected content, checking for dependencies or task sequence references as required
		if ($combobox_AvailableContentType.SelectedItem.ToString() -ne "TaskSequence")
		{
			if ($checkbox_DetectDependencies.Checked -and !$script:DependenciesChecked)
			{
				foreach ($Package in $script:ContentTable.where{ $_.IsSelected -eq $true })
				{
					if ($Package.Dependencies)
					{
						Get-CMDependencyChains -PackageID $Package.ID
					}
				}
				Update-ContentListviews -AvailableListview $listview_AvailableContent -SelectedListview $listview_SelectedContent
				$textbox_TotalContentSize.Text = Get-TotalPackageSize
			}
			$script:DependenciesChecked = $true
			foreach ($Package in $script:ContentTable.where{ $_.IsSelected -eq $true })
			{
				$Item = $listview_SelectedContentSummary.Items.Add($Package.Name)
				$Item.SubItems.Add($Package.ID)
				$Item.SubItems.Add($Package.Size)
			}
		}
		else
		{
			$TSPackageID = $script:ContentTable.where{ $_.IsSelected -eq $true }.ID
			foreach ($ID in $TSPackageID)
			{
				Get-CMTaskSequenceReferencedContent -TSPackageID $ID
				Update-ContentListviews -AvailableListview $listview_AvailableContent -SelectedListview $listview_SelectedContent
				$textbox_TotalContentSize.Text = Get-TotalPackageSize
				foreach ($Package in $script:ContentTable.where{ $_.IsSelected -eq $true })
				{
					$Item = $listview_SelectedContentSummary.Items.Add($Package.Name)
					$Item.SubItems.Add($Package.ID)
					$Item.SubItems.Add($Package.Size)
				}
			}
		}
		#region populate summary tab with selected content, checking for dependencies or task sequence references as required
		
		$textbox_SummaryTotalContentSize.Text = Get-TotalPackageSize
		$listview_SelectedDPSummary.AutoResizeColumns('HeaderSize')
		$listview_SelectedDPSummary.EndUpdate()
		$listview_SelectedContentSummary.AutoResizeColumns('HeaderSize')
		$listview_SelectedContentSummary.EndUpdate()
		#endregion populate summary info
		
		Update-NavButtons
	}
	#endregion tab - Summary
	
	$buttonBack_Click = {
		#Go to the previous tab page
		if ($tabcontrolWizard.SelectedIndex -gt 0)
		{
			$tabcontrolWizard.SelectedIndex--
		}
	}
	
	$buttonNext_Click = {
		#Go to the next tab page
		if ($tabcontrolWizard.SelectedIndex -lt $tabcontrolWizard.TabCount - 1)
		{
			$tabcontrolWizard.SelectedIndex++
		}
	}
	
	$buttonSchedule_Click = {
		$Recipients = $textbox_NotificationRecipient.Text
		$hhmm = Get-Date -Format hh-mm
		$SelectedDP = $script:DPTable.where{ $_.IsSelected -eq $true }
		$SelectedPackages = $script:ContentTable.where{ $_.IsSelected -eq $true }
		$TotalContentSize = $textbox_SummaryTotalContentSize.Text
		
		#region create schedule task
		try
		{
			$TaskName = "$script:Action-$hhmm"
			$allFunctionDefs = "function Start-ContentDistribution { ${function:Start-ContentDistribution} }; function Start-ContentReDistribution { ${function:Start-ContentReDistribution} }; function Start-ContentUpdate { ${function:Start-ContentUpdate} }; function Write-CMLogEntry { ${function:Write-CMLogEntry} }; function New-LoopAction { ${function:New-LoopAction} };"
			$paramRegisterScheduledJob = @{
				Name		   = $TaskName
				ArgumentList   = $Recipients, $FromEmail, $SMTPServer, $script:DPTableType, $SelectedDP, $SelectedPackages, $TotalContentSize, $script:Action, $Script:DistributionCheckInterval, $script:LogPath, $PrimarySiteServer, $SiteCode, $allFunctionDefs
				ScriptBlock    = {
					param ($Recipients,
						$FromEmail,
						$SMTPServer,
						$DPTableType,
						$SelectedDP,
						$SelectedPackages,
						$TotalContentSize,
						$Action,
						$DistributionCheckInterval,
						$script:LogPath,
						$PrimarySiteServer,
						$SiteCode,
						$allFunctionDefs
					)
					.([System.Management.Automation.ScriptBlock]::Create($allFunctionDefs))
					$Recipients = $Recipients -split ";"
					$Recipients = $Recipients.Trim()
					$SelectedPackageNames = $SelectedPackages.Name -join ";"
					$SelectedPackageIDs = $SelectedPackages.ID -join ";"
					$SelectedDPNames = $SelectedDP.Name -join ";"
					$MachineCIMSession = New-CimSession -Name "JobMachineCIMSession"
					$ServerCIMSession = New-CimSession -ComputerName $PrimarySiteServer -Name "JobServerCIMSession"
					$Namespace = "root\sms\site_$SiteCode"
					$DistStart = (Get-Date)
					Write-CMLogEntry -Value "$("-" * 170)" -Component "ScheduledJob"
					Write-CMLogEntry -Value "Scheduled Job started at $DistStart" -Component "ScheduledJob"
					Write-CMLogEntry -Value "Action: $Action" -Component "ScheduledJob"
					Write-CMLogEntry -Value "Package(s): $SelectedPackageNames" -Component "ScheduledJob"
					Write-CMLogEntry -Value "PackageID(s): $SelectedPackageIDs" -Component "ScheduledJob"
					Write-CMLogEntry -Value "Content Size: $TotalContentSize" -Component "ScheduledJob"
					Write-CMLogEntry -Value "$($DPTableType)(s): $SelectedDPNames" -Component "ScheduledJob"
					
					switch ($Action)
					{
						"Distribute Content" {
							Start-ContentDistribution -PackageIDs $SelectedPackages.ID -DPArray $SelectedDP -DPTableType $DPTableType -PrimarySiteServer $PrimarySiteServer -SiteCode $SiteCode -CimSession $ServerCIMSession -Namespace $Namespace
						}
						"Redistribute Content" {
							Start-ContentRedistribution -PackageIDs $SelectedPackages.ID -DPArray $SelectedDP -DPTableType $DPTableType -PrimarySiteServer $PrimarySiteServer -SiteCode $SiteCode -CimSession $ServerCIMSession -Namespace $Namespace
						}
						"Update Content" {
							Start-ContentUpdate -Packages $SelectedPackages -PrimarySiteServer $PrimarySiteServer -SiteCode $SiteCode -CimSession $ServerCIMSession
						}
					}
					$DistribStartBody = "<div>Scheduled ""$Action"" has started. Below is some information regarding the distribution.</div>
									<div>&nbsp;</div>
									<ul>
									<li><strong>Package(s):</strong> $SelectedPackageNames</li>
									<li><strong>PackageID(s):</strong> $SelectedPackageIDs</li>
									<li><strong>Content size:</strong> $TotalContentSize</li>
									<li><strong>$($DPTableType)(s):</strong> $SelectedDPNames</li>
									<li><strong>Start Time:</strong> $DistStart</li>
									</ul>"
					
					Send-MailMessage -From $FromEmail -To $Recipients -SmtpServer $SMTPServer -Subject "Scheduled $Action Started" -Body $DistribStartBody -BodyAsHtml
					
					#region wait for distribution to start
					Start-Sleep -Seconds 10
					New-LoopAction -LoopTimeout 4 -LoopTimeoutType Minutes -LoopDelay 10 -ExitCondition { (($InProgress | Measure-Object | Select-Object -ExpandProperty Count) -gt 0 -and $Started) } -ScriptBlock {
						$InProgress = Get-CimInstance -CimSession $script:ServerCIMSession -Namespace $Namespace -ClassName SMS_DistributionStatus -Filter "Type='2' or Type='4'" | Where-Object { $_.PackageID -in ($script:SelectedPackages | Select-Object -ExpandProperty ID) }
						if ($InProgress)
						{
							$Started = $true
						}
					} -IfTimeoutScript {
						Send-MailMessage -From $script:FromEmail -To $script:Recipients -SmtpServer $script:SMTPServer -Subject "Scheduled Content Distribution Failed to Start" -Body "No ""InProgress"" distribution jobs detected after 240 seconds. Please manually check if distribution has started. Not that this distribution will not be monitored."
						Write-CMLogEntry -Value "Scheduled Content Distribution Failed to Start" -Severity 3 -Component "ScheduledJob"
						Write-CMLogEntry -Value "$("-" * 170)"
						exit
					}
					#endregion wait for distribution to start
					
					#region monitor ongoing distribution
					New-LoopAction -LoopTimeout 48 -LoopTimeoutType Hours -LoopDelay $DistributionCheckInterval -ExitCondition { (($InProgress | Measure-Object | Select-Object -ExpandProperty Count) -eq 0 -and $Started) } -ScriptBlock {
						$InProgress = Get-CimInstance -CimSession $script:ServerCIMSession -Namespace $Namespace -ClassName SMS_DistributionStatus -Filter "Type='2' or Type='4'" | Where-Object { $_.PackageID -in ($script:SelectedPackages | Select-Object -ExpandProperty ID) }
						if ($InProgress)
						{
							$Started = $true
						}
						$Failed = $InProgress | Where-Object { $_.Type -eq '4' } | Select-Object -ExpandProperty count
						if ($Failed -gt 0)
						{
							If ($FoundFail -ne $true)
							{
								Send-MailMessage -From $script:FromEmail -To $script:Recipients -SmtpServer $script:SMTPServer -Subject "Scheduled Content Distribution Partial Failure" -Body "At least one DP reported failed distribution. SCCM will retry up to 100 times to distribute content."
								Write-CMLogEntry -Value "At least one DP reported failed distribution. SCCM will retry up to 100 times to distribute content" -Severity 3 -Component "ScheduledJob"
								$FoundFail = $true
							}
						}
					}
					#endregion monitor ongoing distribution
					
					$DistEnd = (Get-Date)
					$TotalTime = ''
					if ($($($DistEnd - $DistStart).days) -gt 0)
					{
						$TotalTime += "$($($DistEnd - $DistStart).days) Days "
					}
					if ($($($DistEnd - $DistStart).hours) -gt 0)
					{
						$TotalTime += "$($($DistEnd - $DistStart).hours) Hours "
					}
					$TotalTime += "$($($DistEnd - $DistStart).minutes) Minutes"
					
					Write-CMLogEntry -Value "Scheduled Job ended at $DistEnd" -Component "ScheduledJob"
					Write-CMLogEntry -Value "Action: $Action" -Component "ScheduledJob"
					Write-CMLogEntry -Value "Package(s): $SelectedPackageNames" -Component "ScheduledJob"
					Write-CMLogEntry -Value "PackageID(s): $SelectedPackageIDs" -Component "ScheduledJob"
					Write-CMLogEntry -Value "Content Size: $TotalContentSize" -Component "ScheduledJob"
					Write-CMLogEntry -Value "$($DPTableType)(s): $SelectedDPNames" -Component "ScheduledJob"
					Write-CMLogEntry -Value "Total Time: $TotalTime" -Component "ScheduledJob"
					Write-CMLogEntry -Value "$("-" * 170)" -Component "ScheduledJob"
					$DistribEndBody = "<div>Scheduled ""$Action"" has finished. Below is some information regarding the distribution.</div>
									<div>&nbsp;</div>
									<ul>
									<li><strong>Package(s):</strong> $SelectedPackageNames</li>
				<li><strong>PackageID(s):</strong> $SelectedPackageIDs</li>
				<li><strong>Content size:</strong> $TotalContentSize</li>
				<li><strong>$($DPTableType)(s):</strong> $SelectedDPNames</li>
				<li><strong>Start Time:</strong> $DistStart</li>
				<li><strong>End Time:</strong> $DistEnd</li>
				<li><strong>Total Time:</strong> $TotalTime</li>
				</ul>"
					Send-MailMessage -From $FromEmail -To $Recipients -SmtpServer $SMTPServer -Subject "Scheduled $Action Finished" -Body $DistribEndBody -BodyAsHtml
					Get-CimSession -Name @("JobMachineCIMSession", "JobServerCIMSession") | Remove-CimSession
				}
				Trigger	       = (New-JobTrigger -Once -At $script:StartTime)
				ScheduledJobOption = (New-ScheduledJobOption -RunElevated)
				Credential	   = $script:Credentials
			}
			Register-ScheduledJob @paramRegisterScheduledJob
		}
		catch
		{
			$ErrorMessage = $_.Exception.Message
			$Body = "<div>
					Creation of the scheduled job failed. The error that was caught, as well as the state of all the variables necessary to create the task are below.&nbsp;</div>
				<div>
					&nbsp;</div>
				<div>
					<strong>Error:</strong> $ErrorMessage</div>
				<div>
					&nbsp;</div>
				<div>
					<strong>Recipients:</strong> $Recipients</div>
				<div>
					<strong>FromEmail:</strong> $FromEmail</div>
				<div>
					<strong>SMTPServer:</strong> $SMTPServer</div>
				<div>
					<strong>SelectedDPGroups:</strong> $($SelectedDP.Name -join "; ")</div>
				<div>
					<strong>SelectedPackages:</strong> $($SelectedPackages.Name -join "; ")</div>
				<div>
					<strong>TotalContentSize:</strong> $TotalContentSize</div>
				<div>
					<strong>Action:</strong> $script:Action</div>
				<div>
					<strong>PrimarySiteServer:</strong> $PrimarySiteServer</div>
				<div>
					<strong>SiteCode:</strong> $SiteCode</div>
				<div>
					<strong>AllFunctionDefs:</strong></div>
				<div>
					&nbsp;</div>
				<div>
					$allFunctionDefs</div>"
			Send-MailMessage -From $FromEmail -To $Recipients -SmtpServer $SMTPServer -Subject "Scheduled $script:Action - Failed to Create Scheduled Job" -Body $Body -BodyAsHtml
			Write-CMLogEntry -Value "Scheduled Content Distribution - Failed to Create Scheduled Job" -Severity 3 -Component "ScheduledJob"
			Write-CMLogEntry -Value "Error: $ErrorMessage" -Severity 3 -Component "ScheduledJob"
			Write-CMLogEntry -Value "$("-" * 170)" -Component "ScheduledJob"
		}
		#endregion create scheduled task
	}
	
	$formContentDistribution_FormClosed = [System.Windows.Forms.FormClosedEventHandler]{
		#Event Argument: $_ = [System.Windows.Forms.FormClosedEventArgs]
		Write-CMLogEntry -Value "Form Closed"
		Write-CMLogEntry -Value "$("-" * 170)"
		Reset-Log -fileName (Write-CMLogEntry -Value "n/a" -ReturnLogPath) -logcount 2
		Get-CimSession -Name @("ServerCIMSession", "MachineCIMSession") | Remove-CimSession
		Get-Job -State Completed | Remove-Job
		Stop-JobTracker
	}
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formContentDistribution.WindowState = $InitialFormWindowState
	}
	
	$Form_StoreValues_Closing=
	{
		#Store the control values
		$script:MainForm_checkbox_DetectDependencies = $checkbox_DetectDependencies.Checked
		$script:MainForm_radiobutton_TargetDPs = $radiobutton_TargetDPs.Checked
		$script:MainForm_radiobutton_TargetDPGroups = $radiobutton_TargetDPGroups.Checked
		$script:MainForm_combobox_Action = $combobox_Action.Text
		$script:MainForm_combobox_Action_SelectedItem = $combobox_Action.SelectedItem
		$script:MainForm_combobox_TimeZone = $combobox_TimeZone.Text
		$script:MainForm_combobox_TimeZone_SelectedItem = $combobox_TimeZone.SelectedItem
		$script:MainForm_datetimepicker_ScheduledTime = $datetimepicker_ScheduledTime.Value
		$script:MainForm_datetimepicker_ScheduleDay = $datetimepicker_ScheduleDay.Value
		$script:MainForm_textbox_NotificationRecipient = $textbox_NotificationRecipient.Text
		$script:MainForm_textbox_ScheduleInfo = $textbox_ScheduleInfo.Text
		$script:MainForm_listview_AvailableDPGroups = $listview_AvailableDPGroups.SelectedItems
		$script:MainForm_listview_AvailableDPGroups_Checked = $listview_AvailableDPGroups.CheckedItems
		$script:MainForm_textbox_AvailableDPGroupsFilter = $textbox_AvailableDPGroupsFilter.Text
		$script:MainForm_listview_SelectedDPGroups = $listview_SelectedDPGroups.SelectedItems
		$script:MainForm_listview_SelectedDPGroups_Checked = $listview_SelectedDPGroups.CheckedItems
		$script:MainForm_textbox_TotalContentSize = $textbox_TotalContentSize.Text
		$script:MainForm_listview_SelectedContent = $listview_SelectedContent.SelectedItems
		$script:MainForm_listview_SelectedContent_Checked = $listview_SelectedContent.CheckedItems
		$script:MainForm_textbox_AvailableContentFilter = $textbox_AvailableContentFilter.Text
		$script:MainForm_listview_AvailableContent = $listview_AvailableContent.SelectedItems
		$script:MainForm_listview_AvailableContent_Checked = $listview_AvailableContent.CheckedItems
		$script:MainForm_combobox_AvailableContentType = $combobox_AvailableContentType.Text
		$script:MainForm_combobox_AvailableContentType_SelectedItem = $combobox_AvailableContentType.SelectedItem
		$script:MainForm_textbox_SummaryTimezone = $textbox_SummaryTimezone.Text
		$script:MainForm_textbox_SummaryAction = $textbox_SummaryAction.Text
		$script:MainForm_textbox_SummaryRecipients = $textbox_SummaryRecipients.Text
		$script:MainForm_textbox_SummaryScheduledTime = $textbox_SummaryScheduledTime.Text
		$script:MainForm_listview_SelectedContentSummary = $listview_SelectedContentSummary.SelectedItems
		$script:MainForm_textbox_SummaryTotalContentSize = $textbox_SummaryTotalContentSize.Text
		$script:MainForm_listview_SelectedDPSummary = $listview_SelectedDPSummary.SelectedItems
	}

	
	$Form_Cleanup_FormClosed=
	{
		#Remove all event handlers from the controls
		try
		{
			$linklabel_OpenLog.remove_LinkClicked($linklabel_OpenLog_LinkClicked)
			$buttonBack.remove_Click($buttonBack_Click)
			$buttonSchedule.remove_Click($buttonSchedule_Click)
			$checkbox_DetectDependencies.remove_CheckedChanged($checkbox_DetectDependencies_CheckedChanged)
			$radiobutton_TargetDPs.remove_CheckedChanged($radiobutton_TargetDPs_CheckedChanged)
			$radiobutton_TargetDPGroups.remove_CheckedChanged($radiobutton_TargetDPGroups_CheckedChanged)
			$combobox_Action.remove_SelectedIndexChanged($combobox_Action_SelectedIndexChanged)
			$textbox_NotificationRecipient.remove_TextChanged($textbox_NotificationRecipient_TextChanged)
			$tabpage_Configuration.remove_Validated($tabpage_Configuration_Validated)
			$button_DeselectDPGroups.remove_Click($button_DeselectDPGroups_Click)
			$button_SelectDPGroups.remove_Click($button_SelectDPGroups_Click)
			$listview_AvailableDPGroups.remove_MouseDoubleClick($listview_AvailableDPGroups_MouseDoubleClick)
			$textbox_AvailableDPGroupsFilter.remove_TextChanged($textbox_AvailableDPGroupsFilter_TextChanged)
			$button_ResetSelectedDPGroups.remove_Click($button_ResetSelectedDPGroups_Click)
			$listview_SelectedDPGroups.remove_MouseDoubleClick($listview_SelectedDPGroups_MouseDoubleClick)
			$tabpage_DPSelection.remove_Validated($tabpage_DPSelection_Validated)
			$button_DeselectContent.remove_Click($button_DeselectContent_Click)
			$button_SelectContent.remove_Click($button_SelectContent_Click)
			$listview_SelectedContent.remove_MouseDoubleClick($listview_SelectedContent_MouseDoubleClick)
			$button_ResetSelectedContent.remove_Click($button_ResetSelectedContent_Click)
			$textbox_AvailableContentFilter.remove_TextChanged($textbox_AvailableContentFilter_TextChanged)
			$listview_AvailableContent.remove_MouseDoubleClick($listview_AvailableContent_MouseDoubleClick)
			$combobox_AvailableContentType.remove_SelectedIndexChanged($combobox_AvailableContentType_SelectedIndexChanged)
			$tabpage_Content.remove_Validated($tabpage_Content_Validated)
			$tabpage_Summary.remove_Enter($tabpage_Summary_Enter)
			$tabcontrolWizard.remove_Selecting($tabcontrolWizard_Selecting)
			$tabcontrolWizard.remove_Deselecting($tabcontrolWizard_Deselecting)
			$buttonNext.remove_Click($buttonNext_Click)
			$formContentDistribution.remove_FormClosed($formContentDistribution_FormClosed)
			$formContentDistribution.remove_Load($formContentDistribution_Load)
			$timer_JobTracker.remove_Tick($timer_JobTracker_Tick)
			$formContentDistribution.remove_Load($Form_StateCorrection_Load)
			$formContentDistribution.remove_Closing($Form_StoreValues_Closing)
			$formContentDistribution.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch { Out-Null <# Prevent PSScriptAnalyzer warning #> }
	}
	#endregion Generated Events

	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formContentDistribution.SuspendLayout()
	$tabcontrolWizard.SuspendLayout()
	$tabpage_Configuration.SuspendLayout()
	$groupbox_DateTime.SuspendLayout()
	$tabpage_DPSelection.SuspendLayout()
	$groupbox_DPs.SuspendLayout()
	$groupbox_SelectedDPs.SuspendLayout()
	$tabpage_Content.SuspendLayout()
	$groupbox_SelectedContent.SuspendLayout()
	$groupbox_AvailableContent.SuspendLayout()
	$tabpage_Summary.SuspendLayout()
	$groupbox_SummaryConfiguration.SuspendLayout()
	$groupbox_SummaryContent.SuspendLayout()
	$groupbox_SummaryDPs.SuspendLayout()
	$errorprovider.BeginInit()
	#
	# formContentDistribution
	#
	$formContentDistribution.Controls.Add($progressbar_ContentTable)
	$formContentDistribution.Controls.Add($linklabel_OpenLog)
	$formContentDistribution.Controls.Add($buttonCancel)
	$formContentDistribution.Controls.Add($buttonBack)
	$formContentDistribution.Controls.Add($buttonSchedule)
	$formContentDistribution.Controls.Add($tabcontrolWizard)
	$formContentDistribution.Controls.Add($buttonNext)
	$formContentDistribution.AcceptButton = $buttonSchedule
	$formContentDistribution.AutoScaleDimensions = '6, 13'
	$formContentDistribution.AutoScaleMode = 'Font'
	$formContentDistribution.CancelButton = $buttonCancel
	$formContentDistribution.ClientSize = '794, 571'
	$formContentDistribution.FormBorderStyle = 'FixedDialog'
	$formContentDistribution.MaximizeBox = $False
	$formContentDistribution.Name = 'formContentDistribution'
	$formContentDistribution.Text = 'Content Distribution Scheduler'
	$formContentDistribution.add_FormClosed($formContentDistribution_FormClosed)
	$formContentDistribution.add_Load($formContentDistribution_Load)
	#
	# progressbar_ContentTable
	#
	$progressbar_ContentTable.Location = '94, 536'
	$progressbar_ContentTable.MarqueeAnimationSpeed = 0
	$progressbar_ContentTable.Name = 'progressbar_ContentTable'
	$progressbar_ContentTable.Size = '445, 23'
	$progressbar_ContentTable.Style = 'Marquee'
	$progressbar_ContentTable.TabIndex = 12
	#
	# linklabel_OpenLog
	#
	$linklabel_OpenLog.Anchor = 'Top, Right'
	$linklabel_OpenLog.Location = '707, 8'
	$linklabel_OpenLog.Name = 'linklabel_OpenLog'
	$linklabel_OpenLog.Size = '68, 23'
	$linklabel_OpenLog.TabIndex = 11
	$linklabel_OpenLog.TabStop = $True
	$linklabel_OpenLog.Text = 'Open Log'
	$linklabel_OpenLog.TextAlign = 'TopRight'
	$linklabel_OpenLog.UseCompatibleTextRendering = $True
	$linklabel_OpenLog.add_LinkClicked($linklabel_OpenLog_LinkClicked)
	#
	# buttonCancel
	#
	$buttonCancel.Anchor = 'Bottom, Right'
	$buttonCancel.DialogResult = 'Cancel'
	$buttonCancel.Location = '626, 536'
	$buttonCancel.Name = 'buttonCancel'
	$buttonCancel.Size = '75, 23'
	$buttonCancel.TabIndex = 4
	$buttonCancel.Text = '&Cancel'
	$buttonCancel.UseCompatibleTextRendering = $True
	$buttonCancel.UseVisualStyleBackColor = $True
	#
	# buttonBack
	#
	$buttonBack.Anchor = 'Bottom, Left'
	$buttonBack.Location = '13, 536'
	$buttonBack.Name = 'buttonBack'
	$buttonBack.Size = '75, 23'
	$buttonBack.TabIndex = 1
	$buttonBack.Text = '< &Back'
	$buttonBack.UseCompatibleTextRendering = $True
	$buttonBack.UseVisualStyleBackColor = $True
	$buttonBack.add_Click($buttonBack_Click)
	#
	# buttonSchedule
	#
	$buttonSchedule.Anchor = 'Bottom, Right'
	$buttonSchedule.DialogResult = 'OK'
	$buttonSchedule.Location = '707, 536'
	$buttonSchedule.Name = 'buttonSchedule'
	$buttonSchedule.Size = '75, 23'
	$buttonSchedule.TabIndex = 3
	$buttonSchedule.Text = '&Schedule'
	$buttonSchedule.UseCompatibleTextRendering = $True
	$buttonSchedule.UseVisualStyleBackColor = $True
	$buttonSchedule.add_Click($buttonSchedule_Click)
	#
	# tabcontrolWizard
	#
	$tabcontrolWizard.Controls.Add($tabpage_Configuration)
	$tabcontrolWizard.Controls.Add($tabpage_DPSelection)
	$tabcontrolWizard.Controls.Add($tabpage_Content)
	$tabcontrolWizard.Controls.Add($tabpage_Summary)
	$tabcontrolWizard.Anchor = 'Top, Bottom, Left, Right'
	$tabcontrolWizard.Location = '13, 12'
	$tabcontrolWizard.Multiline = $True
	$tabcontrolWizard.Name = 'tabcontrolWizard'
	$tabcontrolWizard.SelectedIndex = 0
	$tabcontrolWizard.Size = '769, 518'
	$tabcontrolWizard.TabIndex = 0
	$tabcontrolWizard.add_Selecting($tabcontrolWizard_Selecting)
	$tabcontrolWizard.add_Deselecting($tabcontrolWizard_Deselecting)
	#
	# tabpage_Configuration
	#
	$tabpage_Configuration.Controls.Add($checkbox_DetectDependencies)
	$tabpage_Configuration.Controls.Add($radiobutton_TargetDPs)
	$tabpage_Configuration.Controls.Add($radiobutton_TargetDPGroups)
	$tabpage_Configuration.Controls.Add($combobox_Action)
	$tabpage_Configuration.Controls.Add($label_Action)
	$tabpage_Configuration.Controls.Add($groupbox_DateTime)
	$tabpage_Configuration.Controls.Add($label_NotificationRecipient)
	$tabpage_Configuration.Controls.Add($textbox_NotificationRecipient)
	$tabpage_Configuration.Controls.Add($textbox_ScheduleInfo)
	$tabpage_Configuration.Location = '4, 22'
	$tabpage_Configuration.Name = 'tabpage_Configuration'
	$tabpage_Configuration.Padding = '3, 3, 3, 3'
	$tabpage_Configuration.Size = '761, 492'
	$tabpage_Configuration.TabIndex = 3
	$tabpage_Configuration.Text = 'Configuration'
	$tabpage_Configuration.UseVisualStyleBackColor = $True
	$tabpage_Configuration.add_Validated($tabpage_Configuration_Validated)
	#
	# checkbox_DetectDependencies
	#
	$checkbox_DetectDependencies.Location = '202, 429'
	$checkbox_DetectDependencies.Name = 'checkbox_DetectDependencies'
	$checkbox_DetectDependencies.Size = '360, 24'
	$checkbox_DetectDependencies.TabIndex = 20
	$checkbox_DetectDependencies.Text = 'Distribute Content For Dependencies?'
	$checkbox_DetectDependencies.UseCompatibleTextRendering = $True
	$checkbox_DetectDependencies.UseVisualStyleBackColor = $True
	$checkbox_DetectDependencies.add_CheckedChanged($checkbox_DetectDependencies_CheckedChanged)
	#
	# radiobutton_TargetDPs
	#
	$radiobutton_TargetDPs.Location = '202, 399'
	$radiobutton_TargetDPs.Name = 'radiobutton_TargetDPs'
	$radiobutton_TargetDPs.Size = '354, 24'
	$radiobutton_TargetDPs.TabIndex = 19
	$radiobutton_TargetDPs.Text = 'Target DPs'
	$radiobutton_TargetDPs.UseCompatibleTextRendering = $True
	$radiobutton_TargetDPs.UseVisualStyleBackColor = $True
	$radiobutton_TargetDPs.add_CheckedChanged($radiobutton_TargetDPs_CheckedChanged)
	#
	# radiobutton_TargetDPGroups
	#
	$radiobutton_TargetDPGroups.Location = '204, 369'
	$radiobutton_TargetDPGroups.Name = 'radiobutton_TargetDPGroups'
	$radiobutton_TargetDPGroups.Size = '352, 24'
	$radiobutton_TargetDPGroups.TabIndex = 18
	$radiobutton_TargetDPGroups.Text = 'Target DP Groups'
	$radiobutton_TargetDPGroups.UseCompatibleTextRendering = $True
	$radiobutton_TargetDPGroups.UseVisualStyleBackColor = $True
	$radiobutton_TargetDPGroups.add_CheckedChanged($radiobutton_TargetDPGroups_CheckedChanged)
	#
	# combobox_Action
	#
	$combobox_Action.AutoCompleteMode = 'SuggestAppend'
	$combobox_Action.AutoCompleteSource = 'ListItems'
	$combobox_Action.FormattingEnabled = $True
	[void]$combobox_Action.Items.Add('Distribute Content')
	[void]$combobox_Action.Items.Add('Redistribute Content')
	$combobox_Action.Location = '274, 342'
	$combobox_Action.Name = 'combobox_Action'
	$combobox_Action.Size = '282, 21'
	$combobox_Action.TabIndex = 2
	$combobox_Action.add_SelectedIndexChanged($combobox_Action_SelectedIndexChanged)
	#
	# label_Action
	#
	$label_Action.AutoSize = $True
	$label_Action.Location = '202, 345'
	$label_Action.Name = 'label_Action'
	$label_Action.Size = '39, 17'
	$label_Action.TabIndex = 17
	$label_Action.Text = 'Action:'
	$label_Action.UseCompatibleTextRendering = $True
	#
	# groupbox_DateTime
	#
	$groupbox_DateTime.Controls.Add($label_TimeZone)
	$groupbox_DateTime.Controls.Add($combobox_TimeZone)
	$groupbox_DateTime.Controls.Add($datetimepicker_ScheduledTime)
	$groupbox_DateTime.Controls.Add($datetimepicker_ScheduleDay)
	$groupbox_DateTime.Controls.Add($label_ScheduleDay)
	$groupbox_DateTime.Controls.Add($label_ScheduleTime)
	$groupbox_DateTime.Location = '198, 171'
	$groupbox_DateTime.Name = 'groupbox_DateTime'
	$groupbox_DateTime.Size = '364, 139'
	$groupbox_DateTime.TabIndex = 0
	$groupbox_DateTime.TabStop = $False
	$groupbox_DateTime.Text = 'Schedule'
	$groupbox_DateTime.UseCompatibleTextRendering = $True
	#
	# label_TimeZone
	#
	$label_TimeZone.AutoSize = $True
	$label_TimeZone.Location = '4, 91'
	$label_TimeZone.Name = 'label_TimeZone'
	$label_TimeZone.Size = '57, 17'
	$label_TimeZone.TabIndex = 6
	$label_TimeZone.Text = 'Timezone:'
	$label_TimeZone.UseCompatibleTextRendering = $True
	#
	# combobox_TimeZone
	#
	$combobox_TimeZone.AutoCompleteMode = 'SuggestAppend'
	$combobox_TimeZone.AutoCompleteSource = 'ListItems'
	$combobox_TimeZone.FormattingEnabled = $True
	$combobox_TimeZone.Location = '76, 88'
	$combobox_TimeZone.Name = 'combobox_TimeZone'
	$combobox_TimeZone.Size = '282, 21'
	$combobox_TimeZone.TabIndex = 2
	#
	# datetimepicker_ScheduledTime
	#
	$datetimepicker_ScheduledTime.CustomFormat = 'h:mm tt'
	$datetimepicker_ScheduledTime.Format = 'Custom'
	$datetimepicker_ScheduledTime.Location = '76, 62'
	$datetimepicker_ScheduledTime.Name = 'datetimepicker_ScheduledTime'
	$datetimepicker_ScheduledTime.ShowUpDown = $True
	$datetimepicker_ScheduledTime.Size = '282, 20'
	$datetimepicker_ScheduledTime.TabIndex = 1
	#
	# datetimepicker_ScheduleDay
	#
	$datetimepicker_ScheduleDay.Location = '76, 36'
	$datetimepicker_ScheduleDay.Name = 'datetimepicker_ScheduleDay'
	$datetimepicker_ScheduleDay.Size = '282, 20'
	$datetimepicker_ScheduleDay.TabIndex = 0
	#
	# label_ScheduleDay
	#
	$label_ScheduleDay.AutoSize = $True
	$label_ScheduleDay.Location = '6, 42'
	$label_ScheduleDay.Name = 'label_ScheduleDay'
	$label_ScheduleDay.Size = '31, 17'
	$label_ScheduleDay.TabIndex = 3
	$label_ScheduleDay.Text = 'Date:'
	$label_ScheduleDay.UseCompatibleTextRendering = $True
	#
	# label_ScheduleTime
	#
	$label_ScheduleTime.AutoSize = $True
	$label_ScheduleTime.Location = '6, 68'
	$label_ScheduleTime.Name = 'label_ScheduleTime'
	$label_ScheduleTime.Size = '33, 17'
	$label_ScheduleTime.TabIndex = 4
	$label_ScheduleTime.Text = 'Time:'
	$label_ScheduleTime.UseCompatibleTextRendering = $True
	#
	# label_NotificationRecipient
	#
	$label_NotificationRecipient.AutoSize = $True
	$label_NotificationRecipient.Location = '202, 319'
	$label_NotificationRecipient.Name = 'label_NotificationRecipient'
	$label_NotificationRecipient.Size = '68, 17'
	$label_NotificationRecipient.TabIndex = 15
	$label_NotificationRecipient.Text = 'Recipient(s):'
	$label_NotificationRecipient.UseCompatibleTextRendering = $True
	#
	# textbox_NotificationRecipient
	#
	$textbox_NotificationRecipient.Location = '274, 316'
	$textbox_NotificationRecipient.Name = 'textbox_NotificationRecipient'
	$textbox_NotificationRecipient.Size = '282, 20'
	$textbox_NotificationRecipient.TabIndex = 1
	$textbox_NotificationRecipient.add_TextChanged($textbox_NotificationRecipient_TextChanged)
	#
	# textbox_ScheduleInfo
	#
	$textbox_ScheduleInfo.BackColor = 'Window'
	$textbox_ScheduleInfo.BorderStyle = 'None'
	$textbox_ScheduleInfo.Location = '198, 53'
	$textbox_ScheduleInfo.Multiline = $True
	$textbox_ScheduleInfo.Name = 'textbox_ScheduleInfo'
	$textbox_ScheduleInfo.ReadOnly = $True
	$textbox_ScheduleInfo.Size = '364, 112'
	$textbox_ScheduleInfo.TabIndex = 13
	$textbox_ScheduleInfo.TabStop = $False
	$textbox_ScheduleInfo.Text = '•Specify the Date, Time, and Timezone for which you want the content distribution to start.
•Specify the "Recipient" email address(es) to receive notifications. Multiple address should be split by a semi-colon (;)
•Specify the "Action" you''d like to perform on the content that will be selected.
•Specify if you''d like to target Distribution Points themselves, or Distribution Point Groups.'
	#
	# tabpage_DPSelection
	#
	$tabpage_DPSelection.Controls.Add($button_DeselectDPGroups)
	$tabpage_DPSelection.Controls.Add($button_SelectDPGroups)
	$tabpage_DPSelection.Controls.Add($groupbox_DPs)
	$tabpage_DPSelection.Controls.Add($groupbox_SelectedDPs)
	$tabpage_DPSelection.Location = '4, 22'
	$tabpage_DPSelection.Name = 'tabpage_DPSelection'
	$tabpage_DPSelection.Padding = '3, 3, 3, 3'
	$tabpage_DPSelection.Size = '761, 492'
	$tabpage_DPSelection.TabIndex = 0
	$tabpage_DPSelection.Text = 'DP Selection'
	$tabpage_DPSelection.UseVisualStyleBackColor = $True
	$tabpage_DPSelection.add_Validated($tabpage_DPSelection_Validated)
	#
	# button_DeselectDPGroups
	#
	$button_DeselectDPGroups.Location = '343, 272'
	$button_DeselectDPGroups.Name = 'button_DeselectDPGroups'
	$button_DeselectDPGroups.Size = '75, 23'
	$button_DeselectDPGroups.TabIndex = 3
	$button_DeselectDPGroups.Text = '<'
	$button_DeselectDPGroups.UseCompatibleTextRendering = $True
	$button_DeselectDPGroups.UseVisualStyleBackColor = $True
	$button_DeselectDPGroups.add_Click($button_DeselectDPGroups_Click)
	#
	# button_SelectDPGroups
	#
	$button_SelectDPGroups.Location = '343, 198'
	$button_SelectDPGroups.Name = 'button_SelectDPGroups'
	$button_SelectDPGroups.Size = '75, 23'
	$button_SelectDPGroups.TabIndex = 2
	$button_SelectDPGroups.Text = '>'
	$button_SelectDPGroups.UseCompatibleTextRendering = $True
	$button_SelectDPGroups.UseVisualStyleBackColor = $True
	$button_SelectDPGroups.add_Click($button_SelectDPGroups_Click)
	#
	# groupbox_DPs
	#
	$groupbox_DPs.Controls.Add($listview_AvailableDPGroups)
	$groupbox_DPs.Controls.Add($label_AvailableDPGroupsFilter)
	$groupbox_DPs.Controls.Add($textbox_AvailableDPGroupsFilter)
	$groupbox_DPs.Location = '6, 6'
	$groupbox_DPs.Name = 'groupbox_DPs'
	$groupbox_DPs.Size = '300, 480'
	$groupbox_DPs.TabIndex = 9
	$groupbox_DPs.TabStop = $False
	$groupbox_DPs.Text = 'Available DP Groups'
	$groupbox_DPs.UseCompatibleTextRendering = $True
	#
	# listview_AvailableDPGroups
	#
	$listview_AvailableDPGroups.Anchor = 'Top, Bottom, Left, Right'
	$listview_AvailableDPGroups.CheckBoxes = $True
	[void]$listview_AvailableDPGroups.Columns.Add($AvailDPGroupsName)
	[void]$listview_AvailableDPGroups.Columns.Add($AvailDPGroupsDescription)
	$listview_AvailableDPGroups.FullRowSelect = $True
	$listview_AvailableDPGroups.GridLines = $True
	$listview_AvailableDPGroups.Location = '6, 48'
	$listview_AvailableDPGroups.Name = 'listview_AvailableDPGroups'
	$listview_AvailableDPGroups.Size = '288, 426'
	$listview_AvailableDPGroups.Sorting = 'Ascending'
	$listview_AvailableDPGroups.TabIndex = 0
	$listview_AvailableDPGroups.UseCompatibleStateImageBehavior = $False
	$listview_AvailableDPGroups.View = 'Details'
	$listview_AvailableDPGroups.add_MouseDoubleClick($listview_AvailableDPGroups_MouseDoubleClick)
	#
	# label_AvailableDPGroupsFilter
	#
	$label_AvailableDPGroupsFilter.AutoSize = $True
	$label_AvailableDPGroupsFilter.Location = '6, 25'
	$label_AvailableDPGroupsFilter.Name = 'label_AvailableDPGroupsFilter'
	$label_AvailableDPGroupsFilter.Size = '82, 17'
	$label_AvailableDPGroupsFilter.TabIndex = 4
	$label_AvailableDPGroupsFilter.Text = 'Filter Available:'
	$label_AvailableDPGroupsFilter.UseCompatibleTextRendering = $True
	#
	# textbox_AvailableDPGroupsFilter
	#
	$textbox_AvailableDPGroupsFilter.Location = '99, 22'
	$textbox_AvailableDPGroupsFilter.Name = 'textbox_AvailableDPGroupsFilter'
	$textbox_AvailableDPGroupsFilter.Size = '195, 20'
	$textbox_AvailableDPGroupsFilter.TabIndex = 6
	$textbox_AvailableDPGroupsFilter.add_TextChanged($textbox_AvailableDPGroupsFilter_TextChanged)
	#
	# groupbox_SelectedDPs
	#
	$groupbox_SelectedDPs.Controls.Add($button_ResetSelectedDPGroups)
	$groupbox_SelectedDPs.Controls.Add($listview_SelectedDPGroups)
	$groupbox_SelectedDPs.Location = '455, 6'
	$groupbox_SelectedDPs.Name = 'groupbox_SelectedDPs'
	$groupbox_SelectedDPs.Size = '300, 480'
	$groupbox_SelectedDPs.TabIndex = 10
	$groupbox_SelectedDPs.TabStop = $False
	$groupbox_SelectedDPs.Text = 'Selected DP Groups'
	$groupbox_SelectedDPs.UseCompatibleTextRendering = $True
	#
	# button_ResetSelectedDPGroups
	#
	$button_ResetSelectedDPGroups.Location = '10, 20'
	$button_ResetSelectedDPGroups.Name = 'button_ResetSelectedDPGroups'
	$button_ResetSelectedDPGroups.Size = '75, 23'
	$button_ResetSelectedDPGroups.TabIndex = 8
	$button_ResetSelectedDPGroups.Text = 'Reset'
	$button_ResetSelectedDPGroups.UseCompatibleTextRendering = $True
	$button_ResetSelectedDPGroups.UseVisualStyleBackColor = $True
	$button_ResetSelectedDPGroups.add_Click($button_ResetSelectedDPGroups_Click)
	#
	# listview_SelectedDPGroups
	#
	$listview_SelectedDPGroups.Anchor = 'Top, Bottom, Right'
	$listview_SelectedDPGroups.CheckBoxes = $True
	[void]$listview_SelectedDPGroups.Columns.Add($SelectedDPGroupsName)
	[void]$listview_SelectedDPGroups.Columns.Add($SelectedDPGroupsDescription)
	$listview_SelectedDPGroups.FullRowSelect = $True
	$listview_SelectedDPGroups.GridLines = $True
	$listview_SelectedDPGroups.Location = '10, 48'
	$listview_SelectedDPGroups.Name = 'listview_SelectedDPGroups'
	$listview_SelectedDPGroups.Size = '284, 426'
	$listview_SelectedDPGroups.Sorting = 'Ascending'
	$listview_SelectedDPGroups.TabIndex = 7
	$listview_SelectedDPGroups.UseCompatibleStateImageBehavior = $False
	$listview_SelectedDPGroups.View = 'Details'
	$listview_SelectedDPGroups.add_MouseDoubleClick($listview_SelectedDPGroups_MouseDoubleClick)
	#
	# tabpage_Content
	#
	$tabpage_Content.Controls.Add($button_DeselectContent)
	$tabpage_Content.Controls.Add($button_SelectContent)
	$tabpage_Content.Controls.Add($groupbox_SelectedContent)
	$tabpage_Content.Controls.Add($groupbox_AvailableContent)
	$tabpage_Content.Location = '4, 22'
	$tabpage_Content.Name = 'tabpage_Content'
	$tabpage_Content.Padding = '3, 3, 3, 3'
	$tabpage_Content.Size = '761, 492'
	$tabpage_Content.TabIndex = 1
	$tabpage_Content.Text = 'Content'
	$tabpage_Content.UseVisualStyleBackColor = $True
	$tabpage_Content.add_Validated($tabpage_Content_Validated)
	#
	# button_DeselectContent
	#
	$button_DeselectContent.Location = '343, 272'
	$button_DeselectContent.Name = 'button_DeselectContent'
	$button_DeselectContent.Size = '75, 23'
	$button_DeselectContent.TabIndex = 5
	$button_DeselectContent.Text = '<'
	$button_DeselectContent.UseCompatibleTextRendering = $True
	$button_DeselectContent.UseVisualStyleBackColor = $True
	$button_DeselectContent.add_Click($button_DeselectContent_Click)
	#
	# button_SelectContent
	#
	$button_SelectContent.Location = '343, 198'
	$button_SelectContent.Name = 'button_SelectContent'
	$button_SelectContent.Size = '75, 23'
	$button_SelectContent.TabIndex = 4
	$button_SelectContent.Text = '>'
	$button_SelectContent.UseCompatibleTextRendering = $True
	$button_SelectContent.UseVisualStyleBackColor = $True
	$button_SelectContent.add_Click($button_SelectContent_Click)
	#
	# groupbox_SelectedContent
	#
	$groupbox_SelectedContent.Controls.Add($textbox_TotalContentSize)
	$groupbox_SelectedContent.Controls.Add($label_TotalContentSize)
	$groupbox_SelectedContent.Controls.Add($listview_SelectedContent)
	$groupbox_SelectedContent.Controls.Add($button_ResetSelectedContent)
	$groupbox_SelectedContent.Enabled = $False
	$groupbox_SelectedContent.Location = '455, 6'
	$groupbox_SelectedContent.Name = 'groupbox_SelectedContent'
	$groupbox_SelectedContent.Size = '300, 480'
	$groupbox_SelectedContent.TabIndex = 3
	$groupbox_SelectedContent.TabStop = $False
	$groupbox_SelectedContent.Text = 'Selected Content'
	$groupbox_SelectedContent.UseCompatibleTextRendering = $True
	#
	# textbox_TotalContentSize
	#
	$textbox_TotalContentSize.Anchor = 'Bottom, Right'
	$textbox_TotalContentSize.Location = '113, 454'
	$textbox_TotalContentSize.Name = 'textbox_TotalContentSize'
	$textbox_TotalContentSize.ReadOnly = $True
	$textbox_TotalContentSize.Size = '181, 20'
	$textbox_TotalContentSize.TabIndex = 12
	#
	# label_TotalContentSize
	#
	$label_TotalContentSize.Anchor = 'Bottom, Right'
	$label_TotalContentSize.AutoSize = $True
	$label_TotalContentSize.Location = '10, 457'
	$label_TotalContentSize.Name = 'label_TotalContentSize'
	$label_TotalContentSize.Size = '100, 17'
	$label_TotalContentSize.TabIndex = 11
	$label_TotalContentSize.Text = 'Total Content Size:'
	$label_TotalContentSize.UseCompatibleTextRendering = $True
	#
	# listview_SelectedContent
	#
	$listview_SelectedContent.Anchor = 'Top, Bottom, Right'
	$listview_SelectedContent.CheckBoxes = $True
	[void]$listview_SelectedContent.Columns.Add($SelectedContentName)
	[void]$listview_SelectedContent.Columns.Add($SelectedContentID)
	[void]$listview_SelectedContent.Columns.Add($SelectedContentSize)
	$listview_SelectedContent.FullRowSelect = $True
	$listview_SelectedContent.GridLines = $True
	$listview_SelectedContent.Location = '6, 72'
	$listview_SelectedContent.Name = 'listview_SelectedContent'
	$listview_SelectedContent.Size = '288, 376'
	$listview_SelectedContent.Sorting = 'Ascending'
	$listview_SelectedContent.TabIndex = 1
	$listview_SelectedContent.UseCompatibleStateImageBehavior = $False
	$listview_SelectedContent.View = 'Details'
	$listview_SelectedContent.add_MouseDoubleClick($listview_SelectedContent_MouseDoubleClick)
	#
	# button_ResetSelectedContent
	#
	$button_ResetSelectedContent.Location = '6, 30'
	$button_ResetSelectedContent.Name = 'button_ResetSelectedContent'
	$button_ResetSelectedContent.Size = '75, 23'
	$button_ResetSelectedContent.TabIndex = 0
	$button_ResetSelectedContent.Text = 'Reset'
	$button_ResetSelectedContent.UseCompatibleTextRendering = $True
	$button_ResetSelectedContent.UseVisualStyleBackColor = $True
	$button_ResetSelectedContent.add_Click($button_ResetSelectedContent_Click)
	#
	# groupbox_AvailableContent
	#
	$groupbox_AvailableContent.Controls.Add($textbox_AvailableContentFilter)
	$groupbox_AvailableContent.Controls.Add($label_AvailableContentFilter)
	$groupbox_AvailableContent.Controls.Add($listview_AvailableContent)
	$groupbox_AvailableContent.Controls.Add($combobox_AvailableContentType)
	$groupbox_AvailableContent.Controls.Add($label_AvailableContentType)
	$groupbox_AvailableContent.Enabled = $False
	$groupbox_AvailableContent.Location = '6, 6'
	$groupbox_AvailableContent.Name = 'groupbox_AvailableContent'
	$groupbox_AvailableContent.Size = '300, 480'
	$groupbox_AvailableContent.TabIndex = 2
	$groupbox_AvailableContent.TabStop = $False
	$groupbox_AvailableContent.Text = 'Available Content'
	$groupbox_AvailableContent.UseCompatibleTextRendering = $True
	#
	# textbox_AvailableContentFilter
	#
	$textbox_AvailableContentFilter.Location = '86, 46'
	$textbox_AvailableContentFilter.Name = 'textbox_AvailableContentFilter'
	$textbox_AvailableContentFilter.Size = '208, 20'
	$textbox_AvailableContentFilter.TabIndex = 4
	$textbox_AvailableContentFilter.add_TextChanged($textbox_AvailableContentFilter_TextChanged)
	#
	# label_AvailableContentFilter
	#
	$label_AvailableContentFilter.AutoSize = $True
	$label_AvailableContentFilter.Location = '6, 49'
	$label_AvailableContentFilter.Name = 'label_AvailableContentFilter'
	$label_AvailableContentFilter.Size = '75, 17'
	$label_AvailableContentFilter.TabIndex = 3
	$label_AvailableContentFilter.Text = 'Filter Content:'
	$label_AvailableContentFilter.UseCompatibleTextRendering = $True
	#
	# listview_AvailableContent
	#
	$listview_AvailableContent.Anchor = 'Top, Bottom, Left'
	$listview_AvailableContent.CheckBoxes = $True
	[void]$listview_AvailableContent.Columns.Add($AvailContentName)
	[void]$listview_AvailableContent.Columns.Add($AvailContentID)
	[void]$listview_AvailableContent.Columns.Add($AvailContentSize)
	$listview_AvailableContent.FullRowSelect = $True
	$listview_AvailableContent.GridLines = $True
	$listview_AvailableContent.Location = '6, 72'
	$listview_AvailableContent.Name = 'listview_AvailableContent'
	$listview_AvailableContent.Size = '288, 402'
	$listview_AvailableContent.Sorting = 'Ascending'
	$listview_AvailableContent.TabIndex = 2
	$listview_AvailableContent.UseCompatibleStateImageBehavior = $False
	$listview_AvailableContent.View = 'Details'
	$listview_AvailableContent.add_MouseDoubleClick($listview_AvailableContent_MouseDoubleClick)
	#
	# combobox_AvailableContentType
	#
	$combobox_AvailableContentType.AutoCompleteMode = 'SuggestAppend'
	$combobox_AvailableContentType.AutoCompleteSource = 'ListItems'
	$combobox_AvailableContentType.FormattingEnabled = $True
	[void]$combobox_AvailableContentType.Items.Add('Application')
	[void]$combobox_AvailableContentType.Items.Add('BootImage')
	[void]$combobox_AvailableContentType.Items.Add('DriverPackage')
	[void]$combobox_AvailableContentType.Items.Add('OSImage')
	[void]$combobox_AvailableContentType.Items.Add('OSUpgradeImage')
	[void]$combobox_AvailableContentType.Items.Add('Package')
	[void]$combobox_AvailableContentType.Items.Add('SoftwareUpdatePackage')
	[void]$combobox_AvailableContentType.Items.Add('TaskSequence')
	$combobox_AvailableContentType.Location = '86, 19'
	$combobox_AvailableContentType.Name = 'combobox_AvailableContentType'
	$combobox_AvailableContentType.Size = '208, 21'
	$combobox_AvailableContentType.TabIndex = 1
	$combobox_AvailableContentType.add_SelectedIndexChanged($combobox_AvailableContentType_SelectedIndexChanged)
	#
	# label_AvailableContentType
	#
	$label_AvailableContentType.AutoSize = $True
	$label_AvailableContentType.Location = '6, 22'
	$label_AvailableContentType.Name = 'label_AvailableContentType'
	$label_AvailableContentType.Size = '75, 17'
	$label_AvailableContentType.TabIndex = 0
	$label_AvailableContentType.Text = 'Content Type:'
	$label_AvailableContentType.UseCompatibleTextRendering = $True
	#
	# tabpage_Summary
	#
	$tabpage_Summary.Controls.Add($groupbox_SummaryConfiguration)
	$tabpage_Summary.Controls.Add($groupbox_SummaryContent)
	$tabpage_Summary.Controls.Add($groupbox_SummaryDPs)
	$tabpage_Summary.Location = '4, 22'
	$tabpage_Summary.Name = 'tabpage_Summary'
	$tabpage_Summary.Size = '761, 492'
	$tabpage_Summary.TabIndex = 2
	$tabpage_Summary.Text = 'Summary'
	$tabpage_Summary.UseVisualStyleBackColor = $True
	$tabpage_Summary.add_Enter($tabpage_Summary_Enter)
	#
	# groupbox_SummaryConfiguration
	#
	$groupbox_SummaryConfiguration.Controls.Add($textbox_SummaryTimezone)
	$groupbox_SummaryConfiguration.Controls.Add($label_SummaryTimezone)
	$groupbox_SummaryConfiguration.Controls.Add($textbox_SummaryAction)
	$groupbox_SummaryConfiguration.Controls.Add($textbox_SummaryRecipients)
	$groupbox_SummaryConfiguration.Controls.Add($textbox_SummaryScheduledTime)
	$groupbox_SummaryConfiguration.Controls.Add($label_SummaryAction)
	$groupbox_SummaryConfiguration.Controls.Add($label_SummaryRecipients)
	$groupbox_SummaryConfiguration.Controls.Add($label_SummaryScheduledTime)
	$groupbox_SummaryConfiguration.Location = '491, 182'
	$groupbox_SummaryConfiguration.Name = 'groupbox_SummaryConfiguration'
	$groupbox_SummaryConfiguration.Size = '266, 129'
	$groupbox_SummaryConfiguration.TabIndex = 17
	$groupbox_SummaryConfiguration.TabStop = $False
	$groupbox_SummaryConfiguration.Text = 'Summary of Configuration'
	$groupbox_SummaryConfiguration.UseCompatibleTextRendering = $True
	#
	# textbox_SummaryTimezone
	#
	$textbox_SummaryTimezone.Location = '99, 45'
	$textbox_SummaryTimezone.Name = 'textbox_SummaryTimezone'
	$textbox_SummaryTimezone.ReadOnly = $True
	$textbox_SummaryTimezone.Size = '161, 20'
	$textbox_SummaryTimezone.TabIndex = 7
	#
	# label_SummaryTimezone
	#
	$label_SummaryTimezone.AutoSize = $True
	$label_SummaryTimezone.Location = '6, 48'
	$label_SummaryTimezone.Name = 'label_SummaryTimezone'
	$label_SummaryTimezone.Size = '57, 17'
	$label_SummaryTimezone.TabIndex = 6
	$label_SummaryTimezone.Text = 'Timezone:'
	$label_SummaryTimezone.UseCompatibleTextRendering = $True
	#
	# textbox_SummaryAction
	#
	$textbox_SummaryAction.Location = '99, 97'
	$textbox_SummaryAction.Name = 'textbox_SummaryAction'
	$textbox_SummaryAction.ReadOnly = $True
	$textbox_SummaryAction.Size = '161, 20'
	$textbox_SummaryAction.TabIndex = 5
	#
	# textbox_SummaryRecipients
	#
	$textbox_SummaryRecipients.Location = '99, 71'
	$textbox_SummaryRecipients.Name = 'textbox_SummaryRecipients'
	$textbox_SummaryRecipients.ReadOnly = $True
	$textbox_SummaryRecipients.Size = '161, 20'
	$textbox_SummaryRecipients.TabIndex = 4
	#
	# textbox_SummaryScheduledTime
	#
	$textbox_SummaryScheduledTime.Location = '99, 19'
	$textbox_SummaryScheduledTime.Name = 'textbox_SummaryScheduledTime'
	$textbox_SummaryScheduledTime.ReadOnly = $True
	$textbox_SummaryScheduledTime.Size = '161, 20'
	$textbox_SummaryScheduledTime.TabIndex = 3
	#
	# label_SummaryAction
	#
	$label_SummaryAction.AutoSize = $True
	$label_SummaryAction.Location = '6, 100'
	$label_SummaryAction.Name = 'label_SummaryAction'
	$label_SummaryAction.Size = '39, 17'
	$label_SummaryAction.TabIndex = 2
	$label_SummaryAction.Text = 'Action:'
	$label_SummaryAction.UseCompatibleTextRendering = $True
	#
	# label_SummaryRecipients
	#
	$label_SummaryRecipients.AutoSize = $True
	$label_SummaryRecipients.Location = '6, 74'
	$label_SummaryRecipients.Name = 'label_SummaryRecipients'
	$label_SummaryRecipients.Size = '60, 17'
	$label_SummaryRecipients.TabIndex = 1
	$label_SummaryRecipients.Text = 'Recipients:'
	$label_SummaryRecipients.UseCompatibleTextRendering = $True
	#
	# label_SummaryScheduledTime
	#
	$label_SummaryScheduledTime.AutoSize = $True
	$label_SummaryScheduledTime.Location = '6, 22'
	$label_SummaryScheduledTime.Name = 'label_SummaryScheduledTime'
	$label_SummaryScheduledTime.Size = '89, 17'
	$label_SummaryScheduledTime.TabIndex = 0
	$label_SummaryScheduledTime.Text = 'Scheduled Time:'
	$label_SummaryScheduledTime.UseCompatibleTextRendering = $True
	#
	# groupbox_SummaryContent
	#
	$groupbox_SummaryContent.Controls.Add($listview_SelectedContentSummary)
	$groupbox_SummaryContent.Controls.Add($textbox_SummaryTotalContentSize)
	$groupbox_SummaryContent.Controls.Add($label_SummaryTotalContentSize)
	$groupbox_SummaryContent.Location = '3, 3'
	$groupbox_SummaryContent.Name = 'groupbox_SummaryContent'
	$groupbox_SummaryContent.Size = '482, 255'
	$groupbox_SummaryContent.TabIndex = 16
	$groupbox_SummaryContent.TabStop = $False
	$groupbox_SummaryContent.Text = 'Summary of Selected Content'
	$groupbox_SummaryContent.UseCompatibleTextRendering = $True
	#
	# listview_SelectedContentSummary
	#
	[void]$listview_SelectedContentSummary.Columns.Add($SummaryContentName)
	[void]$listview_SelectedContentSummary.Columns.Add($SummaryContentID)
	[void]$listview_SelectedContentSummary.Columns.Add($SummaryContentSize)
	$listview_SelectedContentSummary.FullRowSelect = $True
	$listview_SelectedContentSummary.GridLines = $True
	$listview_SelectedContentSummary.Location = '6, 19'
	$listview_SelectedContentSummary.Name = 'listview_SelectedContentSummary'
	$listview_SelectedContentSummary.Size = '470, 200'
	$listview_SelectedContentSummary.Sorting = 'Ascending'
	$listview_SelectedContentSummary.TabIndex = 8
	$listview_SelectedContentSummary.UseCompatibleStateImageBehavior = $False
	$listview_SelectedContentSummary.View = 'Details'
	#
	# textbox_SummaryTotalContentSize
	#
	$textbox_SummaryTotalContentSize.Location = '109, 225'
	$textbox_SummaryTotalContentSize.Name = 'textbox_SummaryTotalContentSize'
	$textbox_SummaryTotalContentSize.ReadOnly = $True
	$textbox_SummaryTotalContentSize.Size = '367, 20'
	$textbox_SummaryTotalContentSize.TabIndex = 14
	#
	# label_SummaryTotalContentSize
	#
	$label_SummaryTotalContentSize.AutoSize = $True
	$label_SummaryTotalContentSize.Location = '6, 228'
	$label_SummaryTotalContentSize.Name = 'label_SummaryTotalContentSize'
	$label_SummaryTotalContentSize.Size = '100, 17'
	$label_SummaryTotalContentSize.TabIndex = 13
	$label_SummaryTotalContentSize.Text = 'Total Content Size:'
	$label_SummaryTotalContentSize.UseCompatibleTextRendering = $True
	#
	# groupbox_SummaryDPs
	#
	$groupbox_SummaryDPs.Controls.Add($listview_SelectedDPSummary)
	$groupbox_SummaryDPs.Location = '3, 264'
	$groupbox_SummaryDPs.Name = 'groupbox_SummaryDPs'
	$groupbox_SummaryDPs.Size = '482, 225'
	$groupbox_SummaryDPs.TabIndex = 15
	$groupbox_SummaryDPs.TabStop = $False
	$groupbox_SummaryDPs.Text = 'Summary of Selected DP Groups'
	$groupbox_SummaryDPs.UseCompatibleTextRendering = $True
	#
	# listview_SelectedDPSummary
	#
	[void]$listview_SelectedDPSummary.Columns.Add($SummaryDPGroupsName)
	[void]$listview_SelectedDPSummary.Columns.Add($SummaryDPGroupsDescription)
	$listview_SelectedDPSummary.FullRowSelect = $True
	$listview_SelectedDPSummary.GridLines = $True
	$listview_SelectedDPSummary.Location = '6, 19'
	$listview_SelectedDPSummary.Name = 'listview_SelectedDPSummary'
	$listview_SelectedDPSummary.Size = '470, 200'
	$listview_SelectedDPSummary.Sorting = 'Ascending'
	$listview_SelectedDPSummary.TabIndex = 7
	$listview_SelectedDPSummary.UseCompatibleStateImageBehavior = $False
	$listview_SelectedDPSummary.View = 'Details'
	#
	# buttonNext
	#
	$buttonNext.Anchor = 'Bottom, Right'
	$buttonNext.Location = '545, 536'
	$buttonNext.Name = 'buttonNext'
	$buttonNext.Size = '75, 23'
	$buttonNext.TabIndex = 2
	$buttonNext.Text = '&Next >'
	$buttonNext.UseCompatibleTextRendering = $True
	$buttonNext.UseVisualStyleBackColor = $True
	$buttonNext.add_Click($buttonNext_Click)
	#
	# AvailDPGroupsName
	#
	$AvailDPGroupsName.Text = 'Name'
	$AvailDPGroupsName.Width = 25
	#
	# AvailDPGroupsDescription
	#
	$AvailDPGroupsDescription.Text = 'Description'
	$AvailDPGroupsDescription.Width = 25
	#
	# SelectedDPGroupsName
	#
	$SelectedDPGroupsName.Text = 'Name'
	$SelectedDPGroupsName.Width = 25
	#
	# SelectedDPGroupsDescription
	#
	$SelectedDPGroupsDescription.Text = 'Description'
	$SelectedDPGroupsDescription.Width = 25
	#
	# AvailContentName
	#
	$AvailContentName.Text = 'Name'
	#
	# AvailContentID
	#
	$AvailContentID.Text = 'ID'
	#
	# AvailContentSize
	#
	$AvailContentSize.Text = 'Size'
	#
	# SelectedContentName
	#
	$SelectedContentName.Text = 'Name'
	$SelectedContentName.Width = 61
	#
	# SelectedContentID
	#
	$SelectedContentID.Text = 'ID'
	#
	# SelectedContentSize
	#
	$SelectedContentSize.Text = 'Size'
	#
	# SummaryDPGroupsName
	#
	$SummaryDPGroupsName.Text = 'Name'
	$SummaryDPGroupsName.Width = 80
	#
	# SummaryDPGroupsDescription
	#
	$SummaryDPGroupsDescription.Text = 'Description'
	$SummaryDPGroupsDescription.Width = 80
	#
	# SummaryContentName
	#
	$SummaryContentName.Text = 'Name'
	#
	# SummaryContentID
	#
	$SummaryContentID.Text = 'ID'
	#
	# SummaryContentSize
	#
	$SummaryContentSize.Text = 'Size'
	#
	# errorprovider
	#
	$errorprovider.ContainerControl = $formContentDistribution
	#
	# timer_JobTracker
	#
	$timer_JobTracker.add_Tick($timer_JobTracker_Tick)
	#
	# openfiledialog_CMTrace
	#
	$openfiledialog_CMTrace.DefaultExt = 'exe'
	$openfiledialog_CMTrace.FileName = 'cmtrace.exe'
	$openfiledialog_CMTrace.Filter = 'EXE Files|*.exe'
	$openfiledialog_CMTrace.InitialDirectory = 'c:\'
	$errorprovider.EndInit()
	$groupbox_SummaryDPs.ResumeLayout()
	$groupbox_SummaryContent.ResumeLayout()
	$groupbox_SummaryConfiguration.ResumeLayout()
	$tabpage_Summary.ResumeLayout()
	$groupbox_AvailableContent.ResumeLayout()
	$groupbox_SelectedContent.ResumeLayout()
	$tabpage_Content.ResumeLayout()
	$groupbox_SelectedDPs.ResumeLayout()
	$groupbox_DPs.ResumeLayout()
	$tabpage_DPSelection.ResumeLayout()
	$groupbox_DateTime.ResumeLayout()
	$tabpage_Configuration.ResumeLayout()
	$tabcontrolWizard.ResumeLayout()
	$formContentDistribution.ResumeLayout()
	#endregion Generated Form Code

	#----------------------------------------------

	#Save the initial state of the form
	$InitialFormWindowState = $formContentDistribution.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formContentDistribution.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formContentDistribution.add_FormClosed($Form_Cleanup_FormClosed)
	#Store the control values when form is closing
	$formContentDistribution.add_Closing($Form_StoreValues_Closing)
	#Show the Form
	return $formContentDistribution.ShowDialog()

}
#endregion Source: MainForm.psf

#Start the application
Main ($CommandLine)
