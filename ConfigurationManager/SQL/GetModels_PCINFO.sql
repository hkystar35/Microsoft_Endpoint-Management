SELECT distinct
version00 AS 'ModelName',
Model00 AS 'ModelNumber',
RS.Name0 AS 'MachineName',
SerialNumber0 AS 'SerialNumber',
CSD.Manufacturer00 AS 'Manufacturer',
RS.Operating_System_Name_and0 AS 'OS',
RS.Creation_Date0 AS 'CreationDate',
SID0 AS 'SID'

FROM COMPUTER_SYSTEM_PRODUCT_DATA CSPD
inner join Computer_System_DATA CSD on CSD.MachineID = CSPD.MachineID 
inner join vSMS_R_System RS on RS.ItemKey = CSPD.MachineID
JOIN dbo.v_GS_PC_BIOS BIOS ON BIOS.ResourceID = CSPD.MachineID

where RS.Name0 like '%DEVWIN10-06%'
--where Model00 like '%20HB%'
--where 'serialnumber' like '%0a47%'
GROUP BY Manufacturer00,Model00,Version00,RS.Name0,SMBIOSBIOSVersion0,SerialNumber0,Creation_Date0,SID0,Operating_System_Name_and0
