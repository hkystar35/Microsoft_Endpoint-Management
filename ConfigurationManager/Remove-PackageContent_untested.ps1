TRY{
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
        $Line = $_.InvocationInfo.ScriptLineNumber
        "Error was in Line $line"
        Write-Output "Error: $_"
        Write-Output "Error: on line $line"
        BREAK
	}

$Search = Read-Host -Prompt 'Search term (wildcard already on end)'
#$Search = 'BIOS Update Retired'
$DPInfo = Get-CMDistributionStatus
$Packages = Get-CMPackage -Name "$($Search)*" | select -Property Name,PackageID,Version,PackageSize

$Packages | Sort-Object Name,PackageID,Version,PackageSize | Format-Table Name,PackageID,Version,@{Name="PackageSizeMB";Expression={[math]::Round($_.PackageSize/1024,1)}}#,@{Name="DPCount";Expression={($DPInfo | ?{$PSItem.PackageID -eq $_.PackageID}).count}} -AutoSize

$ConfirmRemove = Read-Host -Prompt "Continue to delete above package content? (y/n)"

IF($ConfirmRemove -eq 'y'){
[array]$DistributionPointGroups = Get-CMDistributionPointGroup | select -ExpandProperty Name


foreach($Package in $Packages){
    IF(($DPInfo | ?{$_.PackageID -eq $Package.PackageID}).count -gt 0){
    Write-Host "Removing $($Package.Name) $($Package.PackageID)..." -NoNewline
    $RemoveContent = Remove-CMContentDistribution -PackageId $Package.PackageID -DistributionPointGroupName $DistributionPointGroups -ErrorAction SilentlyContinue -Force
    Write-Host " done."
    }
    
}

}ELSE{Write-Output 'Bad answer'}


}CATCH{
    $Line = $_.InvocationInfo.ScriptLineNumber
    "Error was in Line $line"
    Write-Output "Error: $_"
    Write-Output "Error: on line $line"
}