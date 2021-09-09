#
$Machines = "scottbode"
$Service = "WinRM"

foreach($Machine in $Machines){
    $Status = Get-Service -ComputerName $Machine -Name $Service | select -ExpandProperty status
    if($Status -eq "Running"){
        Write-Host "Status is: $Status"
        }elseif($Status -eq "Stopped"){
            Write-Host "Status is: $Status"
            Write-Host "Starting $Service..."
            Set-Service -ComputerName $Machine -Name $Service -StartupType Automatic

        }
}
#>