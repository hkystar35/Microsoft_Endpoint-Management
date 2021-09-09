<#
	.SYNOPSIS
		Sets default IM provider
	
	.DESCRIPTION
		Sets default IM provider
	
	.PARAMETER Remediate
		Runs remediation if set to true
	
	.PARAMETER IMname
		Name of IM provider
	
	.PARAMETER VerboseLogging
		A description of the VerboseLogging parameter.
	
	.PARAMETER DisableLogging
		A description of the DisableLogging parameter.
	
	.NOTES
		Logging is set to $env:TEMP due to users not having Write access to $env:WINDIR\Logs\*
		
		===========================================================================
		
		Created on:   	7/22/2020 13:52:29
		Created by:   	hkystar35@contoso.com
		Organization: 	contoso
		Filename:	      Set-DefaultIMApp.ps1
		===========================================================================
#>
PARAM
(
	$Remediate = $false,
	[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][ValidatePattern('[^-0-9\/]+')][string]$IMname = 'Teams'
)
BEGIN {
	
	$InvocationInfo = $MyInvocation
	[System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
	[string]$ScriptFullPath = $ScriptFileInfo.FullName
	[string]$ScriptNameFileExt = $ScriptFileInfo.Name
	[string]$ScriptName = 'Set-DefaultIMApp.ps1' #$ScriptFileInfo.BaseName
	[string]$scriptRoot = Split-Path $ScriptFileInfo
	# Set TLS
	[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
	
	[string]$Component = 'Begin-Script'
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
	
	.PARAMETER LoggingDisabled
		A description of the LoggingDisabled parameter.
	
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
					   HelpMessage = 'Severity for the log entry.')][ValidateSet('Error', 'Warn', 'Info')][ValidateNotNullOrEmpty()][string]$Level = "Info",
			[Parameter(Mandatory = $false,
					   HelpMessage = 'Name of the log file that the entry will written to.')][ValidateNotNullOrEmpty()][string]$FileName = "$($ScriptName).log",
			[string]$LogsDirectory = $env:TEMP, #"$env:windir\Logs",
			[switch]$WriteVerbose = $VerboseLogging
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
			"Warn"  {
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
		IF ($WriteVerbose) {
			Write-Verbose $LogText
		}
		#ELSE {
		TRY {
			Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop -WhatIf:$false
		}
		CATCH [System.Exception] {
			Write-Warning -Message "Unable to append log entry to $($FileName) file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
		}
		#}
		
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
	
}
PROCESS {
	TRY {
		
		# Gather variables
		$Component = 'Check-Registry'
		# IM Provider registry path
		$imProviderPath = "HKCU:\Software\IM Providers"
		Write-Log "Value of `$imProviderPath is $imProviderPath"
		# Retrieve current IM Provider Information
		$imProvider = Get-ItemProperty -Path $imProviderPath -ErrorAction SilentlyContinue
		Write-Log "Value of `$imProvider is $imProvider"
		# Build Path for Teams
		$teamsPath = Join-Path -Path $imProviderPath -ChildPath $IMname
		Write-Log "Value of `$teamsPath is $teamsPath"
		Write-Log "Value of `$Remediate is $Remediate"
		Write-Log "Value of `$Remediate2 is $Remediate2"
		Write-Log "Value of `$IMname is $IMname"
		Write-Log "Value of `$IMname2 is $IMname2"
		# Remediation
		IF ($Remediate) {
			Write-Log "Remediation param set" -Level Warn
			$Component = 'Set-Registry'
			# If there is a current provider set, set this as the previous IM provider
			# This is if a user unticks the setting in Teams, Teams knows what to fallback to
			IF ($imProvider.DefaultIMApp) {
				# Check Teams IM Provider path exists (it should if Teams has been run before)
				IF (Test-Path $teamsPath) {
					Write-Log "$teamsPath already exists, no action needed..."
				}
				ELSE {
					Write-Log -Level Warn "$teamsPath does not exist, creating..."
					New-Item -Path $imProviderPath -Name $IMname
				}
				# Path should now be created
				IF (Test-Path $teamsPath) {
					Write-Log "Setting previous IM app: $($imProvider.DefaultIMApp) "
					Set-ItemProperty -Path $teamsPath PreviousDefaultIMApp -Value $imProvider.DefaultIMApp -Type String
				}
				ELSE {
					Write-Log "Unable to create $teamsPath!" -Level Error
					RETURN 1
				}
			}
			# Set Teams as Deafult IM App
			Write-Log "Setting Default IM App to $IMname"
			Set-ItemProperty -Path $imProviderPath -Name "DefaultIMApp" -Value $IMname -ErrorAction Stop
			RETURN 0
		}
		# Detection
		ELSE {
			Write-Log "Discovery Only - No changes will be made"
			IF (Test-Path $teamsPath) {
				Write-Log "$teamsPath already exists"
				IF ($imProvider.DefaultIMApp -eq $IMname) {
					Write-Log "Default IM app already set to $($imProvider.DefaultIMApp)"
					RETURN 0
				}
			}
			ELSE {
				Write-Log "Default IM app is NOT set to $IMname (Default IM app is set to $($imProvider.DefaultIMApp))"
				RETURN 1
			}
		}
	}
	CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		Write-Log "Error: $_" -Level Error
		Write-Log "Error: on line $line" -Level Error
		RETURN 2
	}
}
END {
	Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}
# SIG # Begin signature block
# MIIdDAYJKoZIhvcNAQcCoIIc/TCCHPkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDtFckmc0cyiUPV
# Urnv/2Mr6XkIgr2Mau+kmT9RaC82mKCCF+IwggOXMIICf6ADAgECAhBhYcJ31BLv
# p0NXWLdRm/BuMA0GCSqGSIb3DQEBCwUAMB0xGzAZBgNVBAMTEkNob2JhbmktQUYt
# Um9vdC1DQTAeFw0xODA3MTExNzMzMjdaFw00ODA3MTExNzQzMjdaMB0xGzAZBgNV
# BAMTEkNob2JhbmktQUYtUm9vdC1DQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAJwZgF3SLC4M6z6YNgTsIt+bsuCM6vd8O7guJmJL/6VW7k+vYzF0h6xQ
# +oAPgT3/+WoUE/nXgeww2YZje42SrJ6xSojTzC3ZgF/MI54JqErHtE6YV7gr9fgi
# fH/GHFFUdYGa7pvTTva9ZsXgVKheFlUOLs6fyyB2YhH9mrEBkYeo0/weuB/e20L8
# ykV6KxIoW5lTqPbAIuxdDSy1AYPwrxTdFxNrMTzp4cq4EC+Kp+yCITj7S0sMsKjd
# oQ6mgeE1xxcxSjqF6bHYFIlFVmqlCgvHLu3dH/C2oa9KRyiqmw7Ad9oOxokq6ke5
# mt1DxklZWbHc2RI1O43gQtOUd4QQ5xMCAwEAAaOB0jCBzzALBgNVHQ8EBAMCAYYw
# DwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUds57hWvos7QVoA1pZ7ogZN5ZzUUw
# EAYJKwYBBAGCNxUBBAMCAQAwfgYDVR0gBHcwdTBzBggqAwSLL0NZBTBnMDoGCCsG
# AQUFBwICMC4eLABMAGUAZwBhAGwAIABQAG8AbABpAGMAeQAgAFMAdABhAHQAZQBt
# AGUAbgB0MCkGCCsGAQUFBwIBFh1odHRwOi8vcGtpLmFmLmxhbi9wa2kvY3BzLnR4
# dDANBgkqhkiG9w0BAQsFAAOCAQEAGU6uU1bcuQbanJOz6zHBSEHoYP40EErd5uUd
# oF1QIz0b4ibhu0wCAgI37jE8bJUzS2RYMo3XzSs38VEHeoT1q0rLUQxj/XwTmUTh
# UETccrKRi5HnOLB1TD7yYtvajmMEr7oxI1BPebnoTy+4iPB62wUJY94GW0ywqzC1
# VF/ext/8IJTeZlz2AnMdbSq3Q6QcGVaW+OcfqbDG9LVdPTsTJo52KIyfpUIj+yh2
# T23dyA0aCZ4p5+//CDiRTt5blL2qfWXG20mnReLnBpo3OIzTp4Q57F3QQU4V21Jd
# D3Rhoe4bRsJUV57BvxEtiqMalLsf5kJW5+DIg2SR09kFNUwcADCCBBQwggL8oAMC
# AQICCwQAAAAAAS9O4VLXMA0GCSqGSIb3DQEBBQUAMFcxCzAJBgNVBAYTAkJFMRkw
# FwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENBMRswGQYD
# VQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwHhcNMTEwNDEzMTAwMDAwWhcNMjgwMTI4
# MTIwMDAwWjBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1z
# YTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJTvZfi1V5+gUw00BusJH7dHGGrL
# 8Fvk/yelNNH3iRq/nrHNEkFuZtSBoIWLZFpGL5mgjXex4rxc3SLXamfQu+jKdN6L
# Tw2wUuWQW+tHDvHnn5wLkGU+F5YwRXJtOaEXNsq5oIwbTwgZ9oExrWEWpGLmtECe
# w/z7lfb7tS6VgZjg78Xr2AJZeHf3quNSa1CRKcX8982TZdJgYSLyBvsy3RZR+g79
# ijDwFwmnu/MErquQ52zfeqn078RiJ19vmW04dKoRi9rfxxRM6YWy7MJ9SiaP51a6
# puDPklOAdPQD7GiyYLyEIACDG6HutHQFwSmOYtBHsfrwU8wY+S47+XB+tCUCAwEA
# AaOB5TCB4jAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNV
# HQ4EFgQURtg+/9zjvv+D5vSFm7DdatYUqcEwRwYDVR0gBEAwPjA8BgRVHSAAMDQw
# MgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29tL3JlcG9zaXRv
# cnkvMDMGA1UdHwQsMCowKKAmoCSGImh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5uZXQv
# cm9vdC5jcmwwHwYDVR0jBBgwFoAUYHtmGkUNl8qJUC99BM00qP/8/UswDQYJKoZI
# hvcNAQEFBQADggEBAE5eVpAeRrTZSTHzuxc5KBvCFt39QdwJBQSbb7KimtaZLkCZ
# AFW16j+lIHbThjTUF8xVOseC7u+ourzYBp8VUN/NFntSOgLXGRr9r/B4XOBLxRjf
# OiQe2qy4qVgEAgcw27ASXv4xvvAESPTwcPg6XlaDzz37Dbz0xe2XnbnU26UnhOM4
# m4unNYZEIKQ7baRqC6GD/Sjr2u8o9syIXfsKOwCr4CHr4i81bA+ONEWX66L3mTM1
# fsuairtFTec/n8LZivplsm7HfmX/6JLhLDGi97AnNkiPJm877k12H3nD5X+WNbwt
# DswBsI5//1GAgKeS1LNERmSMh08WYwcxS2Ow3/MwggSfMIIDh6ADAgECAhIRIdaZ
# p2SXPvH4Qn7pGcxTQRQwDQYJKoZIhvcNAQEFBQAwUjELMAkGA1UEBhMCQkUxGTAX
# BgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGlt
# ZXN0YW1waW5nIENBIC0gRzIwHhcNMTYwNTI0MDAwMDAwWhcNMjcwNjI0MDAwMDAw
# WjBgMQswCQYDVQQGEwJTRzEfMB0GA1UEChMWR01PIEdsb2JhbFNpZ24gUHRlIEx0
# ZDEwMC4GA1UEAxMnR2xvYmFsU2lnbiBUU0EgZm9yIE1TIEF1dGhlbnRpY29kZSAt
# IEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsBeuotO2BDBWHlgP
# se1VpNZUy9j2czrsXV6rJf02pfqEw2FAxUa1WVI7QqIuXxNiEKlb5nPWkiWxfSPj
# BrOHOg5D8NcAiVOiETFSKG5dQHI88gl3p0mSl9RskKB2p/243LOd8gdgLE9YmABr
# 0xVU4Prd/4AsXximmP/Uq+yhRVmyLm9iXeDZGayLV5yoJivZF6UQ0kcIGnAsM4t/
# aIAqtaFda92NAgIpA6p8N7u7KU49U5OzpvqP0liTFUy5LauAo6Ml+6/3CGSwekQP
# XBDXX2E3qk5r09JTJZ2Cc/os+XKwqRk5KlD6qdA8OsroW+/1X1H0+QrZlzXeaoXm
# IwRCrwIDAQABo4IBXzCCAVswDgYDVR0PAQH/BAQDAgeAMEwGA1UdIARFMEMwQQYJ
# KwYBBAGgMgEeMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24u
# Y29tL3JlcG9zaXRvcnkvMAkGA1UdEwQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUH
# AwgwQgYDVR0fBDswOTA3oDWgM4YxaHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9n
# cy9nc3RpbWVzdGFtcGluZ2cyLmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUH
# MAKGOGh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0L2dzdGltZXN0
# YW1waW5nZzIuY3J0MB0GA1UdDgQWBBTUooRKOFoYf7pPMFC9ndV6h9YJ9zAfBgNV
# HSMEGDAWgBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTANBgkqhkiG9w0BAQUFAAOCAQEA
# j6kakW0EpjcgDoOW3iPTa24fbt1kPWghIrX4RzZpjuGlRcckoiK3KQnMVFquxrzN
# Y46zPVBI5bTMrs2SjZ4oixNKEaq9o+/Tsjb8tKFyv22XY3mMRLxwL37zvN2CU6sa
# 9uv6HJe8tjecpBwwvKu8LUc235IgA+hxxlj2dQWaNPALWVqCRDSqgOQvhPZHXZbJ
# tsrKnbemuuRQ09Q3uLogDtDTkipbxFm7oW3bPM5EncE4Kq3jjb3NCXcaEL5nCgI2
# ZIi5sxsm7ueeYMRGqLxhM2zPTrmcuWrwnzf+tT1PmtNN/94gjk6Xpv2fCbxNyhh2
# ybBNhVDygNIdBvVYBAexGDCCBXIwggRaoAMCAQICE1EAAbYwNnExJnilqIYAAAAB
# tjAwDQYJKoZIhvcNAQELBQAwSjETMBEGCgmSJomT8ixkARkWA2xhbjESMBAGCgmS
# JomT8ixkARkWAmFmMR8wHQYDVQQDExZDaG9iYW5pLVRXRi1Jc3N1aW5nLUNBMB4X
# DTIwMTExOTAyMTM0NFoXDTI0MTExODAyMTM0NFowLzEtMCsGCSqGSIb3DQEJARYe
# bmljb2xhcy53ZW5kbG93c2t5QGNob2JhbmkuY29tMIIBIjANBgkqhkiG9w0BAQEF
# AAOCAQ8AMIIBCgKCAQEAs23VO3lwObP8dvotbgUeVCHr6iCbBr5kUfi3vvWv0HlG
# UVw7xEuK8N1xumwCbV2ArRbtIGrSZXxVRjz+sWSGKIHxyY0tK5v5B6m+K6PzxGwF
# enFQy6sbd5Yztntrf0bHZLRqj8sB430mtvuNbS21YOaNTNDad1v2kzbt0SRlQ1L6
# mh5kCwlXbnp6UQwzxsMiqdasBvlAzBKw5i9UbR5c1Xb1dli4GBC3bRosLXjTXYTv
# SrUAEZylFZu8kmqAAJFgRlH3MygH+F9yrUqXRzLIRj6Ym89afTXvj4FUnggYvNCy
# EIA+JbBdWO89tXoqOlbM1xo8JCnDaRGU4ly4oO1JuQIDAQABo4ICajCCAmYwOgYJ
# KwYBBAGCNxUHBC0wKwYjKwYBBAGCNxUIhLryS4OZmH+BhYEZ+aho1clPgRr71Cap
# t3UCAWQCAQIwEwYDVR0lBAwwCgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgeAMAwG
# A1UdEwEB/wQCMAAwGwYJKwYBBAGCNxUKBA4wDDAKBggrBgEFBQcDAzAdBgNVHQ4E
# FgQUusgB4YdXQvoSOuhqiUQyRmWP6U4wOQYDVR0RBDIwMKAuBgorBgEEAYI3FAID
# oCAMHm5pY29sYXMud2VuZGxvd3NreUBjaG9iYW5pLmNvbTAfBgNVHSMEGDAWgBRj
# 2aWUSsTG9dnuHHG2SUpuHi/WBDBBBgNVHR8EOjA4MDagNKAyhjBodHRwOi8vcGtp
# LmFmLmxhbi9wa2kvQ2hvYmFuaS1UV0YtSXNzdWluZy1DQS5jcmwwggEYBggrBgEF
# BQcBAQSCAQowggEGMFEGCCsGAQUFBzAChkVodHRwOi8vcGtpLmFmLmxhbi9wa2kv
# UEtJUy1VU1RXRi0wMS5hZi5sYW5fQ2hvYmFuaS1UV0YtSXNzdWluZy1DQS5jcnQw
# gbAGCCsGAQUFBzAChoGjbGRhcDovLy9DTj1DaG9iYW5pLVRXRi1Jc3N1aW5nLUNB
# LENOPUFJQSxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxD
# Tj1Db25maWd1cmF0aW9uLERDPWFmLERDPWxhbj9jQUNlcnRpZmljYXRlP2Jhc2U/
# b2JqZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTANBgkqhkiG9w0BAQsF
# AAOCAQEAQNOQ6aDorF7Q4UJW3Tmry7JM3DhMpLaLDb7lVhFIaNeUFgPhmJunAx9O
# YPyJeqL0UDuvk00pgJzebVZrnVfLCkMbdxqCo9Kzkq5iU+zQU6tJWZME5ZmdNE5v
# NDRsX2M/WG0YzTEGHBch/LCCdxhjMGXOJh+AIzYBDEeh5jbATyxiS4EcI07kZ48q
# BuidWNnxfg2q76+QP+8hRbHvr8Q+5wFQNnvLVTHo5q9YZGoqudHreW5KKhrEE8KK
# UoCK16iljG+I19VUnrQVTrEqsGOTJ/rmhzDT2ws+I0BSu4gmlo8eD2bH/9G8hGzQ
# Fb0rlWfjABr+089ZIrYuwbuLOcXUETCCBhIwggT6oAMCAQICEy0AAAAF6gnwnzD5
# mJkAAAAAAAUwDQYJKoZIhvcNAQELBQAwHTEbMBkGA1UEAxMSQ2hvYmFuaS1BRi1S
# b290LUNBMB4XDTE4MDcyMDE5MTUyNFoXDTMzMDcyMDE5MjUyNFowSjETMBEGCgmS
# JomT8ixkARkWA2xhbjESMBAGCgmSJomT8ixkARkWAmFmMR8wHQYDVQQDExZDaG9i
# YW5pLVRXRi1Jc3N1aW5nLUNBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEAzCzgTQ+ywdYG/9/ZpMRODl2m4RTD/vzUCSnRQfN0kla90kTsJai269WuTQ1L
# DkDxQWFBaFUsjcvfI59F7EtfzddgqGMHlrTDBQ3K16IOoN5nC5YAQeWILcOoPyaj
# zZp9m7oU3o+5fwOru8dxP7fBF71H66f6nqgop2UlorQWfJYjpNe+cHZjzjG1H0Bn
# cMviJSinEIkBjsRTUAYrs79yRSBjircqgtUx0CfPUV5S6htVJ78I5OoyOPloXGG+
# 7k/+W282MPVDe4S6CYBejELzAfDavAJo/LZjh5bSFNkcPlOK0Qi6aeSF5V5vpkj5
# Wuk4J57n6yqUFpfL+LyEEHR+HQIDAQABo4IDHDCCAxgwEAYJKwYBBAGCNxUBBAMC
# AQAwHQYDVR0OBBYEFGPZpZRKxMb12e4ccbZJSm4eL9YEMH4GA1UdIAR3MHUwcwYI
# KgMEiy9DWQUwZzA6BggrBgEFBQcCAjAuHiwATABlAGcAYQBsACAAUABvAGwAaQBj
# AHkAIABTAHQAYQB0AGUAbQBlAG4AdDApBggrBgEFBQcCARYdaHR0cDovL3BraS5h
# Zi5sYW4vcGtpL2Nwcy50eHQwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYD
# VR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAUds57hWvos7QV
# oA1pZ7ogZN5ZzUUwgf8GA1UdHwSB9zCB9DCB8aCB7qCB64YsaHR0cDovL3BraS5h
# Zi5sYW4vcGtpL0Nob2JhbmktQUYtUm9vdC1DQS5jcmyGgbpsZGFwOi8vL0NOPUNo
# b2JhbmktQUYtUm9vdC1DQSxDTj1QS0lSLVVTVFdGLTAxLENOPUNEUCxDTj1QdWJs
# aWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9u
# LERDPWFmLERDPWxhbj9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2Jq
# ZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwggEHBggrBgEFBQcBAQSB+jCB
# 9zBGBggrBgEFBQcwAoY6aHR0cDovL3BraS5hZi5sYW4vcGtpL1BLSVItVVNUV0Yt
# MDFfQ2hvYmFuaS1BRi1Sb290LUNBLmNydDCBrAYIKwYBBQUHMAKGgZ9sZGFwOi8v
# L0NOPUNob2JhbmktQUYtUm9vdC1DQSxDTj1BSUEsQ049UHVibGljJTIwS2V5JTIw
# U2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1hZixEQz1s
# YW4/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRpb25B
# dXRob3JpdHkwDQYJKoZIhvcNAQELBQADggEBAAKr417Ziw9kfZXOdlN87OhgpFu5
# kkCzhZUM0vDcm5NnQ9g018AaHvtCiMjodUYuAParejB+mWpYNWo9A78bzbZprxqC
# /6z6uUelgPBWkFqcsBU2qhLgN6pqlABaKoQ9jL7PETYCTcT0mgPfb5PZv6bDFDBg
# /3DZia00H2L1wN5aPI/at54K5akLDyDEaQ5oXrcs7v/BzgeKYk7m8SLNGWZBg2dO
# NYbJU4ATMUqWxQrIzfnRsvEnBiimL/H5DLni31laPyEWJJ+cvmevsouY4f+vlqdd
# 1cZkZFZFNqky1A0BhqIg9URBPb2UVogv5J9om96owYZil2+hnI6xkJjjRqgxggSA
# MIIEfAIBATBhMEoxEzARBgoJkiaJk/IsZAEZFgNsYW4xEjAQBgoJkiaJk/IsZAEZ
# FgJhZjEfMB0GA1UEAxMWQ2hvYmFuaS1UV0YtSXNzdWluZy1DQQITUQABtjA2cTEm
# eKWohgAAAAG2MDANBglghkgBZQMEAgEFAKBMMBkGCSqGSIb3DQEJAzEMBgorBgEE
# AYI3AgEEMC8GCSqGSIb3DQEJBDEiBCCCdUmA79eqMHj89hyX9TOmYGeQ+LSEvab8
# Y+30n5TPRzANBgkqhkiG9w0BAQEFAASCAQBY5GHIJftoNly/9RvIlGL4xeKi+q/y
# /yX+nlpo4ooIFOZ0Bo8qz+skYKTH02MYZJD8y1Dx2iWYQlT4iYQpb6NrxLh+Bz5Q
# rslKg4FHDwK8Ja7ef2beMtHWAUuFQoopbdiSDwCKTVvgRTOYQD+WPtQ8FYnAZPJ2
# hEF33TvStgx3Koy75SFPBSKaiQXAqbadP3S0OMTw7aR1lMSQc6PVxkDWGFWt2jGp
# g+765gKsnP2ZjDHK+BxhTeqnHIdUT9ieZuRPlfT7Sa+mePNF6xsd/dJ2DVu59+4V
# 51hQwWpaNfOCHXKMy4fF38t6nMKwKMLuihxxDr9e1tCgHvb/1yNAJYn7oYICojCC
# Ap4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNV
# BAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0
# YW1waW5nIENBIC0gRzICEhEh1pmnZJc+8fhCfukZzFNBFDAJBgUrDgMCGgUAoIH9
# MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTIwMTEx
# OTAyMzc0N1owIwYJKoZIhvcNAQkEMRYEFDIPt8rkXKmS9HuRV3WYB1qYLc0tMIGd
# BgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUY7gvq2H1g5CWlQULACScUCkz7Hkw
# bDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# KDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh1pmn
# ZJc+8fhCfukZzFNBFDANBgkqhkiG9w0BAQEFAASCAQBdNN5IW6mjsw5vZtWhwpcU
# JN0jb0nAFAgh95RRBR2MyYAU8SOQT4r6vXcbYWET+8ZfDquMxIQtOmp1+ApObtrY
# 14Tymx28UWtc0m1HCBUKCKbJKZt21rjsTBMW6uakaDXVgrzkLWp/DSVLxaTw0VSJ
# VvT/n4r6WC6oQAQ0k3g9nmlljFZ4QLrXDojidUoCvztEed+jXFNOwHGFrGjzzAR1
# yXC0skcNg8Q+BE3ITh35WuSAD2LwODD+yJUsd8k6w4Ea8ea0FfX/AxziLxtZZNrc
# 18vbU6lXKcr3lOayrYPZD022HgujN0M0rs/3ClsJC1wijs9eyLyIDxahXEOv6fkk
# SIG # End signature block
