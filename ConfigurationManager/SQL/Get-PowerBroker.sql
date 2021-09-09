select distinct
v_GS_INSTALLED_SOFTWARE.ProductName0 as 'AppName'
,v_GS_INSTALLED_SOFTWARE.Publisher0 as 'AppPublisher'
,v_GS_INSTALLED_SOFTWARE.ProductVersion0 as 'AppVersion'
,RU.Mail0 AS 'Email'
,RSYS.Name0 AS 'MachineName'

from 
v_R_User RU
inner join v_UsersPrimaryMachines PRIM on RU.ResourceID = PRIM.UserResourceID
inner join v_R_System RSYS on PRIM.MachineID = RSYS.ResourceID
inner join v_GS_INSTALLED_SOFTWARE on RSYS.ResourceID = v_GS_INSTALLED_SOFTWARE.ResourceID
inner join v_UsersPrimaryMachines on PRIM.MachineID = RSYS.ResourceID

where v_GS_INSTALLED_SOFTWARE.ProductName0 = 'BeyondTrust PowerBroker Desktops Client for Windows'

order by 'MachineName'