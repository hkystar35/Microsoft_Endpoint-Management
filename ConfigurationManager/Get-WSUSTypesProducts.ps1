$server = Get-WsusServer -name ah-sccm-01 -portnumber 8530

$prods = Get-WsusProduct -UpdateServer $server

$prods.Product | ?{$_.UpdateSource -eq "Other"} | Format-Table type, title -Autosize

($prods.Product | ?{$_.UpdateSource -eq "Other"} ).count