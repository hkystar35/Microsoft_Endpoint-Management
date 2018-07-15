$storeNames = "TrustedPublisher","root"
foreach($storeName in $storeNames){
  $certString = ""
  $certString.Length
  #$certpw = 'FranceAuntBelfastFifty67'
  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store $storeName, LocalMachine
  $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
 
  $certByteArray = [System.Convert]::FromBase64String($certString)
  #$certpwByteArray = [System.Convert]::FromBase64String($certpw)

  $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
  #$cert.Import($certByteArray,$certpwByteArray)
  $cert.Import($certByteArray)
 
  $store.Add($cert)
  $store.Close()
}