$CollectionName = "U.EUC.Test Applications.Analysts"

$Members = Get-CMCollectionMember -CollectionName $CollectionName | select Name

$Members | foreach{
    $Name = $_.Name
    Write-Host "Name: $Name"
    $ADInfo = Get-ADComputer -Identity $Name
    $ADDN = $ADInfo.DistinguishedName
    
    if ($ADDN -like '*OU=Disabled Computers*')
    {
        Write-Host "DISABLED"
    }
    elseif ($ADDN -like '*OU=GPO Testing,OU=IT Computers*')
    {
        Write-Host "Skipping, already in OU."
    }
    else {
        #Write-Host "DN= $ADDN"
        Write-Host "   Moving to GPO Testing OU..."
        $GetOU = Get-ADOrganizationalUnit -LDAPFilter "(name=GPO Testing)"
        Get-ADComputer $Name | Move-ADObject -TargetPath $GetOU.DistinguishedName

    }
}