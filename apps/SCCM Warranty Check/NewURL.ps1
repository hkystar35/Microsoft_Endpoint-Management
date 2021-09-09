$Info = Invoke-WebRequest -Uri http://supportapi.lenovo.com/v2.5/warranty?Serial=PC0LJ68A | ConvertFrom-Json
$Expand = $info | select -ExpandProperty warranty
foreach($element in $Expand){
    Write-host "Element $element"
}