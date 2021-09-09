$Machines = 'ANDYOSBORN','JODYJENKS','BENFRANCISCO','RICHPACE'
$Machines | foreach{
Start-Process -FilePath C:\Tools\pstools\PsExec.exe -ArgumentList "-S -accepteula \\$_ winrm quickconfig -force" -Wait
    Invoke-Command -ComputerName $_ -ScriptBlock {
        get-disk | select DiskNumber,PartitionStyle,OperationalStatus,BusType,FriendlyName
        Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule "{00000000-0000-0000-0000-000000000108}"
        Invoke-WmiMethod -Namespace root\ccm -Class sms_client -Name TriggerSchedule "{00000000-0000-0000-0000-000000000113}"
    }
}