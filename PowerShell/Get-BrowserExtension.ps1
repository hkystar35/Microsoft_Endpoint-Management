<#	
    .NOTES
    ===========================================================================
    Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2019 v5.6.170
    Created on:   	4/6/2020 13:47
    Created by:   	NWendlowsky
    Organization: 	Paylocity
    Filename:     	
    ===========================================================================
    .DESCRIPTION
    A description of the file.
#>


FUNCTION Download-BrowserExtension {
  [CmdletBinding()]
  PARAM
  (
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$URI
  )
  $URI = 'http://yahoo.com'
  switch ($URI) {
    {$_.trimstart -eq 'http://'} {
      "443"
    }
    {$_.Trimstart -eq 'https://'} {	"80"}
  }
}

Get-ChildItem $env:SystemDrive\users\*\AppData\Roaming\Mozilla\Firefox\Profiles -Recurse -Filter Addons.json | ForEach-Object {

  (Get-Content $_.FullName | ConvertFrom-Json).addons | Select name, Version, id, sourceURI, Description, type, creator, updatedate

} | Out-GridView

[string]$DateFormat = 'MM/dd/yyyy HH:mm:ss'
##//////////////////////#
## Start Here!
## You left off on 9/11/2020 09:58:03
##//////////////////////#
$Extensions_Firefox = [System.Management.Automation.PSCustomObject]@(
  Get-ChildItem "$env:SystemDrive\users\*\AppData\Roaming\Mozilla\Firefox\Profiles" -Recurse -Filter extensions.json | ForEach-Object {
    $Addons = (Get-Content $_.FullName | ConvertFrom-Json).addons
    #New-Object -TypeName pscustomobject -Property 
    @{
      Counter        = 1
      FolderDate     = $Addons.installDate #$((get-date 1970-01-01)+[timespan]::FromMilliseconds($Addons.installDate) | Get-Date -Format $DateFormat.ToString())
      ManifestFolder = $Addons.path
      Name           = $Addons.DefaultLocale.Name
      ProfilePath    = ($Addons.path -split '\\appdata')[0]
      ScriptLastRan  = (Get-Date -Format $DateFormat.ToString())
      Version        = $Addons.Version
      PSComputerName = ''
    }
    Remove-Variable addons
  }
)

$Extensions_Firefox | ft


$Extensions_Firefox | Select @{L="Name";E={$_.DefaultLocale.Name}}, Version, id, sourceURI, Description, type, creator, installdate, updatedate, active, visible | ft

$Extensions_Firefox | Select @{L="Name";E={$_.DefaultLocale.Name}}, , id, sourceURI, Description, type, creator, installdate, updatedate, active, visible | Out-GridView



Counter        : 1
FolderDate     : (get-date 1970-01-01)+[timespan]::FromMilliseconds($installDate) | Get-Date -Format $DateFormat.ToString()
ManifestFolder : $path
Name           : $_.DefaultLocale.Name
ProfilePath    : ($path -split '\\appdata')[0]
ScriptLastRan  : (Get-Date -Format $DateFormat.ToString())
Version        : $Version
PSComputerName


5/31/2020 19:07:56