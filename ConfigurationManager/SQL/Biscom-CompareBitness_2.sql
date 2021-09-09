SELECT DISTINCT  
  SYS.Name0
  ,ARP.DisplayName0 As 'Office Name'
  ,ARP.DisplayName0 As 'Office Bitness'
  ,ARP.Version0 As 'Version'
  ,ARP2.DisplayName0 As 'Biscom Name'
  ,ARP2.DisplayName0 As 'Biscom Bitness'
  ,ARP2.Version0 As 'Version'
 FROM 
  dbo.v_R_System As SYS
  INNER JOIN dbo.v_FullCollectionMembership FCM On FCM.ResourceID = SYS.ResourceID 
  INNER JOIN dbo.v_Add_REMOVE_PROGRAMS As ARP On SYS.ResourceID = ARP.ResourceID 
  INNER JOIN dbo.v_Add_REMOVE_PROGRAMS As ARP2 On SYS.ResourceID = ARP2.ResourceID 
 WHERE 
 sys.Name0 = 'NICWENDLOWSKY'   and 
 (ARP.DisplayName0 LIKE '%Microsoft % Standard%'
 OR ARP.DisplayName0 LIKE 'Microsoft % Professional%'
 OR ARP.DisplayName0 LIKE 'Microsoft % Enterprise %') and ARP2.DisplayName0 like '%Biscom%'
 ORDER BY Name0 ASC