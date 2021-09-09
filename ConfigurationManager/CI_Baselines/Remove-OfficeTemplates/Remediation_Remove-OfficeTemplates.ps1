$FileCheckPath = "C:\Users\*\AppData\Roaming\Microsoft\Templates"
$SourceHashes = '',
				''

$DestinationFiles = Get-ChildItem -Path "$FileCheckPath\*" -Filter *.*otx -Recurse -ErrorAction SilentlyContinue | Select-Object FullName, @{L = "Hash"; E = {Get-FileHash -Path $_.Fullname -ErrorAction SilentlyContinue | Select-Object -ExpandProperty hash}}
$MatchCount = 0
$FailCount = 0
FOREACH ($DestinationFile IN $DestinationFiles) {
	TRY {
		IF ($DestinationFile.Hash) {
			IF ($DestinationFile.Hash -in $SourceHashes) {
				$MatchCount++
				Remove-Item -Path $DestinationFile.FullName -Force -ErrorAction SilentlyContinue
			}
		} ELSE {
			$FailCount++
		}
	} CATCH {
		$FailCount++
	}
}

# Parse counts
$Difference = $MatchCount - $FailCount
IF($FailCount -gt 0){
	$FailCount
}ELSEIF($Difference -ne $MatchCount){
	$Difference
}ELSE{
	0
}
Remove-Variable MatchCount,FailCount,Difference,DestinationFiles,DestinationFile,SourceHashes -ErrorAction SilentlyContinue
