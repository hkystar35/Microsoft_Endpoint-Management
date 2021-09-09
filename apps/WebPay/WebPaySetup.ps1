<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
	 Created on:   	2/8/2018 09:57
	 Created by:   	NWendlowsky
	 Organization: 	Paylocity
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

#region Prerequisites
<#

# Visual Studio 2015 (update 3 or higher)
# 	Ignore any Visual Studio prompts when opening the solution asking if you want to upgrade.
# TypeScript 1.7.6 for Visual Studio 2015

# SQL Server 2014 Developer Edition
# Named Instance: SQLSERVER2014
# 	Include Reporting Services
# 	Include Integration Services
# 	Include SQL Management Studio

# IIS

# git (command line version)

# Powershell
# 	Make sure running script is not disabled (run Set-ExecutionPolicy RemoteSigned)

# PowerBroker
# 	PowerBroker is not required but without it you will need to run some tasks "as admin" and elevate with your localadmin account.
# 	PowerBroker is not recommended for Windows 10 users

# 	If you install PB, do not install PB ver 6 on a windows 10 machine. It's not compatible and will brick most of the PC's functionality.  Also, do not install PB ver 7 on Windows 8.1 for the same reason.
# 	PowerBroker is a third party utility (BeyondTrust PowerBroker) that is used to elevate Paylocity windows domain users to administrators whenever they are running any executable in C:\Paylocity folder. An easy way to verify PowerBroker is running is by opening any solution file located under C:\Paylocity and watch if visual studio opens in Administrator mode (should display "Administrator" in the title bar). If this is not working, please contact support at https://employee.paylocity.com/

# Sql Server Data Tools
# 	version 130 is required, package can be found here: \\kirk\Development\Tools\SSDT 130, also available from Microsoft here:  https://www.microsoft.com/en-us/download/details.aspx?id=53013

#>
#endregion Prerequisites

#region Tooling Setup

#region git setup

#Run from command line:
# git config --global user.name "John Doe"
# git config --global user.email "jdoe@paylocity.com"

#Optional:  Set git to use wincred to avoid constantly entering your password
# git config --global credential.helper wincred

#endregion git setup

#region Visual Studio
# Visual Studio 2015 or newer
#NuGet Package Source
# Within Visual Studio, go to Tools -> Options...
# Select-Object NuGet Package Manager > Package Manager Settings
# Expand NuGet Package Manager
# Select-Object "Package Sources"
# Add source: https://artifact.paylocity.com/artifactory/api/nuget/nuget
# Make sure this is the first source in the list

# (optional) make sure these instructions are applied to all user profiles using visual studio (in case <machinename>\localadmin is used)

# Tab/Space Settings
# Within Visual Studio, go to Tools -> Options...
# Navigate to Text Editor -> All Languages -> Tabs
# Within the "Tab" section, set Tab and Index Size to 2. Check the "Insert spaces" radio box

#endregion Visual Studio

#region Setting Up Web Pay

Clone WebPay repository

Run the following command

git clone -b develop https://jdoe@code.paylocity.com/scm/wp/webpay.git C:\Paylocity\Escher


NOTE #1:  Replace jdoe with your username
NOTE #2: You may have to enter your password. This will be your PAYLOCITY password 


Set-Variable up Database
Clone this repo locally: https://yourusername@code.paylocity.com/scm/wp/databasebackups.git It contains recent copies of all database
If using compressed file, then uncompress it locally
Create the EscherConfiguration db
Navigate to the C:\Paylocity\Escher\DeveloperTasks\DatabaseSetup directory
Execute the ConfigurationDatabase_Deploy.bat file by double-clicking.

Restore Escher, EscherHistory, EscherCustomCalcs, EscherHistoryCustomCalcs, EscherLog, EscherProcessing, and EscherImplementation databases

Warning! Do not use the C:\Paylocity\databaseBackups\developerLocals\*.bak files. The current files (as of 2017-12-22) have data issues in the Escher.STaxCodes table (and potentially other areas). Some SUI taxType records have incorrect tcode values preventing the correct SITW records from being imported. Only use the *.bak files in the root of the repository.
Option 1: Script

RESTORE Escher databases
USE [master]
/*
* Restore the Escher databases
* Replace  C:\Paylocity\DatabaseBackups\   with your path source path
* Optionally, replace C:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA with your destination path
*/
RESTORE DATABASE [Escher] FROM  DISK = N'C:\Paylocity\DatabaseBackups\escher.bak' WITH  FILE = 1, MOVE N'Escher_Data' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\Escher_Data.MDF', MOVE N'Escher_Log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\Escher_Log.LDF', NOUNLOAD, REPLACE, STATS = 5
RESTORE DATABASE [EscherHistory] FROM  DISK = N'C:\Paylocity\DatabaseBackups\escherHistory.bak' WITH  FILE = 1, MOVE N'EscherHistory_Data' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherHistory_Data.MDF', MOVE N'EscherHistory_Log' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherHistory_Log.LDF', NOUNLOAD, REPLACE, STATS = 5
RESTORE DATABASE [EscherCustomCalcs] FROM  DISK = N'C:\Paylocity\DatabaseBackups\escherCustomCalcs.bak' WITH  FILE = 1, MOVE N'EscherCustomCalcs_Data' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherCustomCalcs_Data.MDF', MOVE N'EscherCustomCalcs_Log' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherCustomCalcs_Log.LDF', NOUNLOAD, REPLACE, STATS = 5
RESTORE DATABASE [EscherHistoryCustomCalcs] FROM  DISK = N'C:\Paylocity\DatabaseBackups\escherHistoryCustomCalcs.bak' WITH  FILE = 1, MOVE N'EscherHistoryCustomCalcs_Data' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherHistoryCustomCalcs_Data.MDF', MOVE N'EscherHistoryCustomCalcs_Log' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherHistoryCustomCalcs_Log.LDF', NOUNLOAD, REPLACE, STATS = 5
RESTORE DATABASE [EscherLog] FROM  DISK = N'C:\Paylocity\DatabaseBackups\escherLog.bak' WITH  FILE = 1, MOVE N'EscherLog_Data' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherLog_Data.MDF', MOVE N'EscherLog_Log' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherLog_Log.LDF', NOUNLOAD, REPLACE, STATS = 5
RESTORE DATABASE [EscherProcessing] FROM  DISK = N'C:\Paylocity\DatabaseBackups\escherProcessing.bak' WITH  FILE = 1, MOVE N'EscherProcessing_Data' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherProcessing_Data.MDF', MOVE N'EscherProcessing_Log' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherProcessing_Log.LDF', NOUNLOAD, REPLACE, STATS = 5
RESTORE DATABASE [EscherImplementation] FROM  DISK = N'C:\Paylocity\DatabaseBackups\escherImplementation.bak' WITH  FILE = 1, MOVE N'EscherImplementation_Data' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherImplementation_Data.MDF', MOVE N'EscherImplementation_Log' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherImplementation_Log.LDF', NOUNLOAD, REPLACE, STATS = 5

/*
* Optionally, restore these Escher databases
* They are normally generated automatically by oSetupSql
* This is for restoring a database from a sandbox
*/
--RESTORE DATABASE [EscherArchive] FROM  DISK = N'C:\Paylocity\DatabaseBackups\escherArchive.bak' WITH  FILE = 1, MOVE N'EscherArchive' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherArchive.mdf', MOVE N'EscherArchive_log' TO N'c:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\EscherArchive_log.ldf', NOUNLOAD, REPLACE, STATS = 5

/*
* Optionally, restore the any DevBuildTasks databases
* e.g. Aca, PerformanceManagement, Analytics*, Reporting, ReportManagement
* Normally you these created during DevBuildTasks
* This is for restoring a database from a sandbox
*/
--RESTORE DATABASE [Aca] FROM  DISK = N'C:\Paylocity\DatabaseBackups\aca.bak' WITH  FILE = 2, MOVE N'Aca' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\Aca_Primary.mdf', MOVE N'Aca_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\Aca_Primary.ldf', NOUNLOAD, REPLACE, STATS = 5


/*
* Optionally, Add any team databases to restore here
* Normally you would run the DACPAC from your team's project
 * This is for restoring a database from a sandbox
 */
--RESTORE DATABASE [YearEndDashboard] FROM  DISK = N'C:\Paylocity\DatabaseBackups\YearEndDashboard.bak' WITH  FILE = 1,  MOVE N'YearEndDashboard' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\YearEndDashboard_Primary.mdf',  MOVE N'YearEndDashboard_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.SQLSERVER2014\MSSQL\DATA\YearEndDashboard_Primary.ldf',  NOUNLOAD,  REPLACE,  STATS = 5
  
GO


ii. Option 2: Manually

                MSDN instructions: http://msdn.microsoft.com/en-us/library/ms177429.aspx
                You may encounter an issue when trying to attach the EscherHistory database. You will need to rename one of the files as shown in the below screenshot. Take note of the 'x_' in the logical file name. You will need to update the restore as file to match.
                IMPORTANT: select "Overwrite the existing database (WITH REPLACE)"  option



d. Set up users

            Run the following within SQL Management Studio
            1
            2
            3
            4
            5
            6
            7
            8
            9
            10
            11
            12
            13
            14
            15
            16
            17
            18
            19
            20
            21
            22
            23
            24
            25
            26
            27
            28
            29
            30
            31
            32
            	
            USE [master]
            GO
            If not Exists (select loginname from master.dbo.syslogins  where name = 'Escher')
            Begin
                CREATE LOGIN [Escher] WITH PASSWORD=N'Escher', DEFAULT_DATABASE=[Escher], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
            End
            GO
            If not Exists (select loginname from master.dbo.syslogins  where name = 'EscherUser')
            Begin
                CREATE LOGIN [EscherUser] WITH PASSWORD=N'EscherUser', DEFAULT_DATABASE=[Escher], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
            End
            GO
            If not Exists (select loginname from master.dbo.syslogins  where name = 'wben')
            Begin
                CREATE LOGIN [wben] WITH PASSWORD=N'wben', DEFAULT_DATABASE=[Escher], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
            End
            GO
            If not Exists (select loginname from master.dbo.syslogins  where name = 'onboard')
            Begin
                CREATE LOGIN [onboard] WITH PASSWORD=N'onboard', DEFAULT_DATABASE=[Escher], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
            End
            GO
            IF not Exists (select loginname from master.dbo.syslogins  where name = 'EscherCustomCalcs')
            Begin
                CREATE LOGIN [EscherCustomCalcs] WITH PASSWORD=N'Escher', DEFAULT_DATABASE=[Escher], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
            END
            GO
            If not Exists (select loginname from master.dbo.syslogins  where name = 'EscherCustomCalcsAccruals')
            Begin
                CREATE LOGIN [EscherCustomCalcsAccruals] WITH PASSWORD=N'Escher', DEFAULT_DATABASE=[Escher], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
            End
            GO

            ii.  Run once each for the EscherCustomCalcs, EscherHistoryCustomCalcs databases
            CustomCalcs
            1
            2
            3
            4
            5
            6
            7
            8
            	
            CREATE USER [EscherCustomCalcs] FOR LOGIN [EscherCustomCalcs] WITH DEFAULT_SCHEMA=[Escher]
            GO
            CREATE USER [EscherCustomCalcsAccruals] FOR LOGIN [EscherCustomCalcsAccruals] WITH DEFAULT_SCHEMA=[Escher]
            GO
            CREATE SCHEMA [EscherCustomCalcs]
            GO
            CREATE SCHEMA [EscherCustomCalcsAccruals]
            GO

e. Run the following script:  C:\Paylocity\Escher\DeveloperTasks\DatabaseSetup\FixAllLogins.sql    

            Run once each for the Escher, EscherHistory, EscherCustomCalcs, EscherHistoryCustomCalcs, EscherLog, EscherProcessing, and EscherImplementation databases

f. Run the following script under Esher database context:
SQL Script
1
2
3
4
5
6
	
exec sp_change_users_login 'auto_fix', 'Escher';
exec sp_change_users_login 'auto_fix', 'EscherUser';
exec sp_change_users_login 'auto_fix', 'onboard';
exec sp_change_users_login 'auto_fix', 'wben';
exec sp_change_users_login 'auto_fix', 'EscherCustomCalcs';
exec sp_change_users_login 'auto_fix', 'EscherCustomCalcsAccruals';


g. Run the following SQL script to fix the InstanceName of the machine from the restored backup 
SQL Script
1
2
3
4
	
Use Escher
 
UPDATE Escher.DBSyncRegistration
SET instanceName = HOST_NAME()


3. Setup Decoupled Databases - NON-ACA

        run \\kirk\Development\DevBuildTasks\_InitLocal.bat
        Navigate to C:\Paylocity\DevBuildTasks

Install Microsoft SQL Server Data-Tier Application Framework (x86)

        This is available via the Paylocity App Store.Run PerformanceManagementDatabaseSetup.bat
        If this file is missing, then something probably failed with _InitLocal.bat.
        If you receive the error "An error occurred Element or Annotation class PersistedResolvableAnnotation does not contain the Property class Length."
        If you receive the error "The system cannot find the file specified" and you have Visual Studio 2017 installed, you may need to update the batch file to refer to "C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\sqlpackage.exe" OR "C:\Program Files\Microsoft SQL Server\130\DAC\bin\sqlpackage.exe"
        Visit this link Fixing Errors

4. Setup Decoupled ACA Database

a. Run AcaDatabaseSetup.bat (hint: C:\Paylocity\DevBuildTasks)

        NOTE: you may see an error that it needs an Escher Schema.  
            Open SSMS, 
            Select the ACA database
            run command "create schema escher"
            rerun AcaDatabaseSetup.bat

b. If you receive the error "The system cannot find the file specified" and you have Visual Studio 2017 installed, you may need to update the batch file to refer to "C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\sqlpackage.exe"  OR "C:\Program Files\Microsoft SQL Server\130\DAC\bin\sqlpackage.exe"

    Re-Run C:\Paylocity\escher\DeveloperTasks\DatabaseSetup\FixAllLogins.sql on the ACA database.

5. Run OSetupSQL

    If new machine, run C:\Paylocity\DevBuildTasks\ConfigurationDatabaseSetup.bat
        If you receive the error "The system cannot find the file specified" and you have Visual Studio 2017 installed, you may need to update the batch file to refer to "C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\sqlpackage.exe"  OR "C:\Program Files\Microsoft SQL Server\130\DAC\bin\sqlpackage.exe"

    Navigate to C:\Paylocity\Escher\DeveloperTasks\DatabaseSetup  in Windows Explorer   (not command line)
    Run OSetupSQL_UpdateFull.bat
        If you get errors about paths and the bin directory, you probably need to build the escher.sln first and re-run the script
        If this is a new machine and you ONLY have VS2017 installed and you get the following error "C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" RunOSetupSql.msbuild /t:Update /l:FileLogger,Microsoft.Build.Engine;logfile=Logs\osetupSQL_updateFast.log

        The system cannot find the path specified."  Change the path to one of the following, depending on if you have VS 2017 Professionall (probably) or Enterprise (less likely)

(VS2017 Enterprise): MSBuild.exe in the bat file to "C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin"

(VS2017 Professional): MSBuild.exe in the bat file to "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin"

c. If you get errors about Configuration, setup the Configuration Database first and re-run the script - Setting up the Configuration (toggles) service and Database locally... ONLY do the DATABASE portion, as you won't have the appropriate virtual directories set up yet for the services in IIS until you're done with step 8.

if you get errors about powershell permission to run scripts:

            type powershell in a cmd window
            set-executionpolicy -executionpolicy unrestricted
            re-run the script

d. if you get errors about not being able to connect to the Configuration database, you likely don't have sql authentication turned on- within the Microsoft SQL Server Management Studio in the object explorer:

Right click on the server and click Properties

Go to the Security page

Under Server authentication choose the SQL Server and Windows Authentication mode radio button

Click OK

Restart SQL Services


6. Run DeveloperTasks scripts

Navigate to C:\Paylocity\Escher\DeveloperTasks\  in Windows Explorer   (not command line)
Run ConfigureEscherVirtualDirectory.bat >> Run (as admin)
Run CopyMembershipContent.bat

7. Setup Redis

Navigate to \\kirk\software\Development\Redis
Copy-Item Redis.zip to your Documents folder
Extract to Documents\Redis
Move-Item the entire Redis folder to C:\Program Files (will require elevation) resulting in the file c:\Program Files\Redis\redis-server.exe now existing

Run from command line (as admin):
"C:\Program Files\redis\redis-server"--service-install "C:\Program Files\redis\redis.windows.conf" --loglevel verbose

e. If you get an error when that command executes, check your Services list to see if "Redis" is listed.  If it is, try rebooting to see if that service will start successfully.

f. From an elevated Notepad, open redis.windows.conf file within C:\Program Files\Redis

g. Find maxmemory value

Set-Variable to 50MB, so the line will read:
maxmemory 50MB

Start-Process the Redis service by typing net start redis


8. Setup Local Web Services


Full details here: How to Set Up Services Locally for WebPay

Navigate to C:\Paylocity\Security\Paylocity.Apis.Security.Identity and open Paylocity.Apis.Security.Identity.sln (clone this repo: https://code.paylocity.com/scm/sec/paylocity.apis.security.identity.git).  Right click on the Paylocity.Apis.Security.Identity.WebApis project and select "Build" so it will download the necessary NuGet packages for the project.

Navigate to C:\Paylocity\DevBuildTasks within Windows Explorer on your local workstation

Run WebServicesForEscherSetup.bat and WebServicesForAppShellSetup.bat

a. Double click this within Windows Explorer. Do not run this from the command line

b. This may be run as localadmin via right-click Run as Administrator. You will be prompted for your username several times during the script's execution.

c. You must have PowerBroker running on your workstation. See "PowerBroker" section above in the Prerequisites

Go back and set up the Configuration (toggles) service portion from here: Setting up the Configuration (toggles) service and Database locally.

a. Note: You may not need to complete this step as it was performed by the above scripts

9. Set up Escher_WebUI and Compile

Open Escher.sln   (under C:\Paylocity\Escher) in Visual Studio

a. If the solution hangs when loading, try deleting the ".vs" folder

Set the startup project to Escher_WebUI

Set up Escher_WebUI Virtual Directory

a. Right click on Escher_WebUI and select Properties

b. Select Web tab

c. Under the Servers section, set server to Local IIS and the Project URL to http://localhost/Escher/Escher_WebUI

 


Build solution

VS 2017

You may encounter the following errors:

 The imported project "$(VSToolsPath)\WebApplications\Microsoft.WebApplication.targets" was not found. You can resolve this by copying

C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v14.0\WebApplications
to 
C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v15.0\WebApplications in order to copy over all the WebApplication targets files. 

The type or namespace name 'Notification' does not exist in the namespace 'Escher.Notification' (are you missing an assembly reference?). You can resolve this by:

    Removing the NotificationLibrary project references found in the Notification project
    Building the Notification project
    Adding the NotificationLibrary project references back to the Notification project

10. Setup Local Windows Services

Navigate to c:\paylocity\escher\scripts\commonTasks

Run ServicesInstallAll.bat >> Run (as admin)


11. Reset Escher SuperUser Password (https://wiki.paylocity.com/display/WB/Reset+Super+User+Login+Locally)

Run the below script on the Escher database to reset the date restrictions and challenge questions for 'ckent'.
Reset 'ckent'
1
2
3
4
5
6
7
8
9
10
11
12
13
	
update Escher.[Escher].[ELogin]
set [failedCount] = 0,
lockedOutDate = null,
password = '$2a$08$LrHNPo3sHXj5ZPD2Ce0cbuxg9SnhP.99ajJGCCU.SNC/AzIJEx/IC',
password2 = null,
password3 = null,
password4 = null,
challengeQuestion1 = null,
challengeQuestion2 = null,
challengeQuestion3 = null,
forcePasswordChange = 0,
lastPasswordChange = getdate() -1
where [username] = 'ckent'

12. Run WebPay

WebPay must be run via Visual Studio in order to start several dependent IIS Express services. Attempting to run directly via IIS is possible with additional configuration.


Verify that local Redis service is running.

Run the solution, and verify the installation by navigating to http://localhost/Escher/Escher_WebUI/views/login/login.aspx (click on the Super User login to shortcut having to enter credentials )

Update your start page in Escher to Escher_WebUI/views/login/login.aspx (right click and set as start page). This will allow you to run the solution from Escher without manually pasting the login url.

    Note: With the IDP changes, this file is no longer included in the project but can be manually accessed by direct url entry. 

13. Generate Employee Templates (How to Regenerate Templates on localhost if they are not showing)

The existing templates will need to be deleted and recreated.

a. Login to via Super User/ckent

b. Browse to Setup > Employee Templates

c. Open F12 Developer Tools (Chrome used at the time of writing)

d. Run the below command in the console to enable all the checkboxes for selection
$('input[type="checkbox"]').removeAttr('disabled')

Click the top 'Select all' checkbox, and hit the Delete button.

There are 4 sql scripts that already exist for Escher, however they are currently prevented from running because of version validation on Escher.XSchemaInfo

a. C:\Paylocity\Escher\SQL\Schema\PostUpgrades\XTemplatePreset_NH.sql

b. C:\Paylocity\Escher\SQL\Schema\PostUpgrades\XTemplatePreset_LoA.sql

c. C:\Paylocity\Escher\SQL\Schema\PostUpgrades\XTemplatePreset_JobChange.sql

d. C:\Paylocity\Escher\SQL\Schema\PostUpgrades\XTemplatePreset_Termination.sql

Run the content of each of these scripts (either comment out the leading XSchemaInfo lines, or Execute Selection without them)


14. Import Setup Template Company T9900 (https://wiki.paylocity.com/display/DEVIMPL/Clone+Company+from+an+Integrated+Environment)

Login to WebPay as the Super User

Click on Service Bureau > Company Import & Update

Click Remote Company Import (use an environment of your choice - env must have EscherQA login)

a. Escher Source Server: pewtersql, tinsql, bronzesql, coppersql, etc.

b. Escher History Source Server: pewterrssqla, tinrssqla, bronzerssqla, etc.

c. Company Id: T9900 (note: you can use a different company, however this is the typical one)

Click Service Bureau > Manage Queue

a. Wait until the job titled "Remote Company Copy" is complete, it should have no errors.

b. If the job isn't picked up shortly, make sure the "Paylocity DBSync" and "Paylocity Processing" services are running (services.msc).

c. If the services aren't available, you can install them with scripts found in C:\paylocity\Escher\Scripts\CommonTasks


15. Import Tax Codes

Login to WebPay as the Super User

Click on Service Bureau > Manage Queue

At the bottom of the page, click "Queue TaxCodes Import"

    Wait until the job titled "TaxCodes Import" is complete, it should have no errors.
     

16. Setup a new WebPay Company (optional):

Setup for WebTime/WebPay Integration

 
What could go wrong?

If you are getting this error: "Unable to cast object of type 'Newtonsoft.Json.Linq.JObject' to type 'System.Runtime.Serialization.ISafeSerializationData'", This can be resolved by deleting the Services folder in IIS and re-running:

_InitLocal.bat

WebServicesForEscherSetup.bat

WebServicesForAppShellSetup.bat

If you get an error in ConfigManager.cs, make sure the Project Url in step 10 (iii) is typed correctly http://localhost/Escher/Escher_WebUI

When debugging, if you get this error : "unable to contact the web server, forbbidden 403..", make sure that Debug flag is set to true in the .NET compilation section of the default web site per screen shot below and also reset IIS

If there are errors pulling down some NuGet packages from Artifactory like this:

https://artifact.paylocity.com/artifactory/api/nuget/nuget: Unable to load the service index for source https://artifact.paylocity.com/artifactory/api/nuget/nuget.
The content at 'https://artifact.paylocity.com/artifactory/api/nuget/nuget' is not a valid JSON object.
Unexpected character encountered while parsing value: <. Path '', line 0, position 0.

This can be a problem when running scripts under the localadmin account. Check the NuGet.config file under C:\Users\localadmin\AppData\Roaming\NuGet   (or replace "localadmin" with the current username). The line for Artifactory should be:
<add key="Paylocity Artifactory" value="https://artifact.paylocity.com/artifactory/api/nuget/nuget" />

Remove any protocolVersion attribute

If you are try to create a new company and receive the below error, you may need to delete extra tax codes from the T9900 template company. As of the 2017-12-22 T9900 template on tin/bronze the 'SS3P' and 'MED3P' tax codes do not appear to get imported with the TaxCodes import and will prevent the company creation process from completing unless they are deleted from the template company.

System.Exception: The INSERT statement conflicted with the FOREIGN KEY constraint "FK_CTax_STaxCodes". The conflict occurred in database "Escher", table "Escher.STaxCodes", column 'tcode'.
The INSERT statement conflicted with the FOREIGN KEY constraint "FK_CTax_STaxCodes". The conflict occurred in database "Escher", table "Escher.STaxCodes", column 'tcode'.

Not to be confused with the CSS/Style issue mentioned below under Additional Notes - If at run time you get a screen that looks similar to all formatting having been removed AND the console shows that 'paylocity' is undefined and the javascript sources are empty, double check that you have all the necessary IIS components installed.  This may be overkill, but it worked for me (thank you Edgar Martinez)
