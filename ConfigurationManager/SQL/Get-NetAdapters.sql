select distinct
v_GS_NETWORK_ADAPTER.Description0,
R.Name0


from
v_GS_NETWORK_ADAPTER join vSMS_R_System R on v_GS_NETWORK_ADAPTER.ResourceID = R.ItemKey


where (v_GS_NETWORK_ADAPTER.Description0 like '%wireless%'
or v_GS_NETWORK_ADAPTER.Description0 like '%wi-fi%'
or v_GS_NETWORK_ADAPTER.Description0 like '%wifi%'
or v_GS_NETWORK_ADAPTER.Description0 like '%wi fi%') 
AND v_GS_NETWORK_ADAPTER.Description0 like '%N 7260%'
group by Description0,R.name0
order by R.Name0