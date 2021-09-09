$Exclusion = 'PAY001DF'

# VMware, Parallels, Hyper-V
#$Exclusions = 'PAY001F8','PAY001F7','PAY001F5'
$Exclusions = 'PAY00232'
$Note = "Excludes Lenovo P50 models from collection $Exclusion"
$Collections = Get-CMDeviceCollection -Name "zerodayupdates_*"
$Collections | foreach{
    #Write-Host "Name: " $_.Name
    foreach($Exclusion in $Exclusions){Add-CMDeviceCollectionExcludeMembershipRule -CollectionName $_.Name -ExcludeCollectionId $Exclusion}
    #Add-CMDeviceCollectionExcludeMembershipRule -CollectionName $_.Name -ExcludeCollectionId "PAY001F8,PAY001F7,PAY001F5" -WhatIf
}