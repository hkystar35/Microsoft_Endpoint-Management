select 
UPPER(SUBSTRING(lastmpservername, 1, CHARINDEX('.', lastmpservername) -1 )) as 'Management Point',
count(lastmpservername) as 'Total Clients'

from v_CH_ClientSummary

group by lastmpservername

order by lastmpservername desc