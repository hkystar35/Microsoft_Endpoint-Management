Select  
	VC.Name0 AS 'Video Card',
	count(VC.Name0) 'Count'
From  v_Gs_Video_Controller VC
Where VC.Name0 <> 'ConfigMgr'
	and VC.Name0 NOT LIKE '%DameWare%'
	and VC.Name0 NOT LIKE '%DisplayLink%'
	and VC.Name0 NOT LIKE '%VMware%'
	and VC.Name0 NOT LIKE '%Parallels%'
	and VC.Name0 NOT LIKE '%Hyper-V%'
	and VC.Name0 NOT LIKE '%Microsoft Basic Display Adapter%'
	and VC.Name0 IS NOT NULL
GROUP BY VC.Name0,vc.Caption0,vc.Description0,vc.SystemName0
Order By count desc