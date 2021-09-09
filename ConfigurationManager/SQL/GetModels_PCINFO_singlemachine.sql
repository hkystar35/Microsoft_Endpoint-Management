SELECT distinct
version00 AS 'ModelName',
Model00 AS 'ModelNumber',
vSMS_R_System.Name0 AS 'MachineName',
SerialNumber0 AS 'SerialNumber',
Computer_System_DATA.Manufacturer00 AS 'Manufacturer',
vSMS_R_System.Operating_System_Name_and0 AS 'OS',
vSMS_R_System.Creation_Date0 AS 'CreationDate',
SID0 AS 'SID'

FROM COMPUTER_SYSTEM_PRODUCT_DATA 
inner join Computer_System_DATA on Computer_System_DATA.MachineID = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID 
inner join vSMS_R_System on vSMS_R_System.ItemKey = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID
JOIN dbo.v_GS_PC_BIOS BIOS ON BIOS.ResourceID = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID

where vSMS_R_System.Name0 like '%COURTNAYVASSER%'
--where 'ModelNumber' like '20HH%'
--where 'serialnumber' like '%0a47%'
GROUP BY Manufacturer00,Model00,Version00,vSMS_R_System.Name0,SMBIOSBIOSVersion0,SerialNumber0,Creation_Date0,SID0,Operating_System_Name_and0
