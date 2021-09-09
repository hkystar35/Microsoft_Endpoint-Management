#variables to be modified to suite your site configuration
$sccm_module = "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
$site_code = "PAY:"
$client_version = "5.00.8498.1711"
$client_version_friendly_name = "SCCM CB 1702"
$AllWorkstationsCollectionId = "PAY0000B"
$threshold = "14"

Import-Module $sccm_module
Set-Location $site_code

#create schedule variables
$schedule01 = New-CMSchedule -RecurCount 1 -RecurInterval Days -Start 21:00
$schedule02 = New-CMSchedule -RecurCount 1 -RecurInterval Days -Start 21:15
$schedule03 = New-CMSchedule -RecurCount 1 -RecurInterval Days -Start 21:30
$schedule04 = New-CMSchedule -RecurCount 1 -RecurInterval Days -Start 21:45
$schedule05 = New-CMSchedule -RecurCount 1 -RecurInterval Days -Start 22:00
$schedule06 = New-CMSchedule -RecurCount 1 -RecurInterval Days -Start 22:15
$schedule07 = New-CMSchedule -RecurCount 1 -RecurInterval Days -Start 22:30
$schedule08 = New-CMSchedule -RecurCount 1 -RecurInterval Days -Start 22:45
$schedule09 = New-CMSchedule -RecurCount 1 -RecurInterval Days -Start 23:00
$schedule10 = New-CMSchedule -RecurCount 1 -RecurInterval Days -Start 23:15

#set variables for creating rules
$healthy_assigned = "01 Healthy: Assigned"
$suspect_notassigned="01 Suspect: Not Assigned"
$healthy_client="02 Healthy: Client is Installed"
$healthy_no_client="02 Suspect: Client is Not Installed"
$healthy_client_not_obsolete = "03 Healthy: Client is Not Obsolete"
$healthy_client_obsolete = "03 Suspect: Client is Obsolete"
$healthy_DDR_within_threshold = "04 Healthy: Heartbeat DDR is Current within $threshold Days"
$healthy_DDR_not_within_threshold = "04 Suspect: Heartbeat DDR is Not Current within $threshold Days"
$healthy_hw_inventory_current = "05 Healthy: Hardware Inventory is Current within $threshold days"
$healthy_hw_inventory_not_current = "05 Suspect: Hardware Inventory is Not Current within $threshold Days"
$healthy_hw_memory_reported = "06 Healthy: Physical Memory is Reported"
$healthy_hw_memory_not_reported = "06 Suspect: Physical Memory is Not Reported"
$healthy_sw_reported = "07 Healthy: Software Inventory is Current within $threshold Day"
$healthy_sw_not_reported  = "07 Suspect: Software Inventory is Not Current within $threshold Days"
$healthey_winmgmt_reported = "08 Healthy: Winmgmt.exe is Reported"
$healthey_winmgmt_not_reported = "08 Suspect: Winmgmt.exe is Not Reported"
$healthy_duplicate_guid_does_not_exist = "09 Healthy: Duplicate GUID Problem does Not Exist"
$healthy_duplicate_guid_exists = "09: Suspect Duplicate Exists"
##
 # Creating variables for 3 query rules.  For easy reading.
 $healthy_duplicate_guid_exists1 = "09: Suspect Duplicate GUID Q1"
 $healthy_duplicate_guid_exists2 = "09: Suspect Duplicate GUID Q2"
 $healthy_duplicate_guid_exists3 = "09: Suspect Duplicate GUID Q3"
##
$healthy_agent_installed = "10 Healthy: $client_version_friendly_name is Installed"
$healthy_agent_not_installed = "10 Suspect: $client_version_friendly_name is Not Installed"
$suspect_duplicate_names = "11 Suspect: Systems with Duplicate Names"


#set all query variables
$query01a = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId in (select SMS_R_System.ResourceID from SMS_R_System where SMSAssignedSites is not NULL)"
$query01b = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId not in (select SMS_R_System.ResourceID from SMS_R_System where SMSAssignedSites is not NULL)"
$query02a = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId in (SELECT SMS_R_System.ResourceID FROM SMS_R_System where Client = 1)"
$query02b = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId not in (SELECT SMS_R_System.ResourceID FROM SMS_R_System where Client = 1)"
$query03a = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId not in (select SMS_R_System.ResourceID from SMS_R_System where Obsolete = 1)"
$query03b = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId in (select SMS_R_System.ResourceID from SMS_R_System where Obsolete = 1)"
$query04a = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId in (select ResourceID from SMS_R_System where AgentName in ('Heartbeat Discovery') and DATEDIFF(day,AgentTime,GetDate())<$threshold)"
$query04b = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId not in (select ResourceID from SMS_R_System where AgentName in ('Heartbeat Discovery') and DATEDIFF(day,AgentTime,GetDate())<$threshold)"
$query05a = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId in (select SMS_R_System.ResourceID from SMS_R_System inner join SMS_G_System_WORKSTATION_STATUS on SMS_G_System_WORKSTATION_STATUS.ResourceID = SMS_R_System.ResourceId where DATEDIFF(dd,SMS_G_System_WORKSTATION_STATUS.LastHardwareScan,GetDate()) < $threshold)"
$query05b = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId not in (select SMS_R_System.ResourceID from SMS_R_System inner join SMS_G_System_WORKSTATION_STATUS on SMS_G_System_WORKSTATION_STATUS.ResourceID = SMS_R_System.ResourceId where DATEDIFF(dd,SMS_G_System_WORKSTATION_STATUS.LastHardwareScan,GetDate()) < $threshold)"
$query06a = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId in (select SMS_R_System.ResourceID from SMS_R_System inner join SMS_G_System_X86_PC_MEMORY on SMS_G_System_X86_PC_MEMORY.ResourceID = SMS_R_System.ResourceId where SMS_G_System_X86_PC_MEMORY.TotalPhysicalMemory is not NULL )"
$query06b = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId not in (select SMS_R_System.ResourceID from SMS_R_System inner join SMS_G_System_X86_PC_MEMORY on SMS_G_System_X86_PC_MEMORY.ResourceID = SMS_R_System.ResourceId where SMS_G_System_X86_PC_MEMORY.TotalPhysicalMemory is not NULL )"
$query07a = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId in (select ResourceID from SMS_R_System inner join SMS_G_System_LastSoftwareScan on SMS_G_System_LastSoftwareScan.ResourceID = SMS_R_System.ResourceId where DATEDIFF(dd,SMS_G_System_LastSoftwareScan.LastScanDate,GetDate()) < $threshold)"
$query07b = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId not in (select ResourceID from SMS_R_System inner join SMS_G_System_LastSoftwareScan on SMS_G_System_LastSoftwareScan.ResourceID = SMS_R_System.ResourceId where DATEDIFF(dd,SMS_G_System_LastSoftwareScan.LastScanDate,GetDate()) < $threshold)"
$query08a = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId in (select ResourceID from  SMS_R_System inner join SMS_G_System_SoftwareFile on SMS_G_System_SoftwareFile.ResourceID = SMS_R_System.ResourceId where SMS_G_System_SoftwareFile.FileName = 'winmgmt.exe')"
$query08b = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId not in (select ResourceID from  SMS_R_System inner join SMS_G_System_SoftwareFile on SMS_G_System_SoftwareFile.ResourceID = SMS_R_System.ResourceId where SMS_G_System_SoftwareFile.FileName = 'winmgmt.exe')"
$query09a = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMSUniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where ResourceId in (SELECT SMS_R_System.ResourceID FROM SMS_R_System inner join SMS_G_System_SYSTEM on SMS_G_System_SYSTEM.ResourceID = SMS_R_System.ResourceId where SMS_R_System.Name = SMS_G_System_SYSTEM.Name)"
$query09b1 = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMS_UniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System join SMS_GH_System_System on SMS_R_System.ResourceID = SMS_GH_System_System.ResourceID where SMS_R_System.Name <> SMS_GH_System_System.Name" 
$query09b2 = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMS_UniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System join SMS_G_System_System on SMS_R_System.ResourceID = SMS_G_System_System.ResourceID where SMS_R_System.Name <> SMS_G_System_System.Name"
$query09b3 = "select SMS_R_System.ResourceID,SMS_R_System.ResourceType,SMS_R_System.Name,SMS_R_System.SMS_UniqueIdentifier,SMS_R_System.ResourceDomainORWorkgroup,SMS_R_System.Client from SMS_R_System where SMS_R_System.ResourceID in (select SMS_GH_System_System.ResourceID from SMS_G_System_System join SMS_GH_System_System on SMS_G_System_System.ResourceID = SMS_GH_System_System.ResourceID where SMS_G_System_System.Name <> SMS_GH_System_System.Name)"
$query10a = "select ResourceId, ResourceType, Name, SMSUniqueIdentifier, ResourceDomainORWorkgroup, Client from  SMS_R_System where ResourceId in (select ResourceID from SMS_R_System where ClientVersion >= '$client_version')"
$query10b = "select ResourceId, ResourceType, Name, SMSUniqueIdentifier, ResourceDomainORWorkgroup, Client from  SMS_R_System where ResourceId not in (select ResourceID from SMS_R_System where ClientVersion >= '$client_version')"
$query11a = "select R.ResourceID,R.ResourceType,R.Name,R.SMSUniqueIdentifier,R.ResourceDomainORWorkgroup,R.Client from SMS_R_System as r full join SMS_R_System as s1 on s1.ResourceId =   r.ResourceId full join SMS_R_System as s2 on s2.Name = s1.Name where s1.Name   = s2.Name and s1.ResourceId != s2.ResourceId"


# Create collections
New-CMDeviceCollection -Name $healthy_assigned -RefreshType Periodic -RefreshSchedule $schedule01 -LimitingCollectionId $AllWorkstationsCollectionId
New-CMDeviceCollection -Name $suspect_notassigned -RefreshType Periodic -RefreshSchedule $schedule01 -LimitingCollectionId $AllWorkstationsCollectionId
New-CMDeviceCollection -Name $healthy_client -RefreshType Periodic -RefreshSchedule $schedule02 -LimitingCollectionName $healthy_assigned
New-CMDeviceCollection -Name $healthy_no_client -RefreshType Periodic -RefreshSchedule $schedule02 -LimitingCollectionName $healthy_assigned
New-CMDeviceCollection -Name $healthy_client_not_obsolete -RefreshType Periodic -RefreshSchedule $schedule03 -LimitingCollectionName $healthy_client
New-CMDeviceCollection -Name $healthy_client_obsolete -RefreshType Periodic -RefreshSchedule $schedule03 -LimitingCollectionName $healthy_client
New-CMDeviceCollection -Name $healthy_DDR_within_threshold -RefreshType Periodic -RefreshSchedule $schedule04 -LimitingCollectionName $healthy_client_not_obsolete
New-CMDeviceCollection -Name $healthy_DDR_not_within_threshold -RefreshType Periodic -RefreshSchedule $schedule04 -LimitingCollectionName $healthy_client_not_obsolete
New-CMDeviceCollection -Name $healthy_hw_inventory_current -RefreshType Periodic -RefreshSchedule $schedule05 -LimitingCollectionName $healthy_DDR_within_threshold
New-CMDeviceCollection -Name $healthy_hw_inventory_not_current -RefreshType Periodic -RefreshSchedule $schedule05 -LimitingCollectionName $healthy_DDR_within_threshold
New-CMDeviceCollection -Name $healthy_hw_memory_reported -RefreshType Periodic -RefreshSchedule $schedule06 -LimitingCollectionName $healthy_hw_inventory_current
New-CMDeviceCollection -Name $healthy_hw_memory_not_reported -RefreshType Periodic -RefreshSchedule $schedule06 -LimitingCollectionName $healthy_hw_inventory_current
New-CMDeviceCollection -Name $healthy_sw_reported -RefreshType Periodic -RefreshSchedule $schedule07 -LimitingCollectionName $healthy_DDR_within_threshold
New-CMDeviceCollection -Name $healthy_sw_not_reported -RefreshType Periodic -RefreshSchedule $schedule07 -LimitingCollectionName $healthy_DDR_within_threshold
New-CMDeviceCollection -Name $healthey_winmgmt_reported -RefreshType Periodic -RefreshSchedule $schedule08 -LimitingCollectionName $healthy_sw_reported
New-CMDeviceCollection -Name $healthey_winmgmt_not_reported -RefreshType Periodic -RefreshSchedule $schedule08 -LimitingCollectionName $healthy_sw_reported
New-CMDeviceCollection -Name $healthy_duplicate_guid_does_not_exist -RefreshType Periodic -RefreshSchedule $schedule09 -LimitingCollectionId $AllWorkstationsCollectionId
New-CMDeviceCollection -Name $healthy_duplicate_guid_exists -RefreshType Periodic -RefreshSchedule $schedule09 -LimitingCollectionId $AllWorkstationsCollectionId
New-CMDeviceCollection -Name $healthy_agent_installed -RefreshType Periodic -RefreshSchedule $schedule10 -LimitingCollectionName $healthy_client
New-CMDeviceCollection -Name $healthy_agent_not_installed -RefreshType Periodic -RefreshSchedule $schedule10 -LimitingCollectionName $healthy_client
New-CMDeviceCollection -Name $suspect_duplicate_names -RefreshType Periodic -RefreshSchedule $schedule01 -LimitingCollectionId $AllWorkstationsCollectionId


# create query rules 
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_assigned -QueryExpression $query01a -RuleName $healthy_assigned
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $suspect_notassigned -QueryExpression $query01b -RuleName $suspect_notassigned
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_client -QueryExpression $query02a -RuleName $healthy_client
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_no_client -QueryExpression $query02b -RuleName $healthy_no_client
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_client_not_obsolete -QueryExpression $query03a -RuleName $healthy_client_not_obsolete
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_client_obsolete -QueryExpression $query03b -RuleName $healthy_client_obsolete
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_DDR_within_threshold -QueryExpression $query04a -RuleName $healthy_DDR_within_threshold
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_DDR_not_within_threshold -QueryExpression $query04b -RuleName $healthy_DDR_not_within_threshold
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_hw_inventory_current -QueryExpression $query05a -RuleName $healthy_hw_inventory_current
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_hw_inventory_not_current -QueryExpression $query05b -RuleName $healthy_hw_inventory_not_current
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_hw_memory_reported -QueryExpression $query06a -RuleName $healthy_hw_memory_reported
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_hw_memory_not_reported -QueryExpression $query06b -RuleName $healthy_hw_memory_not_reported
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_sw_reported -QueryExpression $query07a -RuleName $healthy_sw_reported
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_sw_not_reported -QueryExpression $query07b -RuleName $healthy_sw_not_reported
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthey_winmgmt_reported -QueryExpression $query08a -RuleName $healthey_winmgmt_reported
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthey_winmgmt_not_reported -QueryExpression $query08b -RuleName $healthey_winmgmt_not_reported
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_duplicate_guid_does_not_exist -QueryExpression $query09a -RuleName $healthy_duplicate_guid_does_not_exist
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_duplicate_guid_exists -QueryExpression $query09b1 -RuleName $healthy_duplicate_guid_exists1
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_duplicate_guid_exists -QueryExpression $query09b2 -RuleName $healthy_duplicate_guid_exists2
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_duplicate_guid_exists -QueryExpression $query09b3 -RuleName $healthy_duplicate_guid_exists3
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_agent_installed -QueryExpression $query10a -RuleName $healthy_agent_installed
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $healthy_agent_not_installed -QueryExpression $query10b -RuleName $healthy_agent_not_installed
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $suspect_duplicate_names -QueryExpression $query11a -RuleName $suspect_duplicate_names