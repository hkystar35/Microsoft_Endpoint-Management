# Download link for python 3.6.5
#https://www.python.org/ftp/python/3.6.5/python-3.6.5-amd64.exe

# Set Execution policy to RemoteSigned
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
# Download chocolatey ps1 file
$script = New-Object Net.WebClient
$script.DownloadString("https://chocolatey.org/install.ps1")
Start-Sleep -Seconds 10
# Install Choco cmds
Invoke-webrequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
Start-Sleep -Seconds 10
# Install python 3
choco install -y python -version 3.6.6
Start-Sleep -Seconds 20
refreshenv