SELECT DISTINCT  
  SYS.Name0
  ,SYS.Build01
  ,SOF.ARPDisplayName0 As 'Office Name'
  ,'Office Year' =
	Case 
		When SOF2.ARPDisplayName0 like '%Outlook 2016%' Then '2016'
		When SOF2.ARPDisplayName0 like '%Outlook 2013%' Then '2013'
		Else 'Unknown'
	End
  ,'Office Bitness' =
    Case substring(sof.SoftwareCode0,21,1)
      When '0' Then '32-bit'
      When '1' Then '64-bit'
      Else 'Unknown'
    End
	,sof.SoftwareCode0
  ,SOF.ProductVersion0 As 'Office Version'
  ,SOF2.ARPDisplayName0 As 'Biscom Name'
  /*,'Biscom Bitness' =
    Case 
      When SOF2.ARPDisplayName0 like '%64%bit%' Then '64-bit'
      When SOF2.ARPDisplayName0 like '%32%bit%' Then '32-bit'
      Else 'Unknown'
    End
	,'Biscom Office Year' =
	Case 
		When SOF2.ARPDisplayName0 like '%Outlook 2016%' Then '2016'
		When SOF2.ARPDisplayName0 like '%Outlook 2013%' Then '2013'
		Else 'Unknown'
	End
  ,SOF2.ProductVersion0 As 'Biscom Version'
  */
  ,'Office Year Match' =
	Case 
		When (SOF2.ARPDisplayName0 like '%64%bit%') and ('Office Bitness' = '64-bit') Then 'true'
		When 'Biscom Office Year' <> 'Office Year' Then 'false'
		Else 'Unknown'
	End
	,'Bitness Match' =
	Case 
		When 'Biscom Bitness' = 'Office Bitness' Then 'true'
		When 'Biscom Bitness' <> 'Office Bitness' Then 'false'
		Else 'Unknown'
	End --as value
 FROM 
  dbo.v_R_System As SYS
  INNER JOIN dbo.v_FullCollectionMembership FCM On FCM.ResourceID = SYS.ResourceID 
  INNER JOIN dbo.v_GS_INSTALLED_SOFTWARE As SOF On SYS.ResourceID = SOF.ResourceID 
  INNER JOIN dbo.v_GS_INSTALLED_SOFTWARE As SOF2 On SYS.ResourceID = SOF2.ResourceID 
 WHERE 
 FCM.CollectionID = 'PAY0000D' and
 (sys.Name0 like '%bode%' or
 sys.Name0 like '%castro%') and
 --sys.Name0 like '%%'   and 
 SOF.ARPDisplayName0 LIKE '%Microsoft Office Professional%'
 and SOF2.ARPDisplayName0 like '%Biscom%'
 ORDER BY 'Office Name' ASC