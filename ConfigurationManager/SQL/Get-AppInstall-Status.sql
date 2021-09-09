select distinct
aa.ApplicationName,
aa.AssignmentName,
ae.AssignmentID,
aa.CollectionName as 'Target Collection',
ae.descript as 'Deployment Type Name',
s1.netbios_name0 as 'Computer Name',
--s1.Distinguished_Name0 as 'OU',
ae.AppEnforcementState,
case when ae.AppEnforcementState = 1000 then 'Success'
when ae.AppEnforcementState = 1001 then 'Already Compliant'
when ae.AppEnforcementState = 1002 then 'Simulate Success'
when ae.AppEnforcementState = 2000 then 'In Progress'
when ae.AppEnforcementState = 2001 then 'Waiting for Content'
when ae.AppEnforcementState = 2002 then 'Installing'
when ae.AppEnforcementState = 2003 then 'Restart to Continue'
when ae.AppEnforcementState = 2004 then 'Waiting for maintenance window'
when ae.AppEnforcementState = 2005 then 'Waiting for schedule'
when ae.AppEnforcementState = 2006 then 'Downloading dependent content'
when ae.AppEnforcementState = 2007 then 'Installing dependent content'
when ae.AppEnforcementState = 2008 then 'Restart to complete'
when ae.AppEnforcementState = 2009 then 'Content downloaded'
when ae.AppEnforcementState = 2010 then 'Waiting for update'
when ae.AppEnforcementState = 2011 then 'Waiting for user session reconnect'
when ae.AppEnforcementState = 2012 then 'Waiting for user logoff'
when ae.AppEnforcementState = 2013 then 'Waiting for user logon'
when ae.AppEnforcementState = 2014 then 'Waiting to install'
when ae.AppEnforcementState = 2015 then 'Waiting retry'
when ae.AppEnforcementState = 2016 then 'Waiting for presentation mode'
when ae.AppEnforcementState = 2017 then 'Waiting for Orchestration'
when ae.AppEnforcementState = 2018 then 'Waiting for network'
when ae.AppEnforcementState = 2019 then 'Pending App-V Virtual Environment'
when ae.AppEnforcementState = 2020 then 'Updating App-V Virtual Environment'
when ae.AppEnforcementState = 3000 then 'Requirements not met'
when ae.AppEnforcementState = 3001 then 'Host platform not applicable'
when ae.AppEnforcementState = 4000 then 'Unknown'
when ae.AppEnforcementState = 5000 then 'Deployment failed'
when ae.AppEnforcementState = 5001 then 'Evaluation failed'
when ae.AppEnforcementState = 5002 then 'Deployment failed'
when ae.AppEnforcementState = 5003 then 'Failed to locate content'
when ae.AppEnforcementState = 5004 then 'Dependency installation failed'
when ae.AppEnforcementState = 5005 then 'Failed to download dependent content'
when ae.AppEnforcementState = 5006 then 'Conflicts with another application deployment'
when ae.AppEnforcementState = 5007 then 'Waiting retry'
when ae.AppEnforcementState = 5008 then 'Failed to uninstall superseded deployment type'
when ae.AppEnforcementState = 5009 then 'Failed to download superseded deployment type'
when ae.AppEnforcementState = 5010 then 'Failed to updating App-V Virtual Environment'
End as 'State Message'

from v_R_System_Valid s1
join vAppDTDeploymentResultsPerClient AE on AE.ResourceID=s1.ResourceID
join v_CICurrentComplianceStatus ci2 on ci2.CI_ID=ae.CI_ID AND
ci2.ResourceID=s1.ResourceID
join v_ApplicationAssignment aa on ae.AssignmentID = aa.AssignmentID

where ae.AppEnforcementState is not null and aa.ApplicationName='CrowdStrike Falcon'
and s1.netbios_name0 like '%JENKEHR%'
--order by AssignmentName,'State Message','Computer Name' Desc
order by 'Computer Name' Desc