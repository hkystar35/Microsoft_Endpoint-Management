select distinct
PNP_DEVICE_DRIVER_DATA.Name00

from PNP_DEVICE_DRIVER_DATA

where PNP_DEVICE_DRIVER_DATA.Name00 like '\\%'

order by PNP_DEVICE_DRIVER_DATA.Name00