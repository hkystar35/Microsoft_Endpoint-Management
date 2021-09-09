<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows. 
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. 
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
PARAM (
	[Parameter(Mandatory = $false)][ValidateSet('Install', 'Uninstall')][string]$DeploymentType = 'Install',
	[Parameter(Mandatory = $false)][ValidateSet('Interactive', 'Silent', 'NonInteractive')][string]$DeployMode = 'Interactive',
	[Parameter(Mandatory = $false)][switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory = $false)][switch]$TerminalServerMode = $false,
	[Parameter(Mandatory = $false)][switch]$DisableLogging = $false
)

TRY {
	## Set the script execution policy for this process
	TRY {
		Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
	} CATCH {
	}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'Paylocity'
	[string]$appName = 'Get Performance Data for Trend'
	[string]$appVersion = '1.0'
	[string]$appMSIProductCode = $false #''
	[string]$appProcessesString = $false #'' # comma-separated, but all inside sigle quote, like 'chrome,firefox,iexplore'
	[string]$appServicesString = $false #'' # comma-separated, but all inside sigle quote, like 'zoom,ccmexec,spotify'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '02/12/2019'
	[string]$appScriptAuthor = 'Nicolas Wendlowsky'
	##*===============================================
	#Do not modify these variables:
	$appProcesses = $appProcessesString -split (',')
	$appServices = $appServicesString -split (',')
	## Change DeployMode to Interactive if running processes detected that need to be closed.
	#region ChangeDeployMode
	## Leave $appProcessesString variable at '' or $NULL and this will be skipped.
	## -- when running interactive/noninteractive, check whether process is running. If not, then change to Silent.
	$StartingDeployMode = $DeployMode
	IF (($DeployMode -ne 'Silent') -or !($appProcessesString)) {
		$SkipProcessesCheck = 'YES'
	} ELSEIF ($DeployMode -eq 'Silent' -and ($appProcessesString)) {
		$runningApps = 0
		$appProcesses | ForEach-Object{
			IF (Get-Process -Name $_ -ErrorAction SilentlyContinue) {
				$runningApps += 1
				[array]$runningAppNames += $_
			}
		}
		IF ($runningApps -gt 0) {
			$DeployMode = 'Interactive'
		} ELSEIF ($runningApps -eq 0) {
			$DetectedApps = ''
		}
	}
	#endregion
	#>
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.7.0'
	[string]$deployAppScriptDate = '02/13/2018'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	IF (Test-Path -LiteralPath 'variable:HostInvocation') {
		$InvocationInfo = $HostInvocation
	} ELSE {
		$InvocationInfo = $MyInvocation
	}
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	TRY {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		IF (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
			THROW "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
		}
		IF ($DisableLogging) {
			. $moduleAppDeployToolkitMain -DisableLogging
		} ELSE {
			. $moduleAppDeployToolkitMain
		}
	} CATCH {
		IF ($mainExitCode -eq 0) {
			[int32]$mainExitCode = 60008
		}
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		IF (Test-Path -LiteralPath 'variable:HostInvocation') {
			$script:ExitCode = $mainExitCode; EXIT
		} ELSE {
			EXIT $mainExitCode
		}
	}
	
	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
	#Log Entries Change DeployMode
	Write-Log -Message ('Starting Mode: {0}.' -f $StartingDeployMode) -Severity 1 -Source $deployAppScriptFriendlyName
	IF ($SkipProcessesCheck -eq 'YES') {
		Write-Log -Message 'DeployMode is not Silent and/or there are no processes to detect. No change to DeployMode' -Severity 1 -Source $deployAppScriptFriendlyName
	}
	IF ($SkipProcessesCheck -ne 'YES') {
		Write-Log -Message ('Checked for {0} running apps: {1}.' -f $appProcesses.Count, $appProcessesString) -Severity 1 -Source $deployAppScriptFriendlyName
		IF ($DetectedApps -ne '') {
			$DetectedApps = " ($($runningAppNames))"
		}
		Write-Log -Message ('{0} Apps{1} detected. Mode is {2}' -f $runningApps, $DetectedApps, $DeployMode) -Severity 2 -Source $deployAppScriptFriendlyName
	}
	#>		
	IF ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		## Show Welcome Message
		IF ($appProcessesString) {
			Show-InstallationWelcome -CloseApps "$appProcessesString" -AllowDeferCloseApps -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		} ELSE {
			Show-InstallationWelcome -AllowDeferCloseApps -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		}
		## <Perform Pre-Installation tasks here>
		
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		## <Perform Installation tasks here>
		
		#region FUNCTION Release-COMObject
		FUNCTION Release-COMObject ($ref) {
			
			[System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) | out-null
			[System.GC]::Collect()
			[System.GC]::WaitForPendingFinalizers()
			Write-Log -Message "ComObject released" -severity 1 -Source $installPhase
			
		}
		#endregion FUNCTION Release-COMObject
		
		# Set file locations
		$TrendFiles = @()
		$TrendFileDestination = $env:SystemDrive
		Write-Log -Message "Trend File Destination: $TrendFileDestination\" -severity 1 -Source $installPhase
		
		# Copy files
		Get-ChildItem -Path "$dirFiles\LogServer" -Filter *.* | Where-Object{
			$_.PSIsContainer -eq $false
		} | ForEach-Object{
			$TrendFiles += Copy-Item -Path $_.FullName -Destination "$TrendFileDestination\" -PassThru
			Write-Log -Message "Copied File from $($_.Fullname) to $TrendFileDestination\"
			#Copy-File -Path $_.FullName -Destination $TrendFileDestination\
			#$TrendFiles += Get-Item $_.FullName
		}
		
		
		$7Zip = ($TrendFiles | Where-Object{$_.Name -eq '7z.exe'}).FullName
		Write-Log -Message "7Zip Location: $7Zip" -severity 1 -Source $installPhase
		$TrendLogServer = $TrendFiles | Where-Object{$_.Name -eq 'LogServer.exe'}
		$TrendLogServerProcess = $TrendLogServer.BaseName
		$TrendLogServerEXE = $TrendLogServer.Name
		Write-Log -Message "Trend LogServer.exe Location: $TrendLogServerEXE" -severity 1 -Source $installPhase
		
		# Create INI
		$TrendLogfile = "$TrendFileDestination\$($envComputerName)_ofcdebug.log"
		Write-Log -Message "Trend Logfile Location: $TrendLogfile" -severity 1 -Source $installPhase
		$INIcontent = @"
[Debug]
debuglevel=9
debugLog=$($TrendLogfile)
debugLevel_new=D
debugSplitSize=10485760
debugSplitPeriod=12
debugRemoveAfterSplit=1
"@
		$INIFileObj = New-Item -Path $TrendFileDestination\ -ItemType File -Name 'ofcdebug.ini' -Value $INIcontent -Force
		$TrendFiles += $INIFileObj
		Write-Log -Message "Trend INI file Location: $($INIFileObj.FullName)" -severity 1 -Source $installPhase
		
		# Start Trend Log service
		Execute-Process -Path $TrendLogServer -NoWait
		
		# Windows Counters
		Write-Log -Message "Creating PerfMon Data Collector Set" -severity 1 -Source $installPhase
		
		$CounterName = 'Trend_Counters'
		Write-Log -Message "Data Collector Set Name: $($CounterName)" -severity 1 -Source $installPhase
		$Duration = New-TimeSpan -Minutes 15
		$XML_Duration = $Duration.TotalSeconds # seconds
		Write-Log -Message "Data Collector Set Duration: $($Duration.TotalMinutes) minutes" -severity 1 -Source $installPhase
		$XML_Description = 'Trend reporting data.'
		$XML_OutputLocation = "$env:SystemDrive\Logs\Trend_Counters" # date format yyyyMMdd\-NNNNNN
		$XML_RootPath = '%systemdrive%\Logs\Trend_Counters'
		$XML_LatestOutputLocation = "$env:SystemDrive\Logs\Trend_Counters"
		[string]$XML_Content = @"
<?xml version="1.0" encoding="UTF-16"?>
<DataCollectorSet>
	<Status>0</Status>
	<Duration>$XML_Duration</Duration>
	<Description>$XML_Description</Description>
	<DescriptionUnresolved>$XML_Description</DescriptionUnresolved>
	<DisplayName>
	</DisplayName>
	<DisplayNameUnresolved>
	</DisplayNameUnresolved>
	<SchedulesEnabled>-1</SchedulesEnabled>
	<Keyword>CPU</Keyword>
	<Keyword>Memory</Keyword>
	<Keyword>Disk</Keyword>
	<Keyword>Performance</Keyword>
	<LatestOutputLocation>$XML_LatestOutputLocation\EUCE-P1-TEST_20190208-000001</LatestOutputLocation>
	<Name></Name>
	<OutputLocation>$XML_OutputLocation</OutputLocation>
	<RootPath>$XML_RootPath</RootPath>
	<Segment>0</Segment>
	<SegmentMaxDuration>0</SegmentMaxDuration>
	<SegmentMaxSize>0</SegmentMaxSize>
	<SerialNumber>2</SerialNumber>
	<Server>
	</Server>
	<Subdirectory>
	</Subdirectory>
	<SubdirectoryFormat>3</SubdirectoryFormat>
	<SubdirectoryFormatPattern>yyyyMMdd\-NNNNNN</SubdirectoryFormatPattern>
	<Task>
	</Task>
	<TaskRunAsSelf>0</TaskRunAsSelf>
	<TaskArguments>
	</TaskArguments>
	<TaskUserTextArguments>
	</TaskUserTextArguments>
	<UserAccount>SYSTEM</UserAccount>
	<Security>O:BAG:DUD:AI(A;;FA;;;SY)(A;;FA;;;BA)(A;;0x1200a9;;;LU)(A;;0x1301ff;;;S-1-5-80-2661322625-712705077-2999183737-3043590567-590698655)(A;ID;0x1f019f;;;BA)(A;ID;0x1f019f;;;SY)(A;ID;FR;;;AU)(A;ID;FR;;;LS)(A;ID;FR;;;NS)(A;ID;FA;;;BA)</Security>
	<StopOnCompletion>0</StopOnCompletion>
	<TraceDataCollector>
		<DataCollectorType>1</DataCollectorType>
		<Name>NT Kernel</Name>
		<FileName>NtKernel</FileName>
		<FileNameFormat>0</FileNameFormat>
		<FileNameFormatPattern>
		</FileNameFormatPattern>
		<LogAppend>0</LogAppend>
		<LogCircular>0</LogCircular>
		<LogOverwrite>0</LogOverwrite>
		<LatestOutputLocation>$XML_LatestOutputLocation</LatestOutputLocation>
		<Guid>{00000000-0000-0000-0000-000000000000}</Guid>
		<BufferSize>64</BufferSize>
		<BuffersLost>0</BuffersLost>
		<BuffersWritten>0</BuffersWritten>
		<ClockType>1</ClockType>
		<EventsLost>0</EventsLost>
		<ExtendedModes>0</ExtendedModes>
		<FlushTimer>0</FlushTimer>
		<FreeBuffers>0</FreeBuffers>
		<MaximumBuffers>200</MaximumBuffers>
		<MinimumBuffers>0</MinimumBuffers>
		<NumberOfBuffers>0</NumberOfBuffers>
		<PreallocateFile>0</PreallocateFile>
		<ProcessMode>0</ProcessMode>
		<RealTimeBuffersLost>0</RealTimeBuffersLost>
		<SessionName>NT Kernel Logger</SessionName>
		<SessionThreadId>0</SessionThreadId>
		<StreamMode>1</StreamMode>
		<TraceDataProvider>
			<DisplayName>{9E814AAD-3204-11D2-9A82-006008A86939}</DisplayName>
			<FilterEnabled>0</FilterEnabled>
			<FilterType>0</FilterType>
			<Level>
				<Description>Events up to this level are enabled</Description>
				<ValueMapType>1</ValueMapType>
				<Value>0</Value>
				<ValueMapItem>
					<Key>
					</Key>
					<Description>
					</Description>
					<Enabled>-1</Enabled>
					<Value>0x0</Value>
				</ValueMapItem>
			</Level>
			<KeywordsAny>
				<Description>Events with any of these keywords are enabled</Description>
				<ValueMapType>2</ValueMapType>
				<Value>0x10303</Value>
				<ValueMapItem>
					<Key>
					</Key>
					<Description>
					</Description>
					<Enabled>-1</Enabled>
					<Value>0x1</Value>
				</ValueMapItem>
				<ValueMapItem>
					<Key>
					</Key>
					<Description>
					</Description>
					<Enabled>-1</Enabled>
					<Value>0x2</Value>
				</ValueMapItem>
				<ValueMapItem>
					<Key>
					</Key>
					<Description>
					</Description>
					<Enabled>-1</Enabled>
					<Value>0x100</Value>
				</ValueMapItem>
				<ValueMapItem>
					<Key>
					</Key>
					<Description>
					</Description>
					<Enabled>-1</Enabled>
					<Value>0x200</Value>
				</ValueMapItem>
				<ValueMapItem>
					<Key>
					</Key>
					<Description>
					</Description>
					<Enabled>-1</Enabled>
					<Value>0x10000</Value>
				</ValueMapItem>
			</KeywordsAny>
			<KeywordsAll>
				<Description>Events with all of these keywords are enabled</Description>
				<ValueMapType>2</ValueMapType>
				<Value>0x0</Value>
			</KeywordsAll>
			<Properties>
				<Description>These additional data fields will be collected with each event</Description>
				<ValueMapType>2</ValueMapType>
				<Value>0</Value>
			</Properties>
			<Guid>{9E814AAD-3204-11D2-9A82-006008A86939}</Guid>
		</TraceDataProvider>
	</TraceDataCollector>
	<PerformanceCounterDataCollector>
		<DataCollectorType>0</DataCollectorType>
		<Name>Performance Counter</Name>
		<FileName>Performance Counter</FileName>
		<FileNameFormat>0</FileNameFormat>
		<FileNameFormatPattern>
		</FileNameFormatPattern>
		<LogAppend>0</LogAppend>
		<LogCircular>0</LogCircular>
		<LogOverwrite>0</LogOverwrite>
		<LatestOutputLocation>$XML_LatestOutputLocation\EUCE-P1-TEST_20190208-000001\Performance Counter.blg</LatestOutputLocation>
		<DataSourceName>
		</DataSourceName>
		<SampleInterval>1</SampleInterval>
		<SegmentMaxRecords>0</SegmentMaxRecords>
		<LogFileFormat>3</LogFileFormat>
		<Counter>\Process(*)\*</Counter>
		<Counter>\PhysicalDisk(*)\*</Counter>
		<Counter>\Processor(*)\*</Counter>
		<Counter>\Processor Performance(*)\*</Counter>
		<Counter>\Memory\*</Counter>
		<Counter>\System\*</Counter>
		<Counter>\Server\*</Counter>
		<Counter>\Network Interface(*)\*</Counter>
		<Counter>\UDPv4\*</Counter>
		<Counter>\TCPv4\*</Counter>
		<Counter>\IPv4\*</Counter>
		<Counter>\UDPv6\*</Counter>
		<Counter>\TCPv6\*</Counter>
		<Counter>\IPv6\*</Counter>
		<CounterDisplayName>\Process(*)\*</CounterDisplayName>
		<CounterDisplayName>\PhysicalDisk(*)\*</CounterDisplayName>
		<CounterDisplayName>\Processor(*)\*</CounterDisplayName>
		<CounterDisplayName>\Processor Performance(*)\*</CounterDisplayName>
		<CounterDisplayName>\Memory\*</CounterDisplayName>
		<CounterDisplayName>\System\*</CounterDisplayName>
		<CounterDisplayName>\Server\*</CounterDisplayName>
		<CounterDisplayName>\Network Interface(*)\*</CounterDisplayName>
		<CounterDisplayName>\UDPv4\*</CounterDisplayName>
		<CounterDisplayName>\TCPv4\*</CounterDisplayName>
		<CounterDisplayName>\IPv4\*</CounterDisplayName>
		<CounterDisplayName>\UDPv6\*</CounterDisplayName>
		<CounterDisplayName>\TCPv6\*</CounterDisplayName>
		<CounterDisplayName>\IPv6\*</CounterDisplayName>
	</PerformanceCounterDataCollector>
	<DataManager>
		<Enabled>-1</Enabled>
		<CheckBeforeRunning>-1</CheckBeforeRunning>
		<MinFreeDisk>200</MinFreeDisk>
		<MaxSize>1024</MaxSize>
		<MaxFolderCount>100</MaxFolderCount>
		<ResourcePolicy>0</ResourcePolicy>
		<ReportFileName>report.html</ReportFileName>
		<RuleTargetFileName>report.xml</RuleTargetFileName>
		<EventsFileName>
		</EventsFileName>
		<Rules>
			<Logging level="15" file="rules.log">
			</Logging>
			<Import file="%systemroot%\pla\rules\Rules.System.Common.xml">
			</Import>
			<Import file="%systemroot%\pla\rules\Rules.System.Summary.xml">
			</Import>
			<Import file="%systemroot%\pla\rules\Rules.System.Performance.xml">
			</Import>
			<Import file="%systemroot%\pla\rules\Rules.System.CPU.xml">
			</Import>
			<Import file="%systemroot%\pla\rules\Rules.System.Network.xml">
			</Import>
			<Import file="%systemroot%\pla\rules\Rules.System.Disk.xml">
			</Import>
			<Import file="%systemroot%\pla\rules\Rules.System.Memory.xml">
			</Import>
		</Rules>
		<ReportSchema>
			<Report name="systemPerformance" version="1" threshold="100">
				<Import file="%systemroot%\pla\reports\Report.System.Common.xml">
				</Import>
				<Import file="%systemroot%\pla\reports\Report.System.Summary.xml">
				</Import>
				<Import file="%systemroot%\pla\reports\Report.System.Performance.xml">
				</Import>
				<Import file="%systemroot%\pla\reports\Report.System.CPU.xml">
				</Import>
				<Import file="%systemroot%\pla\reports\Report.System.Network.xml">
				</Import>
				<Import file="%systemroot%\pla\reports\Report.System.Disk.xml">
				</Import>
				<Import file="%systemroot%\pla\reports\Report.System.Memory.xml">
				</Import>
			</Report>
		</ReportSchema>
		<FolderAction>
			<Size>0</Size>
			<Age>1</Age>
			<Actions>3</Actions>
			<SendCabTo>
			</SendCabTo>
		</FolderAction>
		<FolderAction>
			<Size>0</Size>
			<Age>56</Age>
			<Actions>8</Actions>
			<SendCabTo>
			</SendCabTo>
		</FolderAction>
		<FolderAction>
			<Size>0</Size>
			<Age>168</Age>
			<Actions>26</Actions>
			<SendCabTo>
			</SendCabTo>
		</FolderAction>
	</DataManager>
	<Value name="PerformanceMonitorView" type="document">
		<OBJECT ID="DISystemMonitor" CLASSID="CLSID:C4D2D8E0-D1DD-11CE-940F-008029004347">
			<PARAM NAME="CounterCount" VALUE="4">
			</PARAM>
			<PARAM NAME="Counter00001.Path" VALUE="\Processor(_Total)\% Processor Time">
			</PARAM>
			<PARAM NAME="Counter00001.Color" VALUE="255">
			</PARAM>
			<PARAM NAME="Counter00001.Width" VALUE="2">
			</PARAM>
			<PARAM NAME="Counter00001.LineStyle" VALUE="0">
			</PARAM>
			<PARAM NAME="Counter00001.ScaleFactor" VALUE="0">
			</PARAM>
			<PARAM NAME="Counter00001.Show" VALUE="1">
			</PARAM>
			<PARAM NAME="Counter00001.Selected" VALUE="1">
			</PARAM>
			<PARAM NAME="Counter00002.Path" VALUE="\Memory\Pages/sec">
			</PARAM>
			<PARAM NAME="Counter00002.Color" VALUE="65280">
			</PARAM>
			<PARAM NAME="Counter00002.Width" VALUE="1">
			</PARAM>
			<PARAM NAME="Counter00003.Path" VALUE="\PhysicalDisk(_Total)\Avg. Disk sec/Read">
			</PARAM>
			<PARAM NAME="Counter00003.Color" VALUE="16711680">
			</PARAM>
			<PARAM NAME="Counter00003.Width" VALUE="1">
			</PARAM>
			<PARAM NAME="Counter00004.Path" VALUE="\PhysicalDisk(_Total)\Avg. Disk sec/Write">
			</PARAM>
			<PARAM NAME="Counter00004.Color" VALUE="55295">
			</PARAM>
			<PARAM NAME="Counter00004.Width" VALUE="1">
			</PARAM>
		</OBJECT>
	</Value>
</DataCollectorSet>
"@
		
		$DCS = New-Object -ComObject Pla.DataCollectorSet
		$DCS.SetXml($XML_Content)
		$DCS.Commit("$CounterName", $null, 0x0003) | Out-Null
		$DCS.start($false)
		
		$PerfMon_LogLocation = $DCS.OutputLocation
		Write-Log -Message "PerfMon DCS Log Location: $PerfMon_LogLocation" -severity 1 -Source $installPhase
		
		$Start = Get-Date
		Write-Log -Message "Starting loop while DCS runs. Start time: $($Start)" -severity 1 -Source $installPhase
		$SleepMinutes = $Duration.TotalMinutes/5
    
		## Do While Loop
		DO {
			Write-Log -Message "Status = $($DCS.Status)"
			Write-Log -Message "Sleeping for $($SleepMinutes) minutes ..." -severity 1 -Source $installPhase
			start-sleep -Seconds  $($SleepMinutes * 60)
		} WHILE ($DCS.Status -eq 1 -or $Start.AddMinutes($Duration.TotalMinutes + $SleepMinutes) -gt (Get-Date))
		
		# Sleep extra 60 seconds while compiling
		start-sleep -Seconds 60
		
		Write-Log -Message "DCS loop ended. Checking results." -severity 1 -Source $installPhase
		
		SWITCH ($DCS.Status) {
			0 {$EndPerfMonStatus = 'stopped'}
			1 {$EndPerfMonStatus = 'running'}
			2 {$EndPerfMonStatus = 'compiling'}
			3 {$EndPerfMonStatus = 'queued'}
			4 {$EndPerfMonStatus = 'unknown'}
		}
		
		IF ($DCS.Status -eq 2) {
			Write-Log -Message "DCS still compiling, waiting another minute" -Severity 1 -Source $installPhase
			Start-Sleep -Seconds 60
		} ELSEIF ($DCS.Status -eq 0) {
			Write-Log -Message "DCS finished Successfully" -Severity 1 -Source $installPhase
		} ELSEIF ($DCS.Status -eq 4) {
			Write-Log -Message "DCS finished Unsuccessfully: $($EndPerfMonStatus)" -severity 3 -Source $installPhase
			Release-COMObject $DCS
			Stop-Process -Name $TrendLogServerEXE -Force -ErrorAction SilentlyContinue
		}
		
		Release-COMObject $DCS
		
		# Stop LogServer
		$Stop = Stop-Process -Name $TrendLogServerProcess -Force -ErrorAction SilentlyContinue -PassThru
		
		
		
		# Gather files and Zip
		$UploadFolder = "$env:SystemDrive\Logs\Uploads\$($envCOMPUTERNAME)_$(Get-Date -Format "yyyy-MM-dd_HHmmss")"
		New-Folder -Path $UploadFolder
		New-Folder -Path "$UploadFolder\RAW"
		$Upload_Files = @()
		
		# Reg Export
		Execute-Process -Path 'Reg.exe' -Parameters "export `"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\TrendMicro`" `"$($UploadFolder)\RAW\$($envCOMPUTERNAME)_Trend.reg`""
		
		Write-Log -Message "Gathering files to add to Zip file" -severity 1 -Source $installPhase
		$LogsToCopy = Get-ChildItem -Path $env:SystemDrive\ -Filter "*$($INIFileObj.BaseName)*"
		$LogsToCopy += Get-ChildItem -Path $env:SystemDrive\ -Filter "*CCSF_DebugLog*"
		$LogsToCopy += Get-ChildItem -Path $PerfMon_LogLocation\ -Filter *.*
		
		$LogsToCopy | ForEach-Object{
			Copy-File -Path $_.FullName -Destination "$UploadFolder\RAW"
		}
		$ZipName = "$UploadFolder\$($envCOMPUTERNAME)_$(Get-Date -Format "yyyy-MM-dd").7z"
		Create-7zip -Directory "$UploadFolder\RAW\*" -DestinationFile $ZipName -PathTo7ZipEXE $7zip
		$7Zip_Upload = Get-Item -Path $ZipName
		
		# Upload to Trend
		IF (Test-Path $7Zip_Upload.FullName -ErrorAction Stop) {
			Write-Log -Message "Final 7z file here: $($7Zip_Upload).FullName" -severity 1
			$URI = 'box-us-file.trendmicro-cloud.com:21'
			$Password = '06869e45197d'
			$User = '00DU0000000JKNeMAO5c61f48a2f888'
			Upload-FTP -File $7Zip_Upload.FullName -User $User -Password $Password -URI $URI
		}
		
		# Delete files on root
		Write-Log -Message "Removing Files from root of disk."
		$TrendFiles | %{
			Remove-File -Path $_.FullName
		}
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		## <Perform Post-Installation tasks here>
		
		
		## Display a message at the end of the install
		#Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait
	} ELSEIF ($deploymentType -ieq 'Uninstall') {
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		## Show Welcome Message, close $appServicesString processes with a 60 second countdown before automatically closing
		IF ($appProcessesString) {
			Show-InstallationWelcome -CloseApps "$appProcessesString" -CloseAppsCountdown 300
		}
		## <Perform Pre-Uninstallation tasks here>
		
		
		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		# <Perform Uninstallation tasks here>
		
		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		## <Perform Post-Uninstallation tasks here>
		
		
		## Display a message at the end of the uninstall
		#Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended uninstallations.' -ButtonRightText 'OK' -Icon Information -NoWait
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
} CATCH {
	Get-Process -Name LogServer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
	Remove-Item -Path $env:SystemDrive\LogServer.exe -Force -ErrorAction SilentlyContinue
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}