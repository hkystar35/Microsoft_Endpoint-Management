$DevColls = Get-CMCollection -Name "Dev*" -CollectionType User | select -ExpandProperty Name | Sort-Object Name
$Count = $DevColls.Count
Write-Host "`nCount of matching Collections: $count "
$DevColls | foreach{
    Write-Host "`n`nColl Name: $_"
    $DevDepl = Get-CMDeployment -CollectionName $_ | select -ExpandProperty ApplicationName | Sort-Object ApplicationName
    foreach($Depl in $DevDepl){
        Write-Host " - DeplName: $Depl"
    }
}