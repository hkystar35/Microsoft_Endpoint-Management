$devmachines = 'AARONCARLO',
'JWIEGERTWIN10',
'RAYMONDKRAUSE',
'SPENCERFLANDERS',
'RONALDRATZLAFF',
'AMALINICH',
'VADIMYUDKOVSKY',
'LARRYBEALL',
'CINDYGALL',
'JOHNPARCHEM',
'DAVIDBLISS',
'DANMADAY',
'AARONWALLIN',
'PAULMILLER10',
'DEVWIN10-4',
#'RUSSGROVER2',
'ADRIAANTTILA',
'STEVEHENKE',
'JIMKRUK2',
'JPETERS1',
'SCOTTBURLEIGH',
'KENMCGOWAN',
'DAVIDWIN10',
'TJCLAYTON',
'JOANNATIO',
'SCOTTDAYBERRY',
'MKOOSHAD10',
'LANCEDIDERICKSE',
'MICHAELHOLLACK1',
'WILLWIN10',
'SJACKSONNEW',
'BRANDONQ',
'DRONGEWIN10',
'JUSTINWEHR',
'ANDREWSCOTT',
'MIKEMOSER',
'SHANEBLAKE',
'ANTHONYCRIADO',
'sjacksonnew',
'SHANEBLAKE',
'ANTHONYCRIADO',
'MIKEMCCUE',
'GARTHFRANKEL2',
'WERNISEAN',
'CHRISPEELE1',
'TRAVISWATSON',
'DALTONDICK1',
'SERGEYVINOKUROV',
'ALPERSUNAR2',
'BILLHAYDEN',
'ADAMESTELA',
'KEVINKEMP',
'CHARLESGRAHAM2',
'BILLHAYDEN',
'BASILIOJOSE',
'STEVEGIAIMO2',
'CHRISHAMBLETON',
'ANDIESAIZAN',
'KCARBONE',
'devwin10-5',
'BRIANHARWELL',
'KCARBONE',
'BHNEW',
'SEANBIEFELD2',
'GORDANACEKICH10',
'JCOTEWIN10',
'JENNIFERCHAPUT',
'DEVWIN10-06',
'CM1030183',
'MICHAELBURNS2',
'PAULPWIN10',
'TIMWILSON'





$Mpaths = @()
$devmachines | %{
    #
    #$Move += Get-ADComputer 'SERGEYVINOKUROV' | Move-ADObject -TargetPath 'OU=GPO Test,OU=Development,OU=Headquarters,DC=paylocity,DC=com' -WhatIf
    $Paths = Get-ADComputer $_ | select Name,@{L="Path";E={$_.DistinguishedName -replace "CN=$($_.name),",""}}
    foreach($Path in $Paths){
        IF($Path.path -ne 'OU=GPO Test,OU=Development,OU=Headquarters,DC=paylocity,DC=com'){
            Write-Host "Current Path: " $Path.Path
            Get-ADComputer $Path.Name | Move-ADObject -TargetPath 'OU=GPO Test,OU=Development,OU=Headquarters,DC=paylocity,DC=com' #-WhatIf
            $NewPath = Get-ADComputer $Path.name | select Name,@{L="Path";E={$_.DistinguishedName -replace "CN=$($_.name),",""}}
            Write-Host "New Path:     " $NewPath.Path
            $Mpaths += $NewPath
        }ELSE{
            $Mpaths += $Path
        }
    }
    #>
    <#
    $test = Test-Connection -ComputerName $_ -Protocol WSMan -Count 1 -Quiet
    IF($test){
        Write-host "$_ online"
    }
    #>
}
