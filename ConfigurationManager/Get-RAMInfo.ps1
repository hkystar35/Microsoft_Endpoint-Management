$Computers = 'JPETERS1'
#$Computers = Get-CMDevice -CollectionName 'All Lenovo ThinkPad P51 (20HH) Workstations' | select -ExpandProperty Name
$RAMOutput = @()
foreach($Computer in $Computers){
    IF(Test-Connection -ComputerName $Computer -Count 1 -Quiet){
        $RAMOutput += Invoke-Command -ComputerName $Computer -ArgumentList $memoryBySlot -ScriptBlock {
        param($memoryBySlot)
            $memoryBySlot = Get-WmiObject -query "Select * from CIM_PhysicalMemory" | Foreach-Object { 
                [PSCustomObject] @{
                    CapacityGB = $_.Capacity /1GB
                    Manufacturer = $_.Manufacturer
                    Speed = $_.Speed
                    FormFactor = $_.FormFactor
                    PartNumber = $_.PartNumber
                    SMBIOSMemoryType = $_.SMBIOSMemoryType
                    TypeDetail = $_.TypeDetail
                    DeviceLocator = $_.DeviceLocator
                    ComputerName = $env:COMPUTERNAME
                }
              }
        $memoryBySlot
        }
    }ELSE{
        $memoryBySlot = [PSCustomObject] @{
            CapacityGB = ''
            Manufacturer = ''
            Speed = ''
            FormFactor = ''
            PartNumber = ''
            SMBIOSMemoryType = ''
            TypeDetail = ''
            DeviceLocator = ''
            ComputerName = $Computer
        }

    }
}
$RAMOutput | Sort-Object ComputerName,PSComputerName,DeviceLocator | Format-Table

