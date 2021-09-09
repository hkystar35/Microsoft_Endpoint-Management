#Requires -Version 4.0

[CmdletBinding()]
param (
    [string] $Version = "0.0.0",
    [nullable[int]] $Revision,
    [string] $CreatedBy,
    [string] $ReleaseType,
    [string] $ChangesPath,
    [switch] $Test = $true,
    [switch] $CodeAnalysis = $true,
    [switch] $PrereleaseOverride,
    [string] $NugetUrl = "https://artifact.paylocity.com/artifactory/api/nuget/nuget",
    [string] $PowershellUrl = "https://artifact.paylocity.com/artifactory/api/nuget/powershell",
    [string] $SoftwareUrl = "https://artifact.paylocity.com/artifactory/software"
)

Set-StrictMode -version Latest
Write-Output "$($MyInvocation.MyCommand.Name) Parameters"
foreach($p in $MyInvocation.MyCommand.Parameters.GetEnumerator()) {
    $pv = ""; if ($PSBoundParameters.ContainsKey($p.Key)) { $pv = $($PSBoundParameters.$($p.Key)) } else { $pv = Get-Variable -ValueOnly $($p.Key) -ErrorAction Ignore }
    Write-Output "$($p.Key)=$(@{$true="*****";$false=$pv}[$p.Key -in @()])"
}

##### BOOTSTRAP #####

. $([ScriptBlock]::Create((New-Object System.Net.WebClient).DownloadString("$SoftwareUrl/bootstrap-module.1")));
Bootstrap-Module -Id @{"Build.Scripts"="1.11.3"} -PowershellUrl $PowershellUrl -ErrorAction Stop;

##### VARIABLE #####

$sourceScriptsPath = $(Resolve-Path "$PSScriptRoot\Source").Path
$nugetPackageFilePath = @()
$packagesDirectory = @{$true="$env:ProgramFiles\PackageManagement\NuGet\Packages";$false="$env:LOCALAPPDATA\PackageManagement\NuGet\Packages"}[$env:USERNAME -eq "$($env:COMPUTERNAME)$"]
$versionParameters = @{}; if ($PSBoundParameters.ContainsKey("Revision")) { $versionParameters.Add("Revision", $Revision) }
$outputPath = "$PSScriptRoot\artifacts"
$verbose = $PSBoundParameters.ContainsKey("Verbose") -and $PSBoundParameters["Verbose"].IsPresent
$versionMeta = $null

##### TASKS #####

function Test-TaskEnabled
{
    param ([boolean] $Value, [string] $Name)
    if (-not $Value) { Write-Host "Precondition was false, not executing $Name." } else { Write-Host (("-"*25) + "[$Name]" + ("-"*25)) }
    return $Value
}

if (Test-TaskEnabled -Value $true -Name Preconditions)
{
    Build.Scripts\Invoke-RetryCommand { `
        $outputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outputPath)
        if (Test-Path $outputPath)
        {
            Remove-Item $outputPath -Recurse -Force -ErrorAction Stop | Out-Null
        }
        New-Item $outputPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
    } -Retry 10 -ErrorAction Stop
    Write-Output "Output directory - $outputPath"
}

if (Test-TaskEnabled -Value $CodeAnalysis -Name Analyze)
{
    Build.Scripts\Invoke-ScriptAnalyzer -Path "$sourceScriptsPath\*.psm1" -ExcludeRule PSUseDeclaredVarsMoreThanAssignments, PSAvoidGlobalVars, PSAvoidUsingEmptyCatchBlock, PSAvoidUsingPlainTextForPassword, PSShouldProcess `
        -NugetRestoreSource $NugetUrl -NugetRestorePackagesDirectory $packagesDirectory -ErrorAction Stop -Verbose:$verbose
}

if (Test-TaskEnabled -Value $Test -Name Tests)
{
    Build.Scripts\Invoke-Pester -ScriptPath @("$PSScriptRoot\Tests\*Newman.Tests.ps1") `
        -Parameter @{ NugetRestoreSource = $NugetUrl } `
        -OutputPath $outputPath -NugetRestoreSource $NugetUrl `
        -NugetRestorePackagesDirectory $packagesDirectory -ErrorAction Stop -Verbose:$verbose
}

if (Test-TaskEnabled -Value $true -Name CreateDocumentation)
{
    & $PSScriptRoot\New-Readme.ps1 -ErrorAction Stop
}

if (Test-TaskEnabled -Value $true -Name CreateNuget)
{
    New-Item $outputPath\nugettemp -ItemType Directory -Force -ErrorAction Stop | Out-Null
    Copy-Item $sourceScriptsPath\*.* $outputPath\nugettemp -Force -ErrorAction Stop | Out-Null
    $files = @("$outputPath\nugettemp\*")
    $fileTargets = @("")
    $releaseNote = ""; if (-not [string]::IsNullOrWhiteSpace($ChangesPath)) { $releaseNote = Get-Content $ChangesPath -ErrorAction Stop | Out-String }
    $versionMeta = Build.Scripts\Get-VersionInfo -Version $Version -ReleaseType $ReleaseType$Revision -ErrorAction Stop -Verbose:$verbose

    $psdContent = Get-Content -Path "$outputPath\nugettemp\Paylocity.CyberArk.psd1" -Force -Raw -ErrorAction Stop
    $psdContent = $psdContent.Replace("'0.0.0'", "'$($versionMeta.Major).$($versionMeta.Minor).$($versionMeta.Build)'")
    if (-not [string]::IsNullOrWhiteSpace($versionMeta.Prerelease))
    {
        $psdContent = $psdContent.Replace("Prerelease = ''", "Prerelease = '$($versionMeta.Prerelease)'")
    }
    else
    {
        $psdContent = $psdContent.Replace("Prerelease = ''", "")
    }
    $psdContent | Set-Content -Path "$outputPath\nugettemp\Paylocity.CyberArk.psd1" -ErrorAction Stop
    $nugetPackageFilePath += Build.Scripts\New-NugetPackage -Id "Paylocity.CyberArk" -Description "Powershell functionality for cyberark" `
        -Version $Version -ReleaseType $ReleaseType$Revision -FileSource $files -FileTarget $fileTargets -ReleaseNote $releaseNote -Tag "CyberArk" `
        -CreatedBy $CreatedBy -NoPackageAnalysis -OutputPath $outputPath -ErrorAction Stop -Verbose:$verbose

    if ($PrereleaseOverride -and -not ([string]::IsNullOrWhiteSpace($versionMeta.Prerelease)))
    {
        $psdContent = Get-Content -Path "$outputPath\nugettemp\Paylocity.CyberArk.psd1" -Force -Raw -ErrorAction Stop
        $psdContent = $psdContent.Replace("Prerelease = '$($versionMeta.Prerelease)'", "")
        $psdContent | Set-Content -Path "$outputPath\nugettemp\Paylocity.CyberArk.psd1" -ErrorAction Stop
        $nugetPackageFilePath += Build.Scripts\New-NugetPackage -Id "Paylocity.CyberArk" -Description "Powershell functionality for cyberark" `
            -Version $Version -FileSource $files -FileTarget $fileTargets -ReleaseNote $releaseNote -Tag "CyberArk" `
            -CreatedBy $CreatedBy -NoPackageAnalysis -OutputPath $outputPath -ErrorAction Stop -Verbose:$verbose
    }
}

if (Test-TaskEnabled -Value $true -Name Cleanup)
{
    Write-Output "Removing unneeded build outputs"
    Build.Scripts\Invoke-RetryCommand { `
        $couldNotDelete = $false
        $excludeFilter = @(".nupkg$",".xml$")
        Get-ChildItem -Path $outputPath -Recurse -ErrorAction Stop | ForEach-Object -Process {
            $allowed = $true
            foreach ($item in $excludeFilter) { if ($_.FullName -imatch $item) { $allowed = $false; break }}
            if ($allowed) { try { Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction Stop } catch { Write-Warning $_; $couldNotDelete = $true }}
        }
        if ($couldNotDelete) { throw "Could not delete some items" }
    } -Retry 10 -ErrorAction SilentlyContinue -Verbose:$verbose
}
