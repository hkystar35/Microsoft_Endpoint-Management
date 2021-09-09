[CmdletBinding()]
PARAM
(
	[Parameter(Mandatory = $false,
			   ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true)][string[]]$ComputerName = $env:computername,
	[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$UserName
)

BEGIN {
}

PROCESS {
	
	FOREACH ($Computer IN $ComputerName) {
		Write-Verbose "Working on $Computer"
		IF (Test-Connection -ComputerName $Computer -Count 1 -ErrorAction 0) {
			$Profiles = Get-WmiObject -Class Win32_UserProfile -ComputerName $Computer -ErrorAction 0
			FOREACH ($profile IN $profiles) {
				$objSID = New-Object System.Security.Principal.SecurityIdentifier($profile.sid)
				$objuser = $objsid.Translate([System.Security.Principal.NTAccount])
				$profilename = $objuser.value.split("\")[1]
				IF ($profilename -eq $UserName) {
					$profilefound = $true
					TRY {
						$profile.delete()
						Write-Host "$UserName profile deleted successfully on $Computer"
					} CATCH {
						Write-Host "Failed to delete the profile, $UserName on $Computer"
					}
				}
			}
			
			IF (!$profilefound) {
				write-Warning "No profiles found on $Computer with Name $UserName"
			}
		} ELSE {
			write-verbose "$Computer Not reachable"
		}
	}
	
}

END {
}