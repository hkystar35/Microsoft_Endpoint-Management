

$MACaddresses = ''

$PrimarySite = "sccmsite.domain.com"
#$MACaddress = Read-Host -Prompt "MAC Address"
$CurrentMACs = Get-WmiObject -Class SMS_CommonMacAddresses -ComputerName "$PrimarySite" -Namespace root\sms\Site_PAY -Property MACAddress | select -ExpandProperty macaddress
foreach($MACaddress in $MACaddresses){
    if($CurrentMACs -notcontains "$MACaddress"){
        Write-Host "MAC not present, adding to exception list."
        Set-WmiInstance -computerName $PrimarySite  -Namespace root\sms\Site_PAY -Class SMS_CommonMacAddresses -Argument @{MACAddress="$MACaddress"}
    }elseif($CurrentMACs -contains "$MACaddress"){
        Write-Host "MAC already present."
    }
}