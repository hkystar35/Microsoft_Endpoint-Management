#region Install Nuget and Trust PSGallery
TRY{
    Install-PackageProvider -Name 'Nuget' -Force -Confirm:$false -ErrorAction Stop
    Set-PackageSource -Name 'PSGallery' -Trusted -Force -Confirm:$false
} CATCH {
  Write-Log -Message "Could not install $PackageProvider" -Level Warn
  $Line = $_.InvocationInfo.ScriptLineNumber
  Write-Log -Message "Error: on line $line"
  THROW "Error: $_"
}
      
#endregion Install PackageProvider

#region Import Modules
$ModuleNames = 'PowerShellGet','Intune.HV.Tools' # array list
IF($ModuleNames){
  $Modules = Get-Module -ListAvailable
  foreach($ModuleName in $ModuleNames){
    IF($Modules.name -contains $ModuleName){
      Import-Module -Name $ModuleName -Global
      Write-Host "Imported module $ModuleName"
    }ELSE{
      Install-Module -Name $ModuleName -Confirm:$false -AllowClobber
      Write-Host "Installed module $ModuleName"
      Import-Module -Name $ModuleName -Global
      Write-Host "Imported module $ModuleName"
    }
  }
}ELSE{
  Write-Log -Message 'No modules to import'
}
#endregion Import Modules

$SourceISOFile = 'C:\Tools\ISO Files\SW_DVD9_Win_Pro_10_1909.4_64BIT_English_Pro_Ent_EDU_N_MLF_X22-28609.ISO'
#$SourceISOFile = 'C:\Tools\ISO Files\SW_DVD9_Win_Pro_10_1809.1_64BIT_English_Pro_Ent_EDU_N_MLF_X22-03114.ISO'
#$RefImageDestinationFile = 'C:\Tools\WindowsAutopilot\.hvtools\tenantVMs\wks1909ref.vhdx'

Initialize-HVTools -Path 'C:\Tools\WindowsAutopilot' -Reset
Add-ImageToConfig -IsoPath $SourceISOFile -ImageName "1909"
Add-TenantToConfig -TenantName 'contoso' -ImageName "1909" -AdminUpn 'hkystar35@contoso.com'
Add-NetworkToConfig -VSwitchName 'Default Switch'
Get-HVToolsConfig
New-ClientVM -TenantName 'contoso' -NumberOfVMs 1 -CPUsPerVM 1 -VMMemory 2GB
