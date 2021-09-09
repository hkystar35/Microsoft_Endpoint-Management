select distinct
GSIS.ProductName0 as 'Name',
GSIS.Publisher0 as 'Publisher',
GSIS.ProductVersion0 as 'Version'
,R.Name0 as [Computer Name]
,R.Resource_Domain_OR_Workgr0 as [Computer Domain]
,R.User_Name0 as [User Name]
,R.User_Domain0 as [User Domain]
--,count(*) as 'Count'
--into #tempapp1
from
v_R_SYSTEM R
join v_GS_INSTALLED_SOFTWARE GSIS on R.ResourceID = GSIS.ResourceID
where GSIS.ProductName0 like '%VNC%'
and GSIS.ProductName0 not like '%driver%'
and GSIS.ProductName0 not like '%server%'
--GROUP BY GSIS.ProductName0,GSIS.Publisher0,GSIS.ProductVersion0
ORDER BY 'Name'