SELECT

case dbo.v_GS_UEFI_SecureBootState0.UEFISecureBootEnabled0
	when 1 then 'UEFI'
	when 0 then 'LegacyBIOS'
	Else 'Unknown'
end AS [UEFI_SECUREBOOT_Status]
FROM dbo.v_GS_UEFI_SecureBootState0 INNER JOIN dbo.v_GS_SYSTEM 
ON dbo.v_GS_UEFI_SecureBootState0.ResourceID = dbo.v_GS_SYSTEM.ResourceID

ORDER BY
[UEFI_SECUREBOOT_Status] asc