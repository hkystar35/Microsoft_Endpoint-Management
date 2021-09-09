$Collections = Get-CMCollection -Name WindowsUpdates_thawed_Group00  | select -Property * | Where-Object {$_.CollectionType -eq 2}
Foreach($Collection in $Collections){
    



}

Add-CMDeviceCollectionDirectMembershipRule
Add-CMDeviceCollectionExcludeMembershipRule
Add-CMDeviceCollectionIncludeMembershipRule
Add-CMDeviceCollectionQueryMembershipRule

Add-CMUserCollectionDirectMembershipRule
Add-CMUserCollectionExcludeMembershipRule
Add-CMUserCollectionIncludeMembershipRule
Add-CMUserCollectionQueryMembershipRule


$CollectionType
2 = Device
1 = User


New-CMCollection -CollectionType Device -Comment -LimitingCollectionId P010000A -Name "test" -RefreshSchedule $RefreshSchedule -RefreshType $RefreshType