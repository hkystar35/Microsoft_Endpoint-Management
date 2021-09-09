Invoke-Command -ComputerName SHARIMASON <#MELISSAPERLAS STEVEBEAUCHAMP ALYSONSTERMER#> -ScriptBlock {
   TRY{
    # Get HKU SID paths
    $SIDS = Get-ChildItem -Path Registry::HKEY_USERS | ?{$_.pschildname.Length -gt 19 -and $_.pschildname -like "S-1-5-*" -and $_.pschildname -notlike "*_Classes"} #| select -ExpandProperty Name
    # Get Outlook current version
    $OutlookVersion = (Get-ItemProperty HKLM:\SOFTWARE\Classes\Outlook.Application\CurVer)."(default)".Replace("Outlook.Application.", "")
    # Get plugin name
    $searchstring = '*biscom*'
    # Reg Keys to create, modify, or delete
    foreach($SID in $SIDS){
      $HKUPath = "Registry::HKEY_USERS\" + $SID.PSChildName
        $AddinName = Get-ChildItem -Path "$HKUPath\SOFTWARE\Microsoft\Office\Outlook\Addins\*" -ErrorAction SilentlyContinue | Where-Object{$SID.PSChildName -like "$($searchstring)"} | Select-Object -ExpandProperty pschildname -Last 1 -ErrorAction SilentlyContinue
      IF(!$AddinName){
        $AddinName = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Office\Outlook\Addins\*' -ErrorAction SilentlyContinue | Where-Object{$SID.PSChildName -like "$($searchstring)"} | Select-Object -ExpandProperty pschildname -Last 1 -ErrorAction SilentlyContinue
      }
      IF($AddinName){
      <#
      IF(!(Test-Path -Path "$HKUPath\Software\Policies\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\AddinList")){
        New-Item -Path "$HKUPath\Software\Policies\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\AddinList" -Force
      }
      Set-ItemProperty -Path "$HKUPath\Software\Policies\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\AddinList" -Name $AddinName -Value 1 -ErrorAction SilentlyContinue
      IF(!(Test-Path -Path "$HKUPath\Software\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\DoNotDisableAddinList")){
        New-Item -Path "$HKUPath\Software\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\DoNotDisableAddinList" -Force
      }
      Set-ItemProperty -Path "$HKUPath\Software\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\DoNotDisableAddinList" -Name $AddinName -Value 1 -ErrorAction SilentlyContinue
      Remove-Item -Path "$HKUPath\Software\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\DisabledItems" -ErrorAction SilentlyContinue
      New-Item -Path "$HKUPath\Software\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\DisabledItems" -Force -ErrorAction SilentlyContinue
      Remove-Item -Path "$HKUPath\Software\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\CrashingAddinList" -ErrorAction SilentlyContinue
      New-Item -Path "$HKUPath\Software\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\CrashingAddinList" -Force -ErrorAction SilentlyContinue
      Set-ItemProperty -Path "$HKUPath\Software\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency" -Name "CheckPoint" -Value 1 -PassThru -ErrorAction SilentlyContinue
      # Check new keys
      #>
      $ResiliencyAddinValue = Get-ItemProperty -Path "$HKUPath\Software\Policies\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\AddinList" -Name $AddinName -ErrorAction SilentlyContinue
      $DoNotDisableAddin = Get-ItemProperty -Path "$HKUPath\Software\Microsoft\Office\$OutlookVersion.0\Outlook\Resiliency\DoNotDisableAddinList" -Name $AddinName -ErrorAction SilentlyContinue
      Write-Output '{0} {1} {2};{3} {4}' -f ($AddinName),(Split-Path -Path $ResiliencyAddinValue.PSParentPath -Leaf),($ResiliencyAddinValue.$AddinName),($DoNotDisableAddin.PSChildName),($DoNotDisableAddin.$AddinName) -ErrorAction SilentlyContinue
      #>
      }ELSEIF(!$AddinName){
        throw 1
      }
    }
    }
    CATCH{
        $Line = $_.InvocationInfo.ScriptLineNumber
        "Error was in Line $line"
        Write-Host "Error: $_" #-Level Error
        Write-Host "Error: on line $line" #-Level Error
    }
}