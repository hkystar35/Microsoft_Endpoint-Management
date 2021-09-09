FUNCTION Get-ChromiumBrowserExtenstionInfo {
<#
	.SYNOPSIS
		Get information on installed browser extensions
	
	.DESCRIPTION
		Excludes non-extension items and anything considered 'built in', like search proivders for Google, Duckduckgo, etc.
		Supply profile path to search
	
	.PARAMETER UserProfileAppDataFolder
		User Profile folder path
	
	.EXAMPLE
		PS C:\> Get-ChromiumBrowserExtenstionInfo -UserProfileAppDataFolder c:\Users\first.last\AppData
	
	.NOTES
		Additional information about the function.
#>
	
	[OutputType([pscustomobject])]
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.IO.DirectoryInfo]$UserProfileAppDataFolder
	)
	
	TRY {
		
		# Verify Appdata path
		IF (Test-Path -Path $UserProfileAppDataFolder -PathType Container -and ($UserProfileAppDataFolder.FullName -match '\\Appdata')) {
			THROW "Folder is not an \AppData path"
		}
		
		$BrowserPaths_MicrosoftEdge = '\AppData\Local\Microsoft\Edge\User Data\', '\AppData\Local\Microsoft\Edge Deta\User Data\', '\AppData\Local\Microsoft\Edge Dev\User Data\'
		$BrowserPaths_GoogleChrome =  '\AppData\Local\Google\Chrome\User Data\', '\AppData\Local\Google\Chrome Beta\User Data\'
		
		$JsonManifests = Get-ChildItem -Path $UserProfileAppDataFolder.FullName\* -Filter Manifest.json -Recurse | Where-Object {$_.FullName -match '\\AppData\\Local\\'}
		$JsonContents = FOREACH ($jsonpath IN $jsonfilepaths) {
			switch ($jsonpath) {
				{$_ -match '\AppData\Local\Microsoft\Edge\User Data\'} { $BrowserName = 'Microsoft Edge' }
				{$_ -match '\AppData\Local\Microsoft\Edge Deta\User Data\'} { $BrowserName = 'Microsoft Edge' }
				{$_ -match '\AppData\Local\Microsoft\Edge Dev\User Data\'} { $BrowserName = 'Microsoft Edge' }
				{$_ -match '\AppData\Local\Google\Chrome\User Data\'} { $BrowserName = 'Microsoft Edge' }
				{$_ -match '\AppData\Local\Google\Chrome Beta\User Data\'} { $BrowserName = 'Microsoft Edge' }
				default { $BrowserName = 'Unknown' }
			}
			$content = Get-Content -Raw $jsonpath | ConvertFrom-Json
			$content | Add-Member -MemberType NoteProperty -Name BrowserName -Value $BrowserName
			$content | Add-Member -MemberType NoteProperty -Name ManifestPath -Value $jsonpath
			$content
		}
		
		$output = @(
			FOREACH ($addon IN ($json | Where-Object {$_.type -eq 'extension' -and $ExcludeLocations -notcontains $_.location})) {
				
				# Define Name
				IF (!$addon.Name -or $addon.Name -like "__*") {
					
					$ExtensionParentFolder = ([system.IO.FileInfo]$addon.ManifestPath | Select-Object -ExpandProperty Directory).Fullname
					$MessagesJsonFile = Get-ChildItem -Path $ExtensionParentFolder\_locales\en*\ -Filter Messages.json | Select-Object -First 1 -ExpandProperty Fullname
				}
				[PSCustomObject]@{
					BrowserName = $addon.BrowserName
					Name   = $extensionname
					Active = [bool]$addon.active
					FolderDate = $addon.installdate
					Counter = ''
					ManifestFolder = $addon.path
					ProfilePath = ($addon.path -split '\\appdata')[0]
					ScriptLastRan = ''
					Version = $addon.version
					PSComputerName = ''
				}
			}
		)
	}
	CATCH {
		$Line = $_.InvocationInfo.ScriptLineNumber
		$_
		$output = [pscustomobject]@{
			ErrorLine = $Line
			Errorfull = $_
		}
		#Write-Log "Error: $_" -Level Error
		#Write-Log "Error: on line $line" -Level Error
	}
	FINALLY {
		$output
	}
}