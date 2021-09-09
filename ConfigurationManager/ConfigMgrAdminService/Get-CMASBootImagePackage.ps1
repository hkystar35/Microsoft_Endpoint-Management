#region FUNCTION Get-CMASBootImagePackage
FUNCTION Get-CMASBootImagePackage {
<#
    .SYNOPSIS
        Get BootImagePackage from AdminService
    
    .DESCRIPTION
        Get all BootImagePackage from AdminService
    
    .PARAMETER adminServerLocalFQDN
        ConfigMgr AdminService hostname FQDN
    
    .PARAMETER All
        Gets all BootImagePackage
    
    .PARAMETER nameStartsWith
        Filters start of BootImagePackage name.
        Implies wildcard (*) used on end of input string
    
    .PARAMETER nameContains
        Filters content of BootImagePackage name.
        Implies wildcard (*) at beginning and end of input string.
    
    .PARAMETER packageID
        Array of strings.
        Gets specified packageID(s)
    
    .EXAMPLE
        PS C:\> Get-CMASBootImagePackage -All
    
    .EXAMPLE
        PS C:\> Get-CMASBootImagePackage -nameStartsWith "TWF-"
    
    .EXAMPLE
        PS C:\> Get-CMASBootImagePackage -nameContains "1234abcd"
    
    .EXAMPLE
        PS C:\> Get-CMASBootImagePackage -packageID '16456789','16456790'
    
    .NOTES
        Additional information about the function.
#>
    
    [CmdletBinding(DefaultParameterSetName = 'BootImagePackagesAll')]
    PARAM
    (
        [ValidateNotNullOrEmpty()][string]$adminServerLocalFQDN = $CM_ProviderMachineName,
        
        [Parameter(ParameterSetName = 'BootImagePackagesAll')][switch]$All,
        
        [Parameter(ParameterSetName = 'BootImagePackagesNameStartsWith',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameStartsWith,
        
        [Parameter(ParameterSetName = 'BootImagePackagesNameContains',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameContains,
        
        [Parameter(ParameterSetName = 'packageIDs',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$packageID
    )
    
    # Set logging component name
    $Component = $MyInvocation.MyCommand
    
    # AdminService URI
    $adminServiceWMI = 'SMS_BootImagePackage'
    $URI = 'https://{0}/AdminService/wmi/{1}' -f $adminServerLocalFQDN,$adminServiceWMI
    <#
    $adminServiceODATA = ''
    $URI = 'https://{0}/AdminService/v1.0/{1}' -f $adminServerLocalFQDN,$adminServiceODATA
    #>

    IF ($nameContains) {
        $filterString = '?$filter=contains(Name,''{0}'')' -f $nameContains
    }
    IF ($nameStartsWith) {
        $filterString = '?$filter=startswith(Name,''{0}'')' -f $nameStartsWith
    }
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
#endregion FUNCTION Get-CMASBootImagePackage