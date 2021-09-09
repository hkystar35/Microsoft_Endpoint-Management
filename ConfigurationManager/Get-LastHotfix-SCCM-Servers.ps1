$StartTime = Get-Date
#$Servers = Get-ADComputer -Filter {(Name -like '*-SCCM-*' -or Name -like '*-IBCM-*' -or Name -like '*-PRINT-*' -or Name -like '*-NUANCE-*' -or Name -like '*-EQUITRAC-*') -and (OperatingSystem -like "*windows*server*")} -Properties OperatingSystem
$Servers = Get-ADComputer JOELTOBECKSEN
$Results = @()
foreach ($Server in $Servers){
    $Hotfixes = Get-WmiObject -ComputerName $Server.Name -Class win32_quickfixengineering | select -Last 10
    foreach($Hotfix in $Hotfixes){
        $Results += New-Object -TypeName 'PSObject' -Property @{
		        MachineName	 = $Server.Name
		        LastHotfix   = $Hotfix.HotFixID
		        LastHotfixInstallDate = $Hotfix.InstalledOn
                OS = $Server.OperatingSystem
        }
    }
}
$EndDate = Get-Date
$elapsedTime = New-TimeSpan -Start $StartTime -End $EndDate
Write-Host "Started at $StartTime `n Elapsed time: $($elapsedTime.TotalSeconds)"
$Results | Sort-Object LastHotfixInstallDate,MachineName | Format-Table MachineName,OS,LastHotfix,LastHotfixInstallDate -AutoSize
#Clear-Variable Servers,Results,Server,Hotfix