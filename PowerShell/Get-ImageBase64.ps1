function Get-ImageBase64 {
    param (
        [System.IO.FileInfo]$ImagePath
    )
    #Use this to create a Base64 image string and copy it to the clipboard for pasting into the Base64 variables
    
    $Image = [System.Drawing.Image]::FromFile($ImagePath)
    $MemoryStream = New-Object System.IO.MemoryStream
    $Image.Save($MemoryStream, $Image.RawFormat)
    [System.Byte[]]$Bytes = $MemoryStream.ToArray()
    $Base64 = [System.Convert]::ToBase64String($Bytes)
    $Image.Dispose()
    $MemoryStream.Dispose()
    $Base64 | Set-Clipboard
    [string]$Base64
}