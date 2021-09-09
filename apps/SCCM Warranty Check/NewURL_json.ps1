$Serials = 'PC0LJ68A','R90A26ND'

ForEach($Serial in $Serials){
  $Info = Invoke-WebRequest -Uri http://supportapi.lenovo.com/v2.5/warranty?Serial=$Serial | ConvertFrom-Json
  $WarrantyEndDate = $info.Warranty[1].End -split ('T')
  Get-date $WarrantyEndDate[0] -Format M/dd/yyy
  Switch($info.InWarranty){True{$Warranty = "Active"} False{$Warranty = "Expired"}}
  Write-Host "Serial Number is "$info.Serial", Warranty is $Warranty, Warranty Expiration Date: "$WarrantyEndDate[0]""
}