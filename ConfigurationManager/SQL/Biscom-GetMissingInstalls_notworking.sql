select
vSMS_R_System.ItemKey,
vSMS_R_System.Client_Type0,
vSMS_R_System.Name0,
vSMS_R_System.SMS_Unique_Identifier0,
vSMS_R_System.Client0

from vSMS_R_System
inner join v_GS_COMPUTER_SYSTEM on v_GS_COMPUTER_SYSTEM.ResourceID = vSMS_R_System.ItemKey

where
v_GS_COMPUTER_SYSTEM.Name0 not in (
	select distinct 
	v_GS_COMPUTER_SYSTEM.Name0
	from  vSMS_R_System
	inner join v_GS_COMPUTER_SYSTEM on v_GS_COMPUTER_SYSTEM.ResourceID = vSMS_R_System.ItemKey 
	inner join v_GS_ADD_REMOVE_PROGRAMS on v_GS_ADD_REMOVE_PROGRAMS.ResourceID = vSMS_R_System.ItemKey
	where v_GS_ADD_REMOVE_PROGRAMS.DisplayName0 like '%Biscom%SFT%'
) 
and v_GS_COMPUTER_SYSTEM.Name0 not in (
	select distinct 
	v_GS_COMPUTER_SYSTEM.Name0
	from  vSMS_R_System
	inner join v_GS_COMPUTER_SYSTEM on v_GS_COMPUTER_SYSTEM.ResourceID = vSMS_R_System.ItemKey 
	inner join v_GS_INSTALLED_SOFTWARE on v_GS_INSTALLED_SOFTWARE.ResourceID = vSMS_R_System.ItemKey
	where v_GS_INSTALLED_SOFTWARE.ProductName0 like '%Biscom%SFT%'
)