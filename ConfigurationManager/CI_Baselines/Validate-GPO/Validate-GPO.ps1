#Validate GPO applied to machine
$GPOGUIDs = '{CEDC279F-0DE4-4700-974E-7786C49C49DD}','{60306B52-2978-4DAB-BA18-D16995BB3088}'
$GPOCache = Get-item -Path "$env:windir\system32\GroupPolicy\Datastore\*\sysvol\contoso.com\Policies" | Select-Object -ExpandProperty Fullname
$i=0
foreach($GUID in $GPOGUIDs){
  IF(Test-Path -Path "$GPOCache\$GUID" -PathType Container -ErrorAction SilentlyContinue){
    $i++
  }
}
IF($i -ge $GPOGUIDs.Count){
  $true
}ELSE{
  $false
}
