function Invoke-OSDInstall
{
Param
(
[String][Parameter(Mandatory=$True, Position=1)] $Computername,
[String][Parameter(Mandatory=$True, Position=2)] $OSDName
 
)
try{
    Begin
    {
 
    $CIMClass = (Get-CimClass -Namespace root\ccm\clientsdk -ComputerName $Computername -ClassName CCM_ProgramsManager)
    $OSD = (Get-CimInstance -ClassName CCM_Program -Namespace "root\ccm\clientSDK" -ComputerName $Computername | Where-Object {$_.Name -like "$OSDName"})
 
    $Args = @{PackageID = $OSD.PackageID
    ProgramID = $OSD.ProgramID
    }
    }
 
    Process
    {
 
    Invoke-CimMethod -CimClass $CIMClass -ComputerName $Computername -MethodName "ExecuteProgram" –Arguments $Args
 
    }
    End {}
}
catch{
    Write-Output "Error"
}
}