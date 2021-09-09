select distinct
GSP.Version0
--,GSP.Name0
,LEFT(GSP.Name0,4) AS 'Prefix'
FROM v_GS_COMPUTER_SYSTEM_PRODUCT GSP

GROUP BY GSP.Version0,GSP.Name0

ORDER BY version0