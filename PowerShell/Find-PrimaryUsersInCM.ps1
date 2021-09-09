$Users = Import-Csv -Path '.\users.csv'
$Domain = 'domain'

$ADUsers = Get-ADObject -Filter {samaccounttype -eq '805306368'} -Properties CanonicalName,userPrincipalName,sAMAccountName
$ADComputers = Get-ADObject -Filter {samaccounttype -eq '805306369'} -Properties CanonicalName,userPrincipalName,sAMAccountName
Set-Location -Path "$($SiteCode.Name):\"
$CMDevices = Get-CMDevice
Set-Location $HOME
$Table = @(
    foreach($User in $Users.Users){
        #$User = $Users[0] | Select-Object -ExpandProperty Users
        Switch($User){
            ($_ -match '[\w\d]\\[\w\d]'){
                                            $samaccountname = $_ -replace "$($Domain)\\",''
                                            $emailaddress = $ADUsers | Where-Object {$_.samaccountname -eq $samaccountname} | Select-Object -ExpandProperty UserPrincipalName
                                            $UserDistinguishedname = $ADUsers | Where-Object {$_.samaccountname -eq $samaccountname} | Select-Object -ExpandProperty CanonicalName
                                            $CMUserName = "$($Domain)\" + $samaccountname
                                            break
                                        }
            ($_ -match '(\w[\w\.]*@\w+\.[\w\.]+)\b'){
                                            $emailaddress = $_
                                            $samaccountname = $ADUsers | Where-Object {$_.UserPrincipalName -eq $emailaddress} | Select-Object -ExpandProperty samaccountname
                                            $UserDistinguishedname = $ADUsers | Where-Object {$_.UserPrincipalName -eq $emailaddress} | Select-Object -ExpandProperty CanonicalName
                                            $CMUserName = "$($Domain)\" + $samaccountname
                                            break
                                        }
            default{
                    $samaccountname = [string]($_ -replace "$($Domain)\\",'')
                    $emailaddress = $ADUsers | Where-Object {$_.samaccountname -eq $samaccountname} | Select-Object -ExpandProperty UserPrincipalName
                    $UserDistinguishedname = $ADUsers | Where-Object {$_.samaccountname -eq $samaccountname} | Select-Object -ExpandProperty CanonicalName
                    $CMUserName = "$($Domain)\" + $samaccountname
                    break
                    }
        }
        $CMDevice = $CMDevices | Where-Object {$_.PrimaryUser -contains $CMUserName} | Sort-Object LastActiveTime | Select-Object -Last 1
        $DeviceOU = $ADComputers | where {$_.name -eq $CMDevice.name} | select -ExpandProperty CanonicalName
        New-Object -TypeName pscustomobject -Property @{
            samaccountname = $samaccountname
            email = $emailaddress
            cmusername = $CMUserName
            userOU = $UserDistinguishedname
            CMPrimaryMachine = $CMDevice.Name
            machineOU = $DeviceOU
        }
        Remove-Variable emailaddress,CMUserName,UserDistinguishedname,CMDevice,DeviceOU
    }
)
$Table | ft -AutoSize