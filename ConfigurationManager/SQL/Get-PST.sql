select distinct   
      Sys.Name0,  
      SF.FileName AS [Filename],  
      SF.ModifiedDate AS [Last Modified Date],  
      SF.Filepath AS [Local Filepath],  
      SF.FileSize/1024 as [Size (MB)],  
      SF.FileSize/1024000000 as [Size (GB)]  
 from v_R_System Sys   
      INNER JOIN v_GS_SoftwareFile SF on  
 Sys.ResourceID = SF.ResourceID  
      INNER JOIN v_FullCollectionMembership FCM on  
 FCM.ResourceID=sys.ResourceID  
      where SF.FileName like '%.pst'
	  and SF.Filepath not like '%recycle%'
	  and SF.FileName not like '%archive%'
      Order by SF.ModifiedDate 