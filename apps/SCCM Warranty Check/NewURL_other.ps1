$SerialNumber = "PC0LJ68A"

$URL = "https://csp.lenovo.com/ibapp/il/WarrantyStatus.jsp?serial=$($SerialNumber)"
    $WebRequestResult = Invoke-WebRequest -Uri $URL
    $TDTagNames = $WebRequestResult.ParsedHtml.getElementsByTagName("TD")
    $TDTagNamesCount = ($TDTagNames | Measure-Object).Count
    $YearList = New-Object -TypeName System.Collections.ArrayList