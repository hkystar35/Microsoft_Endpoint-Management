<#
$Date = Get-Date -Format "yyyy-MM-dd-HHmmss"
# Get all old machines that haven't checked in in 40 days
$oldcomps = Get-WsusComputer | Select-Object -Property Id, FullDomainName, IPAddress, LastSyncTime | Where-Object{
	$_.LastSyncTime -le ((get-date).AddDays(-10))
}
$oldcomps | Export-Csv -Path "C:\temp\wsus_dupes_all_$($Date).csv" -NoTypeInformation
#>

$IDs = Get-Content -Path C:\temp\wsus-dupes.txt
#$IDs = 'a9f7049d-db19-4fa5-84a7-b28d3b38899c','50981bfc-e112-47ee-8e2b-707626896965','93486aea-8e26-4967-a619-ae7c1b8e5fb2'

$Results = @(
foreach($ID in $IDs){
    Get-WsusComputer | Where-Object {$_.ID -like "$ID"}
}
)
$Results | Export-Csv C:\temp\wsus-dupes_export.csv -NoTypeInformation