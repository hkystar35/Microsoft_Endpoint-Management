select
SusClientId00,
MachineID,
Netbios_Name0
from vSMS_R_System inner join SusClientID_DATA on SusClientID_DATA.MachineID = vSMS_R_System.ItemKey
group by SusClientId00,MachineID,Netbios_Name0
--having count(*) >1
order by SusClientId00