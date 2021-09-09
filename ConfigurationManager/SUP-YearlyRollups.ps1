#Creating Software Update Packages for FY rollups

$Products = 'Windows,8.1','Windows,10','Office,2013','Office,2016'
$Years = 2013..2017
$UpdateNames = @()
foreach($Year in $Years){
    $Products|foreach{
        [string]$Product = ($_ -split ',')[0]
        $Version = ($_ -split ',')[1]
        [string]$Name = "$($Year) FY Rollup - $($Product) $($Version)"
        [string]$Description = "All $($Year) updates for $($Product) $($Version)"
        IF(!($Product -eq 'Windows' -and $Version -eq '10' -and [int32]$Year -lt '2016') -and !($Product -eq 'Office' -and $Version -eq '2016' -and [int32]$Year -lt '2015')){
          $UpdateNames += New-Object -TypeName PSObject -Property @{
            Name = $Name
            Description = $Description
            Product = "$Product $Version"
            StartDate = Get-Date -Year $Year -Month 01 -Day 01 -Hour 0 -Minute 0 -Second 0 -Millisecond 1
            EndDate = Get-Date -Year $Year -Month 12 -Day 31 -Hour 23 -Minute 59 -Second 59 -Millisecond 59
          }
          
        }
    }
}
$UpdateNames | Sort-Object StartDate,Product | Format-Table Name,Description,Product,StartDate,EndDate -AutoSize

$UpdateNames | foreach{

    Get-CMSoftwareUpdate -DateRevisedMin $_.StartDate -DateRevisedMax $_.EndDate

}