$Search = "4038782","4041691"

$search | foreach {Get-CMSoftwareUpdate -ArticleId $_ -Fast | Select ArticleID,LocalizedDisplayName,IsDeployed,IsContentProvisioned,IsExpired,IsSuperseded |Format-Table }