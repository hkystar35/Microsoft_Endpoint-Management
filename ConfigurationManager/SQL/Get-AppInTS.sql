select 
tsinfo.PackageID , 
pack.Name as 'application' into #temp1 

from v_TaskSequenceAppReferencesInfo tsinfo join v_package pack on pack.PackageID = tsinfo.RefAppPackageID 
where pack.name like '%officescan%'
--where tsinfo.PackageID = 'pay003f6'

select 
application,
name,
pack.PackageID

from v_package pack join #temp1 on #temp1.packageid = pack.PackageID 

order by 'Name'
drop table #temp1