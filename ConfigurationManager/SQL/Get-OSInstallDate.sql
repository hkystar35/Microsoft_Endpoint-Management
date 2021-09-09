Select
OS.Caption0 AS 'Caption'
,OS.Version0 AS 'OSVersion'
,R.Name0 AS 'MachineName'
,R.User_Name0 AS 'UserName'
,OS.InstallDate0 AS 'OSInstallDate'

FROM v_GS_OPERATING_SYSTEM OS
JOIN vSMS_R_System R on R.ItemKey = OS.ResourceID

WHERE OS.Caption0 like '%Windows 8%'
OR OS.Caption0 like '%Windows 7%'
ORDER BY OS.InstallDate0