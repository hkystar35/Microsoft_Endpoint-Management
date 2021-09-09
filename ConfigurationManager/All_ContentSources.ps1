#borrowed script
#clear-host

#region FUNCTIONS

FUNCTION Get-CMASDriverPackage {
    <#
        .SYNOPSIS
            Get DriverPackage from AdminService
        
        .DESCRIPTION
            Get all DriverPackage from AdminService
        
        .PARAMETER adminServerLocalFQDN
            ConfigMgr AdminService hostname FQDN
        
        .PARAMETER All
            Gets all DriverPackage
        
        .PARAMETER nameStartsWith
            Filters start of DriverPackage name.
            Implies wildcard (*) used on end of input string
        
        .PARAMETER nameContains
            Filters content of DriverPackage name.
            Implies wildcard (*) at beginning and end of input string.
        
        .PARAMETER packageID
            Array of strings.
            Gets specified packageID(s)
        
        .EXAMPLE
            PS C:\> Get-CMASDriverPackage -All
        
        .EXAMPLE
            PS C:\> Get-CMASDriverPackage -nameStartsWith "TWF-"
        
        .EXAMPLE
            PS C:\> Get-CMASDriverPackage -nameContains "1234abcd"
        
        .EXAMPLE
            PS C:\> Get-CMASDriverPackage -packageID '16456789','16456790'
        
        .NOTES
            Additional information about the function.
    #>
        
    [CmdletBinding(DefaultParameterSetName = 'DriverPackagesAll')]
    PARAM
    (
        [ValidateNotNullOrEmpty()][string]$adminServerLocalFQDN = $CM_ProviderMachineName,
            
        [Parameter(ParameterSetName = 'DriverPackagesAll')][switch]$All,
            
        [Parameter(ParameterSetName = 'DriverPackagesNameStartsWith',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameStartsWith,
            
        [Parameter(ParameterSetName = 'DriverPackagesNameContains',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameContains,
            
        [Parameter(ParameterSetName = 'packageIDs',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$packageID
    )
        
    # Set logging component name
    $Component = $MyInvocation.MyCommand
        
    # AdminService URI
    $adminServiceWMI = 'SMS_DriverPackage'
    $URI = 'https://{0}/AdminService/wmi/{1}' -f $adminServerLocalFQDN, $adminServiceWMI
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

FUNCTION Get-CMASPackages {
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
    $URI = 'https://{0}/AdminService/wmi/{1}' -f $adminServerLocalFQDN, $adminServiceWMI
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

FUNCTION Get-CMASOperatingSystemInstallPackage {
    <#
        .SYNOPSIS
            Get OperatingSystemInstallPackage from AdminService
        
        .DESCRIPTION
            Get all OperatingSystemInstallPackage from AdminService
        
        .PARAMETER adminServerLocalFQDN
            ConfigMgr AdminService hostname FQDN
        
        .PARAMETER All
            Gets all OperatingSystemInstallPackage
        
        .PARAMETER nameStartsWith
            Filters start of OperatingSystemInstallPackage name.
            Implies wildcard (*) used on end of input string
        
        .PARAMETER nameContains
            Filters content of OperatingSystemInstallPackage name.
            Implies wildcard (*) at beginning and end of input string.
        
        .PARAMETER packageID
            Array of strings.
            Gets specified packageID(s)
        
        .EXAMPLE
            PS C:\> Get-CMASOperatingSystemInstallPackage -All
        
        .EXAMPLE
            PS C:\> Get-CMASOperatingSystemInstallPackage -nameStartsWith "TWF-"
        
        .EXAMPLE
            PS C:\> Get-CMASOperatingSystemInstallPackage -nameContains "1234abcd"
        
        .EXAMPLE
            PS C:\> Get-CMASOperatingSystemInstallPackage -packageID '16456789','16456790'
        
        .NOTES
            Additional information about the function.
    #>
        
    [CmdletBinding(DefaultParameterSetName = 'OperatingSystemInstallPackagesAll')]
    PARAM
    (
        [ValidateNotNullOrEmpty()][string]$adminServerLocalFQDN = $CM_ProviderMachineName,
            
        [Parameter(ParameterSetName = 'OperatingSystemInstallPackagesAll')][switch]$All,
            
        [Parameter(ParameterSetName = 'OperatingSystemInstallPackagesNameStartsWith',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameStartsWith,
            
        [Parameter(ParameterSetName = 'OperatingSystemInstallPackagesNameContains',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameContains,
            
        [Parameter(ParameterSetName = 'packageIDs',
            Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$packageID
    )
        
    # Set logging component name
    $Component = $MyInvocation.MyCommand
        
    # AdminService URI
    $adminServiceWMI = 'SMS_OperatingSystemInstallPackage'
    $URI = 'https://{0}/AdminService/wmi/{1}' -f $adminServerLocalFQDN, $adminServiceWMI
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

#endregion FUNCTIONS

function GetInfoPackages() {
    $xPackages = Get-CMPackage | Select-object Name, PkgSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object
    }
    $info
}


function GetInfoDriverPackage() {
    $xPackages = Get-CMDriverPackage | Select-object Name, PkgSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object

    }
    $info
}


function GetInfoBootimage() {
    $xPackages = Get-CMBootImage | Select-object Name, PkgSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object
    
    }
    $info
}


function GetInfoOSImage() {
    $xPackages = Get-CMOperatingSystemImage | Select-object Name, PkgSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object
    
    }
    $info
}


function GetInfoDriver() {
    $xPackages = Get-CMDriver | Select-object LocalizedDisplayName, ContentSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.LocalizedDisplayName
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.ContentSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object
    
    }
    $info
}


function GetInfoSWUpdatePackage() {
    $xPackages = Get-CMSoftwareUpdateDeploymentPackage | Select-object Name, PkgSourcePath, PackageID
    $info = @()
    foreach ($xpack in $xPackages) {
        #write-host $xpack.Name
        $object = New-Object -TypeName PSObject
        $object | Add-Member -MemberType NoteProperty  -Name Package -Value $xpack.Name
        $object | Add-Member -MemberType NoteProperty  -Name SourceDir -Value $xpack.PkgSourcePath
        $object | Add-Member -MemberType NoteProperty  -Name PackageID -Value $xpack.PackageID
        $info += $object
    
    }
    $info
}



function GetInfoApplications {
   
    foreach ($Application in Get-CMApplication) {
 
        $AppMgmt = ([xml]$Application.SDMPackageXML).AppMgmtDigest
        $AppName = $AppMgmt.Application.DisplayInfo.FirstChild.Title

        foreach ($DeploymentType in $AppMgmt.DeploymentType) {

            # Calculate Size and convert to MB
            $size = 0
            foreach ($MyFile in $DeploymentType.Installer.Contents.Content.File) {
                $size += [long]($MyFile.GetAttribute("Size"))
            }
            $size = [math]::truncate($size / 1MB)
 
            # Fill properties
            $AppData = @{            
                AppName            = $AppName
                Location           = $DeploymentType.Installer.Contents.Content.Location
                DeploymentTypeName = $DeploymentType.Title.InnerText
                Technology         = $DeploymentType.Installer.Technology
                ContentId          = $DeploymentType.Installer.Contents.Content.ContentId
          
                SizeMB             = $size
            }                           

            # Create object
            $Object = New-Object PSObject -Property $AppData
    
            # Return it
            $Object
        }
    }
}





# Get the Data

Write-host "Applications" -ForegroundColor Yellow
GetInfoApplications | select-object AppName, Location, Technology | Export-Csv -NoTypeInformation -Path C:\temp\Applications_sources.csv

Write-host "Driver Packages" -ForegroundColor Yellow
GetInfoDriverPackage | Export-Csv -NoTypeInformation -Path C:\temp\DriverPackages_sources.csv

Write-host "Drivers" -ForegroundColor Yellow
GetInfoDriver | Export-Csv -NoTypeInformation -Path C:\temp\Drivers_sources.csv

Write-host "Boot Images" -ForegroundColor Yellow
GetInfoBootimage | Export-Csv -NoTypeInformation -Path C:\temp\BootImages_sources.csv

Write-host "OS Images" -ForegroundColor Yellow
GetInfoOSImage | Export-Csv -NoTypeInformation -Path C:\temp\OSImages_sources.csv

Write-host "Software Update Package Groups" -ForegroundColor Yellow
GetInfoSWUpdatePackage | Export-Csv -NoTypeInformation -Path C:\temp\SoftwareUpdatePackageGroups_sources.csv

Write-host "Packages" -ForegroundColor Yellow
GetInfoPackages | Export-Csv -NoTypeInformation -Path C:\temp\Packages_sources.csv