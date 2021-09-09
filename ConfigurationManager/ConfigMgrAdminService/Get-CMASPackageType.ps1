FUNCTION Get-CMASPackageType {
<#
    .SYNOPSIS
        UNFINISHED Get PackageType from AdminService
    
    .DESCRIPTION
        Get all PackageType from AdminService
    
    .PARAMETER adminServerLocalFQDN
        ConfigMgr AdminService hostname FQDN
    
    .PARAMETER packageID
        Array of strings.
        Gets specified packageID(s)
    
    .EXAMPLE
        PS C:\> Get-CMASPackageType -packageID 'P0156789','P0156790'
    
    .NOTES
        Additional information about the function.
#>
    
    [CmdletBinding(DefaultParameterSetName = 'PackageTypesAll')]
    PARAM
    (
        [ValidateNotNullOrEmpty()][string]$adminServerLocalFQDN = $CM_ProviderMachineName,
        
        [Parameter(ParameterSetName = 'packageIDs',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$packageID
    )
    
    # Set logging component name
    $Component = $MyInvocation.MyCommand
    
    # AdminService URI
    $adminServiceWMI = 'SMS_PackageBaseclass'
    $URI = 'https://{0}/AdminService/wmi/{1}' -f $adminServerLocalFQDN,$adminServiceWMI
    <#
    $adminServiceODATA = ''
    $URI = 'https://{0}/AdminService/v1.0/{1}' -f $adminServerLocalFQDN,$adminServiceODATA
    #>

    IF ($packageID) {
        IF ($packageID.Count -ge 2) {
            $filterpackageIDs = @(
                FOREACH ($package IN $packageID) {
                    'packageID eq {0}' -f $package
                }
            ) -join ' or '
            $filterString = '?$filter=({0})' -f $filterpackageIDs
        }
        ELSEIF ($packageID.Count -eq 1) {
            $filterString = '({0})' -f $packageID
        }
    }
    
    # Add filter to URI
    $URI = $URI + $filterString
    
    Write-Log -Message "Querying REST API at $URI"
    $response = Invoke-RestMethod -Uri $URI -Method Get -UseDefaultCredentials -ErrorAction Stop
    IF ($response.value) {
        Write-Log -Message "   Found $($response.value.count) items"
        RETURN $response.value
    }
    ELSE {
        RETURN $false
    }
}