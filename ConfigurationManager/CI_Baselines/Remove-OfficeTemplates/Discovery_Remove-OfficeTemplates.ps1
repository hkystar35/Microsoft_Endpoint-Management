$FileCheckPath = "C:\Users\*\AppData\Roaming\Microsoft\Templates"
$SourceHashes = '',
				''

[psobject]$DestinationFiles = Get-ChildItem -Path "$FileCheckPath\*" -Recurse -ErrorAction SilentlyContinue | Select-Object FullName, @{L = "Hash"; E = {Get-FileHash -Path $_.Fullname -ErrorAction SilentlyContinue | Select-Object -ExpandProperty hash}}
$MatchCount = 0
FOREACH ($DestinationFile IN $DestinationFiles) {
		IF ($DestinationFile.Hash) {
			IF ($DestinationFile.Hash -in $SourceHashes) {
				$MatchCount++
			}
		}
}
$MatchCount
Remove-Variable SourceHashes,DestinationFiles,DestinationFile,MatchCount -ErrorAction SilentlyContinue