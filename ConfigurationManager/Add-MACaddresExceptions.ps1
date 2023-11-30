$PrimarySite = "ah-sccm-01.contoso.com"

FUNCTION Get-DevicesByMAC{
param($MACADDRESS)

    $ServerInstance = "AH-SCCM-01.contoso.com"
    $DB = "CM_PAY"

    # SQL query to find devices that have the inputted MAC associated to it
    $SQLQuery = @"
SELECT
v_RA_System_ResourceNames.Resource_Names0 AS [ResourceName],
v_RA_System_MACAddresses.MAC_Addresses0 AS [MACaddress]

FROM
v_RA_System_MACAddresses INNER JOIN
v_RA_System_ResourceNames ON v_RA_System_MACAddresses.ResourceID = v_RA_System_ResourceNames.ResourceID

WHERE
MAC_Addresses0 like '%$MACADDRESS%'
"@
	
    $SQLResults = Invoke-Sqlcmd -Query $SQLQuery -ServerInstance $ServerInstance -Database $DB
    $SQLResults
}



$MACaddresses = Read-Host -Prompt "MAC Address"

$CurrentMACs = Get-WmiObject -Class SMS_CommonMacAddresses -ComputerName "$PrimarySite" -Namespace root\sms\Site_PAY -Property MACAddress | select -ExpandProperty macaddress

$Results = @()
$SQLMACs = @()
foreach($MACaddress in $MACaddresses){
    if($CurrentMACs -notcontains "$MACaddress"){
        $Status = Set-WmiInstance -computerName $PrimarySite  -Namespace root\sms\Site_PAY -Class SMS_CommonMacAddresses -Argument @{MACAddress="$MACaddress"}
        $Status = "$($Status.MACAddress) added to server $($Status.PSComputerName)."
    }elseif($CurrentMACs -contains "$MACaddress"){
        $Status = "MAC already present."
    }

    $Results += New-Object -TypeName psobject -Property @{
        MAC = $MACaddress
        Status = $Status
        CurrentObjects = Get-DevicesByMAC -MACADDRESS $MACaddress | select -ExpandProperty ResourceName | Out-String
    }

    $Status = $null
}

$Results | ft -AutoSize
