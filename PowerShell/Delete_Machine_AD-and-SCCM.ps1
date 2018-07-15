$Machine = Read-Host "Machine name to remove"
$SCCMServer = 'FQDN.domain.com'
$SiteCode = 'PAY'

$PingTest = Test-Connection -ComputerName $Machine -Count 1 -ErrorAction SilentlyContinue
$IPAddress = $PingTest.IPV4Address.IPAddressToString
if($PingTest){
  Write-Host "`nMachine $Machine is online, checking if on VPN. . ." -NoNewline
  if($IPAddress -like "10.0.*"){
    Write-Host "connected to VPN. Aborting." -BackgroundColor Red -ForegroundColor White
    Break
    }else{
      Write-Host "not connected to VPN, ok to proceed."
    }
  }elseif(!($PingTest)){
    Write-Host "`nMachine $Machine is offline, ok to proceed."
  }

Try{
    $ADName = Get-ADComputer $Machine -ErrorAction SilentlyContinue
    if($ADName){
      Write-host "Found in Active Directory."
      $ADObject = $true
    }
}catch{
    Write-Host "Could not find $Machine in Active Directory"
}

Try{
    $CMName = Get-WmiObject -ComputerName $SCCMServer -namespace root\sms\site_$($SiteCode) -class sms_r_system -filter "Name='$($Machine)'"
    if($CMName.IsAssignedToUser){
        $UDA = Get-SccmUDA -Computer $Machine -SiteCode $SiteCode -SiteServer $SCCMServer
    }
    if($CMName){
      Write-host "Found in ConfigMgr."
      $CMObject = $true
    }
}catch{
    Write-Host "Could not find $Machine in ConfigMgr. Aborting." -BackgroundColor Red -ForegroundColor White
    Break
}

if($ADName.name -eq $CMName.name){
 Write-Host "`nNames match:"
 Write-Host "`n"$adname.name"" -BackgroundColor Yellow -ForegroundColor Black -NoNewline
 Write-Host "- AD object" -NoNewline
 Write-Host "`n"$cmname.name"" -BackgroundColor Yellow -ForegroundColor Black -NoNewline
 Write-Host "- SCCM object, last user is "$UDA""
 Write-Host "`nContinue to DELETE both? (y/n): " -Foregroundcolor Red -NoNewline
 $ConfirmDelete = Read-Host
 Switch ($ConfirmDelete){
  Y {Write-Host "YES, deleting $Machine from Active Directory AND SCCM."; $DeleteMachine=$true}
  N {Write-Host "NO, skipping deleting $Machine."; $DeleteMachine=$false}
 }
 if($DeleteMachine -eq $true){
     try{
      if($ADObject){
        Write-Host "Deleting AD Object..." -NoNewline
        Remove-ADComputer -Identity $ADName.Name -Confirm:$false
        Write-Host "done!"
      }
      }catch{Write-Host "could not delete $Machine." -BackgroundColor Red -ForegroundColor White}
      try{
      if($CMObject){
        Write-Host "Deleting ConfigMgr Object..." -NoNewline
        Remove-CMDevice -Name $CMName.Name -force
        Write-Host "done!"
      }
      }catch{Write-Host "could not delete $Machine." -BackgroundColor Red -ForegroundColor White}
 }
}else{
 Write-Host "Names do not match. Please check your input."
 Break
}

FUNCTION Get-SccmUDA { 
Param([parameter(Mandatory = $true)]$Computer, 
$SiteCode, 
$SiteServer) 
(Get-WmiObject -ComputerName $SiteServer -Namespace root\sms\site_$SiteCode -Query ("Select  
 
SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_UserMachineRelationship.UniqueUserName,SMS_R_SYSTEM.Client FROM SMS_R_System JOIN SMS_UserMachineRelationship ON SMS_R_System.Name=SMS_UserMachineRelationship.ResourceName JOIN SMS_R_User ON SMS_UserMachineRelationship.UniqueUserName=SMS_R_User.UniqueUserName WHERE SMS_UserMachineRelationship.Types=1 AND SMS_R_SYSTEM.Name = '" + $computer + "'")|select -expand Sms_UserMachineRelationship).UniqueUserName 
}