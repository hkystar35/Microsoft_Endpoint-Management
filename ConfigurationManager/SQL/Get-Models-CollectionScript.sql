SELECT distinct
Computer_System_DATA.Manufacturer00 AS 'Manufacturer', 
CASE (version00)
      WHEN '%' THEN 'Model'
	  ELSE 'Model'
   END AS 'ModelNametest',
model00 AS 'ModelPrefix'

FROM COMPUTER_SYSTEM_PRODUCT_DATA join Computer_System_DATA on Computer_System_DATA.MachineID = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID
join dbo.v_GS_PC_BIOS BIOS ON BIOS.ResourceID = Computer_System_DATA.MachineID
Where Manufacturer00 not like '%LENOVO%'
GROUP BY Manufacturer00,Version00,model00


SELECT distinct
Computer_System_DATA.Manufacturer00 AS 'Manufacturer', 
version00 AS 'ModelName',
LEFT(model00,4) AS 'ModelPrefix'

FROM COMPUTER_SYSTEM_PRODUCT_DATA join Computer_System_DATA on Computer_System_DATA.MachineID = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID
join dbo.v_GS_PC_BIOS BIOS ON BIOS.ResourceID = Computer_System_DATA.MachineID
Where Manufacturer00 like '%LENOVO%'
GROUP BY Manufacturer00,Version00,LEFT(model00,4)