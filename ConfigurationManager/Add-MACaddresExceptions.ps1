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

<#
$MACaddresses = '3C:18:A0:10:15:42',
'3C:18:A0:0F:DF:5F',
'3C:18:A0:0F:DE:5C',
'3C:18:A0:0F:DD:D9',
'3C:18:A0:0F:DF:5A',
'3C:18:A0:0F:D8:EE',
'3C:18:A0:0F:DF:8B',
'3C:18:A0:0F:DF:68',
'3C:18:A0:0F:DF:46',
'3C:18:A0:0F:DF:6D',
'3C:18:A0:02:FB:4F',
'A0:CE:C8:0C:15:9D',
'00:24:9B:1E:61:5C',
'58:EF:68:C2:9C:09',
'3C:18:A0:10:44:1C',
'3C:18:A0:10:43:DF',
'3C:18:A0:10:53:95',
'3C:18:A0:10:43:EC',
'3C:18:A0:10:44:2D'
#>

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
