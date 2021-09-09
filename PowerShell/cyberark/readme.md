General Info
============

The purpose of this package is to manage cyberark.

There are two primary functions available:
* **Connect-CyberArk** - Will handle creating a session with cyberark
* **Disconnect-CyberArk** - Will handle removing a session with cyberark
* **Get-Account** - Will retrieve account info

Modules
============
[Paylocity.CyberArk](#Paylocity.CyberArk-module)



<a id="Paylocity.CyberArk-module"></a>

Paylocity.CyberArk

---------------

Powershell functionality for cyberark



[Tests](https://code.paylocity.com/projects/TOOL/repos/paylocity.cyberark/browse/Source/Tests/Paylocity.CyberArk.Tests.ps1?at=refs%2Fheads%2Fmaster)


*Examples*
~~~powershell
Remove-Module Paylocity.CyberArk -Force -ErrorAction Ignore

Import-Module "$env:LOCALAPPDATA\PackageManagement\NuGet\Packages\Paylocity.CyberArk.1.0.0\tools\Paylocity.CyberArk.psm1"
$result = Paylocity.CyberArk\Verb-Noun

OR

Install-Module -Name Paylocity.CyberArk -RequiredVersion 1.0.0
Import-Module -Name Paylocity.CyberArk -RequiredVersion 1.0.0
$result = Paylocity.CyberArk\Verb-Noun
~~~


