SELECT Distinct top 10
R.Name0
,A.Description0
,A.FileName0
,A.Publisher0
,A.FileVersion0
,A.TimeStamp
,A.Location0
,A.StartupType0
,A.StartupValue0


FROM v_GS_AUTOSTART_SOFTWARE as A
join vSMS_R_System R on R.ItemKey = A.ResourceID

--where R.Name0 = 'tferree'
Where A.Publisher0 like 'F5%'

order by a.TimeStamp