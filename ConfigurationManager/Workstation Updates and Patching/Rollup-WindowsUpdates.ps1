<#
	.SYNOPSIS
		A brief description of the !Template.ps1 file.
	
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER Input
		A description of the Input parameter.
	
	.NOTES
		===========================================================================

		Created on:   	09/13/2019 3:49:53 PM
		Created by:   	hkystar35@contoso.com
		Organization: 	contoso
		Filename:	
		===========================================================================
#>
[CmdletBinding()]
PARAM
(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Input
)
BEGIN {
    $InvocationInfo = $MyInvocation
    [System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
    [string]$ScriptFullPath = $ScriptFileInfo.FullName
    [string]$ScriptNameFileExt = $ScriptFileInfo.Name
    [string]$ScriptName = $ScriptFileInfo.BaseName
    [string]$scriptRoot = Split-Path $ScriptFileInfo
	
    #region FUNCTION Write-Log
    FUNCTION Write-Log {
        [CmdletBinding()]
        PARAM
        (
            [Parameter(Mandatory = $true,
                ValueFromPipelineByPropertyName = $true)][ValidateNotNullOrEmpty()][Alias("LogContent")][string]$Message,
            [Parameter(Mandatory = $false)][Alias('LogPath')][string]$Path = "$env:windir\Logs\$($ScriptName).log",
            [Parameter(Mandatory = $false)][ValidateSet("Error", "Warn", "Info")][string]$Level = "Info",
            [Parameter(Mandatory = $false)][switch]$NoClobber,
            [Parameter(Mandatory = $false)][int]$MaxLogSize = '2097152'
        )
		
        BEGIN {
            # Set VerbosePreference to Continue so that verbose messages are displayed. 
            $VerbosePreference = 'SilentlyContinue'
            $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        PROCESS {
			
            # Test if log exists
            IF (Test-Path -Path $Path) {
                $FilePath = Get-Item -Path $Path
                IF ($NoClobber) {
                    Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
                    RETURN
                }
                IF ($FilePath.Length -gt $MaxLogSize) {
                    Rename-Item -Path $FilePath.FullName -NewName $($FilePath.BaseName).log_ -Force
                }
            }
            ELSEIF (!(Test-Path $Path)) {
                Write-Verbose "Creating $Path."
                $NewLogFile = New-Item $Path -Force -ItemType File
            }
            # Write message to error, warning, or verbose pipeline and specify $LevelText 
            SWITCH ($Level) {
                'Error' {
                    Write-Error $Message
                    $LevelText = 'ERROR:'
                }
                'Warn' {
                    Write-Warning $Message
                    $LevelText = 'WARNING:'
                }
                'Info' {
                    Write-Verbose $Message
                    $LevelText = 'INFO:'
                }
            }
			
            # Write log entry to $Path 
            "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
        }
        END {
        }
    }
    #endregion FUNCTION Write-Log	
	
    Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
}
PROCESS {
    TRY {
        # Windows Updates Management


        # Current Year Updates




        # Previous Year Updates


        # Organization
        Operating System
        Product
        Year
        Ignore 3rd Party updates

        # Deployment Collections
        OS
        Product (Office only)
        ## Main Script Block
        function Get-SUPupdatesByCategory {
<#
	.SYNOPSIS
		A brief description of the Get-SUPupdatesByCategory function.
	
	.DESCRIPTION
		A detailed description of the Get-SUPupdatesByCategory function.
	
	.PARAMETER ComputerName
		 establishes an alternate name for the parameter
		 Other Params
		 specifies that the parameter value must represent the path, that is referring to User drive
		 specifies that the parameter value must represent the path, that is referring to allowed drives only
		 specifies that the parameter value cannot be $null and cannot be an empty string ""
		 specifies that the parameter value cannot be $null
		 specifies a set of valid values for a parameter or variable
		 specifies a script that is used to validate a parameter or variable value
		 specifies a numeric range or a ValidateRangeKind enum value for each parameter or variable value
		 specifies a regular expression that is compared to the parameter or variable value
		 specifies the minimum and maximum number of characters in a parameter or variable value
		 specifies the minimum and maximum number of parameter values that a parameter accepts
		 Validation Params
		 allows the value of a mandatory parameter to be an empty collection @()
		 allows the value of a Mandatory parameter to be an empty string ("")
		 allows the value of a Mandatory parameter to be $null
		 Allow Params
		 help message that explains the expected parameter value.
		 String parameter that accepts an array or strings
	
	.PARAMETER Remaining
		 Only accepts one string object at a time.
		 Basic String Parameter
	
	.PARAMETER Enable
		 effective only when they are used and have only one effect. Present = $True | NOT Present =  $False
		 Switch Parameter
	
	.PARAMETER CategoryType
		A description of the CategoryType parameter.
	
	.EXAMPLE
				PS C:\> Get-SUPupdatesByCategory -ComputerName Low
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding(DefaultParameterSetName = 'Computer')]
	[OutputType([array])]
	param
	(
		[Parameter(ParameterSetName = 'Computer',
		           Mandatory = $true,
		           ValueFromPipeline = $true,
		           Position = 0,
		           HelpMessage = 'Enter one or more computer names separated by commas.')]
[ValidateUserDrive()]
[ValidateDrive("C", "D", "Variable", "Function")]
		[ValidateNotNullOrEmpty()]
		[ValidateNotNull()]
		[ValidateSet('Low', 'Average', 'High')]
		[ValidateScript({ $_ -ge (Get-Date) })]
		[ValidateRange(0, 10)]
		[ValidatePattern('[0-9][0-9][0-9][0-9]')]
		[ValidateLength(1, 10)]
		[ValidateCount(1, 5)]
		[AllowEmptyCollection()]
		[AllowEmptyString()]
		[AllowNull()]
		[Alias('CN' ,'MachineName')]
		[String[]]
		$ComputerName,
		[Parameter(Position = 1)]
		[String]
		$Remaining,
		[Parameter(Mandatory = $false)]
		[Switch]
		$Enable,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('Year', 'Product', 'OperatingSystem')]
		[string]
		$CategoryType
	)
	
# Output Type: 
            
            # Function Body
            Begin {
                # specifying variables and arrays
            
            }
            Process {
                # where the work is done
            
            }
            End {
                # clean objects up or return any complex data structures
            
            }
}
		
    }
    CATCH {
        $Line = $_.InvocationInfo.ScriptLineNumber
        Write-Log -Message "Error: $_" -Level Error
        Write-Log -Message "Error: on line $line" -Level Error
    }
}
END {
    Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}
