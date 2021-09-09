TRY {
		$StartingLocation = Get-Location
		Import-Module -Name $env:SMS_ADMIN_UI_PATH.Replace('\bin\i386', '\bin\ConfigurationManager.psd1')
		Write-Output "Changing location to $($SiteCode.Name):\"
		$SiteCode = Get-PSDrive -PSProvider CMSITE
		Set-Location -Path "$($SiteCode.Name):\"
		Write-Output "done."
	} CATCH {
		Write-Output 'Could not import SCCM module'
		Set-Location -Path $StartingLocation
		BREAK
	}
# App names can be list or truncated
#[string[]]
$App = Read-Host -Prompt "App Name"
#Write-Host "Here's the stuff: $app <end of stuff>"
#foreach ($App in $Apps){
# Get Application Info from SCCM
$cmApps = Get-CMApplication  -Name "$App*"
$RemovalResults = @()
    # Loop through each found application
    foreach ($cmApp in $cmApps){
        # Set variables
        $cmLocalName = $cmApp.LocalizedDisplayName
        $cmPversion = $cmApp.SDMPackageVersion
        # Get Revision History for application
        $cmAppRevision = $cmApp | Get-CMApplicationRevisionHistory | select -Property *vers*
        if($cmAppRevision.Count -gt 1){
            # Write output to screen
            Write-Host "Before $($cmLocalName) - Latest Revision: $($cmPversion) - Number of revisions: $($cmAppRevision.Count)" -ForegroundColor Yellow -BackgroundColor DarkGray
            #
            # Delete revisions except for latest
            for($i = 0;$i -lt $cmAppRevision.Count-1;$i++){
                $RemovalResults += Remove-CMApplicationRevisionHistory -Name "$cmLocalName" -revision $cmAppRevision[$i].CIVersion -Force -ErrorAction Continue
            }
            # Get updated Revision History for application
            $cmAppRevision2 = $cmApp | Get-CMApplicationRevisionHistory
            # Write output to screen
            "After {0} - Latest Revision: {1} - Number of revisions: {2}" -f "$cmLocalName", "$cmPversion", $cmAppRevision2.Count
            #>
        }Elseif($cmAppRevision.Count -eq 1){
            Write-Host "$cmLocalName - Revisions are clean"
        }
    }
#}
Set-Location $HOME