<#
	.SYNOPSIS
		Automatically creates SCCM Collections when new device models are added to the database.
	
	.DESCRIPTION
		Queries SQL and creates collections when needed.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
		Created on:   	8/20/2018 4:07 PM
		Created by:   	Nhkystar35
		Organization: 	contoso
		Filename:
		===========================================================================
#>


TRY {
	TRY {
		#variables to be modified to suit your site configuration
		$CurrentLocation = Get-Location
		Import-Module -Name $env:SMS_ADMIN_UI_PATH.Replace('\bin\i386', '\bin\ConfigurationManager.psd1')
		$site_code = Get-PSDrive -PSProvider CMSITE
		Set-Location -Path "$($Site_Code.Name):\"
	}CATCH {
		Write-Host 'Failed to set location.'	
	}
	#SQL query to get unique values of machines
	$SQLQuery = @"
SELECT distinct
Manufacturer00 AS 'Manufacturer',
version00 AS 'ModelName',
LEFT(model00,4) AS 'Prefix',
LEFT(SMBIOSBIOSVersion0,4) AS 'BIOS Prefix'

FROM COMPUTER_SYSTEM_PRODUCT_DATA 
 join Computer_System_DATA on Computer_System_DATA.MachineID = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID 
 join vSMS_R_System on vSMS_R_System.ItemKey = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID
JOIN dbo.v_GS_PC_BIOS BIOS ON BIOS.ResourceID = COMPUTER_SYSTEM_PRODUCT_DATA.MachineID

Where Manufacturer00 LIKE '%LENOVO%'

GROUP BY Manufacturer00,Version00,LEFT(SMBIOSBIOSVersion0,4),LEFT(model00,4)
ORDER BY 'ModelName'
"@
	
	$ServerInstance = "AH-SCCM-01.contoso.com"
	$DB = "CM_PAY"
	
	$SQLResults = Invoke-Sqlcmd -Query $SQLQuery -ServerInstance $ServerInstance -Database $DB
	
	$LimitingCollectionId = 'SMS00001' #All Systems
	$ExcludeServers = 'PAY0000A' #All Windows Servers
	
	FOREACH ($Machine IN $SQLResults) {
		#Set Collection values
		$CollName = "All $($Machine.Manufacturer) $($Machine.ModelName) ($($Machine.Prefix)) Workstations"
		$CollComment = @"
All $($Manufacturer) $($Series) $($ModelName) ($($ModelNum4)) Workstations
BIOS Prefix: $BIOSPrefix
"@
		
		$Query = "select SMS_R_System.Name, SMS_G_System_COMPUTER_SYSTEM.Manufacturer, SMS_G_System_COMPUTER_SYSTEM.Model, SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version from  SMS_R_System inner join SMS_G_System_COMPUTER_SYSTEM on SMS_G_System_COMPUTER_SYSTEM.ResourceID = SMS_R_System.ResourceId inner join SMS_G_System_COMPUTER_SYSTEM_PRODUCT on SMS_G_System_COMPUTER_SYSTEM_PRODUCT.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COMPUTER_SYSTEM_PRODUCT.Version like `"%$($Machine.ModelName)%`" and SMS_G_System_COMPUTER_SYSTEM.Model like `"$($Machine.Prefix)%`" and SMS_G_System_COMPUTER_SYSTEM.Manufacturer like `"%$($Machine.Manufacturer)%`""
		#Test for existing collection
		IF (Get-CMCollection -Name "$CollName") {
			Write-Host "$CollName already exists. Skipping."
		} ELSEIF (!(Get-CMCollection -Name "$CollName")) {
			Write-Host "Creating Collection: $CollName."
		<#Generate Random Time for eval
		[string]$Random_Hour = Get-Random -InputObject 18,19,20,21,22,23
		[string]$Random_Minute = Get-Random -InputObject 15, 30, 45
		$Start = $Random_Hour + ':' + $Random_Minute
		#create schedule variables
		$Schedule = New-CMSchedule -RecurCount 3 -RecurInterval Days -Start $Start
		# Create collections
		New-CMDeviceCollection -Name "$CollName" -RefreshType Periodic -RefreshSchedule $Schedule -LimitingCollectionId $LimitingCollectionId
		Add-CMDeviceCollectionQueryMembershipRule -CollectionName "$CollName" -QueryExpression "$Query" -RuleName "$CollName"
		Add-CMDeviceCollectionExcludeMembershipRule -CollectionName "$CollName" -ExcludeCollectionId $ExcludeServers
		#>
		}
	}
} CATCH {
	$LASTEXITCODE	
}

Set-Location $CurrentLocation
