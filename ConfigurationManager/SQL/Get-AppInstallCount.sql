/*
select distinct
ISH.ProductName00,
ISH.ProductVersion00

from INSTALLED_SOFTWARE_HIST ISH

where ISH.ProductName00 like '%zoom%'
*/

select distinct
ISD.ProductName00 AS 'App Name',
ISD.ProductVersion00 AS 'App Version',
COUNT(*) AS 'Count'

from INSTALLED_SOFTWARE_DATA ISD

where ISD.ProductName00 like '%Teams%'

GROUP BY ISD.ProductName00,ISD.ProductVersion00

ORDER BY ISD.ProductVersion00