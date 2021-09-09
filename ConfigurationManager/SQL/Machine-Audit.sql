SELECT distinct
dbo.v_R_System.Name0 AS 'Machine Name',
dbo.v_R_System.User_Name0 AS 'Last User',
dbo.v_R_System.Last_Logon_Timestamp0 AS 'Last Logon',
dbo.Computer_System_DATA.Manufacturer00 AS 'Manufacturer', 
dbo.COMPUTER_SYSTEM_PRODUCT_DATA.version00 AS 'Model Name',
dbo.Computer_System_DATA.model00 AS 'Model No.',
dbo.COMPUTER_SYSTEM_PRODUCT_DATA.IdentifyingNumber00 AS 'S/N',
max(dbo.v_RA_System_SystemOUName.System_OU_Name0) AS 'OU',
dbo.v_AgentDiscoveries.AgentTime AS 'Last DDR'


FROM 
dbo.v_R_System
inner join dbo.Computer_System_DATA on dbo.Computer_System_DATA.MachineID = dbo.v_R_System.ResourceID
inner join dbo.COMPUTER_SYSTEM_PRODUCT_DATA ON dbo.COMPUTER_SYSTEM_PRODUCT_DATA.MachineID = dbo.v_R_System.ResourceID
inner join dbo.v_RA_System_SystemOUName ON dbo.v_RA_System_SystemOUName.ResourceID = dbo.v_R_System.ResourceID
inner join dbo.v_AgentDiscoveries ON dbo.v_AgentDiscoveries.ResourceId = dbo.v_R_System.ResourceID

Where  dbo.v_AgentDiscoveries.AgentName = 'Heartbeat Discovery' AND (dbo.Computer_System_DATA.Manufacturer00 = 'LENOVO' or dbo.Computer_System_DATA.Manufacturer00 Like 'Microsoft%')

GROUP BY Manufacturer00,Version00,model00,dbo.v_R_System.Name0,AgentTime,AgentName,User_Name0,Last_Logon_Timestamp0,dbo.COMPUTER_SYSTEM_PRODUCT_DATA.IdentifyingNumber00

ORDER BY 'OU', 'Last User'