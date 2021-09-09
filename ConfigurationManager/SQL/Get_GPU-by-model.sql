Select distinct
	CS.Model0 AS 'Model',
	VC.Name0 AS 'Video Card',
	count(VC.Name0) 'Count'
From  v_Gs_Video_Controller VC 
	join v_GS_COMPUTER_SYSTEM CS on vc.ResourceID=cs.ResourceID
Where VC.Name0 <> 'ConfigMgr'
	and VC.Name0 NOT LIKE '%DameWare%'
	and VC.Name0 NOT LIKE '%DisplayLink%'
	and VC.Name0 NOT LIKE '%VMware%'
	and VC.Name0 NOT LIKE '%Parallels%'
	and VC.Name0 NOT LIKE '%Hyper-V%'
	and VC.Name0 NOT LIKE '%Microsoft Basic Display Adapter%'
	and VC.Name0 IS NOT NULL
GROUP BY VC.Name0,CS.Model0
Order By count desc