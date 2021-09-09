$machines = 'NICWENDLOWSKY','CLINTSMITH','DANMADAY','AustinWimberly2','LGullett','JPalmer','ATurner'
$ADTable = @()

$machines | foreach{
    $Name = Get-ADComputer $_ -Properties *
    $ADTable += [PSCustomObject] @{
        Name = $Name.Name
        Enabled = $Name.Enabled 
        CreatedDate = $Name.whencreated 
        DN = $Name.DistinguishedName
    }
     
}

$ADTable | Format-Table -AutoSize
#| Export-Csv -Path C:\temp\cybertron.csv