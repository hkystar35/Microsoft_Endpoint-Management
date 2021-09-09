$ScriptName = 'Get-BlockingTypes'
#$ScanresultFile = 'C:\$WINDOWS.~BT\Sources\Panther\scanresult.xml'
$CompatXMLsPath = 'C:\Users\hkystar35\Downloads\ann\Panther'
$CompatXMLs = Get-ChildItem -Path $CompatXMLsPath\* -Filter "CompatData_*.xml" | select -ExpandProperty Fullname

$ErrorActionPreference = 'Stop'
$table = @(
    foreach($XMLfile in $CompatXMLs){
        TRY{
          [xml]$xml = Get-content -Path $XMLfile
          IF(!($file = (Test-Path -Path $XMLfile -PathType Leaf -ErrorAction SilentlyContinue).fullname)){$file = (new-item "$env:windir\logs\$ScriptName.log" -Force).fullname}

          "*****************************"  | out-file -FilePath $file -Append
          "Starting on $(Get-Date)"  | out-file -FilePath $file -Append
          "File imported: $XML" | out-file -FilePath $file -Append
          "*****************************"  | out-file -FilePath $file -Append
          "*** Files being modified: ***"  | out-file -FilePath $file -Append
 
          $BlockingTypes = $xml.CompatReport.Hardware.HardwareItem | select HardwareType,@{L="BlockingTypeValue";E={$_.CompatibilityInfo.BlockingType}}
      
          $BlockingTypes #| where {$_.BlockingTypeValue -ne 'None'}
          "*****************************`n*****************************"  | out-file -FilePath $file -Append
          #"XML original content:"| out-file -FilePath $file -Append
          #Get-Content -Path C:\Temp\ScanResult.xml | out-file -FilePath $file -Append
          "*****************************`n*****************************"  | out-file -FilePath $file -Append
        }CATCH{
          $Line = $_.InvocationInfo.ScriptLineNumber
	        "Error: on line $line"  | out-file -FilePath $file -Append
          "Error: $_"  | out-file -FilePath $file -Append
          "*****************************"  | out-file -FilePath $file -Append
          "*****Failed to run **********"  | out-file -FilePath $file -Append
        }
    }
)
$table
