SELECT DISTINCT

    R.Name0 AS [Computer Name]
    , R.Resource_Domain_OR_Workgr0 AS [Domain]
    , R.AD_Site_Name0 AS [AD Site]
    , CASE R.Client0
        WHEN  2 THEN 'true'
        ELSE 'false'
    END AS [DomainController]
    , CASE BL.ComplianceState
        WHEN 1 THEN 'Azure'
        WHEN 2 THEN 'On-Prem'
    END AS [Hosted in]
    , CASE R.Client0
        WHEN  0 THEN 'no'
        WHEN  1 THEN 'Installed'
        ELSE 'unkown'
    END AS [CM Client]
    , CS.LastActiveTime AS [CM Last Activity]
    , sw.Name AS [CM MW Name]
    , sw.Description AS [CM MW Description]
    , sw.StartTime AS [CM MW Start Time]
    , sw.Duration AS [CM MW Duration Minutes]
    , CASE sw.IsEnabled
        WHEN 0 THEN 'false'
        WHEN 1 THEN 'true'
    END AS [CM MW Enabled]
    , col.Name AS [CM MW Collection Name]

FROM v_R_System AS R
    inner Join v_FullCollectionMembership FCM ON R.ResourceID = FCM.ResourceID
    inner join dbo.v_ServiceWindow AS SW ON SW.CollectionID = FCM.CollectionID
    inner join v_GS_OPERATING_SYSTEM OS ON OS.ResourceID = R.ResourceID
    inner join v_CH_ClientSummary CS ON CS.ResourceID = R.ResourceID
    inner join v_CICurrentComplianceStatus BL ON BL.ResourceID = R.ResourceID

    Join v_Collection COL ON FCM.CollectionID = COL.CollectionID

WHERE OS.ProductType0 != 1
    AND BL.CI_ID = '17334141' -- CI_ID for "OS_IsAzureVM" Baseline
    AND SW.Name NOT LIKE 'ZeroDay_All' -- Zero-Day Maintenance Window

ORDER BY [Computer Name]