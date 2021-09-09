$TaskSequenceName = "Windows 10 Enterprise - Office 2016"
$SiteCode = "PAY"
 
$TSID = Get-WmiObject -Namespace ROOT\sms\Site_$SiteCode -Query "Select PackageID from SMS_PackageStatusDetailSummarizer where Name = '$TaskSequenceName'" |
    Select -ExpandProperty PackageID
 
$PKGs = Get-WmiObject -Namespace ROOT\sms\Site_$SiteCode -Query "Select * from SMS_TaskSequencePackageReference where PackageID = '$TSID'" | 
    Select @{N='PackageName';E={$_.ObjectName}},@{N='Size (MB)';E={$($_.SourceSize / 1KB).ToString(".00")}} | Sort PackageName
 
$Stats = $PKGs | Measure-Object "Size (MB)" -sum
$PKGs | Out-GridView -Title "Packages in ""$TaskSequenceName""   |   Total Packages: $($Stats.Count)   |   Total Size of Packages: $(($Stats.Sum / 1KB).ToString(".00")) GB"
