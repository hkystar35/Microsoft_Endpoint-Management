########################################
# Remove Windows 10 Modern Apps (System)
########################################

# To find app names use: 
# Get-AppxProvisionedPackage -online  | Select DisplayName, PackageName
#region AppXProvisionedPackages
$AppXProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object -filterscript {$_.DisplayName -NotLike 
  "*WindowsCamera*" -and $_.DisplayName -NotLike 
  "*VCLibs.140.00*" -and $_.DisplayName -NotLike 
  "*NET.Native*" -and $_.DisplayName -NotLike 
  "*Windows.Photos*" -and $_.DisplayName -NotLike 
  "*AccountsControl*" -and $_.DisplayName -NotLike 
  "*PPIProjection*" -and $_.DisplayName -NotLike 
  "*DesktopView*" -and $_.DisplayName -NotLike 
  "*Windows.PrintDialog*" -and $_.DisplayName -NotLike 
  "*Windows.WindowPicker*" -and $_.DisplayName -NotLike 
  "*WindowsAlarms*" -and $_.DisplayName -NotLike 
  "*WindowsSoundRecorder*" -and $_.DisplayName -NotLike 
  "*WindowsCalculator*" -and $_.DisplayName -NotLike 
  "*MSPaint*" -and $_.DisplayName -NotLike 
  "*MicrosoftStickyNotes*" -and $_.DisplayName -NotLike 
  "*DesktopAppInstaller*"} | Sort-Object DisplayName
#endregion

#region AppXPackages
$AppXPackages = Get-AppxPackage | Where-Object -filterscript {$_.Name -NotLike 
  "*WindowsCamera*" -and $_.Name -NotLike 
  "*VCLibs.140.00*" -and $_.Name -NotLike 
  "*NET.Native*" -and $_.Name -NotLike 
  "*Windows.Photos*" -and $_.Name -NotLike 
  "*AccountsControl*" -and $_.Name -NotLike 
  "*PPIProjection*" -and $_.Name -NotLike 
  "*DesktopView*" -and $_.Name -NotLike 
  "*Windows.PrintDialog*" -and $_.Name -NotLike 
  "*Windows.WindowPicker*" -and $_.Name -NotLike 
  "*WindowsAlarms*" -and $_.Name -NotLike 
  "*WindowsSoundRecorder*" -and $_.Name -NotLike 
  "*WindowsCalculator*" -and $_.Name -NotLike 
  "*MSPaint*" -and $_.Name -NotLike 
  "*MicrosoftStickyNotes*" -and $_.Name -NotLike 
  "*DesktopAppInstaller*"} | Sort-Object Name
#endregion


$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

#Start output file
New-Item -Path "$env:windir\Logs\Software" -ItemType Directory -Force
Write-Output "-----------------------------------------------------------------" | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber
Write-Output "$date Appx Removal Script" | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber
Write-Output "-----------------------------------------------------------------" | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber
Write-Output "-- Removing AppXProvisionedPackages --" | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber
Write-Output "-----------------------------------------------------------------" | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber

$AppXProvisionedPackages | foreach {
  try{
      Remove-AppxProvisionedPackage -PackageName "$($_.PackageName)" -AllUsers -Online -LogPath "$env:windir\Logs\Software\RemoveAppx_$($_.DisplayName).log"
      Write-Output "AppXProvisionedPackages Removed - $($_.DisplayName)" | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber
  }
  catch
  {
    Write-Output "Critical error removing AppXProvisionedPackage: $($_.Name)"  | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber
  }
}


Write-Output "-----------------------------------------------------------------" | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber
Write-Output "-- Removing AppXPackages --" | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber
Write-Output "-----------------------------------------------------------------" | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber

$AppXPackages | foreach {
  try{
      Remove-AppxPackage -Package "$($_.PackageFullName)" -ErrorAction SilentlyContinue
      Write-Output "AppxPackage Removed - $($_.Name)" | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber
  }
  catch
  {
    Write-Output "Critical error removing AppXPackage: $($_.Name)"  | Out-File -FilePath "$env:windir\Logs\Software\RemoveAppx.log" -Append -NoClobber
  }
}