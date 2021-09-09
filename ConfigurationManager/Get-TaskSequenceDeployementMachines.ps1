<#
    Get machines from a TS deployment depending on Success status of overall TS
    Useful for deploying additional items to successful TS installs

#

[cmdletbinding()]
PARAM(
    [string]$Name,
    $status
)

#>

$SiteServer = "AH-SCCM-01"
$SiteCode = "PAY"
$ComputerName = "KIRAHOSKEY"
$TimeFrame = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime((Get-Date).AddDays(-1))
 
$Status = 1
$TSSummary = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_StatusMessage -ComputerName $SiteServer -Filter "(Component like 'Task Sequence Engine') AND (MachineName like '$($ComputerName)' AND (MessageID = 11143))" -ErrorAction Stop
$StatusMessageCount = ($TSSummary | Measure-Object).Count
if (($TSSummary -ne $null) -and ($StatusMessageCount -eq 1)) {
    foreach ($Object in $TSSummary) {
        if (($Object.Time -ge $TimeFrame)) {
            $Status = 0
        }
    }
}
elseif (($TSSummary -ne $null) -and ($StatusMessageCount -ge 2)) {
    foreach ($Object in $TSSummary) {
        if ($Object.Time -ge $TimeFrame) {
            $Status = 0
        }
    }
}
else {
    $Status = 1
}
$Status