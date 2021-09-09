$DPs = 'FL-SCCM-DP-01.PAYLOCITY.COM',
	'ID-SCCM-DP-03.PAYLOCITY.COM',
	'IL-SCCM-DP-01.PAYLOCITY.COM',
	'INT-IBCM-MP-01.PAYLOCITY.COM',
	'INT-SCCM-DP-01.PAYLOCITY.COM'

foreach($DP in $DPs){
    Invoke-Command -ComputerName $DP -ScriptBlock {$WMIPkgList = Get-WmiObject -Namespace Root\SCCMDP -Class SMS_PackagesInContLib | Select -ExpandProperty PackageID | Sort-Object
        $ContentLib = (Get-ItemProperty -path HKLM:SOFTWARE\Microsoft\SMS\DP -Name ContentLibraryPath)
        $PkgLibPath = ($ContentLib.ContentLibraryPath) + "\PkgLib"
        $PkgLibList = (Get-ChildItem $PkgLibPath | Select -ExpandProperty Name | Sort-Object)
        $PkgLibList = ($PKgLibList | ForEach-Object {$_.replace(".INI","")})
        $PksinWMIButNotContentLib = Compare-Object -ReferenceObject $WMIPkgList -DifferenceObject $PKgLibList -PassThru | Where-Object { $_.SideIndicator -eq "&lt;=" }
        $PksinContentLibButNotWMI = Compare-Object -ReferenceObject $WMIPkgList -DifferenceObject $PKgLibList -PassThru | Where-Object { $_.SideIndicator -eq "=&gt;" }
        Write-Host "$env:COMPUTERNAME`nDelete these items from WMI:"
        $PksinWMIButNotContentLib
        Write-Host "$env:COMPUTERNAME`nDelete .INI files of these packages from the PkgLib folder:"
        $PksinContentLibButNotWMI
    }
}