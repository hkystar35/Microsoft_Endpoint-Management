

$Path = 'OU=GPO Testing,OU=IT Computers,OU=IT,OU=Headquarters,DC=contoso,DC=com'

$Models = 't450s','t460s','t470s','w540','x1c','p51','x1y','x1c3'
$Models | foreach{
    $Name = 'Meltdown-' + $_
    New-ADComputer -Name $Name -Description "Meltdown Tester - Model $_" -Path "$Path" #-WhatIf
}
