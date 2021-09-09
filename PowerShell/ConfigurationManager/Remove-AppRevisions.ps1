# App names can be list or truncated
#[string[]]
$App = Read-Host -Prompt "App Name"
#Write-Host "Here's the stuff: $app <end of stuff>"
#foreach ($App in $Apps){
# Get Application Info from SCCM
$cmApps = Get-CMApplication  -Name "$App*"
    # Loop through each found application
    foreach ($cmApp in $cmApps){
        # Set variables
        $cmLocalName = $cmApp.LocalizedDisplayName
        $cmPversion = $cmApp.SDMPackageVersion
        # Get Revision History for application
        $cmAppRevision = $cmApp | Get-CMApplicationRevisionHistory
        if($cmAppRevision.Count -gt 1){
            # Write output to screen
            "Before {0} - Latest Revision: {1} - Number of revisions: {2}" -f "$cmLocalName", "$cmPversion", $cmAppRevision.Count
            #
            # Delete revisions except for latest
            for($i = 0;$i -lt $cmAppRevision.Count-1;$i++){
                Remove-CMApplicationRevisionHistory -Name "$cmLocalName" -revision $cmAppRevision[$i].CIVersion -Force
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