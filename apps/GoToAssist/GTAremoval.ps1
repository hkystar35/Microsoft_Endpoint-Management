#Function Uninstall-GTA
	Function Uninstall-GTA {
        <#
        .DESCRIPTION
	        To reduce code space, function calls uninstall routine for both Pre-Installation (upgrade) and Uninstallation (removal).
        .EXAMPLE
	        Uninstall-GTA
        #>
		[CmdletBinding()]
		Param (
			[string]$GTA
		)
<#		Remove-MSIApplications -Name "GoToAssist"
		Remove-MSIApplications -Name "GoToAssist Corporate"
		Remove-MSIApplications -Name "GoToAssist Unattended Customer"#>
	$envProgramFilesX86 = 'C:\Program Files (x86)'
	$envProgramFiles = 'C:\Program Files'
    $UninstallPaths = 	'Citrix\GoToAssist Remote Support Customer',
         				'Citrix\GoToAssist Remote Support Expert',
         				'Citrix\GoToAssist',
						'GoToAssist Remote Support Customer',
						'Citrix\GoToAssist Express Expert'
         
	$UninstallPaths | foreach{
      if(Test-Path -Path $envProgramFilesX86\$_){
			$Uninstaller = Get-ChildItem -Path $envProgramFilesX86\$_ -Filter "*uninstall*.exe" -Recurse
			$UninstallerFullX86 = $Uninstaller.FullName
			#Write-Log -Message
			Write-Host "Uninstall path: "$UninstallerFullX86""
			#Execute-Process -Path "$UninstallerFullX86" -Parameters "/S /LOG=`"$configToolkitLogDir\$appName-$uninstallversion-uninstall.log`""
		}elseif(Test-Path -Path $envProgramFiles\$_){
			$Uninstaller = Get-ChildItem -Path $envProgramFiles\$_ -Filter "*uninstall*.exe" -Recurse
			$UninstallerFull = $Uninstaller.FullName
			#Write-Log -Message
			Write-Host "Uninstall path: "$UninstallerFullX86""
			#Execute-Process -Path "$UninstallerFull" -Parameters "/S /LOG=`"$configToolkitLogDir\$appName-$uninstallversion-uninstall.log`""
    	}
	}
	}

Uninstall-GTA