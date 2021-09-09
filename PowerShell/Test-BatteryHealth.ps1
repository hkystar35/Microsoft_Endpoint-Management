<#
    .SYNOPSIS
    A brief description of the !Template.ps1 file.
	
    .DESCRIPTION
    A description of the file.
	
    .PARAMETER Input
    A description of the Input parameter.
	
    .NOTES
    ===========================================================================

    Created on:   	2021-07-19 08:42:57
    Created by:   	Nicolas.Wendlowsky@chobani.com
    Organization: 	Chobani
    Filename:	      
    ===========================================================================
#>
[CmdletBinding()]
PARAM
(
    #[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Input
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
	
    [string]$Global:Component = 'Begin-Script'
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
		
        $Component = $MyInvocation.MyCommand

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

    function Test-BatteryHealth {

        $Component = $MyInvocation.MyCommand
        
        # Check for presence of battery and check where present
        If (Get-CimInstance -ClassName win32_battery) {
            # Check machine type and other info
            [string]$SerialNumber = (Get-CimInstance -ClassName win32_bios).SerialNumber
            
            # Maximum Acceptable Health Perentage
            $MinHealth = "40"
    
            # Multiple Battery handling
            $BatteryInstances = Get-CimInstance -Namespace "ROOT\WMI" -ClassName "BatteryStatus" | Select-Object -ExpandProperty InstanceName
            
            ForEach ($BatteryInstance in $BatteryInstances) {
    
                # Set Variables for health check
    
                $BatteryDesignSpec = Get-CimInstance -Namespace "ROOT\WMI" -ClassName "BatteryStaticData" -Property DesignedCapacity,InstanceName | Where-Object -Property InstanceName -EQ $BatteryInstance | Select-Object -ExpandProperty DesignedCapacity
                $BatteryFullCharge = Get-CimInstance -Namespace "ROOT\WMI" -ClassName "BatteryFullChargedCapacity" -Property FullChargedCapacity,InstanceName | Where-Object -Property InstanceName -EQ $BatteryInstance | Select-Object -ExpandProperty FullChargedCapacity
    
                # Fall back WMI class for Microsoft Surface devices
                if ($BatteryDesignSpec -eq $null -or $BatteryFullCharge -eq $null -and ((Get-CimInstance -ClassName Win32_BIOS | Select-Object -ExpandProperty Manufacturer) -match "Microsoft")) {
        
                    # Attempt to call WMI provider
                    if (Get-CimInstance -ClassName MSBatteryClass -Namespace "ROOT\WMI") {
                        $MSBatteryInfo = Get-CimInstance -ClassName MSBatteryClass -Namespace "root\wmi" | Where-Object -Property InstanceName -EQ $BatteryInstance | Select-Object FullChargedCapacity, DesignedCapacity
            
                        # Set Variables for health check
                        $BatteryDesignSpec = $MSBatteryInfo.DesignedCapacity
                        $BatteryFullCharge = $MSBatteryInfo.FullChargedCapacity
                    }
                }
            
                if ($BatteryDesignSpec -gt $null -and $BatteryFullCharge -gt $null) {
                    # Determine battery replacement required
                    [int]$CurrentHealth = ($BatteryFullCharge / $BatteryDesignSpec) * 100
                    if ($CurrentHealth -le $MinHealth) {
                        $ReplaceBattery = $true
                    
                        # Generate Battery Report
                        $ReportingPath = Join-Path -Path $env:SystemDrive -ChildPath "Reports"
                        if (-not (Test-Path -Path $ReportingPath)) {
                            New-Item -Path $ReportingPath -ItemType Dir | Out-Null
                        }
                        $ReportOutput = Join-Path -Path $ReportingPath -ChildPath $('\Battery-Report-' + $SerialNumber + '.html')
                    
                        # Run Windows battery health report
                        Start-Process PowerCfg.exe -ArgumentList "/BatteryReport /OutPut $ReportOutput" -Wait -WindowStyle Hidden
                    
                        # Output replacement message and flag for remediation step
                        Write-Output "Battery replacement required - $CurrentHealth% of manufacturer specifications"
                        exit 1
                    
                    }
                    else {
                        # Output replacement not required values
                        $ReplaceBattery = $false
                        Write-Output "Battery status healthy: $($CurrentHealth)% of manufacturer specifications"
                        # Not exiting here so that second battery can be checked
                    }
                }
                else {
                    # Output battery not present
                    Write-Output "Battery not present in system."
                    exit 0
                }
            }
        }
        else {
            # Output battery value condition check error
            Write-Output "Unable to obtain battery health information from WMI"
            exit 0
        }
    }
    
}
PROCESS {
    TRY {
		
		    Test-BatteryHealth
            
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