DECLARE @site VARCHAR(MAX),@computer VARCHAR(MAX), @solution VARCHAR(MAX), @application VARCHAR(MAX), @status VARCHAR(MAX);

SET @site = @CollectionName;
 SET @computer = @ComputerName;
 SET @solution = @SolutionName;
 SET @application = @ApplicationName;
 SET @status = @LoadStatus

 if @CollectionName= 'All'
	SET @site = '%'
if @ComputerName= 'All'
	SET @computer ='%'
if @SolutionName= 'All'
	SET @solution ='%'
if @ApplicationName= 'All'
	SET @application ='%'
if @LoadStatus = 'All'
	SET @status ='%'


SELECT 		DISTINCT([CM_PAY].[dbo].[Custom_OfficeAddins_DATA].InstanceKey),
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].MachineID,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].TimeKey,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].RevisionID,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].AgentID,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].Application00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].ComputerName00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].Description00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].FriendlyName00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].FullPath00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].ID00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].IsOutlookCrashingAddin00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].IsResilient00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].LoadBehavior00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].LoadBehaviorStatus00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].LoadBehaviorValue00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].LoadTime00,
		
		CASE 
		When  FriendlyName00  != Null OR FriendlyName00 !='' THEN FriendlyName00 ELSE 		Name00 END as Name,

		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].OfficeVersion00,
		[CM_PAY].[dbo].[Custom_OfficeAddins_DATA].RegistryPath00
   From [CM_PAY].[dbo].[Custom_OfficeAddins_DATA] 
-- LEFT JOIN [CM_PAY].[dbo].[CollectionMembers]  ON [CM_PAY].[dbo].[Custom_OfficeAddins_DATA].MachineID = [CM_PAY].[dbo].[CollectionMembers].MachineID
-- LEFT JOIN [CM_PAY].[dbo].[Collections_G] ON [CM_PAY].[dbo].[Collections_G].SiteID = [CM_PAY].[dbo].[CollectionMembers].SiteID
 WHERE ComputerName00 LIKE @computer AND 
(Name00 LIKE @solution OR
FriendlyName00 LIKE @solution) AND 
LoadBehaviorStatus00 LIKE @status 
--AND [CM_PAY].[dbo].[Collections_G].CollectionName LIKE @site AND
--[CM_PAY].[dbo].[Collections_G].CollectionType = 2