select distinct
G.DisplayName0 as 'Name'
,G.Publisher0 as 'Publisher'
,G.Version0 as 'Version'
--,count(*) as 'InstallCount'
,R.Name0 AS 'MachineName'
,R.User_Name0 AS 'UserName'
,U.Full_User_Name0 AS 'Full Name'

from
v_GS_ADD_REMOVE_PROGRAMS G JOIN vSMS_R_System R on G.ResourceID = R.ItemKey
join v_R_User U on R.User_Name0 = U.User_Name0

where
G.DisplayName0 LIKE '%zoom%'
and
R.Name0 like '%TameraRomero%'

Group By G.DisplayName0,R.User_Name0,U.Full_User_Name0,R.Name0,G.Version0,G.Publisher0

order by U.Full_User_Name0

/*
select
count(vSMS_R_System.Operating_System_Name_and0) as 'Machines'
from vSMS_R_System
*/