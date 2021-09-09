select
CollectionName,
SiteID
from Collections
where CollectionName like 'All Lenovo %(%)%'
order by CollectionName