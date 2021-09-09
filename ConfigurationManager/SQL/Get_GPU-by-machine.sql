Select  
SD.Name0 'Machine Name',
VC.Name0 'Video Card',
Convert(VarChar, VC.AdapterRam0 / 1024) + ' MB' AS 'GPU Mem'
From v_R_System SD
Join v_Gs_Video_Controller VC on SD.ResourceID = VC.ResourceID
Where VC.Name0 <> 'ConfigMgr'
and VC.Name0 NOT LIKE '%DameWare%'
and VC.Name0 NOT LIKE '%DisplayLink%'
and VC.Name0 NOT LIKE '%VMware%'
and VC.Name0 NOT LIKE '%Parallels%'
and VC.Name0 NOT LIKE '%Hyper-V%'
and VC.Name0 NOT LIKE '%Microsoft Basic Display Adapter%'
and VC.Name0 IS NOT NULL
--Order By SD.Name0
Order By VC.Name0