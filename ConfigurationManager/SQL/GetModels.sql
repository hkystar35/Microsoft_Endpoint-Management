SELECT distinct
version00 AS 'Model Name'
,Model00 AS 'Model Number'
--,LEFT(model00,4) AS 'Prefix'
,Count(Version00) AS 'Count' 
--,vSMS_R_System.Name0 AS 'MachineName'
--,BIOS.SMBIOSBIOSVersion0 AS 'BIOS Version'
--,SerialNumber0 AS 'Serial Number'

FROM COMPUTER_SYSTEM_PRODUCT_DATA 
inner join Computer_System_DATA on Computer_System_DATA.MachineID = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID 
inner join vSMS_R_System on vSMS_R_System.ItemKey = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID
JOIN dbo.v_GS_PC_BIOS BIOS ON BIOS.ResourceID = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID
--where vSMS_R_System.Name0 like 'Clintsm%' or vSMS_R_System.Name0 like 'austinwimberly3' or vSMS_R_System.Name0 like 'dylanb%'
 --where vSMS_R_System.ItemKey like '16790360'


/*
where (vSMS_R_System.Name0 like '%michael%'

or vSMS_R_System.Name0 like '%clint%'
or vSMS_R_System.Name0 like '%davidpin%'
or vSMS_R_System.Name0 like '%davidjoh%'
or vSMS_R_System.Name0 like '%dougw%'
or vSMS_R_System.Name0 like '%wimb%'
or vSMS_R_System.Name0 like '%johnrin%') and Model00 like '20hh%'

*/

--where SerialNumber0 like '%PF12WT6U%'
--or SerialNumber0 like '%PF13y228%'
where version00 like 'thinkpad p52'

GROUP BY Version00,Model00 --,Manufacturer00,vSMS_R_System.Name0,SMBIOSBIOSVersion0,SerialNumber0

ORDER BY 'Model name'