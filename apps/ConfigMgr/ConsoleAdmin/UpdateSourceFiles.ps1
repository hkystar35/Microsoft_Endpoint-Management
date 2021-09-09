#$SourceFilePath = 'C:\Temp_Nic\configmgr\ConsoleAdmin\Source'
#$FileName = 'consoleadmin.msi'
$SourceFilePath = '\\kirk\it\Software\Dominik Reichl\KeePass Password Safe\2.37\Files'
$FileName = 'KeePass-2.37-Setup.exe'
$DestFolder = $PSScriptRoot + '\' + 'Files'

#region Get-MSIinfo
function Get-MSIinfo {
	param (
		[parameter(Mandatory = $true,HelpMessage='Full Path including file name')][ValidateNotNullOrEmpty()][System.IO.FileInfo]$Path,
		[parameter(Mandatory = $true,HelpMessage='Select info needed')][ValidateNotNullOrEmpty()][ValidateSet("ProductCode", "ProductVersion", "ProductName", "Manufacturer", "ProductLanguage", "FullVersion")][string]$Property
	)
	Process {
		try {
			# Read property from MSI database
			$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
			$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($Path.FullName, 0))
			$Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
			$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
			$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
			$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
			$Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
			
			# Commit database and close view
			$MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
			$View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)
			$MSIDatabase = $null
			$View = $null
			
			# Return the value
			return $Value
		} catch {
			Write-Warning -Message $_.Exception.Message; break
		}
	}
	End {
		# Run garbage collection and release ComObject
		[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null
		[System.GC]::Collect()
	}
}
#endregion
$FileNameFullPath = "$SourceFilePath\$FileName"
$FileExtension = [System.IO.Path]::GetExtension($FileNameFullPath)

if($FileExtension -eq '.msi'){
  $FileVersion = Get-MSIinfo -Path $SourceFilePath\$FileName -Property ProductVersion
}elseif($FileExtension -eq '.exe'){
  $Version = Get-ItemProperty -Path $SourceFilePath\$FileName
  if($Version.VersionInfo.FileVersion -eq $Version.VersionInfo.ProductVersion){
    $FileVersion = $Version.VersionInfo.FileVersion
  }elseif($Version.VersionInfo.FileVersion -ne $Version.VersionInfo.ProductVersion){
    Write-Output "Version mistmatch. Choose 1 or 2:`n 1) $($Version.VersionInfo.FileVersion)`n 2) $($Version.VersionInfo.ProductVersion)"
    $Choice = Read-Host -Prompt "Type 1 or 2"
    switch($choice){
      1 {$FileVersion = $Version.VersionInfo.FileVersion}
      2 {$FileVersion = $Version.VersionInfo.ProductVersion}
    }
  }
}

Write-Output " Filetype is $FileExtension`n FileVersion is $FileVersion"

$path = Get-ChildItem -Path $PSScriptRoot
$path | foreach{
  if($_.Attributes -eq 'Directory'){
    Write-output "$($_) is a folder name"
  }

  
}

if([System.Version]"$($path[0])" -gt [System.Version]"3.0.0.4080"){

}