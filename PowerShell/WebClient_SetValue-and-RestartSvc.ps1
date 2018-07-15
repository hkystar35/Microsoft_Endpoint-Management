Try{
  $Key = 'HKLM:\SYSTEM\CurrentControlSet\Services\WebClient\Parameters'
  $Name = 'FileAttributesLimitInBytes'
  $Value = '20000000'
  
  If(!(Test-Path -Path $Key)){
    $Key_Create = New-Item -Path $Key -Name $Name
    if($Key_Create){$Created = 'created'}
  }Else{$created = 'already there'}

  $Key_Value = New-ItemProperty -Path $Key -Name $Name -Value $Value -PropertyType DWORD -Force
  if($Key_Value){$Value_Created = $Value}

  $ServiceName = 'WebClient'
  Restart-Service $ServiceName

  Write-Output "Value set to $($Value_Created) and Key was $($Created) / $ServiceName service restarted"
}catch{Write-Output "Failed"}