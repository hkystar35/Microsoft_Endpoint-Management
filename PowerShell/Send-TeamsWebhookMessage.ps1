<#
	.SYNOPSIS
		Send dynamic key value data pairs to Teams webhook
	
	.DESCRIPTION
		Use this as an adaptable function or script to send dynamic data to a Teams webhook.
		Simply set the $inputValuePairs parameters to a hastable and the data will be auto-added to a FactSet from the AdaptiveCard.io framework and sent to your webhook.
	
	.PARAMETER TeamsWebhook
		Teams webhook URI.
		How to create a Teams webhook:
		https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook
	
	.PARAMETER title
		Largest font of the message. Make it short and sweet.
	
	.PARAMETER inputValuePairs
		Hashtable of Key-Value pairs. Can have empty Keys or Values, the script will ignore them (useful for when you know a value might be empty and you don't want it in the message).
		Not required. Leave empty or $null and only the Title will be sent.
	
	.PARAMETER isError
		Generic variable to help determine the color of the Title text.
		Not required. If null or empty, uses "default" text color.
		See link for values:
		https://adaptivecards.io/explorer/TextBlock.html
		
	.EXAMPLE
		.\Send-TeamsWebhookMessage.ps1 `
			-Title "Image %TSCompletionStatus%: %OSDCOMPUTERNAME%" `
			-isError "%ErrorReturnCode%" `
			-inputValuePairs @{ 
							    "Task Sequence:"    = "%_SMSTSPackageName%"; 
							    "Site:"             = "%SiteLocation%"; 
							    "Primary User:"     = "%SMSTSUDAUsers%"; 
							    "Manufacturer:"     = "%_SMSTSMake%"; 
							    "Model:"            = "%_SMSTSModel%"; 
							    "Serial:"           = "%_SMSTSSerialNumber%"; 
							    "Failed Step Name:" = "%FailedStepName%"; 
							    "Exit Code:"        = "%ErrorReturnCode%"; 
							    "Log File Path:"    = "%zippedLogFile%"; 
							    "IP Address:"       = "_SMSTSIPAddresses";
							    "Imager:"           = "%OSDAuthUser%";
							} `
			-TeamsWebhook "%Webhook_OSDChannel%"
		
		Sends a webhook from within ConfigMgr OSD Task Sequence using TS Variables. Any TS Variable that is empty in the hastable will be ignored, so it can be dynamically used for both Success and Failure.
		The error-related TS Variables only hold values if en error occurs, so those would be ignored during a Successful image since the script checks for null, empty, or whitespace values.

	.EXAMPLE
		.\Send-TeamsWebhookMessage.ps1 `
			-Title "Successful Image: %OSDCOMPUTERNAME%" `

		Sends a webhook with only the Title data and nothing else. Useful for simple, quick alerts.

	.NOTES
		Adaptive card TextBlock color values must be lower-case.
		Good = "default"
		Bad = "Attention"

    .NOTES
        There is a limit to the number of characters the paramaters can total, so don't get too crazy with the data you're putting in the hashtable.
        Nearest I can tell, it's 8,191 unless there's a different document saying otherwise:
        https://docs.microsoft.com/en-US/troubleshoot/windows-client/shell-experience/command-line-string-limitation

		===========================================================================
		
		Created on:   	2021-08-19 17:09:33
		Created by:   	hkystar35@contoso.com
		Organization: 	contoso
		Filename:	    Send-TeamsWebhookMessage.ps1
		===========================================================================
#>
[CmdletBinding()]
PARAM
(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [uri]$TeamsWebhook,
	
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$title = 'test title',
	
    [ValidateNotNullOrEmpty()]
    [System.Collections.Specialized.OrderedDictionary]$inputValuePairs,
	
    [string]$isError
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
    
    #region FUNCTIONS

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
    
    #endregion FUNCTIONS
    
    Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
}
PROCESS {
    TRY {
		
        # generate FactSet from parameters, if present
        IF ($null -ne $inputValuePairs) {
            $FactSetArray = [ordered]@{
                "type"      = "FactSet"
                "facts"     = @(
                    $inputValuePairs.GetEnumerator() | ForEach-Object {
                        # Ignore empty Values
                        IF ((-not [string]::IsNullOrEmpty($_.Key) -and -not [string]::IsNullOrWhiteSpace($_.Key)) -and (-not [string]::IsNullOrEmpty($_.Value) -and -not [string]::IsNullOrWhiteSpace($_.Value))) {
                            [ordered]@{
                                "title" = $_.key
                                "value" = $_.value
                            }
                        }
                    }
                )
                "separator" = "true"
            }
        }

        # set color of title
        $color = SWITCH ($isError) {
            { } { "default" }
            { } { "dark" }
            { } { "light" }
            { } { "accent" }
            { $_ -eq 0 -or $_ -eq $false -or $null -ne $_ } { "good" }
            { } { "warning" }
            { $_ -eq $true -or $_ -gt 0 } { "attention" }
            default { 'default' }
        }

        $jsonBody = [PSCustomObject][ordered]@{
            type        = 'message'
            attachments = @(
                [ordered]@{
                    "contentType" = "application/vnd.microsoft.card.adaptive"
                    "contentUrl"  = $null
                    content       = [ordered]@{
                        "`$schema" = "http://adaptivecards.io/schemas/adaptive-card.json"
                        "type"     = "AdaptiveCard"
                        "version"  = "1.2"
                        body       = @(
                            [ordered]@{
                                "type"      = "TextBlock"
                                "text"      = $title
                                "size"      = "large"
                                "color"     = $color
                                "separator" = "true"
                            };
                            #$FactSetArray
                            IF($FactSetArray){$FactSetArray}
                        )
                    }
                }
            )
        }

        # Convert to JSON
        $Script:Component = 'JSON'
        $webhookJSON = convertto-json $jsonBody -Depth 100
        write-log -message $webhookJSON

        $webhookCall = @{
            "URI"         = $TeamsWebhook
            "Method"      = 'POST'
            "Body"        = $webhookJSON
            "ContentType" = 'application/json'
        }

        $Script:Component = 'Invoke-RestMethod'
        try {
            Write-Log "Sending JSON payload to webhook"
            $webhookresult = Invoke-WebRequest @webhookCall
        }
        catch {
            $result = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($result)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Log $responseBody -Level Error
        }
        
        IF (!$responseBody) {
            if ($webhookresult.StatusCode -eq 200) {
                write-log "Webhook succeeded with Status Code $($webhookresult.StatusCode)"
            }
            ELSE {
                write-log "Webhook failed with Status Code $($webhookresult.StatusCode)" -Level Error
            }
        }
		
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
