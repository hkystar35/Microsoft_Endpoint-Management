FUNCTION Get-SccmUDA { 
Param([parameter(Mandatory = $true)]$Computer, 
$SiteCode, 
$SiteServer) 
(Get-WmiObject -ComputerName $SiteServer -Namespace root\sms\site_$SiteCode -Query ("Select  
 
SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_UserMachineRelationship.UniqueUserName,SMS_R_SYSTEM.Client FROM SMS_R_System JOIN SMS_UserMachineRelationship ON SMS_R_System.Name=SMS_UserMachineRelationship.ResourceName JOIN SMS_R_User ON SMS_UserMachineRelationship.UniqueUserName=SMS_R_User.UniqueUserName WHERE SMS_UserMachineRelationship.Types=1 AND SMS_R_SYSTEM.Name = '" + $computer + "'")|select -expand Sms_UserMachineRelationship).UniqueUserName 
}
$results = Get-SccmUDA -Computer nichkystar35 -SiteCode PAY -SiteServer ah-sccm-01

Write-Host "the user is: $results"
