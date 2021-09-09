FUNCTION Update-ConfigStaticXML {
  <#
      .SYNOPSIS
      Updates or creates local config.xml file using URL source to overwrite
	
      .DESCRIPTION
      Updates or creates local config.xml file using URL source to overwrite
	
      .PARAMETER ConfigStaticXMLURL
      A description of the XMLURL parameter.
	
      .PARAMETER Destination
      A description of the Destination parameter.
	
      .PARAMETER Certificate
      A description of the Certificate parameter.
	
      .EXAMPLE
      PS C:\> Update-ConfigStaticXML -ConfigStaticXMLURL $value1
	
      .NOTES
      Additional information about the function.
  #>
		
  [CmdletBinding()]
  PARAM
  (
    [Parameter(Mandatory = $true)][ValidatePattern('.xml$')][ValidateNotNullOrEmpty()]$ConfigStaticXMLURL,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][system.io.fileinfo]$Destination,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.Security.Cryptography.X509Certificates.X509Certificate]$Certificate
  )
		
  TRY {
    $request = Invoke-WebRequest -Uri $ConfigStaticXMLURL -ErrorAction SilentlyContinue -OutFile $destination.FullName -UseBasicParsing -PassThru #-Certificate $Certificate
    #$Log.UpdateConfigStaticXMLURL = 
    'StatusCode {0}: {1}' -f $request.StatusCode, $ConfigStaticXMLURL
  }
  CATCH {
    #$Log.UpdateConfigStaticXMLURL = 
    '[URI {0} invalid or unreachable] Status {1}' -f $ConfigStaticXMLURL, $request.StatusCode
  }
}

FUNCTION Get-MachineCertificate {
  [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate])]
  PARAM
  (
    [Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][ValidateSet('Client Authentication', 'Code Signing', 'Server Authentication')]$AuthenticationType = 'Client Authentication',
    [ValidateNotNullOrEmpty()][ValidateSet('Root', 'CA', 'TrustedPublisher', 'AAD Token Issuer', 'My')]$Store = 'My'
  )
		
  Get-ChildItem -Path Cert:\LocalMachine\* -Recurse | Where-Object {
    $_.Subject -match $env:COMPUTERNAME -and $_.PSParentPath -match "Microsoft.PowerShell.Security\\Certificate\:\:LocalMachine\\$Store" -and $_.EnhancedKeyUsageList -like "$($AuthenticationType)*"
  } | Sort-Object -Property notafter | Select-Object -Last 1
}

Update-ConfigStaticXML -ConfigStaticXMLURL "https://sccmdp-no-01.af.lan/ConfigMgrWebService/bin/ClientHealth_config.xml" -Destination "C:\ProgramData\ConfigMgrClientHealth\Config-test.xml" -Certificate $(Get-MachineCertificate)
<#
Invoke-WebRequest -Uri "https://sccmdp-no-01.af.lan/ConfigMgrWebService/bin/ClientHealth_config.xml" -UseBasicParsing
#-Certificate $(Get-MachineCertificate) -UseBasicParsing
#-ErrorAction SilentlyContinue -OutFile $destination.FullName -PassThru
#>