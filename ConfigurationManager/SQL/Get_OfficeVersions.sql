SELECT DISTINCT  
  SYS.Name0
  ,ARP.DisplayName0 As 'Software Name'
  ,ARP.Version0 As 'Version'
  ,ARP.InstallDate0 As 'Installed Date'
 FROM 
  dbo.v_R_System As SYS
  INNER JOIN dbo.v_FullCollectionMembership FCM On FCM.ResourceID = SYS.ResourceID 
  INNER JOIN dbo.v_Add_REMOVE_PROGRAMS As ARP On SYS.ResourceID = ARP.ResourceID 
 WHERE   
 (ARP.DisplayName0 LIKE '%Microsoft Office Standard%'
 OR ARP.DisplayName0 LIKE 'Microsoft Office Professional%'
 OR ARP.DisplayName0 LIKE 'Microsoft Office Enterprise %')
 ORDER BY Version0 Desc