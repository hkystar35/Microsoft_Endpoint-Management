<#
		.Synopsis
		Short description
		.DESCRIPTION
		Long description
		.EXAMPLE
		Example of how to use this cmdlet
		.EXAMPLE
		Another example of how to use this cmdlet
#>

[CmdletBinding()]
param (
		# Param1 help description
		[Parameter(ValueFromPipelineByPropertyName,
		Position = 0)]
		[string]
		$MatchProperty = 'MifName',

		# Param1 help description
		[Parameter(ValueFromPipelineByPropertyName,
		Position = 1)]
		[string]
		$ModelName = (Get-WmiObject -Class win32_computersystemproduct -Namespace root\cimv2).Version,

		# Param2 help description
		[Parameter(ValueFromPipelineByPropertyName,
		Position = 2)]
		[string]
		$PackageXMLLibrary = ".\packages.xml",

		# Param3 help description
		[Parameter(ValueFromPipelineByPropertyName,
		Position = 3)]
		[ValidateSet("Windows 7 X64","Windows 7 X32","Windows 8 X32","Windows 8 X64","Windows 8.1 X64","Windows 8.1 X32","Windows 10 X64","Windows 10 X32","")]
		[string]
		$OSVersion = "",

		[switch]$PackageCheck
)
function Get-CMCEDynamicPackage
{
	[OutputType([string])]
	Param
	(
		# Param1 help description
		[Parameter(ValueFromPipelineByPropertyName,
		Position = 0)]
		[string]
		$MatchProperty = 'MifName',

		# Param1 help description
		[Parameter(ValueFromPipelineByPropertyName,
		Position = 1)]
		[string]
		$ModelName = (Get-WmiObject -Class win32_computersystemproduct -Namespace root\cimv2).Version,


		# Param2 help description
		[Parameter(ValueFromPipelineByPropertyName,
		Position = 2)]
		[string]
		$PackageXMLLibrary = ".\packages.xml",

				# Param3 help description
		[Parameter(ValueFromPipelineByPropertyName,
		Position = 3)]
		[ValidateSet("Windows 7 X64","Windows 7 X32","Windows 8 X32","Windows 8 X64","Windows 8.1 X64","Windows 8.1 X32","Windows 10 X64","Windows 10 X32","")]
		[string]
		$OSVersion = ""
	)
	Process
	{
		#interesting properties pkgsourcepath, Description, ISVData, ISVString, Manufacturer, MifFileName, MifName, MifPublisher, MIFVersion, Name, PackageID, ShareName, Version
		[xml]$Packages = Get-Content -Path $PackageXMLLibrary

		#environment variable call for task sequence only

		try
		{
			$tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
			$tsenvInitialized = $true
		}
		catch
		{
			Write-Host -Object 'Not executing in a tasksequence'
			$tsenvInitialized = $false
		}
		if ($OSVersion -eq "")
			{
				$PackageID = (Import-Clixml $PackageXMLLibrary | ? {$_.$MatchProperty.Split(',') -Contains "$ModelName"} | Sort-Object Version -Descending | Select-Object -First 1).PackageID
				$PackageID
					if ($tsenvInitialized)
					{
						$tsenv.Value('OSDDownloadDownloadPackages') = $PackageID
					}
			else
			{
				$PackageID = (Import-Clixml $PackageXMLLibrary | ? {$_.$MatchProperty.Split(',') -Contains "$ModelName" -and $_.MifVersion -eq $OSVersion} | Sort-Object Version -Descending | Select-Object -First 1).PackageID}
				$PackageID
					if ($tsenvInitialized)
					{
						$tsenv.Value('OSDDownloadDownloadPackages') = $PackageID
					}
			}
	}

}

Get-CMCEDynamicPackage -MatchProperty $MatchProperty -ModelName $ModelName -PackageXMLLibrary $PackageXMLLibrary

IF($PackageCheck){
	
}