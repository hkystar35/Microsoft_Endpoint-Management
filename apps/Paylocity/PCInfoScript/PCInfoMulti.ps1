#PCInfo - Get Computer Info and Populate Database
#kholland - created 7/5/12
Add-PSSnapin Quest.ActiveRoles.ADManagement
Import-Module SQLPS
import-module c:\scripts\PowershellModules\pcty.psm1
$Settings = Get-ConfigSettings
C:

$DBServer = ($Settings | ?{$_.ConfigKey -eq "ServerName.PCInfo"}).ConfigValue.Trim()
$Database = ($Settings | ?{$_.ConfigKey -eq "DatabaseName.PCInfo"}).ConfigValue.Trim()
$Table = ($Settings | ?{$_.ConfigKey -eq "PCInfo.TableName.PCInfo"}).ConfigValue.Trim()

#Get list of all computers in Headquarters
$computers = get-QADComputer -SearchRoot 'paylocity.com/headquarters' -SizeLimit 0

#Specify number of threads that should be spawned concurrently
$Threads = 8

#Begin Loop on each computer
foreach($computerjob in $computers)
{
	$computersid = $computerjob.sid.value
	While ($(Get-Job -state running).count -gt $Threads){Start-Sleep -Milliseconds 500}
	start-job -argumentlist $computersid, $DBServer, $Database, $Table  -scriptblock {
		param(
			[string]
			$computersid,
			[string]
			$DBServer,
			[string]
			$Database,
			[string]
			$Table
		)
#Add Snappins
		Import-Module SQLPS
		Add-PSSnapin Quest.ActiveRoles.ADManagement

#Clear Variables
		C:
		$username = $null
		$profilepath = $null
		$badname = $null

#Define Database Info
        $NICTable = "dbo.NICInfo"
		$SID = $computersid
		$Computer = Get-QADComputer $SID
        $NetworkAdapterObjects = @()

#Ping the computer once, if no response, skip.
		if (-not (Test-Connection $computer.dnsname -count 1 -quiet)) {exit}
		$Name = $Computer.Name
		$Name2 = $Computer.DNSName.Replace(".Paylocity.com", "").Replace(".paylocity.com", "")
		
		write-host "$name ping passed" -foregroundcolor Green

		$PingResults = Ping $Name -n 4
		$PingResponseLines = $PingResults[2..5]
		$PingIP = ($PingResults[1].split("["))[1].Split("]")[0]
		$PingMSResponse = @()
		ForEach($PingLine in $PingResponseLines)
		{
			If($pingLine -eq "Request timed out.")
			{
				$PingResponse = 'lost'
			}
			Else
			{
				$PingResponse = ($pingLine.Split(' ') | ?{$_ -like "time*"}) -Replace "time", "" -Replace "<", "" -Replace ">", "" -Replace "=", "" -Replace "ms", ""
			}
			Invoke-SQLCmd -ServerInstance $DBServer -Database $Database -Query "Insert into dbo.pingresults with (ROWLOCK) (Name, IP, response, DateTime) values ('$Name', '$pingIP', '$PingResponse', getdate())"
		}


#Get WMI Information
		$WMIComputerSystem = Get-WmiObject win32_computersystem -computername $name -ErrorAction SilentlyContinue
		If(!$WMIComputerSystem)
		{
			$NameOld = $Name
			$Name = $Name2
			$WMIComputerSystem = Get-WmiObject win32_computersystem -computername $name -ErrorAction SilentlyContinue
		}
#If no response to the first WMI query, skip.
		if (-not($WMIComputerSystem)){exit}
		$WMIBIOS = Get-WmiObject win32_bios -computername $name -ErrorAction SilentlyContinue
		$WMIProcessor = Get-WmiObject win32_processor -computername $name -ErrorAction SilentlyContinue
		$WMILogicalDisk = Get-WMIObject win32_LogicalDisk -computername $name -ErrorAction SilentlyContinue
		$WMIOS = Get-WmiObject win32_operatingsystem -computername $name -ErrorAction SilentlyContinue
		$WMIGroup = Get-WMIObject win32_groupuser -computername $name -ErrorAction SilentlyContinue
		$WMIProfile = Get-WMIObject win32_userprofile -computername $name -ErrorAction SilentlyContinue
		$WMIEnclosure = Get-WMIObject win32_SystemEnclosure -computername $name -ErrorAction SilentlyContinue
		$WMISQL = Get-WmiObject -Namespace root\Microsoft\SqlServer\ComputerManagement10 -computername $name -class SQLService -ErrorAction SilentlyContinue
		$WMINetwork = Get-WMIObject win32_networkadapter -computername $name
        $WMINetworkConfig = Get-WmiObject win32_networkadapterconfiguration -ComputerName $Name
#Extract Data from WMI Info
		$model = $WMIComputerSystem.Model
		$memory = $WMIComputerSystem.TotalPhysicalMemory
		$serial = $WMIBIOS.SerialNumber
		$BIOS = $WMIBIOS.Version
		$cpu = $WMIProcessor.Name
		$disk = $WMILogicalDisk | ? {$_.DeviceID -eq "C:"}
		$OS = $WMIOS.Caption
		$SPLevel = $WMIOS.ServicePackMajorVersion
		$OSDate = ([WMI]'').ConvertToDateTime(($WMIOS).InstallDate).ToString("yyyy-MM-dd HH:mm:ss")
		$ChassisType = $WMIEnclosure.ChassisTypes
		$NetworkAdapters = $WMINetwork | ? {$_.MacAddress} | ? {(-not($_.Description -match "Miniport|RAS|Bluetooth|Sonicwall"))}
        $NICConfig = $WMINetworkConfig | ? {$_.IPAddress}

#Get Local Admin users - This section modified from script by Paperclips on MS Technet http://gallery.technet.microsoft.com/scriptcenter/Get-remote-machine-members-bc5faa57/view/Discussions#content
		$Admins = $WMIGroup | ? {$_.groupcomponent -like '*"Administrators"'} | % {
			$_.partcomponent –match “.+Domain\=(.+)\,Name\=(.+)$” > $nul  
			$matches[1].trim('"') + “\” + $matches[2].trim('"')} | ? {($_ -notlike "PAYLOCITY\PenetratorGroup") -and ($_ -notlike "PAYLOCITY\IT Technicians") -and ($_ -notlike "PAYLOCITY\Domain Admins") -and ($_ -notlike "$name\Administrator")}

#Check if Computer Name matches Users Name
		if ($WMIComputerSystem.Username){
			$username = $WMIComputerSystem.username | Split-Path -Leaf
			$adname = (Get-QADUser $username)
			$adfullname = ($adname).FirstName + ($adname).LastName
			$adfullname = $adfullname.Substring(0, [Math]::Min(15, $adfullname.length))
			if (($adfullname -eq $name) -or ($adfullname -eq $NameOld)) {$BadName = 0}
			if (($adfullname -ne $name) -and ($adfullName -ne $NameOld)) {$BadName = 1}}

#Get Dates
		$Date = Get-Date -format "yyyy-MM-dd HH:mm:ss"
		$DateCreated = $Computer.CreationDate.ToString("yyyy-MM-dd HH:mm:ss")
		
#Get SQLInstance
		if ($WMISQL){$SQLInstance = ($WMISQL | ? {($_.__RELPATH -like "*SQLServiceType=1") -and ($_.State -eq 4)}).ServiceName}
		
#Get ProfilePath
		$ProfilePath = ($WMIProfile | ? {($_.Special -eq $false) -and ($_.LocalPath -like "*$username*")}).LocalPath

#Get OU
		$OU = $Computer.parentcontainer | split-path -leaf
		
#Get NIC Info
        if($NetworkAdapters){
            Foreach ($NetworkAdapter in $NetworkAdapters){
                $IP = ($Nicconfig | ? {$_.Description -eq $Networkadapter.name}).IPAddress
                $NetworkAdapterObjects += [pscustomobject]@{AdapterName=$NetworkAdapter.Name;MAC=$NetworkAdapter.MACAddress;IP=$IP}}}
		if($NetworkAdapters){$MAC = $NetworkAdapters | % {$_.MacAddress}}
		if($NetworkAdapters){$NICMAC = $NetworkAdapters | % {$_.Name + " - " + $_.MacAddress}}

#Check if the computer has a bitlocker recovery code, and determine if bitlocker is enabled.
		$BitKey = Get-QADObject -Type "msFVE-RecoveryInformation" -SizeLimit 0 -Includedproperties msFVE-RecoveryPassword -SearchRoot $computer.parentcontainer | ? {$_.ParentContainerDN -eq $computer.DN} | Select-Object -ExpandProperty 'msFVE-RecoveryPassword'
		if ($BitKey.Count -gt 1){$Bitkey = $Bitkey[-1]}
		if ($BitKey){$Bitlocker = $true}
		if (-not($BitKey)){$Bitlocker = $false}
		
#get LAPS PW
		$LAPS = (Get-AdmPwdPassword $Name).Password
		
#Cleanup WMI Info and switch Model, CPU, and ChassisType to friendly names
		$cpu = $cpu.Trim()
		$model = $model.Trim()
		$serial = $serial.Trim()
		$serial = $serial.Replace("VMware-", "")
		$HDFree = $Disk.FreeSpace / 1GB
		$HDFree = [math]::round($HDFree, 0)
		$HDSize = ($disk.size / 1GB)
		$HDSize = [math]::round($HDSize, 0)
		$HDPercent = ($disk.freespace / $disk.size) * 100
		$HDPercent = [math]::round($HDPercent, 0)

		$model = switch ($model)
			{
				"6459CTO" {"Thinkpad T60 (6459CTO)"}
				"8744C9U" {"ThinkPad T60p (8744C9U)"}
				"6460DVU" {"ThinkPad T61p (6460DVU)"}
				"20823GU" {"ThinkPad T500 (20823GU)"}
				"2082BNU" {"ThinkPad T500 (2082BNU)"}
				"43192PU" {"ThinkPad W510 (43192PU)"}
				"427637U" {"ThinkPad W520 (427637U)"}
				"42763JU" {"ThinkPad W520 (42763JU)"}
				"24382HU" {"ThinkPad W530 (24382HU)"}
				"24384CU" {"ThinkPad W530 (24384CU)"}
				"243852U" {"ThinkPad W530 (243852U)"}
				"20BG0016US" {"ThinkPad W540 (20BG0016US)"}
				"3444CWU" {"ThinkPad X1 (Gen 1) (3444CWU)"}
				"20A7003DUS" {"ThinkPad X1 (Gen 2)(20A7003DUS)"}
				"20A70037US" {"ThinkPad X1 (Gen 3)(20A7003DUS)"}
				"3282A1U" {"ThinkCentre M90p (3282A1U)"}
				"3282B1U" {"ThinkCentre M90p (3282B1U)"}
				"7052A8U" {"ThinkCentre M91p (7052A8U)"}
				"7052B2U" {"ThinkCentre M91p (7052B2U)"}
				"7052C9U" {"ThinkCentre M91p (7052C9U)"}
				"2992A3U" {"ThinkCentre M92p (2992A3U)"}
				"10A7000FUS" {"ThinkCentre M93p (10A7000FUS)"}
				"10A7000SUS" {"ThinkCentre M93p (10A7000SUS)"}
				"10A7000QUS" {"ThinkCentre M93p (10A7000QUS)"}
				"VMWare Virtual Platform" {"VMware"}
				default {$model}
		}
		$cpu = switch ($cpu)
			{
				"AMD Athlon(tm) 64 Processor 3800+" {"Athlon 64 3800+"}
				"AMD Athlon(tm) 64 X2 Dual Core Processor 4000+" {"Athlon 64x2 4000+"}
				"Intel(R) Celeron(R) CPU 2.40GHz" {"Celeron 2.40GHz"}
				"Intel(R) Pentium(R) 4 CPU 3.00GHz" {"Pentium 4 3.00GHz"}
				"Intel(R) Pentium(R) 4 CPU 2.80GHz" {"Pentium 4 2.80GHz"}
				"Intel(R) Pentium(R) 4 CPU 2.40GHz" {"Pentium 4 2.40GHz"}
				"Intel(R) Pentium(R) 4 CPU 2.66GHz" {"Pentium 4 2.66GHz"}
				"Intel(R) Pentium(R) 4 CPU 2.00GHz" {"Pentium 4 2.00GHz"}
				"Intel(R) Pentium(R) 4 CPU 2.60GHz" {"Pentium 4 2.60GHz"}
				"Intel(R) Pentium(R) 4 CPU 3.20GHz" {"Pentium 4 3.20GHz"}
				"Intel(R) Core(TM) i5 CPU         650  @ 3.20GHz" {"i5-650 3.20GHz"}
				"Intel(R) Core(TM) i5-3427U CPU @ 1.80GHz" {"i5-3427U 1.80GHz"}
				"Intel(R) Core(TM) i5-4300U CPU @ 1.90GHz" {"i5-4300U 1.90GHz"}
				"Intel(R) Core(TM) i7 CPU         860  @ 2.80GHz" {"i7-860 2.80GHz"}
				"Intel(R) Core(TM) i7-2600 CPU @ 3.40GHz" {"i7-2600 3.40GHz"}
				"Intel(R) Core(TM) i7-3720QM CPU @ 2.60GHz" {"i7-3720QM 2.60GHz"}
				"Intel(R) Core(TM) i7-3770 CPU @ 3.40GHz" {"i7-3770 3.40GHz"}
				"Intel(R) Core(TM) i7-4770 CPU @ 3.40GHz" {"i7-4770 3.40GHz"}
				"Intel(R) Core(TM) i7-4800MQ CPU @ 2.70GHz" {"i7-4800MQ 2.7GHz"}
				"Intel(R) Core(TM)2 Duo CPU     T9400  @ 2.53GHz" {"C2D T9400 2.53GHz"}
				"Intel(R) Core(TM)2 Duo CPU     T9600  @ 2.80GHz" {"C2D T9600 2.80GHz"}
				"Intel(R) Core(TM)2 Duo CPU     T7500  @ 2.20GHz" {"C2D T7500 2.20GHz"}
				"Intel(R) Core(TM)2 CPU         T7200  @ 2.00GHz" {"C2D T7200 2.00GHz"}
				"Intel(R) Core(TM)2 Duo CPU     T9300  @ 2.50GHz" {"C2D T9300 2.50GHz"}
				"Intel(R) Core(TM) i7 CPU       Q 720  @ 1.60GHz" {"i7-Q720 1.60GHz"}
				"Intel(R) Core(TM) i7-2720QM CPU @ 2.20GHz" {"i7-2720QM 2.20GHz"}
				"Intel(R) Core(TM) i7-2760QM CPU @ 2.40GHz" {"i7-2760QM 2.40GHz"}
				"Intel(R) Core(TM) i7-3740QM CPU @ 2.70GHZ" {"i7-3740QM 2.70GHz"}
				"Intel(R) Core(TM) i7-4600U CPU @ 2.10GHZ" {"i7-4600U 2.10GHz"}
				"Intel(R) Xeon(R) CPU           E5430  @ 2.66GHz" {"Xeon E5430 2.66GHz"}
				"Intel(R) Xeon(R) CPU           X5560  @ 2.80GHz" {"Xeon X5560 2.80GHz"}
				default {$cpu}
		}
		$ChassisType = switch ($ChassisType)
			{
				"1" {"Other"}
				"2" {"Unknown"}
				"3" {"Desktop"}
				"4" {"Low Profile Desktop"}
				"5" {"Pizza Box"}
				"6" {"Mini Tower"}
				"7" {"Tower"}
				"8" {"Portable"}
				"9" {"Laptop"}
				"10" {"Notebook"}
				"11" {"Hand Held"}
				"12" {"Docking Station"}
				"13" {"All in One"}
				"14" {"Sub Notebook"}
				"15" {"Space-Saving"}
				"16" {"Lunch Box"}
				"17" {"Main System Chassis"}
				"18" {"Expansion Chassis"}
				"19" {"Sub Chassis"}
				"20" {"Bus Expansion Chassis"}
				"21" {"Peripheral Chassis"}
				"22" {"Storage Chassis"}
				"23" {"Rack Mount Chassis"}
				"24" {"Sealed-Case PC"}
				default {$ChassisType}
			}
		$memory = $memory/1GB
		$memory = [math]::round($memory, 0)
		
	if ($model -eq "ThinkPad W520 (427637U)"){$ChassisType = "Notebook"}
		
#Comma Delineate Arrays into single line
		$OFS = ', '
		$Admins = "$Admins"
		$ProfilePath = "$ProfilePath"
		$MAC = "$MAC"
		$NICMAC = "$NICMAC"
		
#Write data to AD Description
		Set-QADComputer $computer -Description $model" | "$cpu" | "$memory"GB | "$HDPercent"% of "$HDSize"GB | "$serial
		
#Check if Computer exists in database already, update if it does.
		$RowExists = (Invoke-Sqlcmd -Query "Select ID from $table with (nolock) where Name='$Name' and Serial='$Serial' and SID='$SID'" -ServerInstance $DBServer -Database $Database).id
		if ($RowExists) {
			if ($ADName){
				Invoke-Sqlcmd -Query "Update $Table with (ROWLOCK) set Name='$Name', OS='$OS', Processor='$cpu', MemoryGB='$memory', HDSizeGB='$HDSize', HDFreeGB='$HDFree', Serial='$Serial', BadName='$BadName', Bitlocker='$Bitlocker', DateCreated='$DateCreated', ImageDate='$OSDate', LastUpdated='$Date', SID='$SID', LoggedOnUser='$username', OU='$OU', LocalAdmins='$Admins', ServicePack='$SPLevel', BIOS='$BIOS', ProfilePath='$ProfilePath', Model = '$Model', IsActive=1, ChassisType='$ChassisType', SQLInstance='$SQLInstance', BitLockerKey='$BitKey', MACAddress='$MAC', NIC='$NICMAC', LAPS='$LAPS' where ID='$RowExists'" -ServerInstance "$DBServer" -Database "$Database"}
			else{
				Invoke-Sqlcmd -Query "Update $Table with (ROWLOCK) set Name='$Name', OS='$OS', Processor='$cpu', MemoryGB='$memory', HDSizeGB='$HDSize', HDFreeGB='$HDFree', Serial='$Serial', Bitlocker='$Bitlocker', DateCreated='$DateCreated', ImageDate='$OSDate', LastUpdated='$Date', SID='$SID', OU='$OU', LocalAdmins='$Admins', ServicePack='$SPLevel', BIOS='$BIOS', Model = '$Model', IsActive=1, ChassisType='$ChassisType', SQLInstance='$SQLInstance', BitLockerKey='$BitKey', MACAddress='$MAC', NIC='$NICMAC', LAPS='$LAPS' where ID='$RowExists'" -ServerInstance "$DBServer" -Database "$Database"}}
#if Computer does not exist, create an entry for it.
		else{
			Invoke-Sqlcmd -Query "Insert into $table with (ROWLOCK) (Name, OS, Processor, MemoryGB, HDSizeGB, HDFreeGB, Serial, Bitlocker, DateCreated, ImageDate, LastUpdated, SID, LoggedOnUser, OU, LocalAdmins, ServicePack, BIOS, ProfilePath, Model, IsActive, ChassisType, SQLInstance, BitLockerKey, ActiveDate, MACAddress, NIC, LAPS) values ('$Name', '$OS', '$cpu', '$memory', '$HDSize', '$HDFree', '$Serial', '$Bitlocker', '$DateCreated', '$OSDate', '$Date', '$SID', '$Username', '$OU', '$Admins', '$SPLevel', '$BIOS', '$ProfilePath', '$Model', 1, '$ChassisType', '$SQLInstance', '$BitKey', '$Date', '$MAC', '$NICMAC', '$LAPS')" -ServerInstance "$DBServer" -Database "$Database"
            $RowExists = (Invoke-Sqlcmd -Query "Select ID from $table with (nolock) where Name='$Name' and Serial='$Serial' and SID='$SID'" -ServerInstance $DBServer -Database $Database).id
		}
	}
}


#Write NICInfo table
        Foreach ($NetworkAdapterObject in $NetworkAdapterObjects){
		    $NICExists = Invoke-Sqlcmd -Query "Select ComputerID, AdapterName, MAC, IP from $NICtable with (nolock) where MAC = '$($NetworkAdapterObject.MAC)' and ComputerID = '$RowExists'" -ServerInstance $DBServer -Database $Database
            If($NICExists){
                If($NICExists.IP -ne $NetworkAdapterObject.IP){
                    Invoke-Sqlcmd -Query "Update $NICTable with (ROWLOCK) set IP = '$($NetworkAdapterObject.IP)' where MAC = '$($NetworkAdapterObject.MAC)' and ComputerID = '$RowExists'" -ServerInstance $DBServer -Database $Database}}
            Else{
                Invoke-Sqlcmd -Query "Insert into $NICTable with (ROWLOCK) (ComputerID, AdapterName, MAC, IP) values ('$Rowexists', '$($NetworkAdapterObject.AdapterName)', '$($NetworkAdapterObject.MAC)', '$($NetworkAdapterObject.IP)')" -ServerInstance $DBServer -Database $Database}}
#Cleanup PCInfo Database, get last accessed date, set inactive computers.
$Date = Get-Date -format "yyyy-MM-dd HH:mm:ss"

#Select Active Computers
$Computers = Invoke-Sqlcmd -Query "Select Name, ID, SID, Serial from $Table where IsActive='1'" -ServerInstance $DBServer -Database $Database

#Database Cleanup - Mark computers Inactive if they do not match a computer in AD by Name, Serial, and SID.
Foreach ($Computer in $Computers)
	{
	$Name = $Computer.Name
	$ID = $Computer.ID
	$SID = $Computer.SID
	$Serial = $Computer.Serial
#Get AD Computer Account
	$ADComputer = Get-QADComputer $SID
#If there is no computer account, set IsActive to False
	If (-Not($ADComputer)){Invoke-Sqlcmd -Query "Update $Table Set IsActive='0', InActiveDate='$Date' where ID='$ID'" -ServerInstance $DBServer -Database $Database}
		Else {
#Write modification date to determine unused computers
		$DateAccessed = $ADComputer.ModificationDate.ToString("yyyy-MM-dd HH:mm:ss")
		Invoke-Sqlcmd -query "Update $Table set DateAccessed='$DateAccessed' where ID='$ID'" -ServerInstance $DBServer -Database $Database
#Check if Serial number matches
		$ADSerial = $ADComputer | ? {$_.Description -like "*$Serial*"}
#If there is a computer account, verify SID and Serial are the same, if not set IsActive to false.
			If((-Not($ADSerial)) -or ($ADComputer.name -ne $Computer.name)){Invoke-Sqlcmd -Query "Update $Table Set IsActive='0', InActiveDate='$Date' where ID='$ID'" -ServerInstance $DBServer -Database $Database}}}