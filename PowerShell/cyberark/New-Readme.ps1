#Requires -Version 4.0

[CmdletBinding()]
param(
)

# will generate the readme content
$testUrl = "https://code.paylocity.com/projects/TOOL/repos/paylocity.cyberark/browse/Source/Tests"
$branch = "master"
$sourcePath = Resolve-Path "$PSScriptRoot\Source"
$readmeFilePath = "$PSScriptRoot\readme.md"

$fileContent = Get-Content "$PSScriptRoot\general.md" -ErrorAction Stop
$files = Get-ChildItem -Path "$sourcePath\*.psd1"
$fileContent += "Modules"
$fileContent += "============"
$fileContent += (($files | Select-Object -ExpandProperty Name) | ForEach-Object -Process { "[$([System.IO.Path]::GetFileNameWithoutExtension($_))](#$([System.IO.Path]::GetFileNameWithoutExtension($_))-module)" }) -join " | "
$fileContent += "`r`n`r`n"
foreach ($file in $files)
{
    $moduleInfo = Test-ModuleManifest $file.FullName
    $fileContent += "<a id=""$($moduleInfo.Name)-module""></a>`r`n"
    $fileContent += "$($moduleInfo.Name)`r`n"
    $fileContent += "---------------`r`n"
    $fileContent += $moduleInfo.Description + "`r`n"
    $fileContent += "`r`n"
    $fileContent += "[Tests]($testUrl/$($moduleInfo.Name).Tests.ps1?at=refs%2Fheads%2F$branch)`r`n"
    $fileContent += ""
    $fileContent += "*Examples*"
    $fileContent += "~~~powershell"
    $fileContent += "Remove-Module $($moduleInfo.Name) -Force -ErrorAction Ignore"
    $fileContent += ""
    $fileContent += "Import-Module ""`$env:LOCALAPPDATA\PackageManagement\NuGet\Packages\$($moduleInfo.Name).1.0.0\tools\$($moduleInfo.Name).psm1"""
    $fileContent += "`$result = $($moduleInfo.Name)\Verb-Noun"
    $fileContent += ""
    $fileContent += "OR"
    $fileContent += ""
    $fileContent += "Install-Module -Name $($moduleInfo.Name) -RequiredVersion 1.0.0"
    $fileContent += "Import-Module -Name $($moduleInfo.Name) -RequiredVersion 1.0.0"
    $fileContent += "`$result = $($moduleInfo.Name)\Verb-Noun"
    $fileContent += "~~~"
    $fileContent += "`r`n"
}

# $files = Get-ChildItem -Path "$sourcePath\*.ps1"
# $fileContent += "Scripts
# ============

# "
# $fileContent += (($files | Select-Object -ExpandProperty Name) | ForEach-Object -Process { "[$([System.IO.Path]::GetFileNameWithoutExtension($_))](#$([System.IO.Path]::GetFileNameWithoutExtension($_))-script)" }) -join " | "
# $fileContent += "`r`n`r`n"
# foreach ($file in $files)
# {
#     $content =  Get-Content -Path $file.FullName | Out-String
#     $name = [System.IO.Path]::GetFileNameWithoutExtension($file.FullName)
#     $help = (([Regex]'(?is)(?:(?<=#HELP-START#).+(?=#HELP-END#))').Match(($content)).Value).Replace("<#", "").Replace("#>", "").Trim()
#     $example = (".EXAMPLE" + ([Regex]'(?is)(?:(?<=\.EXAMPLE).+)').Match(($help)).Value).Trim().Replace(".EXAMPLE", "# EXAMPLE")
#     $documentation = $help.Replace(".EXAMPLE", "# EXAMPLE").Replace($example, "").Trim()
#     $code = $content.Replace($help, "")

#     [string[]] $dependencies = @()
#     try
#     {
#         $matches = [regex]::Matches($code, "(\\)(\S*\.ps1)")
#         foreach ($match in $matches)
#         {
#             if (-not $dependencies.Contains($match.Groups[2].Value))
#             {
#                 $dependencies += "[$([System.IO.Path]::GetFileNameWithoutExtension($match.Groups[2].Value))](#$([System.IO.Path]::GetFileNameWithoutExtension($match.Groups[2].Value))-script)"
#             }
#         }
#     }
#     catch
#     {
#         throw $_
#     }
#     [string[]] $dependencies = @($dependencies | Select-Object -Unique | Sort-Object)

#     $fileContent += "<a id=""$name-script""></a>`r`n"
#     $fileContent += "$name`r`n"
#     $fileContent += "---------------`r`n"
#     $fileContent += "~~~xml`r`n"
#     $fileContent += $documentation + "`r`n"
#     $fileContent += "~~~`r`n"
#     $fileContent += "`r`n"
#     $fileContent += "*Examples*`r`n"
#     $fileContent += "~~~powershell`r`n"
#     $fileContent += $example + "`r`n"
#     $fileContent += "~~~`r`n"
#     $fileContent += "`r`n"
#     $fileContent += "Dependencies: **$(if ($dependencies.Count -gt 0) { $dependencies -join ", " } else { "None" })**`r`n"
#     $fileContent += "`r`n"
#     $fileContent += "[Tests]($testUrl/$name.Tests.ps1?at=refs%2Fheads%2F$branch)`r`n"
#     $fileContent += "`r`n"
# }
Set-Content -Path $readmeFilePath -Value $fileContent -Force