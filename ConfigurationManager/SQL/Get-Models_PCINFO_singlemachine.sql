SELECT DISTINCT
  R.Name0 AS 'Machine Name'
, R.ResourceID AS 'ResourceID'
, CASE
    WHEN CSP.Vendor0 LIKE '%Lenovo%' THEN CSP.Version0
    ELSE CSP.Name0
  END AS 'Model Name'
, CASE
    WHEN CSP.Vendor0 LIKE '%Lenovo%' THEN LEFT(CSP.Name0,4)
    ELSE CSP.SKUNumber0
  END AS 'System SKU'
, BIOS.SerialNumber0 AS 'Serial Number'
, BIOS.BIOSVersion0 AS 'BIOS Version'
, CS.Manufacturer0 AS 'Manufacturer'
, OS.Caption0 AS 'OS Caption'
, OS.Version0 AS 'OS Version'
, R.Creation_Date0 AS 'OS Creation Date'
, R.SID0 AS 'SID'
, FORMAT(CS.TotalPhysicalMemory0 / (1024.00 * 1024.00), '###.##') AS 'Total RAM'
, FORMAT(LD.Size0 / (1024.00),'####.##') AS 'Disk Size GB'
, FORMAT(LD.FreeSpace0 / (1024.00), '###.##') AS 'Disk Free GB'
, P.Name0 AS 'CPU Name'

FROM v_R_System R
    left join v_GS_COMPUTER_SYSTEM_PRODUCT CSP on CSP.ResourceID = R.ResourceID
    left join v_GS_COMPUTER_SYSTEM CS on CS.ResourceID = R.ResourceID
    left JOIN v_GS_PC_BIOS BIOS ON BIOS.ResourceID = R.ResourceID
    left join v_GS_OPERATING_SYSTEM OS on OS.ResourceID = R.ResourceID
    left join v_GS_LOGICAL_DISK LD on LD.ResourceID = R.ResourceID
    left join v_GS_PROCESSOR P on P.ResourceID = R.ResourceID

where 
    LD.DriveType0 = 3
    and LD.Name0 LIKE 'C:%'

ORDER BY [OS Creation Date]