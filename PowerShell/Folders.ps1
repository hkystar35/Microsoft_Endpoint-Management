$Apps = Import-CSV -Path 'C:\Temp\Organizeapps.csv'
#$StartLoc = Get-Location
#C:\Tools\importSCCM.ps1
#Set-Location ".\Applications\Software Deployments"
foreach($App in $Apps) {
  #IF(!(Test-Path $App.Vendor)){
  #  New-Item -Name "$($App.Vendor)" -Verbose
  #}
  $AppInput = get-cmapplication -Name $($App.Name)
  $AppInput | Move-CMObject -FolderPath ".\$($App.Vendor)"
  clear-variable appinput
}
#Set-Location $StartLoc