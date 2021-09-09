SELECT
sys1.netbios_name0 as [Computername],
WarrantyCheckDate0,
WarrantyStatus0
FROM v_r_system_valid sys1
Left Join v_GS_WarrantyInformation0 dn
ON dn.resourceid=sys1.ResourceID
ORDER BY WarrantyStatus0 desc