SELECT distinct
p.Name
,p.Description
,n.SourceCompressedSize
,'Source Size (MB)' = n.SourceSize/1024
,dp.LastRefreshTime
, p.Manufacturer
, p.Version
, p.Language
, p.SourceSite
, p.PackageID
--, case when dp.IsPeerDP=1 then '*' else " end as BranchDP
,psd.InstallStatus

FROM v_Package p
INNER JOIN
v_DistributionPoint dp
ON
p.PackageID = dp.PackageID
LEFT JOIN
v_PackageStatusRootSummarizer n
ON
p.PackageID = n.PackageID
LEFT JOIN
v_PackageStatusDistPointsSumm psd
ON
dp.ServerNALPath=psd.ServerNALPath
AND
dp.PackageID=psd.PackageID
LEFT JOIN
v_PackageStatus ps
ON
dp.ServerNALPath=ps.PkgServer
AND
dp.PackageID=ps.PackageID
--WHERE dp.ServerNALPath LIKE '%' + @ID + '%'