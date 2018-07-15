<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.152
	 Created on:   	5/31/2018 9:34 AM
	 Created by:   	NWendlowsky
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		Create FireWall Rules - Inbound or Outbound.
#>

FUNCTION Create-FirewallRule {
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateSet('TCP', 'UDP', 'TCPUDP')][ValidateNotNullOrEmpty()][Alias('P')][string]$Protocol,
		[switch]$RemoveExisiting = $false,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Description,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$DisplayName,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$FilePath
	)
	
	$Protocols = "TCP", "UDP"
	#$FirewallDisplayName = "solsticeclient"
	#$FirewallRuleDescription = $FirewallDisplayName
	
	#Remove Existing Firewall Rules
	IF ($RemoveExisiting) {
		$GetExistingRules = Get-NetFirewallRule | Where-Object{
			$_.DisplayName -like "*solstice*"
		}
		IF ($GetExistingRules) {
			$GetExistingRules | ForEach-Object{
				Write-Log -Message "Found Existing Firewall Rule, Deleting: $($_.DisplayName) ($($_.Name))" -Severity 1 -Source $installPhase
				$_ | Remove-NetFirewallRule
			}
		}
	}
	#Create New Firewall Rules
	IF (Test-Path -Path $FilePath -PathType Leaf) {
		FOREACH ($Protocol IN $Protocols) {
			$NewFirewallRule = New-NetFirewallRule -DisplayName "$FirewallDisplayName" -Description "$FirewallRuleDescription" -Direction Inbound -Program "$FilePath" -Protocol $Protocol -Action Allow -EdgeTraversalPolicy DeferToUser -Enabled True
			IF ($NewFirewallRule) {
				Write-Log -Message "Created new $Protocol Firewall Rule: $FirewallDisplayName" -Severity 1 -Source $installPhase
			} ELSE {
				Write-Log -Message "Failed to create $FirewallDisplayName rule for protocol $Protocol." -Severity 2 -Source $installPhase
			}
		}
	} ELSE {
		Write-Log -Message "Could not create new firewall rule, target file for rule not found." -Severity 2 -Source $installPhase
	}
	#endregion Create FireWall Rules - Inbound
	
	"$env:USERPROFILE\AppData\Local\LogMeIn Rescue Applet"
}