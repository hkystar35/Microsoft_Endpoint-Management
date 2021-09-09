$CopyCollections = 'Customer Service Computers;FREEZE;06',
'Development Computers;thawed;03',
'Distribution Computers;FREEZE;07',
'Finance Computers;FREEZE;05',
'HR Computers;FREEZE;08',
'Implementation Computers;FREEZE;05',
'InfoSec Computers;thawed;02',
'IT Comptuers;thawed;02',
'Learning Computers;thawed;04',
'Recruiting Computers;thawed;04',
'Sales Computers;thawed;04',
'Tax Computers;FREEZE;08',
'Tech Services Computers;FREEZE;07',
'Time and Labor Computers;FREEZE;08'
$CopyCollections | foreach{
  $Collection = $_ -split (';')
  $Name = 'WindowsUpdates_' + $($Collection[0])
  $Newname = 'WindowsUpdates_' + $($Collection[1]) + '_Group' + $($Collection[2]) + '_' + $($Collection[0])
  #Write-Host "Original Name: " $Name
  #Write-Host "     New Name: " $Newname
  Set-CMCollection -Name $Name -NewName $Newname #-WhatIf
  #Copy-CMCollection -Name $_ -NewName $Newname #-WhatIf
}