$IDs = Get-Content -Path C:\temp\wsus-dupes.txt

$Results = @(
foreach($ID in $IDs){
    Get-WsusComputer | Where-Object {$_.ID -like "$ID"}
}
)
$Results | Export-Csv C:\temp\wsus-dupes_export.csv -NoTypeInformation