function Get-VMWMisnamedVMs {
    param (
        $hyperVisorFQDN
    )
    Connect-VIServer -Server $hypervisorFQDN
    $VMs = Get-VM -Server $hyperVisorFQDN | Where-Object { -not [string]::IsNullOrEmpty($_.Guest.HostName) }
    $VMs | Where-Object { $_.Name -ne $($_.Guest.HostName.split('.')[0]) } | Select-Object -Property Name, @{L = "Guest.HostName"; E = { $_.Guest.HostName.split('.')[0] } }, @{L = "Configured OS"; E = { $_.ExtensionData.Config.GuestFullname } }, @{L = "Running OS"; E = { $_.Guest.OsFullName } }, @{L = "disktype"; E = { (Get-Harddisk $_).Storageformat } }
    Disconnect-VIServer -Server $hyperVisorFQDN -Confirm:$false -Force
}

$hyperVisors = @(
    'vc-ustwf-01.af.lan',
    'vc-nor-01.af.lan',
    'vc-soho-01.af.lan',
    'vc-au-01.af.lan'
)

$mismatchedVMs = @(
    $hyperVisors | foreach {
        Get-VMWMisnamedVMs -hyperVisorFQDN $_ | Select-Object -Property *, @{L = "vCenter"; E = { $_ } }
    }
)