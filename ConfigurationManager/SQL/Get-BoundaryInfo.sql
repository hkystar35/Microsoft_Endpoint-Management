select distinct
vSMS_R_System.Name0,
System_IP_Subnets_ARR.IP_Subnets0,
vSMS_R_System.Operating_System_Name_and0
--count(System_IP_Subnets_ARR.IP_Subnets0) as 'location'
--vSMS_Boundary.Value
--vSMS_BoundaryGroup.Name
from 

vSMS_R_System join System_IP_Subnets_ARR on vSMS_R_System.ItemKey = System_IP_Subnets_ARR.ItemKey 
--join vSMS_Boundary on vSMS_Boundary.Value = System_IP_Subnets_ARR.IP_Subnets0
--join vSMS_BoundaryGroupMembers on vSMS_BoundaryGroupMembers.BoundaryID = vSMS_Boundary.BoundaryID
--join vSMS_BoundaryGroup on vSMS_BoundaryGroup.GroupID = vSMS_BoundaryGroupMembers.GroupID

--where Name0 like 'tom%'
where System_IP_Subnets_ARR.IP_Subnets0 like '10.129.%'
--and vSMS_R_System.Operating_System_Name_and0 like 'Microsoft Windows NT Workstation 6%'
-- or System_IP_Subnets_ARR.IP_Subnets0 like '10.129.%'
--where vSMS_BoundaryGroup.GroupID != '16777218'
order by IP_Subnets0