$DriverPkgs = Get-CMDriverPackage
$Output = @()
foreach($DriverPkg in $DriverPkgs){
    $Drivers = $DriverPkg | Get-CMDriver | select -Property DriverClass
    $Output += New-Object -TypeName 'psobject' -Property @{
        DriverPackage   = $DriverPkg.Name
        Bluetooth       = ($Drivers | ?{$_.DriverClass -eq 'Bluetooth'}).count
        Display         = ($Drivers | ?{$_.DriverClass -eq 'Display'}).count
        Image           = ($Drivers | ?{$_.DriverClass -eq 'Image'}).count
        MEDIA           = ($Drivers | ?{$_.DriverClass -eq 'MEDIA'}).count
        Monitor         = ($Drivers | ?{$_.DriverClass -eq 'Monitor'}).count
        MTD             = ($Drivers | ?{$_.DriverClass -eq 'MTD'}).count
        Net             = ($Drivers | ?{$_.DriverClass -eq 'Net'}).count
        Ports           = ($Drivers | ?{$_.DriverClass -eq 'Ports'}).count
        SDHost          = ($Drivers | ?{$_.DriverClass -eq 'SDHost'}).count
        USB             = ($Drivers | ?{$_.DriverClass -eq 'USB'}).count
    
    }
    Clear-Variable Drivers,DriverPkg
}
#$Output | Sort-Object DriverPackage,Display,Bluetooth,Image,Monitor,Net,USB | Format-Table DriverPackage,Display,Bluetooth,Image,Monitor,Net,USB -AutoSize
#$Output | Export-Csv -Path $env:USERPROFILE\Downloads\drivers.csv -NoTypeInformation

$DriverCategories = Get-CMCategory -CategoryType DriverCategories



# Add-CMDriverToDriverPackage Lenovo-ThinkPad P52-Windows 10-201805