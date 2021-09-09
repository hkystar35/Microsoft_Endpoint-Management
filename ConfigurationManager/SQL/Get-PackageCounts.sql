select 
PackageType =
	Case P.Packagetype
	When 0 Then 'Software Distribution Package'
	When 3 Then 'Driver Package'
	When 4 Then 'Task Sequence Package'
	When 5 Then 'Software Update Package'
	When 6 Then 'Device Settings Package'
	When 7 Then 'Virtual Application Package'
	When 8 Then 'Application Package'
	When 257 Then 'Image Package'
	When 258 Then 'Boot Image Package'
	When 259 Then 'OS Install Package'
	When 260 Then 'VHD Package'
	-- URL https://docs.microsoft.com/en-us/sccm/develop/reference/core/servers/configure/sms_packagebaseclass-server-wmi-class#packagetype
End
,COUNT(PackageType) as Total


FROM dbo.v_package p

WHERE
packageID not in (select PackageID from dbo.v_Advertisement)and
PackageID not in (SELECT ReferencePackageID FROM v_TaskSequenceReferencesInfo)

GROUP BY PackageType