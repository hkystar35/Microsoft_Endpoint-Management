#Requires -Version 5.1

$script:cyberarkBaseUrl = $null
$script:cyberarkSession = $null

#region General
# ****************************************************************************************
# General
# ****************************************************************************************

function Get-CallerPreference
{
    <#
    .SYNOPSIS
       Fetches "Preference" variable values from the caller's scope.
    .DESCRIPTION
       Script module functions do not automatically inherit their caller's variables, but they can be
       obtained through the $PSCmdlet variable in Advanced Functions.  This function is a helper function
       for any script module Advanced Function; by passing in the values of $ExecutionContext.SessionState
       and $PSCmdlet, Get-CallerPreference will set the caller's preference variables locally.
    .PARAMETER Cmdlet
       The $PSCmdlet object from a script module Advanced Function.
    .PARAMETER SessionState
       The $ExecutionContext.SessionState object from a script module Advanced Function.  This is how the
       Get-CallerPreference function sets variables in its callers' scope, even if that caller is in a different
       script module.
    .PARAMETER Name
       Optional array of parameter names to retrieve from the caller's scope.  Default is to retrieve all
       Preference variables as defined in the about_Preference_Variables help file (as of PowerShell 4.0)
       This parameter may also specify names of variables that are not in the about_Preference_Variables
       help file, and the function will retrieve and set those as well.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Imports the default PowerShell preference variables from the caller into the local scope.
    .EXAMPLE
       Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState -Name 'ErrorActionPreference','SomeOtherVariable'

       Imports only the ErrorActionPreference and SomeOtherVariable variables into the local scope.
    .EXAMPLE
       'ErrorActionPreference','SomeOtherVariable' | Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

       Same as Example 2, but sends variable names to the Name parameter via pipeline input.
    .INPUTS
       String
    .OUTPUTS
       None.  This function does not produce pipeline output.
    .LINK
       about_Preference_Variables
    #>
    [CmdletBinding(DefaultParameterSetName = 'AllVariables')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ $_.GetType().FullName -eq 'System.Management.Automation.PSScriptCmdlet' })]
        $Cmdlet,
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.SessionState]
        $SessionState,
        [Parameter(ParameterSetName = 'Filtered', ValueFromPipeline = $true)]
        [string[]]
        $Name
    )

    begin
    {
        $filterHash = @{}
    }

    process
    {
        if ($null -ne $Name)
        {
            foreach ($string in $Name)
            {
                $filterHash[$string] = $true
            }
        }
    }

    end
    {
        # List of preference variables taken from the about_Preference_Variables help file in PowerShell version 4.0

        $vars = @{
            'ErrorView' = $null
            'FormatEnumerationLimit' = $null
            'LogCommandHealthEvent' = $null
            'LogCommandLifecycleEvent' = $null
            'LogEngineHealthEvent' = $null
            'LogEngineLifecycleEvent' = $null
            'LogProviderHealthEvent' = $null
            'LogProviderLifecycleEvent' = $null
            'MaximumAliasCount' = $null
            'MaximumDriveCount' = $null
            'MaximumErrorCount' = $null
            'MaximumFunctionCount' = $null
            'MaximumHistoryCount' = $null
            'MaximumVariableCount' = $null
            'OFS' = $null
            'OutputEncoding' = $null
            'ProgressPreference' = $null
            'PSDefaultParameterValues' = $null
            'PSEmailServer' = $null
            'PSModuleAutoLoadingPreference' = $null
            'PSSessionApplicationName' = $null
            'PSSessionConfigurationName' = $null
            'PSSessionOption' = $null
            'ErrorActionPreference' = 'ErrorAction'
            'DebugPreference' = 'Debug'
            'ConfirmPreference' = 'Confirm'
            'WhatIfPreference' = 'WhatIf'
            'VerbosePreference' = 'Verbose'
            'WarningPreference' = 'WarningAction'
        }

        foreach ($entry in $vars.GetEnumerator())
        {
            if (([string]::IsNullOrEmpty($entry.Value) -or -not $Cmdlet.MyInvocation.BoundParameters.ContainsKey($entry.Value)) -and
                ($PSCmdlet.ParameterSetName -eq 'AllVariables' -or $filterHash.ContainsKey($entry.Name)))
            {
                $variable = $Cmdlet.SessionState.PSVariable.Get($entry.Key)

                if ($null -ne $variable)
                {
                    if ($SessionState -eq $ExecutionContext.SessionState)
                    {
                        Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                    }
                    else
                    {
                        $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                    }
                }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Filtered')
        {
            foreach ($varName in $filterHash.Keys)
            {
                if (-not $vars.ContainsKey($varName))
                {
                    $variable = $Cmdlet.SessionState.PSVariable.Get($varName)

                    if ($null -ne $variable)
                    {
                        if ($SessionState -eq $ExecutionContext.SessionState)
                        {
                            Set-Variable -Scope 1 -Name $variable.Name -Value $variable.Value -Force -Confirm:$false -WhatIf:$false
                        }
                        else
                        {
                            $SessionState.PSVariable.Set($variable.Name, $variable.Value)
                        }
                    }
                }
            }
        }
    }
}

function Disable-CertificateVerification
{
    if ($PSVersionTable.Platform -ne "Unix")
    {
        Add-Type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;

        public class NoSSLCheckPolicy : ICertificatePolicy {
            public NoSSLCheckPolicy() {}
            public bool CheckValidationResult(
                ServicePoint sPoint, X509Certificate cert,
                WebRequest wRequest, int certProb) {
                return true;
            }
        }
"@
        [System.Net.ServicePointManager]::CertificatePolicy = new-object NoSSLCheckPolicy
    }
    else
    {
        Write-Error -Message "DisableCertificateVerification is not supported"
    }
}

function Invoke-Api
{
    param(
        [Parameter(Mandatory=$true)]
        [string] $Method,
        [Parameter(Mandatory=$true)]
        [string] $Url,
        [object] $Body,
        [int] $Retry = 0,
        [int] $RetryDelay = 0
    )

    if (-not $script:cyberarkBaseUrl -or -not $script:cyberarkSession)
    {
        Write-Error "You need to connect first, use Connect-CyberArk"
    }

    try
    {
        $params = @{}
        if ($PSBoundParameters.ContainsKey("Body"))
        {
            $params.Add("Body", $($Body | ConvertTo-Json -Depth 99))
        }
        $fullUrl = "$($script:cyberarkBaseUrl)$Url"
        return Invoke-RestMethod -Uri $fullUrl -Headers $(Get-AuthorizationHeader) `
            -Method $Method -ContentType application/json -ErrorAction Stop @params
    }
    catch
    {
        if ($PSVersionTable.ContainsKey("Platform") -and $PSVersionTable.Platform -ne "Unix")
        {
            $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $errorMessage = $streamReader.ReadToEnd()
            $streamReader.Close()
            Write-Error -Message "$errorMessage $fullUrl"
        }
        else
        {
            Write-Error -Exception "$_ $fullUrl"
        }
    }
}

function Get-AuthorizationHeader
{
    return @{Authorization=$script:cyberarkSession}
}

function Connect-CyberArk
{
    <#
    .SYNOPSIS
       Will handle creating a session with cyberark
    .DESCRIPTION
       Will handle creating a session with cyberark
    .PARAMETER Credential
       Login credentials
    .PARAMETER Url
       Url of the cyberark instance
    .PARAMETER DisableCertificateVerification
       Will disable certifictae verification
    #>
    param (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential] $Credential,
        [Parameter(Mandatory=$true)]
        [string] $Url,
        [switch] $DisableCertificateVerification
    )

    $result = $null

    try
    {
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        if ($DisableCertificateVerification)
        {
            Disable-CertificateVerification
        }

        $urlTemp = [System.Uri]$Url
        $urlLocal = "$($urlTemp.Scheme)://$($urlTemp.Host)"
        $loginResult = Invoke-RestMethod -Uri "$urlLocal/PasswordVault/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logon" `
            -Body $(@{username = $credential.GetNetworkCredential().UserName; password = $credential.GetNetworkCredential().Password} | ConvertTo-Json) `
            -Method Post -ContentType "application/json"
        if (-not $loginResult -or -not $loginResult.CyberArkLogonResult)
        {
            Write-Error -Message "Could not authenticate to cyberark"
        }
        $script:cyberarkBaseUrl = $urlLocal;
        $script:cyberarkSession = $loginResult.CyberArkLogonResult;
    }
    catch
    {
        Write-Error -Exception $_.Exception
    }
}

function Disconnect-CyberArk
{
    <#
    .SYNOPSIS
       Will handle removing a session with cyberark
    .DESCRIPTION
       Will handle removing a session with cyberark
    #>

    try
    {
        if (-not [string]::IsNullOrWhiteSpace($script:cyberarkBaseUrl))
        {
            $logoffResult = Invoke-RestMethod -Uri "$($script:cyberarkBaseUrl)/PasswordVault/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logoff" `
                -Headers $(Get-AuthorizationHeader) -Method Post -ContentType "application/json"
            if (-not $logoffResult)
            {
                Write-Error -Message "Could not disconnect from cyberark"
            }
        }
        $script:cyberarkBaseUrl = "";
        $script:cyberarkSession = "";
    }
    catch
    {
        Write-Error -Exception $_.Exception
    }
}


#region Operation
# ****************************************************************************************
# Operation
# ****************************************************************************************

function Get-Account
{
    <#
    .SYNOPSIS
       Will retrieve account info
    .DESCRIPTION
       Will retrieve account info
    .PARAMETER SafeName
       Name of the safe
    .PARAMETER Name
       Name of the account
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $SafeName,
        [Parameter(Mandatory=$true)]
        [string] $Name
    )

    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $accountResult = @(Invoke-Api -Method Get -Url "/PasswordVault/WebServices/PIMServices.svc/Accounts?Keywords=$Name&Safe=$SafeName")
    if ($accountResult.Count -gt 0)
    {
        if ($accountResult[0].Count -gt 1)
        {
            Write-Warning "$($accountResult[0].Count) matching accounts found for keywords '$Name' in safe '$SafeName'. Only the first result will be returned."
        }        
        $password = Invoke-Api -Method Post -Url "/PasswordVault/api/Accounts/$($accountResult[0].accounts.AccountID)/password/retrieve" -Body @{ "actionType" = "Show" }
    }

    return New-Object PSObject -Property @{
        Username = ($accountResult.accounts.Properties | Where-Object { $_.Key -eq "UserName" } | Select-Object -First 1).Value
        Password = $password
    }

}

Export-ModuleMember -Function @("Connect-CyberArk","Disconnect-CyberArk","Get-Account") -Cmdlet @("Connect-CyberArk","Disconnect-CyberArk","Get-Account")