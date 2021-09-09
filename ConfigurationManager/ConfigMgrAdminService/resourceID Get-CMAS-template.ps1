FUNCTION Get-CMASreplaceThisNoun {
<#
    .SYNOPSIS
        Get replaceThisNoun from AdminService
    
    .DESCRIPTION
        Get all replaceThisNoun from AdminService
    
    .PARAMETER adminServerLocalFQDN
        ConfigMgr AdminService hostname FQDN
    
    .PARAMETER All
        Gets all replaceThisNoun
    
    .PARAMETER nameStartsWith
        Filters start of replaceThisNoun name.
        Implies wildcard (*) used on end of input string
    
    .PARAMETER nameContains
        Filters content of replaceThisNoun name.
        Implies wildcard (*) at beginning and end of input string.
    
    .PARAMETER resourceID
        Array of strings.
        Gets specified resourceID(s)
    
    .EXAMPLE
        PS C:\> Get-CMASreplaceThisNoun -All
    
    .EXAMPLE
        PS C:\> Get-CMASreplaceThisNoun -nameStartsWith "TWF-"
    
    .EXAMPLE
        PS C:\> Get-CMASreplaceThisNoun -nameContains "1234abcd"
    
    .EXAMPLE
        PS C:\> Get-CMASreplaceThisNoun -resourceID '16456789','16456790'
    
    .NOTES
        Additional information about the function.
#>
    
    [CmdletBinding(DefaultParameterSetName = 'replaceThisNounsAll')]
    PARAM
    (
        [ValidateNotNullOrEmpty()][string]$adminServerLocalFQDN = $CM_ProviderMachineName,
        
        [Parameter(ParameterSetName = 'replaceThisNounsAll')][switch]$All,
        
        [Parameter(ParameterSetName = 'replaceThisNounsNameStartsWith',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameStartsWith,
        
        [Parameter(ParameterSetName = 'replaceThisNounsNameContains',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameContains,
        
        [Parameter(ParameterSetName = 'resourceIDs',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$resourceID
    )
    
    # Set logging component name
    $Component = $MyInvocation.MyCommand
    
    # AdminService URI
    $adminServiceWMI = ''
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
    IF ($resourceID) {
        IF ($resourceID.Count -ge 2) {
            $filterResourceIDs = @(
                FOREACH ($resource IN $resourceID) {
                    'ResourceId eq {0}' -f $resource
                }
            ) -join ' or '
            $filterString = '?$filter=({0})' -f $filterResourceIDs
        }
        ELSEIF ($resourceID.Count -eq 1) {
            $filterString = '({0})' -f $resourceID
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