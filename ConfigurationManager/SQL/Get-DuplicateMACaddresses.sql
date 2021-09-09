SELECT
v_RA_System_ResourceNames.Resource_Names0 AS [Resource name],
v_RA_System_MACAddresses.MAC_Addresses0 AS [MAC Address]
--COUNT(MAC_Addresses0) AS [Count]

FROM
v_RA_System_MACAddresses  JOIN
v_RA_System_ResourceNames ON v_RA_System_MACAddresses.ResourceID = v_RA_System_ResourceNames.ResourceID

--GROUP BY MAC_Addresses0,Resource_Names0

--HAVING (COUNT(MAC_Addresses0) > 1)

--ORDER BY [Count] desc
--WHERE MAC_Addresses0 like '1E:15:35:AF:FC:1D'
WHERE MAC_Addresses0 like '00:50:56:C0:00:08' OR
MAC_Addresses0 like '00:50:56:C0:00:01' OR
MAC_Addresses0 like '0A:00:27:00:00:14' OR
MAC_Addresses0 like '0A:00:27:00:00:11' OR
MAC_Addresses0 like '0A:00:27:00:00:00' OR
MAC_Addresses0 like '0A:00:27:00:00:09' OR
MAC_Addresses0 like '0A:00:27:00:00:0E' OR
MAC_Addresses0 like '0A:00:27:00:00:10' OR
MAC_Addresses0 like '0A:00:27:00:00:12' OR
MAC_Addresses0 like '0A:00:27:00:00:18' OR
MAC_Addresses0 like '0A:00:27:00:00:0C' OR
MAC_Addresses0 like '0A:00:27:00:00:03' OR
MAC_Addresses0 like '0A:00:27:00:00:05' OR
MAC_Addresses0 like '00:50:56:93:01:26' OR
MAC_Addresses0 like '00:50:56:93:1E:21' OR
MAC_Addresses0 like '00:50:56:93:27:63' OR
MAC_Addresses0 like '00:50:56:93:30:FD' OR
MAC_Addresses0 like '00:50:56:93:3D:FD' OR
MAC_Addresses0 like '00:50:56:93:42:C9' OR
MAC_Addresses0 like '00:50:56:93:6E:B8' OR
MAC_Addresses0 like '00:50:56:93:C4:A2' OR
MAC_Addresses0 like '00:50:56:93:CA:67' OR
MAC_Addresses0 like '00:50:56:AA:7B:EC' OR
MAC_Addresses0 like '0A:00:27:00:00:08' OR
MAC_Addresses0 like '00:50:56:C0:00:02' OR
MAC_Addresses0 like '0A:00:27:00:00:19' OR
MAC_Addresses0 like '3C:18:A0:08:2E:9B' OR
MAC_Addresses0 like '3C:18:A0:0A:E7:12' OR
MAC_Addresses0 like '8C:16:45:24:73:25' OR
MAC_Addresses0 like '8C:16:45:53:08:44' OR
MAC_Addresses0 like '8C:16:45:D6:F7:77' OR
MAC_Addresses0 like '8C:16:45:DF:65:9F' OR
MAC_Addresses0 like 'C8:5B:76:E1:71:BE' OR
MAC_Addresses0 like 'C8:5B:76:EF:0A:EB' OR
MAC_Addresses0 like '0A:00:27:00:00:13' OR
MAC_Addresses0 like '0A:00:27:00:00:16' OR
MAC_Addresses0 like '0A:00:27:00:00:17' OR
MAC_Addresses0 like '00:50:56:91:00:02' OR
MAC_Addresses0 like '0A:00:27:00:00:0F'

ORDER BY [MAC Address]