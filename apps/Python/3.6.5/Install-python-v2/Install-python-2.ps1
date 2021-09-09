python -m pip install --upgrade pip
Start-Sleep -Seconds 15
refreshenv

pip install selenium
Start-Sleep -Seconds 15
pip install xlrd
Start-Sleep -Seconds 15
pip install openpyxl
Start-Sleep -Seconds 15
pip install beautifulsoup4
Start-Sleep -Seconds 15

$latestRelease = Invoke-restmethod -Method Get -Uri 'http://chromedriver.storage.googleapis.com/LATEST_RELEASE'
$url = "https://chromedriver.storage.googleapis.com/$latestRelease/chromedriver_win32.zip"
$output = "$home\chromdriver_win32.zip"
(New-Object System.Net.WebClient).DownloadFile($url, $output)
Start-Sleep -Seconds 15
#Expand-Archive -Path $output -DestinationPath C:\python36

Add-Type -assembly "system.io.compression.filesystem"

# Extracting the folder to the correct location
[io.compression.zipfile]::ExtractToDirectory($output, "C:\python36")