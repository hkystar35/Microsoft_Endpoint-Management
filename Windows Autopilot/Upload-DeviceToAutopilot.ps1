[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#Script variables
$clientId = "enterprise app client ID"
$tenantName = "tenant.onmicrosoft.com"
$ClientSecret = "enterprise app client secret"

#Retrieve OAuth token
$ReqTokenBody = @{
	Grant_Type = "client_credentials"
	Scope = "https://graph.microsoft.com/.default"
	client_Id = $clientID
	Client_Secret = $clientSecret
}

$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody

$HeaderParams = @{ Authorization = "Bearer $($Tokenresponse.access_token)" }

# Gather device hash data
Write-Verbose -Message "Gather device hash data from local machine"
$DeviceHashData = (Get-WmiObject -Namespace "root/cimv2/mdm/dmmap" -Class "MDM_DevDetail_Ext01" -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" -Verbose:$false).DeviceHardwareData
$SerialNumber = (Get-WmiObject -Class "Win32_BIOS" -Verbose:$false).SerialNumber
$ProductKey = (Get-WmiObject -Class "SoftwareLicensingService" -Verbose:$false).OA3xOriginalProductKey
$GroupTag = "HOF9000"

# Construct Graph variables
$GraphVersion = "beta"
$GraphResource = "deviceManagement/importedWindowsAutopilotDeviceIdentities"
$GraphURI = "https://graph.microsoft.com/$($GraphVersion)/$($GraphResource)"

# Construct hash table for new Autopilot device identity and convert to JSON
Write-Verbose -Message "Constructing required JSON body based upon parameter input data for device hash upload"
$AutopilotDeviceIdentity = [ordered]@{
	'@odata.type' = '#microsoft.graph.importedWindowsAutopilotDeviceIdentity'
	'orderIdentifier' = IF ($GroupTag) { "$($GroupTag)" } else { "" }
	'serialNumber' = "$($SerialNumber)"
	'productKey' = IF ($ProductKey) { "$($ProductKey)" } else { "" }
	'hardwareIdentifier' = "$($DeviceHashData)"
	'assignedUserPrincipalName' = IF ($UserPrincipalName) { "$($UserPrincipalName)" } else { "" }
	'state' = @{
		'@odata.type' = 'microsoft.graph.importedWindowsAutopilotDeviceIdentityState'
		'deviceImportStatus' = 'pending'
		'deviceRegistrationId' = ''
		'deviceErrorCode' = 0
		'deviceErrorName' = ''
	}
}
$AutopilotDeviceIdentityJSON = $AutopilotDeviceIdentity | ConvertTo-Json

TRY {
	# Call Graph API and post JSON data for new Autopilot device identity
	Write-Verbose -Message "Attempting to post data for hardware hash upload"
	$AutopilotDeviceIdentityResponse = Invoke-RestMethod -Uri $GraphURI -Headers $HeaderParams -Method Post -Body $AutopilotDeviceIdentityJSON -ContentType "application/json" -ErrorAction Stop -Verbose:$false
	$AutopilotDeviceIdentityResponse
}
CATCH [System.Exception] {
	# Construct stream reader for reading the response body from API call
	$ResponseBody = Get-ErrorResponseBody -Exception $_.Exception
	
	# Handle response output and error message
	Write-Output -InputObject "Response content:`n$ResponseBody"
	Write-Warning -Message "Failed to upload hardware hash. Request to $($GraphURI) failed with HTTP Status $($_.Exception.Response.StatusCode) and description: $($_.Exception.Response.StatusDescription)"
}