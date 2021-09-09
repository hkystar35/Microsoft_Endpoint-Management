## Variables
 
# Enter ComputerName
$ComputerName = $env:computername
# Enter file share for text logs
$ServerPath = "\\kirk\it\logs\SCCM\DiskSpaceReports"
# Format Date
$TodaysDate = Get-Date -Format "yyyy-MM-dd HH:MM:ss"
 
# Enter email details
$SendEmail = "yes"
$smtpServer = "post.contoso.com"
$smtpFrom = "$ComputerName@contoso.com"
[string[]]$smtpTo = "hkystar35@contoso.com"#,jjenks@contoso.com,chofman@contoso.com"
$messageSubject = "Drive Space Report for $ComputerName"
 
## Get and email the data
 
# Get drive and directory data
$D1 = "c:"
$Folder1 = "RemoteInstall"
$colItems = (Get-ChildItem $d1\$Folder1 -recurse -Force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
$Folder1a = "{0:N2}" -f ($colItems.sum / 1GB)

$D2 = "c:"
$Folder2 = "SMSPKGC$" 
$colItems = (Get-ChildItem $d2\$Folder2 -recurse -Force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
$Folder2a = "{0:N2}" -f ($colItems.sum / 1GB)

$D3 = "c:"
$Folder3 = "SCCMContentLib" 
$colItems = (Get-ChildItem $d3\$Folder3 -recurse -Force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
$Folder3a = "{0:N2}" -f ($colItems.sum / 1GB)

$D4 = "c:"
$Folder4 = "WSUS_Updates"
if(test-path -Path $d4\$Folder4){
    $colItems = (Get-ChildItem $d4\$Folder4 -recurse -Force -ErrorAction SilentlyContinue | Measure-Object -property length -sum)
    $Folder4a = "{0:N2}" -f ($colItems.sum / 1GB)
}else{
    $Folder4a = "N\A"
}
 
$data = Get-WmiObject -Class Win32_Volume -ComputerName $ComputerName | Where-Object {$_.DriveLetter -eq 'C:'} | Select Capacity,FreeSpace,SystemName,DriveLetter
 
$capacity = "{0:N2}" -f ($data.capacity / 1GB)
$freespace = "{0:N2}" -f ($data.freespace / 1GB)
$systemname = $data.SystemName
$driveletter = $data.DriveLetter
 
# Add data to a simple text 'table'
$table = "`nReport as of $TodaysDate`nServer: $systemname`n`n${Folder1}:`t`t$Folder1a GB`n${Folder2}:`t`t$Folder2a GB`n${Folder3}:`t$Folder3a GB`n${Folder4}:`t$Folder4a GB`nDiskCapacity:`t`t$capacity`nAvailableSpace:`t`t$freespace"

$InfoFile = "$ServerPath\$ComputerName.log"
if(!(Test-Path -Path $InfoFile)){
    New-Item -Path $InfoFile -ItemType File
}
$table2= "$TodaysDate  Server: $systemname  //  ${Folder1}: $Folder1a GB  //  ${Folder2}: $Folder2a GB  //  ${Folder3}: $Folder3a GB  //  ${Folder4}: $Folder4a GB  //  DiskCapacity: $capacity  //  AvailableSpace: $freespace"
Add-Content -Path $InfoFile -Value $table2

# Send data as an email
if ($SendEmail -eq "Yes")
{
$message = New-Object System.Net.Mail.MailMessage $smtpfrom, $smtpto
$message.Subject = $messageSubject
$message.Body = $table
$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($message)
}
<# SQL Stuff
 
# Database info
$dataSource = “MySQLServer\INST_SCCM”
$database = “SCCM_Server_Data”
 
# Open a connection
cls
Write-host "Opening a connection to '$database' on '$dataSource'"
$connectionString = “Server=$dataSource;Database=$database;Integrated Security=SSPI;”
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()
 
# Set and run the SQL Command
$update = "UPDATE DiskSpace SET WSUS_Updates = '$WSUS_Updates', SMSPKGx = '$SMSPKGG', SCCMContentLib = '$SCCMContentLib', DiskCapacity = '$capacity', AvailableSpace = '$freespace' WHERE SERVER = '$ComputerName'"
$command = $connection.CreateCommand()
$command.CommandText = $update
$command.ExecuteNonQuery()
 
# Close the connection
$connection.Close()
#>
