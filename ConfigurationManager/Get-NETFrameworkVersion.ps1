[int]$RegKey = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | Get-ItemPropertyValue -Name Release

if($RegKey -ge 394802){
    Switch ($RegKey){
        378389 {$Version = '.NET Framework 4.5'}
        378675 {$Version = '.NET Framework 4.5.1 installed with Windows 8.1'}
        378758 {$Version = '.NET Framework 4.5.1 installed on Windows 8, Windows 7 SP1, or Windows Vista SP2'}
        379893 {$Version = '.NET Framework 4.5.2'}
        393295 {$Version = '.NET Framework 4.6 installed with Windows 10'}
        393297 {$Version = '.NET Framework 4.6 installed on all other Windows OS versions'}
        394254 {$Version = '.NET Framework 4.6.1 installed on Windows 10'}
        394271 {$Version = '.NET Framework 4.6.1 installed on all other Windows OS versions'}
        394802 {$Version = '.NET Framework 4.6.2 installed on Windows 10 Anniversary Update'}
        394806 {$Version = '.NET Framework 4.6.2 installed on all other Windows OS versions'}
        460798 {$Version = '.NET Framework 4.7 installed on Windows 10 Creators Update'}
        460805 {$Version = '.NET Framework 4.7 installed on all other Windows OS versions'}
        461308 {$Version = '.NET Framework 4.7.1 installed on Windows 10 Fall Creators Update'}
        461310 {$Version = '.NET Framework 4.7.1 installed on all other Windows OS versions'}
    }
}
$version