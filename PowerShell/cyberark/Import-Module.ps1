#Requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string[]] $Id,
    [Parameter(Mandatory=$true)]
    [string[]] $Version,
    [string] $Prefix,
    [string] $PowershellUrl = ""
)

Write-Verbose "Validating parameters"
if ($null -eq $Id) { $Id = @() } else { $Id = @($Id) }
if ($null -eq $Version) { $Version = @() } else { $Version = @($Version) }
if ($Id.Count -ne $Version.Count) 
{
    throw "Id and Version must have same number of elements."
}

if ($PSVersionTable.ContainsKey("Platform") -and $PSVersionTable.Platform -eq "Unix")
{
    $installScope = @{$true="AllUsers";$false="CurrentUser"}[[bool]($(whoami) -eq "root")]
}
else
{
    $installScope = @{$true="AllUsers";$false="CurrentUser"}[[bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")]
}
$packageSource = @(Get-PackageSource) | Where-Object { $_.Location -eq $PowershellUrl } | Select-Object -First 1
if ($null -eq $packageSource) { $packageSource = Register-PackageSource -Name PaylocityPowershell -Location $PowershellUrl -ProviderName PowershellGet -Trusted -Force -ErrorAction Stop ; }
for ($i=0; $i -lt $Id.Count; $i++)
{
    if ($null -eq (Get-Module $Id[$i] -ListAvailable -ErrorAction Stop | Where-Object { $_.Version -eq $Version[$i] }))
    { 
        Install-Module -Name $Id[$i] -RequiredVersion $Version[$i] -Scope $installScope -Repository $packageSource.Name -AllowClobber -SkipPublisherCheck -ErrorAction Stop
    }
    if ($null -eq (Get-Module $Id[$i] -ErrorAction Stop))
    { 
        Import-Module -Name $Id[$i] -RequiredVersion $Version[$i] -Prefix $Prefix -ErrorAction Stop
    }
    elseif (@(Get-Module $Id[$i] -ErrorAction Stop | Where-Object { $_.Version -ne $Version[$i] }).Count -gt 0)
    {
        Write-Warning "Skipping import of module $($Id[$i]) v$($Version[$i]) because v$((Get-Module $Id[$i] -ErrorAction Stop | Where-Object { $_.Version -ne $Version[$i] } | Select-Object -First 1).Version.ToString()) is already loaded.  Some modules need session restart to load new versions."
    }
}
