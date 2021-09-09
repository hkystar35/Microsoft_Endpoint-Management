# Update content - OSD
TRY {
		$StartingLocation = Get-Location
		Import-Module -Name $env:SMS_ADMIN_UI_PATH.Replace('\bin\i386', '\bin\ConfigurationManager.psd1')
		Write-Output "Changing location to $($SiteCode.Name):\"
		$SiteCode = Get-PSDrive -PSProvider CMSITE
		Set-Location -Path "$($SiteCode.Name):\"
		Write-Output "done."
	} CATCH {
		Write-Output 'Could not import SCCM module'
		Set-Location -Path $StartingLocation
		BREAK
	}

TRY{
    $Machine = 'aaronmcnutt'
    $User = 'amcnutt'
    
    $CMUser = Get-CMUser -Name $User | select -Property *
    $CMDevice = Get-CMDevice -Name $Machine | select -Property *
    $CMUserDeviceAffinity = Get-CMUserDeviceAffinity -DeviceName $CMDevice.Name

    $CMUserDeviceAffinity | foreach{
        
    }


IF($Machine -and $User){
  $PostName = $User.Substring(1,($User.Length -1))

  if($Machine.EndsWith($PostName)){
    'set device affinity'
  }Else{
    'names dont match'
  }
}ELSE{
  'no last loggedon user'
}
}
Catch{

}
finally{
        Set-Location -Path $StartingLocation
}