FUNCTION Get-CMASPackage {
	<#
	.SYNOPSIS
		Gets Configuration Manager Packages
	
	.DESCRIPTION
		Gets Configuration Manager Packages from AdminSurvice API. Currently using WMI until Odata has more options
	
	.PARAMETER AdminServiceProviderFQDN
		FQDN of SMS Provider service role
	
	.PARAMETER Name
		Name of Package to filter. Supports wildcards.
	
	.PARAMETER PackageIDs
		Package ID(s) of specific Packages to retrieve.
	
	.PARAMETER Description
		Filter Packages by Description. Supports wildcards
	
	.PARAMETER All
		Retrieve all Pacakges.
	
	.EXAMPLE
				PS C:\> Get-CMASPackage -All

	.EXAMPLE
				PS C:\> Get-CMASPackage -Name "Drivers - *"
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding(DefaultParameterSetName = 'All')][OutputType([System.Array])]
	PARAM
	(
		[Parameter(ParameterSetName = 'Filter',
			HelpMessage = 'FQDN of SMS Provider service role')][ValidateNotNullOrEmpty()][Alias('SMS')][string]$AdminServiceProviderFQDN,
		
		[Parameter(ParameterSetName = 'Filter')][SupportsWildcards()][ValidateNotNullOrEmpty()][string]$Name,
		
		[Parameter(ParameterSetName = 'Filter')][ValidateNotNullOrEmpty()][string[]]$PackageIDs,
		
		[Parameter(ParameterSetName = 'Filter')][SupportsWildcards()][ValidateNotNullOrEmpty()]$Description,
		
		[Parameter(ParameterSetName = 'All',
			Mandatory = $true)][switch]$All
	)
	
	# AdminService URI
    $adminServiceWMI = 'SMS_Package'
    $URI = 'https://{0}/AdminService/wmi/{1}' -f $AdminServiceProviderFQDN,$adminServiceWMI
    <#
    $adminServiceODATA = ''
    $URI = 'https://{0}/AdminService/v1.0/{1}' -f $AdminServiceProviderFQDN,$adminServiceODATA
    #>

	Write-Verbose "AdminService REST API base RUI: $smsURI"
	
	IF ($PSBoundParameters.ContainsKey('PackageIDs')) {
		IF ($PackageIDs.Count -gt 1) {
			$filterPackageIDs = @(
				FOREACH ($PackageID IN $PackageIDs) {
					'PackageID eq ''{0}''' -f $PackageID
				}
			) -join ' or '
			$uriSuffix = '?$filter=({0})' -f $filterPackageIDs
		}
		ELSE {
			$keyPackageID = $PackageIDs
			$uriSuffix = '({0})' -f $keyPackageID
		}
		
	}
	ELSEIF ($PSBoundParameters.ContainsKey('Name')) {
		
	}
	
	ELSEIF ($PSBoundParameters.ContainsKey('Description')) {
		
	}
	
	# Full URI
	$URI = $URI + $uriSuffix
	Write-Verbose "Full URI: $URI"
	
	$response = Invoke-RestMethod -Uri $URI -Method Get -UseDefaultCredentials -ErrorAction Stop
	IF ($response.value) {
		Write-Verbose "   Found $($response.value.count) items"
		$response.value
	}
}