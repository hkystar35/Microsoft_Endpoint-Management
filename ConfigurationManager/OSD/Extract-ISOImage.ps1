<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.152
	 Created on:   	6/5/2018 12:38 PM
	 Created by:   	Nhkystar35
	 Organization: 	contoso
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>





FUNCTION Extract-Image {
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateScript({
				(Test-Path $_ -PathType Leaf) -and ([System.IO.Path]::GetExtension($_) -eq '.iso')
			})][ValidateNotNullOrEmpty()][string]$ISOPath,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$FolderName
	)
	
	$ParentPath = Split-Path -Path $ISOPath -Parent
	$FileFullName = Split-Path -Path $ISOPath -Leaf
	$FileName = [System.IO.Path]::GetFileNameWithoutExtension($FileFullName)
	$WIMMountDir = Join-Path $ParentPath $FolderName | Join-Path -ChildPath 'WIM_Mount'
	$ISOExtractDir = Join-Path $ParentPath $FolderName | Join-Path -ChildPath 'FullExtract_Upgrades'
	$IndexName = 'Windows 10 Enterprise'
	$OutputImageDir = Join-Path $ParentPath $FolderName | Join-Path -ChildPath "Enterprise_Only"
	$DISMLogFile = "$ParentPath\DISM"
	
	# Create Folders
	$NewFolders = "$WIMMountDir", "$ISOExtractDir", "$OutputImageDir", "$DISMLogFile"
	$NewFolders | ForEach-Object{
		New-Item -Path $_ -ItemType Container -ErrorAction SilentlyContinue
	}
	
	TRY {
		IF ((Test-Path -Path "$ParentPath\7z.exe" -PathType Leaf) -and (Test-Path -Path "$ParentPath\7z.dll" -PathType Leaf)) {
			# Extract ISO to path from parameter
			$arguments = @("x", "`"$($ISOPath)`"", "-o`"$($ISOExtractDir)`"", "-y")
			$Extract = start-process -FilePath "$ParentPath\7z.exe" -ArgumentList $arguments -wait -PassThru
			
			# Get WIM info
			$WimPath = Get-ChildItem -Path $ISOExtractDir -Recurse -Filter 'install.wim' | Select-Object -ExpandProperty FullName
			
			$WIMInfo = Get-WindowsImage -ImagePath $WimPath -Name "$IndexName"
			[int32]$Index = $WIMInfo.ImageIndex
			[char[]]$invalidFileNameChars = [IO.Path]::GetInvalidFileNameChars()
			$ImageName = $WIMInfo.ImageName -replace "[$invalidFileNameChars]", '' -replace ' ', ''
			$WIMExport = Export-WindowsImage -SourceImagePath $WimPath -SourceIndex $Index -DestinationImagePath "$OutputImageDir\install.wim" -DestinationName "$ImageName" -LogPath "$DISMLogFile"
		}
	} CATCH {
		
	}
}

#Mount-Image -Path 'c:\Temp\10192159_15_600_600.jpg' -MountPath 'c:\Temp_Nic' -OutPath 'c:\Tools'
