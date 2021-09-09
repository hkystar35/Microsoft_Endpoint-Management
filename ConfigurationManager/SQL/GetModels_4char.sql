SELECT distinct
Computer_System_DATA.Manufacturer00 AS 'Manufacturer', 
version00 AS 'Model Name',
LEFT(model00,4) AS 'Model Prefix',
Count(LEFT(model00,4)) AS 'Count',
LEFT(SMBIOSBIOSVersion0,4) AS 'BIOS Prefix',
CASE LEFT(model00,4)
      WHEN '2438' THEN 'NO'
      WHEN '2992' THEN 'NO'
      WHEN '3282' THEN 'NO'
	  WHEN '3444' THEN 'NO'
	  WHEN '7052' THEN 'NO'
	  WHEN '10A7' THEN 'NO'
	  WHEN '10AY' THEN 'NO'
	  WHEN '20FD' THEN 'NO'
	  ELSE 'YES'
   END AS Win10_Compatible

FROM COMPUTER_SYSTEM_PRODUCT_DATA join Computer_System_DATA on Computer_System_DATA.MachineID = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID
join dbo.v_GS_PC_BIOS BIOS ON BIOS.ResourceID = Computer_System_DATA.MachineID
Where Manufacturer00 = 'LENOVO'
GROUP BY Manufacturer00,Version00,LEFT(model00,4),LEFT(SMBIOSBIOSVersion0,4)

ORDER BY 'Model Name' desc
--ORDER BY 'count' desc
--ORDER BY 'BIOS Prefix' desc
--ORDER BY 'Win10_Compatible','Model Name' desc