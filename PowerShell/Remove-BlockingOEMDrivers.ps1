$ScanresultFile = 'C:\$WINDOWS.~BT\Sources\Panther\scanresult.xml'
$ErrorActionPreference = 'Stop'
TRY{
  [xml]$xml = Get-content -Path $ScanresultFile
  IF(!($file = (Test-Path -Path $ScanresultFile -PathType Leaf -ErrorAction SilentlyContinue).fullname)){$file = (new-item 'C:\windows\temp\Remove-driversLog.log' -Force).fullname}

  "*****************************"  | out-file -FilePath $file -Append
  "Starting on $(Get-Date)"  | out-file -FilePath $file -Append
  "File imported: $ScanresultFile" | out-file -FilePath $file -Append
  "*****************************"  | out-file -FilePath $file -Append
  "*** Files being modified: ***"  | out-file -FilePath $file -Append
 
  $DriverPackages = $xml.CompatReport.DriverPackages.DriverPackage
  Foreach($DriverPackage in $DriverPackages){
    If($DriverPackage.BlockMigration -eq $true){ 
      #pnputil.exe -f -d "$($DriverPackage.Inf)"
      "$($DriverPackage.Inf) Deleted" | out-file -FilePath $file -Append
    }
  }
  "*****************************`n*****************************"  | out-file -FilePath $file -Append
  "XML original content:"| out-file -FilePath $file -Append
  Get-Content -Path C:\Temp\ScanResult.xml | out-file -FilePath $file -Append
  "*****************************`n*****************************"  | out-file -FilePath $file -Append
}CATCH{
  $Line = $_.InvocationInfo.ScriptLineNumber
	"Error: on line $line"  | out-file -FilePath $file -Append
  "Error: $_"  | out-file -FilePath $file -Append
  "*****************************"  | out-file -FilePath $file -Append
  "*****Failed to run **********"  | out-file -FilePath $file -Append
}