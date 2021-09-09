DECLARE @MissingSourceDirectory NVARCHAR(512)
DECLARE @PackageId NVARCHAR(8)
SET @MissingSourceDirectory = '7c1bc577-52cb-462f-9621-5180be268589'
SET @PackageId = 'PAY003CC'

SELECT CASE
        WHEN ci.BulletinID LIKE '' OR ci.BulletinID IS NULL THEN 'Non Security Update'
        ELSE ci.BulletinID
        END As BulletinID
    , ci.ArticleID
    , loc.DisplayName
    , loc.Description
    , ci.IsExpired
    , ci.DatePosted
    , ci.DateRevised
    , ci.Severity
    , ci.RevisionNumber
    , ci.CI_ID
FROM dbo.v_UpdateCIs AS ci
LEFT OUTER JOIN dbo.v_LocalizedCIProperties_SiteLoc AS loc ON loc.CI_ID = ci.CI_ID
WHERE ci.CI_ID IN
(
    SELECT [FromCI_ID]
    FROM [dbo].[CI_ConfigurationItemRelations] cir
    INNER JOIN [dbo].[CI_RelationTypes] rt ON cir.RelationType = rt.RelationType
    WHERE cir.ToCI_ID IN
    (
        SELECT CI_ID
        FROM [dbo].[CI_ContentPackages] cp
        INNER JOIN [dbo].[CI_ConfigurationItemContents] cic ON cp.Content_ID = cic.Content_ID
        WHERE cp.ContentSubFolder = @MissingSourceDirectory AND cp.PkgID = @PackageId
    )
)

