General Info
============

The purpose of this package is to manage cyberark.

There are two primary functions available:
* **Connect-CyberArk** - Will handle creating a session with cyberark
* **Disconnect-CyberArk** - Will handle removing a session with cyberark
* **Get-Account** - Will retrieve account info

Modules
============
[Cyberark](#Cyberark-module)



<a id="Cyberark-module"></a>

Cyberark

---------------

Powershell functionality for cyberark



[Tests](Tests/CyberArk.Tests.ps1)


*Examples*
~~~powershell
Remove-Module Cyberark -Force -ErrorAction Ignore

Import-Module "$env:LOCALAPPDATA\PackageManagement\NuGet\Packages\Cyberark.1.0.0\tools\Cyberark.psm1"
$result = Cyberark\Verb-Noun

OR

Install-Module -Name Cyberark -RequiredVersion 1.0.0
Import-Module -Name Cyberark -RequiredVersion 1.0.0
$result = Cyberark\Verb-Noun
~~~


