<#
    .SYNOPSIS
    A brief description of the !Template.ps1 file.
	
    .DESCRIPTION
    A description of the file.
	
    .PARAMETER Input
    A description of the Input parameter.
	
    .NOTES
    ===========================================================================

    Created on:   	4/14/2020 16:23:20
    Created by:   	hkystar35@contoso.com
    Organization: 	contoso
    Filename:	      Move-OutlookClientRulesToO365
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
      Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop -Whatif:$false
    } CATCH [System.Exception] {
      Write-Warning -Message "Unable to append log entry to $($FileName) file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
  }
  #endregion FUNCTION Write-Log
	
  #region Import Modules
  $ModuleNames = 'AzureAD' # 'PowerShellGet','ConfluencePS','PSSlack' # array list
  IF($ModuleNames){
    $Modules = Get-Module -ListAvailable
    foreach($ModuleName in $ModuleNames){
      IF($Modules.name -contains $ModuleName){
        Import-Module -Name $ModuleName -Global
        Write-Host "Imported module $ModuleName"
      }ELSE{
        Install-Module -Name $ModuleName -Confirm:$false -AllowClobber
        Write-Host "Installed module $ModuleName"
        Import-Module -Name $ModuleName -Global
        Write-Host "Imported module $ModuleName"
      }
    }
  }ELSE{
    Write-Log -Message 'No modules to import'
  }
  #endregion Import Modules
  
  Write-Log -Message " ----- BEGIN $($ScriptNameFileExt) execution ----- "
}
PROCESS {
  TRY {
		
    # Prompt User to Confirm identity
    $UserPrincipalName = 'hkystar35@contoso.com'
    
    # Exchange Online
    Connect-ExchangeOnline -UserPrincipalName $UserPrincipalName
    
    # Get EXO mailbox
    $Mailbox = Get-EXOMailbox -Identity $UserPrincipalName
    
    # Get EXO inbox Rules
    $EXOInboxRules = $Mailbox | Get-InboxRule
    
    # Connect to Outlook client MAPI
    Add-Type -assembly "Microsoft.Office.Interop.Outlook"
    $Outlook = New-Object -comobject Outlook.Application
    $namespace = $Outlook.GetNameSpace("MAPI")
    
    # Get MAPI client Rules
    $MAPIInboxRules = $namespace.DefaultStore.GetRules()
    
    # Get MAPI Rule counts
    $MAPIEnabledRuleCount = $MAPIInboxRules.IsRssRulesProcessingEnabled
    $MAPIRuleCount = $MAPIInboxRules.Count
    
    # Extract Rule Conditions to PSObject
    
    # Create new EXO Rules
    $MAPIRulesSplat = @{
      Actions       = "" #Property     RuleActions Actions () {get}                                                                                                                     
      Application   = "" #Property     _Application Application () {get}                                                                                                                
      Class         = "" #Property     OlObjectClass Class () {get}                                                                                                                     
      Conditions    = "" #Property     RuleConditions Conditions () {get}                                                                                                               
      Enabled       = "" #Property     bool Enabled () {get} {set}                                                                                                                      
      Exceptions    = "" #Property     RuleConditions Exceptions () {get}                                                                                                               
      ExecutionOrder= "" #Property     int ExecutionOrder () {get} {set}                                                                                                                
      IsLocalRule   = "" #Property     bool IsLocalRule () {get}                                                                                                                        
      Name          = "" #Property     string Name () {get} {set}                                                                                                                       
      Parent        = "" #Property     IDispatch Parent () {get}                                                                                                                        
      RuleType      = "" #Property     OlRuleType RuleType () {get}                                                                                                                     
      Session       = "" #Property     _NameSpace Session () {get}     
    }
    
    $RuleSplat = @{
      ApplyCategory                        = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      ApplySystemCategory                  = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[Microsoft.Exchange.Data.SystemCategoryType, Microsoft.Excha...
      BodyContainsWords                    = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      CopyToFolder                         = "" #Property      {get;set;}                                                                                                               
      DeleteMessage                        = "" #Property     System.Boolean {get;set;}                                                                                                 
      DeleteSystemCategory                 = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[Microsoft.Exchange.Data.SystemCategoryType, Microsoft.Excha...
      Description                          = "" #Property     System.String {get;set;}                                                                                                  
      Enabled                              = "" #Property     System.Boolean {get;set;}                                                                                                 
      ErrorType                            = "" #Property     System.String {get;set;}                                                                                                  
      ExceptIfBodyContainsWords            = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      ExceptIfFlaggedForAction             = "" #Property      {get;set;}                                                                                                               
      ExceptIfFrom                         = "" #Property      {get;set;}                                                                                                               
      ExceptIfFromAddressContainsWords     = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      ExceptIfFromSubscription             = "" #Property      {get;set;}                                                                                                               
      ExceptIfHasAttachment                = "" #Property     System.Boolean {get;set;}                                                                                                 
      ExceptIfHasClassification            = "" #Property      {get;set;}                                                                                                               
      ExceptIfHeaderContainsWords          = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      ExceptIfMessageTypeMatches           = "" #Property      {get;set;}                                                                                                               
      ExceptIfMyNameInCcBox                = "" #Property     System.Boolean {get;set;}                                                                                                 
      ExceptIfMyNameInToBox                = "" #Property     System.Boolean {get;set;}                                                                                                 
      ExceptIfMyNameInToOrCcBox            = "" #Property     System.Boolean {get;set;}                                                                                                 
      ExceptIfMyNameNotInToBox             = "" #Property     System.Boolean {get;set;}                                                                                                 
      ExceptIfReceivedAfterDate            = "" #Property      {get;set;}                                                                                                               
      ExceptIfReceivedBeforeDate           = "" #Property      {get;set;}                                                                                                               
      ExceptIfRecipientAddressContainsWords= "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      ExceptIfSentOnlyToMe                 = "" #Property     System.Boolean {get;set;}                                                                                                 
      ExceptIfSentTo                       = "" #Property      {get;set;}                                                                                                               
      ExceptIfSubjectContainsWords         = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      ExceptIfSubjectOrBodyContainsWords   = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      ExceptIfWithImportance               = "" #Property      {get;set;}                                                                                                               
      ExceptIfWithinSizeRangeMaximum       = "" #Property      {get;set;}                                                                                                               
      ExceptIfWithinSizeRangeMinimum       = "" #Property      {get;set;}                                                                                                               
      ExceptIfWithSensitivity              = "" #Property      {get;set;}                                                                                                               
      FlaggedForAction                     = "" #Property      {get;set;}                                                                                                               
      ForwardAsAttachmentTo                = "" #Property      {get;set;}                                                                                                               
      ForwardTo                            = "" #Property      {get;set;}                                                                                                               
      From                                 = "" #Property     Deserialized.Microsoft.Exchange.Data.Storage.Management.ADRecipientOrAddress[] {get;set;}                                 
      FromAddressContainsWords             = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      FromSubscription                     = "" #Property      {get;set;}                                                                                                               
      HasAttachment                        = "" #Property     System.Boolean {get;set;}                                                                                                 
      HasClassification                    = "" #Property      {get;set;}                                                                                                               
      HeaderContainsWords                  = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      Identity                             = "" #Property     System.String {get;set;}                                                                                                  
      InError                              = "" #Property     System.Boolean {get;set;}                                                                                                 
      IsValid                              = "" #Property     System.Boolean {get;set;}                                                                                                 
      Legacy                               = "" #Property      {get;set;}                                                                                                               
      MailboxOwnerId                       = "" #Property     System.String {get;set;}                                                                                                  
      MarkAsRead                           = "" #Property     System.Boolean {get;set;}                                                                                                 
      MarkImportance                       = "" #Property      {get;set;}                                                                                                               
      MessageTypeMatches                   = "" #Property      {get;set;}                                                                                                               
      MoveToFolder                         = "" #Property     System.String {get;set;}                                                                                                  
      MyNameInCcBox                        = "" #Property     System.Boolean {get;set;}                                                                                                 
      MyNameInToBox                        = "" #Property     System.Boolean {get;set;}                                                                                                 
      MyNameInToOrCcBox                    = "" #Property     System.Boolean {get;set;}                                                                                                 
      MyNameNotInToBox                     = "" #Property     System.Boolean {get;set;}                                                                                                 
      Name                                 = "" #Property     System.String {get;set;}                                                                                                  
      ObjectState                          = "" #Property     System.String {get;set;}                                                                                                  
      PinMessage                           = "" #Property     System.Boolean {get;set;}                                                                                                 
      Priority                             = "" #Property     System.Int32 {get;set;}                                                                                                   
      ReceivedAfterDate                    = "" #Property      {get;set;}                                                                                                               
      ReceivedBeforeDate                   = "" #Property      {get;set;}                                                                                                               
      RecipientAddressContainsWords        = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      RedirectTo                           = "" #Property      {get;set;}                                                                                                               
      RuleIdentity                         = "" #Property     System.UInt64 {get;set;}                                                                                                  
      SendTextMessageNotificationTo        = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[Microsoft.Exchange.Data.Storage.Management.E164Number, Micr...
      SentOnlyToMe                         = "" #Property     System.Boolean {get;set;}                                                                                                 
      SentTo                               = "" #Property      {get;set;}                                                                                                               
      StopProcessingRules                  = "" #Property     System.Boolean {get;set;}                                                                                                 
      SubjectContainsWords                 = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      SubjectOrBodyContainsWords           = "" #Property     Deserialized.Microsoft.Exchange.Data.MultiValuedProperty`1[[System.String, mscorlib, Version=4.0.0.0, Culture=neutral, ...
      SupportedByTask                      = "" #Property     System.Boolean {get;set;}                                                                                                 
      WithImportance                       = "" #Property      {get;set;}                                                                                                               
      WithinSizeRangeMaximum               = "" #Property      {get;set;}                                                                                                               
      WithinSizeRangeMinimum               = "" #Property      {get;set;}                                                                                                               
      WithSensitivity                      = "" #Property      {get;set;}  
    
    }
    
    $TestRule = New-InboxRule
    
  } CATCH {
    $Line = $_.InvocationInfo.ScriptLineNumber
    Write-Log -Message "Error: $_" -Level Error
    Write-Log -Message "Error: on line $line" -Level Error
  }
}
END {
  Write-Log -Message " ----- END $($ScriptNameFileExt) execution ----- "
}
