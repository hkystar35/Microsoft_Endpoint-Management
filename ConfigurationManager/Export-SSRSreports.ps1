[string]$Global:Component = 'Begin-Script'
#region FUNCTION Write-Log
	FUNCTION Write-Log {
<#
	.SYNOPSIS
		Create log file
	
	.DESCRIPTION
		Logs messages in Configuration Manager-specific format for easy cmtrace.exe reading
	
	.PARAMETER Message
		Value added to the log file.
	
	.PARAMETER Level
		Severity for the log entry.
	
	.PARAMETER FileName
		Name of the log file that the entry will written to.
	
	.PARAMETER LogsDirectory
		A description of the LogsDirectory parameter.
	
	.EXAMPLE
				PS C:\> Write-Log -Message 'Value1'
	
	.NOTES
		Additional information about the function.
#>
		
	[CmdletBinding()]
		PARAM
		(
			[Parameter(Mandatory = $true,
					   HelpMessage = 'Value added to the log file.')][ValidateNotNullOrEmpty()][string]$Message,
			[Parameter(Mandatory = $false,
				   HelpMessage = 'Severity for the log entry.')][ValidateNotNullOrEmpty()][ValidateSet('Error', 'Warn', 'Info')][string]$Level = "Info",
			[Parameter(Mandatory = $false,
					   HelpMessage = 'Name of the log file that the entry will written to.')][ValidateNotNullOrEmpty()][string]$FileName = "$($ScriptName).log",
			[string]$LogsDirectory = "$env:windir\Logs"
		)
		
		# Determine log file location
		IF ($FileName.Length -le 4) {
			$FileName = "GenericScriptLog_$(Get-Date -Format yyyy-MM-dd)$FileName"
		}
		$LogFilePath = Join-Path -Path $LogsDirectory -ChildPath $FileName
		
		# Construct time stamp for log entry
		IF (-not (Test-Path -Path 'variable:global:TimezoneBias')) {
			[string]$global:TimezoneBias = [System.TimeZoneInfo]::Local.GetUtcOffset((Get-Date)).TotalMinutes
			IF ($TimezoneBias -match "^-") {
				$TimezoneBias = $TimezoneBias.Replace('-', '+')
		}
		ELSE {
				$TimezoneBias = '-' + $TimezoneBias
			}
		}
		$Time = -join @((Get-Date -Format "HH:mm:ss.fff"), $TimezoneBias)
		
		# Construct date for log entry
		$Date = (Get-Date -Format "MM-dd-yyyy")
		
		# Construct context for log entry
		$Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
		
		# Switch Severity to number
		SWITCH ($Level) {
			"Info"	{
				$Severity = 1
			}
			"Warn"  {
				$Severity = 2
			}
			"Error" {
				$Severity = 3
			}
			default {
				$Severity = 1
			}
		}
		
		# Construct final log entry
		$LogText = "<![LOG[$($Message)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""$($component)"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
		
		# Add value to log file
		TRY {
			Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop -WhatIf:$false
		} CATCH [System.Exception] {
			Write-Warning -Message "Unable to append log entry to $($FileName) file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
		}
	}
	#endregion FUNCTION Write-Log
 Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "

#region FUNCTION Export-SSRSCustomReports
FUNCTION Export-SSRSCustomReports {
  <#
      .SYNOPSIS
      Export of all SSRS reports datasources and images
	
      .DESCRIPTION
      This PowerShell script exports all (or filtered) reports, data sources and images directly from the ReportServer database to a specified folder. For the file name the complete report path is used; for file name invalid characters are replaced with a -.
      Reports are exported with .rdl as extension, data sources with .rds and resources without any additional extension.
      Please change the "Configuration data" below to your enviroment.
      Works with SQL Server 2005 and higher versions in all editions.
      Requires SELECT permission on the ReportServer database.
	
      .PARAMETER server
      SQL Server Instance
	
      .PARAMETER database
      ReportServer Database name
	
      .PARAMETER folder
      Path to Export reports to
	
      .EXAMPLE
      Export-SSRSCustomReports
      explains how to use the command
      can be multiple lines
	
      .EXAMPLE
      Export-SSRSCustomReports
      another example
      can have as many examples as you like
	
      .NOTES
      Author  : Olaf Helper
      Requires: PowerShell Version 1.0, Ado.Net assembly
	
      .LINK
      GetSqlBinary: http://msdn.microsoft.com/en-us/library/system.data.sqlclient.sqldatareader.getsqlbinary.aspx
  #>
	
  [CmdletBinding()]
  PARAM
  (
    [Parameter(Mandatory = $false,
           Position = 0)][ValidateNotNullOrEmpty()][string]$Server,
    [Parameter(Mandatory = $false,
           Position = 1)][ValidateNotNullOrEmpty()][string]$Database,
    [Parameter(Mandatory = $false,
           Position = 2)][ValidateNotNullOrEmpty()][System.IO.DirectoryInfo]$folder
  )
	
  # Select-Statement for file name & blob data with filter. 
  $sql = @"
SELECT CT.[Path]
,CT.[Type]
,CONVERT(varbinary(max), CT.[Content]) AS BinaryContent
,CT.CreatedByID
,U.UserName
FROM dbo.[Catalog] AS CT
join Users U on U.UserID = ct.CreatedByID
WHERE CT.[Type] IN (2, 3, 5)
and U.UserName != 'NT AUTHORITY\SYSTEM'
ORDER BY CreatedByID
"@
	
  # Open ADO.NET Connection with Windows authentication. 
  $con = New-Object Data.SqlClient.SqlConnection;
  $con.ConnectionString = "Data Source=$server;Initial Catalog=$database;Integrated Security=True;";
  $con.Open();
	
  Write-Log -Message "Starting...";
	
  # New command and reader. 
  $cmd = New-Object Data.SqlClient.SqlCommand $sql, $con;
  $rd = $cmd.ExecuteReader();
	
  $invalids = [System.IO.Path]::GetInvalidFileNameChars();
  # Looping through all selected datasets. 
  WHILE ($rd.Read()) {
    TRY {
      # Get the name and make it valid. 
      $name = $rd.GetString(0);
      FOREACH ($invalid IN $invalids) {
        $name = $name.Replace($invalid, "-");
      }
			
      IF ($rd.GetInt32(1) -eq 2) {
        $name = $name + ".rdl";
      } ELSEIF ($rd.GetInt32(1) -eq 5) {
        $name = $name + ".rds";
      }
			
      Write-Log -Message "Exporting $name"
			
      $name = [System.IO.Path]::Combine($folder, $name);
			
      # New BinaryWriter; existing file will be overwritten. 
      $fs = New-Object System.IO.FileStream ($name), Create, Write;
      $bw = New-Object System.IO.BinaryWriter($fs);
			
      # Read of complete Blob with GetSqlBinary 
      $bt = $rd.GetSqlBinary(2).Value;
      $bw.Write($bt, 0, $bt.Length);
      $bw.Flush();
      $bw.Close();
      $fs.Close();
    } CATCH {
      Write-Log -Message "$($_.Exception.Message)"
    } FINALLY {
      $fs.Dispose();
    }
  }
	
  # Closing & Disposing all objects 
  $rd.Close();
  $cmd.Dispose();
  $con.Close();
  $con.Dispose();
	
  Write-Log -Message "Finished"
}
#endregion FUNCTION Export-SSRSCustomReports