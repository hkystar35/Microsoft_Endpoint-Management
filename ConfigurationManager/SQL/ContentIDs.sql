SELECT LP.DisplayName,
CP.CI_ID,
CPS.PkgID,
CPS.ContentSubFolder
FROM dbo.CI_ContentPackages CPS
INNER JOIN dbo.CIContentPackage CP
ON CPS.PkgID = CP.PkgID
LEFT OUTER JOIN dbo.CI_LocalizedProperties LP
ON CP.CI_ID = LP.CI_ID
where DisplayName like '%crowdstrike%'
--where ContentSubFolder like '%f71b7aaf-ef36-4726-9e1e-f0a9c825a9b2%'
--where CPS.PkgID like '%3D%'
ORDER BY CPS.ContentSubFolder DESC