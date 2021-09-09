#
#region Machines
$Machines = "JAREDWEINBERG",
"LAUREENMARK",
"AARONLIGA",
"TYLERLUDWIG",
"KATEGENTILE",
"AMBERMORGAN",
"KACYHANKINS",
"JOSHUAHAMILTON",
"TSAMPSONYOGA",
"WHITNEYOTT",
"JMASONSMITH",
"JEREMYHARRIS1",
"CAROLYNBOURG",
"LAURENNEWX1",
"COLINTRACY",
"CALEBBUCK",
"NIKKISOLTANIPOU",
"REBECCAMILLER",
"BRIANAVERY2",
"BRYCEROMNEY",
"ANITRAQUIRE",
"CMALYSONEW",
"CKREUSH2",
"SUZIFRANKS2",
"JULIEKANNAS",
"KARABUTTON2",
"LISABEAVERS",
"SUZANNEPOSTIGLI",
"MIKEJOHNSON",
"TEMP122017",
"NARESHPATEL",
"LOFGRENCLAY",
"SCOTTMERROW",
"JOELSANCHEZ2",
"KRISTINAGUARINO",
"ALLYAJLOUNY",
"ANDIARDOIN",
"ANDYWERTSCHNIG",
"BRADROBINSON",
"BRANDONBERRY",
"CAITLINCOOK",
"CHADCAUDILL",
"CHAISEBLATCHLEY",
"CHARLESGRAHAM8",
"CHRISHANNA",
"DANSWEENEY",
"DAVEHAMMER",
"DAVIDMALEY",
"DENISEFIGONE",
"DONMCKEW",
"DOUGENAS",
"HAMPTONCRUMP",
"IDNSS006",
"JOHNPALMER",
"KACIEEMERSON",
"KEVINASTURIAS",
"LEOORTEGA",
"AARONALSGAARD"
#endregion
#>
$PSTools = 'C:\Tools\pstools'
$ClientSource = '\\kirk\it\Software\SCCM\SCCM_Client\5.00.8540.1611'
$PS1FileName = 'ccmclient_5.00.8540.1611.ps1'

$Machines | foreach{
#$TestMachine | foreach{
    $result = Test-Connection -ComputerName $_ -Count 1 -Quiet -ErrorAction SilentlyContinue
    Write-Host $_ "is " $result
    if($result -eq 'true'){
        Write-Host 'Online'
        $Destination = "\\$_\c$\temp\CCMClient"
        Write-Host '  Enabling WinRM'
        Start-Process -FilePath "$PSTools\psexec.exe" -ArgumentList "-S -Accepteula \\$_ cmd /c winrm quickconfig -quiet" -Wait
        Write-Host '  Creating temp folder...'
        New-Item -Path "$Destination" -ItemType Directory -Force
        if(Test-Path -Path "$Destination" -PathType Container){
            if(!(Test-Path -Path $Destination\install.bat -PathType Leaf)){
                Write-Host '   Copying files...'
                Start-Process -FilePath "C:\Windows\SysWOW64\Robocopy.exe" -ArgumentList "`"$ClientSource`" `"$Destination`" *.* /MIR" -Wait
            }
            if(Test-Path -Path $Destination\install.bat -PathType Leaf){
                Write-Host '   Install.bat found, executing.'
                Write-Host '    Checking PS1 version...' -NoNewline
                $SourcePS1 = [datetime](Get-ItemProperty -Path $ClientSource\$PS1FileName -Name LastWriteTimeutc).lastwritetimeutc
                $DestinationPS1 = [datetime](Get-ItemProperty -Path $Destination\$PS1FileName -Name LastWriteTimeutc).lastwritetimeutc
                    if($SourcePS1 -eq $DestinationPS1){
                        Write-Host "up to date." -NoNewline
                    }
                    if($SourcePS1 -ne $DestinationPS1){
                        Write-Host "copying new file..." -NoNewline
                        Copy-Item -Path "$ClientSource\$PS1FileName" -Destination "$Destination\$PS1FileName" -Force
                        Write-Host "done." -NoNewline
                    }
                Start-Process -FilePath "$PSTools\psexec.exe" -ArgumentList "-S -Accepteula \\$_ C:\temp\CCMClient\install.bat" -Wait
            }
        }
    }
}