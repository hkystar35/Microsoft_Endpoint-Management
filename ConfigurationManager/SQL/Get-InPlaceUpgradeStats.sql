select distinct
vSMS_R_System.Name0 as [MachineName],
coalesce(InPlaceUpgrade_DATA.DeadlineDate00,InPlaceUpgrade64_DATA.DeadlineDate00) as [DeadlineDate],
coalesce(InPlaceUpgrade_DATA.DeferDate00,InPlaceUpgrade64_DATA.DeferDate00) as [DeferDate],
coalesce(InPlaceUpgrade_DATA.FirstRun00,InPlaceUpgrade64_DATA.FirstRun00) as [FirstRun],
coalesce(InPlaceUpgrade_DATA.LastRunDate00,InPlaceUpgrade64_DATA.LastRunDate00) as [LastRunDate],
coalesce(InPlaceUpgrade_DATA.LastRunUser00,InPlaceUpgrade64_DATA.LastRunUser00) as [LastRunUser],
coalesce(InPlaceUpgrade_DATA.OSDPackageID00,InPlaceUpgrade64_DATA.OSDPackageID00) as [OSDPackageID],
coalesce(InPlaceUpgrade_DATA.PowerBrokerStatus00,InPlaceUpgrade64_DATA.PowerBrokerStatus00) as [PowerBrokerStatus],
coalesce(InPlaceUpgrade_DATA.StartingOS00,InPlaceUpgrade64_DATA.StartingOS00) as [StartingOS],
coalesce(InPlaceUpgrade_DATA.UpgradeDate00,InPlaceUpgrade64_DATA.UpgradeDate00) as [UpgradeDate],
coalesce(InPlaceUpgrade_DATA.UpgradeNow00,InPlaceUpgrade64_DATA.UpgradeNow00) as [UpgradeNow]

from InPlaceUpgrade_DATA join vSMS_R_System on vSMS_R_System.ItemKey = InPlaceUpgrade_DATA.MachineID
join InPlaceUpgrade64_DATA on vSMS_R_System.ItemKey = InPlaceUpgrade64_DATA.MachineID

where InPlaceUpgrade_DATA.DeadlineDate00 <> '' or InPlaceUpgrade64_DATA.DeadlineDate00 <> ''

order by DeferDate desc