<#	
    .NOTES
    ===========================================================================
    Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.152
    Created on:   	5/18/2018 2:03 PM
    Created by:   	
    Organization: 	
    Filename:     	
    ===========================================================================
    .DESCRIPTION
    Imports cert to selected stores from Base64String. Needs string created beforehand
#>



FUNCTION Import-CertString {
  <#
      .SYNOPSIS
      A brief description of the Import-CertString function.
	
      .DESCRIPTION
      A detailed description of the Import-CertString function.
	
      .PARAMETER StoreLocation
      Choose Store and Location
	
      .PARAMETER Password
      If needed.
	
      .PARAMETER CertString
      Base64String required, use separate script to generate
	
      .EXAMPLE
      PS C:\> Import-CertString -StoreLocation 'AddressBook, CurrentUser'
	
      .NOTES
      Additional information about the function.
  #>
	
  [CmdletBinding()]
  PARAM
  (
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][ValidateSet('AddressBook,CurrentUser', 'AuthRoot,CurrentUser', 'CA,CurrentUser', 'Disallowed,CurrentUser', 'My,CurrentUser', 'Root,CurrentUser', 'TrustedPeople,CurrentUser', 'TrustedPublisher,CurrentUser', 'AddressBook,LocalMachine', 'AuthRoot,LocalMachine', 'CA,LocalMachine', 'Disallowed,LocalMachine', 'My,LocalMachine', 'Root,LocalMachine', 'TrustedPeople,LocalMachine', 'TrustedPublisher,LocalMachine')]$StoreLocation,
    [ValidateNotNullOrEmpty()][string]$Password,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$CertString
  )
  $ErrorActionPreference = 'Stop'
  TRY {
    $Split = $StoreLocation -split ','
    $storeName = $Split[0]
    $Location = $Split[1]
		
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store $storeName, $Location
    $store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
		
    $certByteArray = [System.Convert]::FromBase64String($certString)
		
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    IF ($certpw) {
      $cert.Import($certByteArray, $certpw)
    } ELSEIF (!$certpw) {
      $cert.Import($certByteArray)
    }
		
    $store.Add($cert)
    $store.Close()

    
  } CATCH {
    Write-Output $_.Exception.Message
  }
}