FUNCTION Remove-CMASResource {
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
                    PS C:\> Get-CMASPackages -All
    
        .EXAMPLE
                    PS C:\> Get-CMASPackages -Name "Drivers - *"
        
        .NOTES
            Additional information about the function.
    #>
        
    [CmdletBinding()][OutputType([System.Array])]
    PARAM
    (
        [Parameter(HelpMessage = 'FQDN of SMS Provider service role')][ValidateNotNullOrEmpty()][Alias('SMS')][string]$AdminServiceProviderFQDN = 'sccm-no-01.af.lan',
            
        [ValidateNotNullOrEmpty()][string[]]$DeviceNames,
            
        [ValidateNotNullOrEmpty()][string[]]$ResourceIDs
            
    )
        
    # WMI URI
    $smsURI = 'https://{0}/AdminService/wmi/SMS_Package' -f $AdminServiceProviderFQDN
        
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