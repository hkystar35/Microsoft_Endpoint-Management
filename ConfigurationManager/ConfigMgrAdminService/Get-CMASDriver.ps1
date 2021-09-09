FUNCTION Get-CMASDriver {
    <#
    .SYNOPSIS
        Get Driver from AdminService
    
    .DESCRIPTION
        Get all Driver from AdminService
    
    .PARAMETER adminServerLocalFQDN
        ConfigMgr AdminService hostname FQDN
    
    .PARAMETER All
        Gets all Drivers
    
    .PARAMETER nameStartsWith
        Filters start of Driver name.
        Implies wildcard (*) used on end of input string
    
    .PARAMETER nameContains
        Filters content of Driver name.
        Implies wildcard (*) at beginning and end of input string.
    
    .PARAMETER CIID
        Array of strings.
        Gets specified CIID(s)
    
    .EXAMPLE
        PS C:\> Get-CMASDriver -All
    
    .EXAMPLE
        PS C:\> Get-CMASDriver -nameStartsWith "TWF-"
    
    .EXAMPLE
        PS C:\> Get-CMASDriver -nameContains "1234abcd"
    
    .EXAMPLE
        PS C:\> Get-CMASDriver -CIID '16456789','16456790'
    
    .NOTES
        Additional information about the function.
#>
    
    [CmdletBinding(DefaultParameterSetName = 'DriversAll')]
    PARAM
    (
        [ValidateNotNullOrEmpty()][string]$adminServerLocalFQDN = $CM_ProviderMachineName,
        
        [Parameter(ParameterSetName = 'DriversAll')][switch]$All,
        
        [Parameter(ParameterSetName = 'DriversNameStartsWith',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameStartsWith,
        
        [Parameter(ParameterSetName = 'DriversNameContains',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameContains,
        
        [Parameter(ParameterSetName = 'CIIDs',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$CIID
    )
    
    # Set logging component name
    $Component = $MyInvocation.MyCommand
    
    # AdminService URI
    $adminServiceWMI = 'SMS_Driver'
    $URI = 'https://{0}/AdminService/wmi/{1}' -f $adminServerLocalFQDN, $adminServiceWMI
    <#
    $adminServiceODATA = ''
    $URI = 'https://{0}/AdminService/v1.0/{1}' -f $adminServerLocalFQDN,$adminServiceODATA
    #>

    IF ($nameContains) {
        $filterString = '?$filter=contains(LocalizedDisplayName,''{0}'')' -f $nameContains
    }
    IF ($nameStartsWith) {
        $filterString = '?$filter=startswith(LocalizedDisplayName,''{0}'')' -f $nameStartsWith
    }
    IF ($CIID.Count -ge 1) {
        $filterCIIDs = @(
            FOREACH ($ID IN $CIID) {
                'CI_ID eq {0}' -f $ID
            }
        ) -join ' or '
        $filterString = '?$filter=({0})' -f $filterCIIDs
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