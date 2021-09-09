<#
 
.SYNOPSIS
Get Server Info and Populate Database.
 
.DESCRIPTION
Get Server Info and Populate Database.

.EXAMPLE
./PCInfoServer.ps1

.NOTES
        Author:             ITSysAdmins
        Email:              JRobertson@paylocity.com
          
        Changelog:
            4/9/2013		Initial Release
			
.LINK
http://sharepoint/itwiki
 
#>
import-module c:\scripts\PowershellModules\pcty.psm1
$Settings = Get-ConfigSettings
Add-PSSnapin Quest.ActiveRoles.ADManagement

$DBServer = ($Settings | ?{$_.ConfigKey -eq "ServerName.PCInfo"}).ConfigValue.Trim()
$Database = ($Settings | ?{$_.ConfigKey -eq "DatabaseName.PCInfo"}).ConfigValue.Trim()
$Table = ($Settings | ?{$_.ConfigKey -eq "PCInfo.TableName.ServerInfo"}).ConfigValue.Trim()
$NICTable = ($Settings | ?{$_.ConfigKey -eq "PCInfo.TableName.ServerNIC"}).ConfigValue.Trim()
$diskTable = ($Settings | ?{$_.ConfigKey -eq "PCInfo.TableName.ServerDisk"}).ConfigValue.Trim()

#Get list of all computers in Headquarters
$computers = get-QADComputer -SearchRoot 'paylocity.com/servers' -SizeLimit 0

#Specify number of threads that should be spawned concurrently
$Threads = 8

#Begin Loop on each computer
foreach($computerjob in $computers)
{
    if (-not (Test-Connection $computerjob.dnsname -count 1 -quiet))
	{
		Continue
	}
	write-host "$($Computerjob.name) ping passed" -foregroundcolor Green

	$computersid = $computerjob.sid.value
	While ($(Get-Job -state running).count -gt $Threads)
	{
		Start-Sleep -Milliseconds 500
	}
	start-job -argumentlist $computersid, $DBServer, $Database, $Table, $NICTable, $DiskTable -scriptblock {
		param(
			[string]
			$computersid,
			[string]
			$DBServer,
			[string]
			$Database,
			[string]
			$Table,
			[string]
			$NICTable,
			[string]
			$DiskTable
		)
#Add Snappins
		Add-PSSnapin Quest.ActiveRoles.ADManagement


#Define Database Info
		$SID = $ComputerSID
		$Computer = Get-QADComputer $SID
        $NetworkAdapterObjects = @()
        $DiskObjects = @()
        $name = $computer.Name

#Ping the computer once, if no response, skip.

#Get WMI Information
		$WMIComputerSystem = Get-WmiObject win32_computersystem -computername $name
#If no response to the first WMI query, skip.
		if (-not($WMIComputerSystem)){exit}
		$WMIBIOS = Get-WmiObject win32_bios -computername $name
		$WMIProcessor = Get-WmiObject win32_processor -computername $name
		$WMILogicalDisk = Get-WMIObject win32_LogicalDisk -computername $name
		$WMIOS = Get-WmiObject win32_operatingsystem -computername $name
		$WMIGroup = Get-WMIObject win32_groupuser -computername $name
		$WMIProfile = Get-WMIObject win32_userprofile -computername $name
		$WMIEnclosure = Get-WMIObject win32_SystemEnclosure -computername $name
		$WMISQL = Get-WmiObject -Namespace root\Microsoft\SqlServer\ComputerManagement10 -computername $name -class SQLService
		$WMINetwork = Get-WMIObject win32_networkadapter -computername $name
        $WMINetworkConfig = Get-WmiObject win32_networkadapterconfiguration -ComputerName $Name
#Extract Data from WMI Info
		$model = $WMIComputerSystem.Model
		$memory = $WMIComputerSystem.TotalPhysicalMemory
		$serial = $WMIBIOS.SerialNumber.Replace(' ', '').Replace('-', '').Replace('VMware', '')
		$BIOS = $WMIBIOS.Version
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

#Get Dates
		$Date = Get-Date -format "yyyy-MM-dd HH:mm:ss"
		$DateCreated = $Computer.CreationDate.ToString("yyyy-MM-dd HH:mm:ss")

#Get CPU
        $sockets = $WMIProcessor.Count
		If($sockets -gt 1)
        {
            $cpu = $WMIProcessor[0].Name
            $cores = $WMIProcessor[0].NumberofCores
        }
        Else
        {
            $cpu = $WMIProcessor.Name
            $cores = $WMIProcessor.NumberOfCores
            $sockets = 1
        }

#Get SQLInstance
		if ($WMISQL){$SQLInstance = ($WMISQL | ? {($_.__RELPATH -like "*SQLServiceType=1") -and ($_.State -eq 4)}).ServiceName}

#Get OU
		$OU = $Computer.parentcontainer | split-path -leaf
            
#Get Disk Info
        Foreach ($Disk in ($WMILogicalDisk | ? {$_.Description -eq 'Local Fixed Disk'}))
        {
            $DiskObjects += [pscustomobject]@{DriveLetter=$Disk.Name;DiskSize=([math]::round($Disk.Size / 1GB));FreeSpace=([math]::round($Disk.Freespace / 1GB));VolumeName=$Disk.VolumeName}
        }
#Get NIC Info
        if($NetworkAdapters){
            Foreach ($NetworkAdapter in $NetworkAdapters){
                $IP = ($Nicconfig | ? {$_.Description -eq $Networkadapter.name}).IPAddress
                $NetworkAdapterObjects += [pscustomobject]@{AdapterName=$NetworkAdapter.Name;MAC=$NetworkAdapter.MACAddress;IP=$IP}}}
		if($NetworkAdapters){$MAC = $NetworkAdapters | % {$_.MacAddress}}
		if($NetworkAdapters){$NICMAC = $NetworkAdapters | % {$_.Name + " - " + $_.MacAddress}}

#Get Description from AD
        $description = $computer.Description
		
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
				"3282A1U" {"ThinkCentre M90p (3282A1U)"}
				"3282B1U" {"ThinkCentre M90p (3282B1U)"}
				"7052A8U" {"ThinkCentre M91p (7052A8U)"}
				"7052B2U" {"ThinkCentre M91p (7052B2U)"}
				"7052C9U" {"ThinkCentre M91p (7052C9U)"}
				"2992A3U" {"ThinkCentre M92p (2992A3U)"}
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
				"Intel(R) Core(TM) i7 CPU         860  @ 2.80GHz" {"i7-860 2.80GHz"}
				"Intel(R) Core(TM) i7-2600 CPU @ 3.40GHz" {"i7-2600 3.40GHz"}
				"Intel(R) Core(TM) i7-3720QM CPU @ 2.60GHz" {"i7-3720QM 2.60GHz"}
				"Intel(R) Core(TM) i7-3770 CPU @ 3.40GHz" {"i7-3770 3.40GHz"}
				"Intel(R) Core(TM)2 Duo CPU     T9400  @ 2.53GHz" {"C2D T9400 2.53GHz"}
				"Intel(R) Core(TM)2 Duo CPU     T9600  @ 2.80GHz" {"C2D T9600 2.80GHz"}
				"Intel(R) Core(TM)2 Duo CPU     T7500  @ 2.20GHz" {"C2D T7500 2.20GHz"}
				"Intel(R) Core(TM)2 CPU         T7200  @ 2.00GHz" {"C2D T7200 2.00GHz"}
				"Intel(R) Core(TM)2 Duo CPU     T9300  @ 2.50GHz" {"C2D T9300 2.50GHz"}
				"Intel(R) Core(TM) i7 CPU       Q 720  @ 1.60GHz" {"i7-Q720 1.60GHz"}
				"Intel(R) Core(TM) i7-2720QM CPU @ 2.20GHz" {"i7-2720QM 2.20GHz"}
				"Intel(R) Core(TM) i7-2760QM CPU @ 2.40GHz" {"i7-2760QM 2.40GHz"}
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

#Import SQL Module
		Import-Module SQLPS
#Check if Computer exists in database already, update if it does.
		$RowExists = (Invoke-Sqlcmd -Query "Select ID from $table with (nolock) where Name='$Name' and Serial='$Serial' and SID='$SID'" -ServerInstance $DBServer -Database $Database).id
		if ($RowExists) {
			Invoke-Sqlcmd -Query "Update $Table with (ROWLOCK) set Name='$Name', OS='$OS', Processor='$cpu', MemoryGB='$memory', Serial='$Serial', DateCreated='$DateCreated', ImageDate='$OSDate', LastUpdated='$Date', SID='$SID', OU='$OU', LocalAdmins='$Admins', ServicePack='$SPLevel', BIOS='$BIOS', Model = '$Model', IsActive=1, SQLInstance='$SQLInstance', CoresPerCPU='$Cores', CPUs='$Sockets', Description='$Description' where ID='$RowExists'" -ServerInstance "$DBServer" -Database "$Database"}
#if Computer does not exist, create an entry for it.
		else{
			Invoke-Sqlcmd -Query "Insert into $table with (ROWLOCK) (Name, OS, Processor, MemoryGB, Serial, DateCreated, ImageDate, LastUpdated, SID, OU, LocalAdmins, ServicePack, BIOS, Model, IsActive, SQLInstance, ActiveDate, CoresPerCPU, CPUs, Description) values ('$Name', '$OS', '$cpu', '$memory', '$Serial', '$DateCreated', '$OSDate', '$Date', '$SID', '$OU', '$Admins', '$SPLevel', '$BIOS', '$Model', 1, '$SQLInstance', '$Date', '$Cores', '$Sockets', '$Description')" -ServerInstance "$DBServer" -Database "$Database"
            $RowExists = (Invoke-Sqlcmd -Query "Select ID from $table with (nolock) where Name='$Name' and Serial='$Serial' and SID='$SID'" -ServerInstance $DBServer -Database $Database).id}

#Write NICInfo table
        Foreach ($NetworkAdapterObject in $NetworkAdapterObjects){
		    $NICExists = Invoke-Sqlcmd -Query "Select ComputerID, AdapterName, MAC, IP from $NICtable with (nolock) where MAC = '$($NetworkAdapterObject.MAC)' and ComputerID = '$RowExists'" -ServerInstance $DBServer -Database $Database
            If($NICExists){
                If($NICExists.IP -ne $NetworkAdapterObject.IP){
                    Invoke-Sqlcmd -Query "Update $NICTable with (ROWLOCK) set IP = '$($NetworkAdapterObject.IP)' where MAC = '$($NetworkAdapterObject.MAC)' and ComputerID = '$RowExists'" -ServerInstance $DBServer -Database $Database}}
            Else{
                Invoke-Sqlcmd -Query "Insert into $NICTable with (ROWLOCK) (ComputerID, AdapterName, MAC, IP) values ('$Rowexists', '$($NetworkAdapterObject.AdapterName)', '$($NetworkAdapterObject.MAC)', '$($NetworkAdapterObject.IP)')" -ServerInstance $DBServer -Database $Database}}

#Write DriveInfo Table
        Foreach ($DiskObject in $DiskObjects)
        {
        	$diskExists = Invoke-Sqlcmd -Query "Select ComputerID, DriveLetter, VolumeName, DiskSize, FreeSpace from $Disktable with (nolock) where DriveLetter = '$($DiskObject.DriveLetter)' and VolumeName = '$($DiskObject.VolumeName)' and ComputerID = '$RowExists'" -ServerInstance $DBServer -Database $Database
            If($diskExists)
            {
                If($diskExists.FreeSpace -ne $Disk.FreeSpace)
                {
                    Invoke-Sqlcmd -Query "Update $DiskTable with (ROWLOCK) set FreeSpace = '$($DiskObject.FreeSpace)' where DriveLetter = '$($DiskObject.DriveLetter)' and ComputerID = '$RowExists'" -ServerInstance $DBServer -Database $Database
                }
            }
            Else
            {
                Invoke-Sqlcmd -Query "Insert into $DiskTable with (ROWLOCK) (ComputerID, DriveLetter, DiskSize, FreeSpace, VolumeName) values ('$Rowexists', '$($DiskObject.DriveLetter)', '$($DiskObject.DiskSize)', '$($DiskObject.FreeSpace)', '$($DiskObject.VolumeName)')" -ServerInstance $DBServer -Database $Database
            }
        }
    }
}