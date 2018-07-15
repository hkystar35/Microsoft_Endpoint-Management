$LimCol = "All Windows Desktops"
$ColNames = "Zero-Day Updates - Groups 0-1;PAY000AA;PAY000A6"
<#,
"Zero-Day Updates - Groups 3-4;PAY0016C;PAY000AC",
"Zero-Day Updates - Groups 5;PAY000AD",
"Zero-Day Updates - Groups 6;PAY000AE",
"Zero-Day Updates - Groups 7-9;PAY000AF;PAY0009C;PAY0009F",
"Zero-Day Updates - Service Pilot"
#>
$RefreshSchedule = New-CMSchedule -Start "09/14/2017 6:00 PM" -DayOfWeek Saturday -RecurCount 1

foreach($ColName in $ColNames){
    $SplitVar1 = $ColName -split (";")
        $Comment = "Zero-Day Update Group, based on SUGs $($SplitVar1[1]) $($SplitVar1[2]) $($SplitVar1[3])"
        Write-Host "Creating Collection named `"$($SplitVar1[0])`" with Comment: `"$comment`""
        New-CMCollection -CollectionType Device -LimitingCollectionName "$LimCol" -Name "$($SplitVar1[0])" -Comment "$Comment" -RefreshSchedule $RefreshSchedule
            if($SplitVar1[1]){
                Write-Host "Collection $($SplitVar1[1]) as Included member of `"$($SplitVar1[0])`""
                Add-CMDeviceCollectionIncludeMembershipRule -CollectionName "$($SplitVar1[0])" -IncludeCollectionId "$($SplitVar1[1])"
            }
            if($SplitVar1[2]){
                Write-Host "Collection $($SplitVar1[2]) as Included member of `"$($SplitVar1[0])`""
                Add-CMDeviceCollectionIncludeMembershipRule -CollectionName "$($SplitVar1[0])" -IncludeCollectionId "$($SplitVar1[2])"
            }
            if($SplitVar1[3]){
                Write-Host "Collection $($SplitVar1[3]) as Included member of `"$($SplitVar1[0])`""
                Add-CMDeviceCollectionIncludeMembershipRule -CollectionName "$($SplitVar1[0])" -IncludeCollectionId "$($SplitVar1[3])"
            }
        Write-Host "`n-----"
}