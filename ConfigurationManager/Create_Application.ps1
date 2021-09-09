$IconPath = '\\kirk\it\software'
$AppInfo = "KeePass Password Safe;2.37;Dominik Reichl;KeePass.png;KeePass is a free open source password manager, which helps you to manage your passwords in a secure way."
$AppContent = '\\kirk\it\software'
<#,
"7-Zip;17.01.00.0;Igor Pavlov;7zip.png;7-Zip is an Open Source file compression software application.",
"Adobe Acrobat Reader DC;15.007.20033;Adobe Systems Incorporated;ReaderDC.png;Adobe Acrobat Reader allows you read PDF files.",
"Mozilla Firefox;57.0.2;Mozilla;Firefox.png;Firefox is a modern, fast web browser.",
"Notepad++;7.5.2;Notepad++ Team;Notepad++.png;Notepad++ is a free source code editor and Notepad replacement that supports several languages. Running in the MS Windows environment, its use is governed by GPL License."
#>

$AppOwner = '_EUCEngineers'
$AppInfo | foreach{
    $Split = $_ -split (';')
    $AppName = $Split[0]
    $AppVersion = $Split[1]
    $AppPublisher = $Split[2]
    $IconFile = "$AppContent\$AppPublisher\$AppName\$($Split[3])"
    $AppDescription = $Split[4]
    $ScriptContent = "$AppContent\$AppPublisher\$AppName\$AppVersion"
    Write-Host $ScriptContent
    Test-Path $ScriptContent
    Write-Host $IconFile
    Test-Path $IconFile
    New-CMApplication -Name "$AppName $AppVersion" -IconLocationFile "$IconFile" -AutoInstall $true -IsFeatured $False -LocalizedDescription "$AppDescription" -LocalizedName "$AppName" -Owner $AppOwner -Publisher "$AppPublisher" -SoftwareVersion "$AppVersion" -WhatIf
    #Add-CMDeploymentType -DeploymentTypeName "${AppName}_${AppVersion}_DT" -InstallationProgram "install.bat" -ScriptContent "$ScriptContent" -ScriptInstaller -ApplicationName "$AppName $AppVersion" -ContentLocation "$ScriptContent" -EnableContentLocationFallback $True -EstimatedInstallationTimeMins 15 -InstallationBehaviorType InstallForSystem -InstallationProgramVisibility Normal -LogonRequirementType WhetherOrNotUserLoggedOn -MaximumAllowedRunTimeMins 120 -OnSlowNetworkMode Download -PersistContentInClientCache $False -RequireUserInteraction $False -UninstallProgram "uninstall.bat" -WhatIf
}
#-IconLocationFile "$IconFile"