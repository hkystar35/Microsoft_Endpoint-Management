SELECT
sys1.netbios_name0 as [Computername],
MAX(CASE dn.version0 when '1.0' THEN
case dn.buildNumber0 when isnull(dn.buildnumber0,1) then dn.BuildNumber0 End END) AS [.Net 1.0],
MAX(CASE dn.version0 when '1.1' THEN
case dn.BuildNumber0 when isnull(dn.buildnumber0,1) then dn.buildnumber0 End END) AS [.Net 1.1],
MAX(CASE dn.version0 when '2.0' THEN
case dn.BuildNumber0 when isNull(dn.buildnumber0,1) then dn.BuildNumber0 end END) AS [.Net 2.0],
MAX(CASE dn.version0 when '3.0' THEN
case dn.BuildNumber0 when isNull(dn.buildnumber0,1) then dn.BuildNumber0 end END) AS [.Net 3.0],
MAX(CASE dn.version0 when '3.5' THEN
case dn.BuildNumber0 when isNull(dn.buildnumber0,1) then dn.BuildNumber0 end END) AS [.Net 3.5],
MAX(CASE dn.version0 when '3.5' THEN
case dn.ServicePack0 when isnull(DN.ServicePack0,1) then dn.ServicePack0 end END) AS [.Net 3.5 ServicePack],
MAX(CASE dn.version0 when '4.0' THEN
case dn.BuildNumber0 when isNull(dn.buildnumber0,1) then dn.BuildNumber0 end END) AS [.Net 4.0]
FROM
v_r_system_valid sys1
Left Join v_gs_dotnetframeworks0 dn
ON dn.resourceid=sys1.ResourceID
Group By
sys1.netbios_name0
ORDER BY
[.Net 4.0] desc