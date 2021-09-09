select distinct
v_GS_ADD_REMOVE_PROGRAMS.DisplayName0 as 'Name',
v_GS_ADD_REMOVE_PROGRAMS.Publisher0 as 'Publisher',
v_GS_ADD_REMOVE_PROGRAMS.Version0 as 'Version',
count(*) as 'InstallCount'

from
v_GS_ADD_REMOVE_PROGRAMS

where
v_GS_ADD_REMOVE_PROGRAMS.DisplayName0 LIKE '%ssms tool%'

Group By DisplayName0,Version0,Publisher0

order by version desc