'Get-WinEvent takes {0} milliseconds to find {1} events' -f (Measure-Command -Expression {
    $Params = @{ 
      FilterHashtable = @{Logname = 'System';ID = "1074","6008","6009"}
    }   
    $Count = (Get-WinEvent @Params).count
}).TotalMilliseconds,$Count
Remove-Variable Params,count

'Get-EventLog takes {0} milliseconds to find {1} events' -f (Measure-Command -Expression {
    $Params = @{ 
      Logname = 'System'
      InstanceId = "2147484722","2147489656","2147489657"
    }   
    $Count = (Get-EventLog @Params).count
}).TotalMilliseconds,$Count
Remove-Variable Params,count

'Get-WMIObject takes {0} milliseconds to find {1} events' -f (Measure-Command -Expression {
    $Params = @{ 
      Class  = 'Win32_NTLogEvent' 
      Filter  = "LogFile = 'System' and EventCode = 6009 or EventCode = 6008 or EventCode = 1074" 
    }    
    $Count = (Get-WmiObject @Params).count
}).TotalMilliseconds,$Count
Remove-Variable Params,count