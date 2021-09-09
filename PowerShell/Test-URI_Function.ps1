FUNCTION Test-URI {
  param([string]$URI)
  
  TRY{
    $result = [bool](Invoke-WebRequest -Uri $URI -Method Head -UseBasicParsing -DisableKeepAlive -ErrorAction SilentlyContinue)
  }CATCH{
    $result = $false
  }
  $result
}

$URI = 'https://www.printerlogic.com/browser-extension/'

$userAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Firefox
#$userAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer
$Page = Invoke-WebRequest -Uri $URI -UserAgent $userAgent -SessionVariable websession