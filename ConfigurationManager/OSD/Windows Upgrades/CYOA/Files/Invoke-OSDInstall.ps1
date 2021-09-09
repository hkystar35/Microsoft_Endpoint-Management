FUNCTION Invoke-OSDInstall {
	PARAM
	(
		[Parameter(Mandatory = $true)][String]$OSDPackageID
	)
	
	TRY {
		$CIMClass = Get-CimClass -Namespace root\ccm\clientsdk -ClassName CCM_ProgramsManager
		$OSD = Get-CimInstance -ClassName CCM_Program -Namespace "root\ccm\clientSDK" | Where-Object {
			$_.PackageID -eq $OSDPackageID
		}
		$Args = @{
			PackageID	  = $OSD.PackageID
			ProgramID	  = $OSD.ProgramID
		}
		Invoke-CimMethod -CimClass $CIMClass -MethodName "ExecuteProgram" –Arguments $Args
		Write-Output $Error[0]
	} CATCH {
		Write-Output $Error[0]
	}
}
#endregion Invoke-OSDInstall
Invoke-OSDInstall -OSDPackageID PAY004F6