<#
    .SYNOPSIS
    A brief description of the !Template.ps1 file.
	
    .DESCRIPTION
    A description of the file.
	
    .PARAMETER Input
    A description of the Input parameter.
	
    .NOTES
    ===========================================================================

    Created on:   	2021-07-12 16:19:10
    Created by:   	Nicolas.Wendlowsky@chobani.com
    Organization: 	Chobani
    Filename:	      
    ===========================================================================
#>
[CmdletBinding()]
PARAM
(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$CM_SiteCode = 'NOR',
	
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$CM_ProviderMachineName = 'SCCM-NO-01.af.lan',

    [Parameter(Mandatory = $true, HelpMessage = 'String array of OUs to search in DistinguishedName format: "DC=domain,DC=TLD"')]
    [ValidateNotNullOrEmpty()]
    [string[]]$OUs,

    [Parameter(HelpMessage = 'Enter a single email address.')][ValidatePattern('^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@chobani.com')]
    [ValidateNotNullOrEmpty()]
    [Alias('E')]
    [String[]]$EmailAddress,

    [Parameter(HelpMessage = 'Set minimum number of days a machine has to be stale in order to mark for Disablement. Default it 60')]
    [ValidateNotNullOrEmpty()]
    [int]$OlderThanDays,

    [Parameter(HelpMessage = 'Folder path to export table to Excel')]
    [ValidateNotNullOrEmpty()]
    [System.IO.DirectoryInfo]$ExcelFolderPath,

    [Parameter(HelpMessage = 'Warninig: Will disable all machines identified as "Disable"')]
    [switch]$Disable,

    [Parameter(Mandatory = $true)]
    [string]$DisabledOU
)
BEGIN {
    $InvocationInfo = $MyInvocation
    [System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
    [string]$ScriptFullPath = $ScriptFileInfo.FullName
    [string]$ScriptNameFileExt = $ScriptFileInfo.Name
    [string]$ScriptName = $ScriptFileInfo.BaseName
    [string]$scriptRoot = Split-Path $ScriptFileInfo
    # Set TLS
    [Net.ServicePointManager]::SecurityProtocol = 'Tls12'
	
    [string]$Script:Component = 'Begin-Script'
    #region FUNCTION Write-Log
    FUNCTION Write-Log {
        <#
	.SYNOPSIS
		Create log file
	
	.DESCRIPTION
		Logs messages in Configuration Manager-specific format for easy cmtrace.exe reading
	
	.PARAMETER Message
		Value added to the log file.
	
	.PARAMETER Level
		Severity for the log entry.
	
	.PARAMETER FileName
		Name of the log file that the entry will written to.
	
	.PARAMETER LogsDirectory
		A description of the LogsDirectory parameter.
	
	.EXAMPLE
				PS C:\> Write-Log -Message 'Value1'
	
	.NOTES
		Additional information about the function.
#>
		
        [CmdletBinding()]
        PARAM
        (
            [Parameter(Mandatory = $true,
                HelpMessage = 'Value added to the log file.')][ValidateNotNullOrEmpty()][string]$Message,
            [Parameter(Mandatory = $false,
                HelpMessage = 'Severity for the log entry.')][ValidateNotNullOrEmpty()][ValidateSet('Error', 'Warn', 'Info')][string]$Level = "Info",
            [Parameter(Mandatory = $false,
                HelpMessage = 'Name of the log file that the entry will written to.')][ValidateNotNullOrEmpty()][string]$FileName = "$($ScriptName).log",
            [string]$LogsDirectory = "$env:windir\Logs"
        )
		
        # Determine log file location
        IF ($FileName.Length -le 4) {
            $FileName = "GenericScriptLog_$(Get-Date -Format yyyy-MM-dd)$FileName"
        }
        $LogFilePath = Join-Path -Path $LogsDirectory -ChildPath $FileName
		
        # Construct time stamp for log entry
        IF (-not (Test-Path -Path 'variable:global:TimezoneBias')) {
            [string]$global:TimezoneBias = [System.TimeZoneInfo]::Local.GetUtcOffset((Get-Date)).TotalMinutes
            IF ($TimezoneBias -match "^-") {
                $TimezoneBias = $TimezoneBias.Replace('-', '+')
            }
            ELSE {
                $TimezoneBias = '-' + $TimezoneBias
            }
        }
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), $TimezoneBias)
		
        # Construct date for log entry
        $Date = (Get-Date -Format "MM-dd-yyyy")
		
        # Construct context for log entry
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
		
        # Switch Severity to number
        SWITCH ($Level) {
            "Info"	{
                $Severity = 1
            }
            "Warn" {
                $Severity = 2
            }
            "Error" {
                $Severity = 3
            }
            default {
                $Severity = 1
            }
        }
		
        # Construct final log entry
        $LogText = "<![LOG[$($Message)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""$($component)"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
		
        # Add value to log file
        TRY {
            Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop -WhatIf:$false
        }
        CATCH [System.Exception] {
            Write-Warning -Message "Unable to append log entry to $($FileName) file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
        }
    }
    #endregion FUNCTION Write-Log
    Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
    #region FUNCTION Install-PoShPackageProviders
    FUNCTION Install-PoShPackageProviders {
        <#
	.SYNOPSIS
		Silently installs package providers
	
	.DESCRIPTION
		Mainly used for ensuring NuGet is installed
	
	.PARAMETER PackageProviders
		A description of the PackageProviders parameter.
	
	.EXAMPLE
				PS C:\> Install-PoShPackageProviders
	
	.NOTES
		Additional information about the function.
#>
		
        [CmdletBinding()]
        PARAM
        (
            [ValidateNotNullOrEmpty()][string[]]$PackageProviders
        )
		
        TRY {
            FOREACH ($PackageProvider IN $PackageProviders) {
                IF ((Get-PackageProvider -Name $PackageProvider -ErrorAction SilentlyContinue) -eq $null) {
                    Write-Log -Message "$PackageProvider missing. Installing now."
                    Find-PackageProvider -Name $PackageProvider -OutVariable Latest -ErrorAction Stop
                    Install-PackageProvider -Name $PackageProvider -MinimumVersion $Latest[0].version -ErrorAction Stop
                }
            }
        }
        CATCH {
            Write-Log -Message "Could not install $PackageProvider" -Level Warn
            $Line = $_.InvocationInfo.ScriptLineNumber
            Write-Log -Message "Error: on line $line"
            THROW "Error: $_"
        }
    }
	
    #endregion FUNCTION Install-PoShPackageProviders
    #region FUNCTION Install-PoShModules
    FUNCTION Install-PoShModules {
        <#
	.SYNOPSIS
		Silently installs PoSh modules
	
	.DESCRIPTION
		PowerShellGet, sqlserver, etc.
	
	.PARAMETER ModuleNames
		A description of the ModuleNames parameter.
	
	.EXAMPLE
				PS C:\> Install-PoShModules
	
	.NOTES
		Additional information about the function.
#>
		
        [CmdletBinding()]
        PARAM
        (
            [ValidateNotNullOrEmpty()][Alias('M')][string[]]$ModuleNames
        )
		
        FOREACH ($ModuleName IN $ModuleNames) {
            IF ($ModuleName) {
                IF ((Get-Module -Name $ModuleName -ErrorAction SilentlyContinue) -eq $null) {
                    Write-Log -Message "$ModuleName module not imported."
                    Install-Module -Name $ModuleName -Force -ErrorAction Stop
                    Import-Module $ModuleName -Force -Cmdlet:$false -ErrorAction Stop
                    TRY {
                        Get-Module -Name $ModuleName -ErrorAction Stop
                        Write-Log -Message "$ModuleName module now present found."
                    }
                    CATCH {
                        Write-Log -Message "Could not import $ModuleName module" -Level Warn
                        $Line = $_.InvocationInfo.ScriptLineNumber
                        Write-Log -Message "Error: on line $line"
                        Send-ErrorEmail -Message "Could not import $ModuleName module.`nError on line $line.`nError: $_"
                        THROW "Error: $_"
                    }
                }
            }
            ELSE {
                Write-Log -Message 'No Modules to import.'
            }
        }
    }
    #endregion FUNCTION Install-PoShModules

    #region FUNCTION Get-CMASDevice
    FUNCTION Get-CMASDevice {
        <#
        .SYNOPSIS
            Get Device from AdminService
        
        .DESCRIPTION
            Get all Devices from AdminService
        
        .PARAMETER AdminServerLocalFQDN
            ConfigMgr AdminService hostname FQDN
        
        .PARAMETER All
            Default: $true
            Gets all Devices
        
        .PARAMETER nameStartsWith
            Filters start of Device name.
            Implies wildcard (*) used on end of input string
        
        .PARAMETER nameContains
            Filters content of Device name.
            Implies wildcard (*) at beginning and end of input string.
        
        .PARAMETER resourceID
            Array of strings.
            Gets specified resourceID(s)
        
        .EXAMPLE
            PS C:\> Get-CMASDevice -All
        
        .EXAMPLE
            PS C:\> Get-CMASDevice -nameStartsWith "TWF-"
        
        .EXAMPLE
            PS C:\> Get-CMASDevice -nameContains "1234abcd"
        
        .EXAMPLE
            PS C:\> Get-CMASDevice -resourceID '16456789','16456790'
        
        .NOTES
            Additional information about the function.
    #>
        
        [CmdletBinding(DefaultParameterSetName = 'devicesAll')]
        PARAM
        (
            [ValidateNotNullOrEmpty()][string]$AdminServerLocalFQDN = $CM_ProviderMachineName,
            
            [Parameter(ParameterSetName = 'devicesAll')][switch]$All,
            
            [Parameter(ParameterSetName = 'devicesNameStartsWith',
                Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameStartsWith,
            
            [Parameter(ParameterSetName = 'devicesNameContains',
                Mandatory = $true)][ValidateNotNullOrEmpty()][string]$nameContains,
            
            [Parameter(ParameterSetName = 'resourceIDs',
                Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$resourceID
        )
        
        # Set logging component name
        $Component = $MyInvocation.MyCommand
        
        # AdminService URI
        $URI = 'https://{0}/AdminService/wmi/SMS_R_System' -f $AdminServerLocalFQDN
        #$URI = 'https://{0}/AdminService/v1.0/device' -f $AdminServerLocalFQDN
        
        #$filter = (Name eq 'NORxxx123')
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
            $response.value
        }
        ELSE {
            RETURN $false
        }
    }
    #endregion FUNCTION Get-CMASDevice

    #region FUNCTION Get-StaleADComputers
    FUNCTION Get-StaleADComputers {
        [CmdletBinding(ConfirmImpact = 'None',
            SupportsShouldProcess = $false)][OutputType([psobject])]
        PARAM
        (
            [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string[]]$OUsToSearch,
            [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][int]$DaysSinceLastLogin
        )
        BEGIN {
            # Set logging component name
            $Component = $MyInvocation.MyCommand
        }
        PROCESS {
            Write-Log -Message "Gathering Stale AD Computers with Last Logon older than $DaysSinceLastLogin days"

            # Connect to DC to import AD module
            $dc = $env:LOGONSERVER -replace "\\",""
            TRY{
                $pssession = New-PSSession -ComputerName $dc -ErrorAction Stop
                Import-Module -PSSession $pssession -Name ActiveDirectory -ErrorAction Stop
            }CATCH {
                $lasterr = $_
                $Line = $lasterr.InvocationInfo.ScriptLineNumber
                Write-Log "Error: on line $line | Full error: $lasterr" -Level Error
            }

            $ADMachines = @(
                FOREACH ($OU IN $OUsToSearch) {
                    Write-Log -Message "Getting AD computers from $($OU)"
                    Get-ADComputer -SearchBase $OU `
                    -Filter {
                        operatingsystem -like "*Windows*"
                        -and operatingSystem -notlike "*Server*"
                        -and operatingSystem -notlike "*team*"
                        -and operatingSystem -notlike "*embedded*"
                        -and Enabled -eq $true
                    } `
                    -Properties DNSHostname, description, operatingSystem, canonicalname, lastLogonTimestamp `
                    | Where-Object {
                        ([DateTime]::FromFileTime($_.lastLogonTimestamp)) -lt $Today.AddDays( - $($DaysSinceLastLogin))
                    } `
                    | Select-Object *, @{L = "LastLogonTimeStampReadable"; E = { ([DateTime]::FromFileTime($_.lastLogonTimestamp)) } }
                }
            )

            IF (!$ADMachines -or $ADMachines.count -le 0) {
                $ErrorMessage = 'No machines found in OU(s) specified'
                Write-Log -Message "$ErrorMessage" -Level Warn
            }
            ELSE {
                # output object
                Write-Log -Message "Found $($ADMachines.count) matching computer objects"
                
            }
            return $ADMachines
        }
        END{
            $pssession | Remove-PSSession
        }
    }
    #endregion FUNCTION Get-StaleADComputers

}
PROCESS {
    TRY {
		
        # Get CM Devices
        $cmDevices = Get-CMASDevice -All

        # Get AD Devices
        # temp vars
        $OUs = 'DC=af,DC=lan'
        $OlderThanDays = 365
        #>

        $adDevices = Get-StaleADComputers -OUsToSearch $OUs -DaysSinceLastLogin $OlderThanDays

        # Get Intune Devices
        
	
        # Get Bomgar Devices


		
    }
    CATCH {
        $Line = $_.InvocationInfo.ScriptLineNumber
        Write-Log "Error: $_" -Level Error
        Write-Log "Error: on line $line" -Level Error
    }
}
END {
    Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}