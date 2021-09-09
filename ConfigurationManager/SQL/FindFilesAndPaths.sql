select distinct /*Sys.Name0,*/SF.FileName,SF.ModifiedDate as 'LastModified Date' ,SF.Filepath, SF.FileSize/1024 as Megs
from v_R_System Sys INNER JOIN v_GS_SoftwareFile SF on
Sys.ResourceID = SF.ResourceID
INNER JOIN v_FullCollectionMembership FCM on
FCM.ResourceID=sys.ResourceID

where SF.FileName like '%'+'.EXE' /*and CollectionID=@COLLID */  and

SF.Filepath like 'C:\Users\%\appdata\%' 
Order by SF.FileName