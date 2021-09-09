$DomainControllers = Get-ADDomainController -Filter * | select -Property hostname
$AllDCTimes = @()
$Users = Get-ADGroupMember -Identity _EUCEngineers | select -ExpandProperty SamAccountName
foreach($DC in $DomainControllers){
    IF(Test-Connection -ComputerName $DC.hostname -Protocol WSMan -WsmanAuthentication Negotiate -Count 1 -Quiet -ErrorAction SilentlyContinue){
        foreach($User in $Users){
            $DCTime = Get-ADuser -Identity $User -Properties samaccountname,lastlogontimestamp,lastlogon -Server $DC.hostname | select -Property lastlogontimestamp,samaccountname,lastlogon -Last 1
            $AllDCTimes += New-Object -TypeName PSObject -Property @{
                UserName = $DCTime.samaccountname
                LastLogonTimestamp = [datetime]::FromFileTime($DCTime.lastlogontimestamp)
                LastLogon = [datetime]::FromFileTime($DCTime.lastlogon)
                DC = $DC.Hostname
            }
        }
    }
}
$AllDCTimes | Sort-Object LastLogon,lastlogontimestamp | Format-Table -AutoSize