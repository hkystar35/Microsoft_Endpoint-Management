<#
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
#>

################################################################################
#.SYNOPSIS
#   Decline-WindowsItanium.ps1
#   A helper script function to identify Windows Itanium, IA64 and AMD64 updates
#      for declining in WSUS and expiring in ConfigMgr/SCCM
#.LINK
#   Reference Invoke-DGASoftwareUpdateMaintenance.ps1
#.NOTES
#   This script is invoked by Invoke-DGASoftwareUpdateMaintenance.ps1 and not run independently
#
#   ========== Keywords ==========
#   Keywords: WSUS SUP SCCM ConfigMgr Decline Expire Update Maintenance Superseded
#   ========== Change Log History ==========
#   - 2018/04/30 by Chad.Simmons@CatapultSystems.com - Created
#   - 2018/04/30 by Chad@ChadsTech.net - Created
#   === To Do / Proposed Changes ===
#   - TODO: None
################################################################################

Function Invoke-SelectUpdatesPlugin{
    $DeclineUpdates = @{}
    $WindowsItaniumUpdates = ($ActiveUpdates | Where-Object {($_.LegacyName -like '*-IA64-*' -or $_.ProductTitles -like '* Itanium*' -or $_.ProductTitles -like '* for IA64 *')})
    #Loop through the updates and decline any that match the version.
    ForEach ($Update in $WindowsItaniumUpdates) {
        $DeclineUpdates.Set_Item($Update.Id.UpdateId,"Windows Itanium")
    }
    Return $DeclineUpdates
}