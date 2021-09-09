<#
    .SYNOPSIS
    Enables Remote Desktop
	
    .DESCRIPTION
    Enables Remote Desktop
	
    .NOTES
    ===========================================================================

    Created on:   	4/8/2020 11:20:47
    Created by:   	hkystar35@contoso.com
    Organization: 	contoso
    Filename:	      Enable-RemoteDesktopProtocol.ps1
    ===========================================================================
#>
BEGIN {
  $InvocationInfo = $MyInvocation
  [System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
  [string]$ScriptFullPath = $ScriptFileInfo.FullName
  [string]$ScriptNameFileExt = $ScriptFileInfo.Name
  [string]$ScriptName = 'Enable-RemoteDesktopProtocol'
  [string]$scriptRoot = Split-Path $ScriptFileInfo
	
#region FUNCTION Write-Log
  FUNCTION Write-Log {
    PARAM (
      [parameter(Mandatory = $true, HelpMessage = "Value added to the log file.")][ValidateNotNullOrEmpty()][string]$Message,
      [parameter(Mandatory = $false, HelpMessage = "Severity for the log entry.")][ValidateNotNullOrEmpty()][ValidateSet("Error", "Warn", "Info")][string]$Level = "Info",
      [parameter(Mandatory = $false, HelpMessage = "Name of the log file that the entry will written to.")][ValidateNotNullOrEmpty()][string]$FileName = "$($ScriptName).log",
      [string]$LogsDirectory = "$env:windir\Logs",
      [string]$component = ''
    )
    # Determine log file location
    IF ($FileName2.Length -le 4) {
      $FileName2 = "GenericScriptLog_$(Get-Date -Format yyyy-MM-dd)$FileName2"
    }
    $LogFilePath = Join-Path -Path $LogsDirectory -ChildPath $FileName
		
    # Construct time stamp for log entry
    IF (-not (Test-Path -Path 'variable:global:TimezoneBias')) {
      [string]$global:TimezoneBias = [System.TimeZoneInfo]::Local.GetUtcOffset((Get-Date)).TotalMinutes
      IF ($TimezoneBias -match "^-") {
        $TimezoneBias = $TimezoneBias.Replace('-', '+')
      } ELSE {
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
    TRY {
      Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop -WhatIf:$false
    } CATCH [System.Exception] {
      Write-Warning -Message "Unable to append log entry to $($FileName) file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
  }
  #endregion FUNCTION Write-Log
	
  Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
}
PROCESS {
  TRY {
		
    ## Main Script Block
    Write-Log -Message "Setting fDenyTSConnections registry name value to 0"
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0
    Write-Log -Message "Enabling `"Remote Desktop`" Firewall group"
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
		
		
  } CATCH {
    $Line = $_.InvocationInfo.ScriptLineNumber
    Write-Log -Message "Error: $_" -Level Error
    Write-Log -Message "Error: on line $line" -Level Error
  }
}
END {
  Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}
