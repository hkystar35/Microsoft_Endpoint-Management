select distinct 
tsr.packageID
,tsr.referencepackageid
,tsr.referencename
,'Source Size (MB)' = P.SourceSize/1024
,P.SourceDate
,tsp.packageid
,tsp.name

from v_tasksequenceReferencesInfo tsr

join v_tasksequencePackage tsp On tsr.packageID = tsp.packageid
left join v_PackageStatusRootSummarizer P on P.PackageID = tsr.PackageID

--where tsp.name like '%s%'
--and 
where tsr.ReferenceName like '%%'

ORDER BY tsr.ReferenceName,tsp.Name