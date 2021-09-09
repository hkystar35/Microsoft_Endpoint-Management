<#
    .SYNOPSIS
    Enables WinRM service
	
    .DESCRIPTION
    Enables Remote Desktop
	
    .NOTES
    ===========================================================================

    Created on:   	2020/12/15
    Created by:   	Nicolas.Wendlowsky@chobani.com
    Organization: 	Chobani
    Filename:	      Enable-WinRM.ps1
    ===========================================================================
#>
BEGIN {
  $InvocationInfo = $MyInvocation
  [System.IO.FileInfo]$ScriptFileInfo = $InvocationInfo.MyCommand.Path
  [string]$ScriptFullPath = $ScriptFileInfo.FullName
  [string]$ScriptNameFileExt = $ScriptFileInfo.Name
  [string]$ScriptName = 'Enable-WinRM'
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
		
    # Get WinRM
    $WinRM_service = Get-Service -Name WinRM -ErrorAction Stop
    
    # Enable WinRM commands
    Start-Process -FilePath $env:windir\System32\winrm.cmd -ArgumentList 'quickconfig -force' -ErrorAction Stop
    Enable-PSRemoting -SkipNetworkProfileCheck -Force
      
    # Set TrustedHosts
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force -Confirm:$false
      
    # Start WinRM Service
    $WinRM_service | Start-Service -ErrorAction Stop
      
    # Set WinRM to auto-start
    $WinRM_service | Set-Service -StartupType Automatic
      
    # Enable Firewall Group
    Get-NetFirewallRule -DisplayGroup 'Windows Remote Management' | where {$_.Profile -notcontains 'Public'} | Enable-NetFirewallRule -Confirm:$false
		
  } CATCH {
    $Line = $_.InvocationInfo.ScriptLineNumber
    Write-Log -Message "Error: $_" -Level Error
    Write-Log -Message "Error: on line $line" -Level Error
  }
}
END {
  Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}