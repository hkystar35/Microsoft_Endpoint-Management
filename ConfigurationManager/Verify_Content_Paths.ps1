$Path = "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
Import-Module $Path
$SiteServer = "AH-SCCM-01"
$siteCode = "PAY"
CD $siteCode`:
$Applications = Get-CMApplication -Name "sql prompt"

$AppCount = $Applications.Count

Write-Host "$AppCount applications counted."
ForEach($Element in $Applications){
    $LocDispName = $Element.LocalizedDisplayName
    $PkgID = $Element.PackageID
    
    $XMLList = Get-WmiObject -ComputerName $SiteServer -Namespace root\sms\site_$siteCode -Class SMS_ConfigurationItemBaseClass | Where {$_.LocalizedDisplayName -eq $LocDispName}
        foreach ($Element in $XMLList){
        # Using the __PATH property, obtain a direct reference to the instance
        $Element = [wmi]"$($Element.__PATH)"
            foreach ($Data in $Element.SDMpackageXML){
            $xml = $null
            $xml = [xml]$Data
            $AppLocation = $xml.AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location
            Foreach($DTpath in $AppLocation){
            Write-Host "$LocDispName DT: $DTpath"
            }
<#            $TestLocation = $AppLocation
                CD c:
                $DTNames = Get-CMDeploymentType -ApplicationName $LocDispName | Select -ExpandProperty LocalizedDisplayName
                if(Test-Path -Path "$TestLocation"){
                    foreach($DTName in $DTNames){
                        Write-Host "Here: $DTName"
                    }
                        Write-Host "$LocDispName;$PkgID;$TestLocation;TRUE"
                }
                if(!(Test-Path -Path "$TestLocation")){
                    Write-Host "$LocDispName;$PkgID;$TestLocation;FALSE"
                }
                #>
                CD $siteCode`:
            }
        }
}
CD c: