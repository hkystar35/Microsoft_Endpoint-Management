<#
    .SYNOPSIS
    Inventory Chrome Extension Information 
    .DESCRIPTION
    Evaluates every extension in every user profile and saves the information to a custom WMI namespace. Steps:
    1. Add all extension messages found to the $ExtensionMessage array
    2. Check for the WMI Namespace and create it if its missing
    3. Check for the Chrome_Extensions WMI Class and delete and recreate if it already exists
    4. Find all user profiles on the system and loop through them looking for extensions
    5. Check if the Chrome extension folder exists for that user profile
    6. Find all extension folders in the current profile and loop through them
    7. Check to see if there is more than 1 manifest.json file in the extension folder and get the newest dated one - This can happen if Chrome has downloaded an update for an extension but the update is still pending a restart of the browser
    8. Look inside the manifest.json file and save what's after '"version":' and what's after '"Name":'
    9. If the display name contains a ':' split it once and join everything after the first split - LastPass is a good example that has a ':' in the display name
    10. If '"Name":' is like '"__*"' then look for a language specific name under the _locales folder
    A. Look for an 'en' or 'en_US' folder. If both exist, use 'en'
    B. Inside the messages.json file loop through the $ExtensionMessage options looking for a match and save the '"message"' value
    C. Once the message value is populated save the value and break the loop
    11. Save the data into the Chrome_Extensions WMI Class
    .EXAMPLE
    .\Set-ChromeExtensions.ps1
    .NOTES
    Filename:   Set-ChromeExtensions.ps1
    Author:     Zach Sattler
    Contact:    @zsattler
    Created:    1/27/17
    Updated:    1/27/17
    Version:    1.0.0
    Requirements:
    - Define $Namespace and $Class variables to match your environment
    - Must be run as an Administrator
#>

TRY{
  # Ignore All Errors
  $ErrorActionPreference = 'SilentlyContinue'

  # WMI Variables
  $Namespace = 'Browsers'
  $Class = 'Chrome_Extensions'

  # Extension Message
  $ExtensionMessage = @(
    'about_ext_name',
    'action_api',
    'app_name',
    'appFullName',
    'application_title',
    'appName',
    'app Name',
    'chrome_ext_short_name',
    'chrome_hangouts_short_name',
    'citrix_receiver',
    'DISPLAY_SERVICE_NAME',
    'extension_name',
    'extensionName',
    'ext_name',
    'extName',
    'ExtnName',
    'gaoptout_name',
    'gmailcheck_name',
    '4886126295094352182',
    '8969005060131950570',
    '"name":',
    'qs_name',
    'rss_subscription_name',
    'screenshotplugin_name',
    'NoteStationClipperSECTIONappKEYdisplayname',
    'themeName',
    'tv_name',
    'uwl_ext_chrome_name',
    'web2pdfExtnName',
    'web2pdfTitle',
    'webstore_pronghorn_product_name',
    'word_title'
  )

  # Function to create a Custom Namespace
  Function CreateNamespace{
    $rootNamespace = [wmiclass]'root:__namespace'
    $NewNamespace = $rootNamespace.CreateInstance()
    $NewNamespace.Name = $Namespace
    $NewNamespace.Put() | Out-Null
  }

  # Function to create the Chrome_Extensions Class
  Function CreateClass{
    $NewClass = New-Object System.Management.ManagementClass("root\$namespace", [string]::Empty, $null)
    $NewClass.name = $Class
    $NewClass.Qualifiers.Add("Static", $true)
    $NewClass.Properties.Add("Counter", [System.Management.CimType]::UInt32, $false)
    $NewClass.Qualifiers.Add("Description","Chrome_Extensions stores information on extensions add in Chrome.")
    $NewClass.Properties.Add("ProfilePath", [System.Management.CimType]::String, $false)
    $NewClass.Properties.Add("ManifestFolder", [System.Management.CimType]::String, $false)
    $NewClass.Properties.Add("FolderDate", [System.Management.CimType]::DateTime, $false)
    $NewClass.Properties.Add("Name", [System.Management.CimType]::String, $false)
    $NewClass.Properties.Add("Version", [System.Management.CimType]::String, $false)
    $NewClass.Properties.Add("ScriptLastRan", [System.Management.CimType]::String, $false)
    $NewClass.Properties["Counter"].Qualifiers.Add("Key", $true)
    $NewClass.Put() | Out-Null
  }

  # Function to get the extension name
  Function GetDisplayName{
    param($ENPath,$Name)
    $indx = Select-String "$Name" $ENPath | ForEach-Object {$_.LineNumber}
    If($indx -ne $null){
      If(($indx).count -gt 1){$indx = $indx[0]}
      $indxNextLine = (Get-Content $ENPath)[$indx]
      # Citrix Receiver extension messages.json file contains 'app_name' and 'citrix_receiver'. Skip 'app_name' if the next line is like '*content*'
      If($indxNextLine -like '*content*'){}
      Else{
        If($indxNextLine -like '*description*'){
          $indx = $indx + 1
          $indxNextLine = (Get-Content $ENPath)[$indx]
        }
        # If the display name contains a ':' split it once and join everything after the first split
        $charCount = ($indxNextLine.ToCharArray() | Where-Object {$_ -eq ':'} | Measure-Object).Count
        If($charCount -gt 1){
          $label,$Value = $indxNextLine.split(':').trim().trim([Char]0x002C).trim([Char]0x0022)
          $Value = $Value -join ': '
        }
        Else{$label,$Value = $indxNextLine.split(':').trim().trim([Char]0x002C).trim([Char]0x0022)}
        Return $label,$Value
      }
    }
    Else{}
  }

  # Check for WMI Namespace and create if missing
  $NSfilter = "Name = '$Namespace'"
  $NSExist = Get-WmiObject -Namespace root -Class __namespace -Filter $NSfilter
  If($NSExist -eq $null){CreateNamespace}
  # Check for WMI Class and recreate if it exists
  $ClassExist = Get-CimClass -Namespace root/$Namespace -ClassName $Class -ErrorAction SilentlyContinue
  If($ClassExist -eq $null){CreateClass}
  Else{
    Remove-WmiObject -Namespace root/$Namespace -Class $Class
    CreateClass
  }

  # Counter variable
  $j = 1
  # Find User Profiles
  $path = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*'
  $ProfilePath = Get-ItemProperty -Path $path | Select-Object -Property ProfileImagePath
  # Loop through each profile looking for extensions
  $ProfilePath | ForEach-Object{
    # See if extension folder exists
    If(Test-Path ($_.profileimagepath + "\appdata\local\google\chrome\user data\default\extensions")){
      $ChromeProfileFolder = Get-ChildItem ($_.profileimagepath + "\appdata\local\google\chrome\user data\default\extensions") | ? { $_.PSIsContainer}
      # Loop through each extension folder
      ForEach ($CPF in $ChromeProfileFolder){
        # Check to see if there is more than 1 manifest.json file
        If((Get-ChildItem -Path $cpf.fullName -Filter manifest.json -Recurse).Count -gt 1){
          $NewestFolder = Get-ChildItem -Path $cpf.fullname | sort LastWriteTime | select -last 1
          $FolderDate = Get-ChildItem -Path $NewestFolder.FullName | Select-Object -last 1 | ForEach-Object {($_.lastwritetime.tostring("yyyyMMddhhmmss"))+ '.000000-000'}
          $UserPath,$Leftovers = $NewestFolder.FullName -split('appdata')
          $ManifestFile = (Get-ChildItem -Path $NewestFolder.FullName -filter manifest.json -Recurse).FullName
          $ManifestFileFolder = (Get-ChildItem -Path $NewestFolder.FullName -Filter manifest.json -Recurse).DirectoryName
        }
        Else{
          $FolderDate = Get-ChildItem $cpf.fullname | Select-Object -Last 1 | ForEach-Object {($_.lastwritetime.tostring("yyyyMMddhhmmss"))+ '.000000-000'}
          $UserPath,$Leftovers = $cpf.fullname -split('appdata')
          $ManifestFile = (Get-ChildItem -Path $cpf.fullName -Filter manifest.json -Recurse).FullName
          $ManifestFileFolder = (Get-ChildItem -Path $cpf.fullName -Filter manifest.json -Recurse).DirectoryName
        }
        # Get Version Number
        $VersionNumber = (Get-Content $ManifestFile | Where-Object {$_ -like '*"version":*'}) | foreach{$VersionLabel,$Version = $_.split(':').trim().trim([Char]0x002C).trim([Char]0x0022)}
        # Get Extension Name
        $Name = (Get-Content $ManifestFile | Where-Object {$_ -like '*"name":*'})  | foreach{
          # If the display name contains a : split it once and join everything after the first split
          $charCount = ($_.ToCharArray() | Where-Object {$_ -eq ':'} | Measure-Object).Count
          If($charCount -gt 1){
            $NameLabel,$NameValue = $_.split(':').trim().trim([Char]0x002C).trim([Char]0x0022)
            $NameValue = $NameValue -join ': '
            $NameToRecord = $NameValue
          }
          Else{
            $NameLabel,$NameValue = $_.split(':').trim().trim([Char]0x002C).trim([Char]0x0022)
            $NameToRecord = $NameValue
          }
          # No name in manifest.json. Search in messages.json
          If($NameValue -like "__*"){
            Remove-Variable -Name EnglishMessages -Force
            Remove-Variable -Name EnglishMessages2 -Force
            Remove-Variable -Name ENPath -Force
            $EnglishMessages = (Get-ChildItem -Path ($ManifestFileFolder + "\_locales\en") -filter messages.json -Recurse).FullName
            $EnglishMessages2 = (Get-ChildItem -Path ($ManifestFileFolder + "\_locales\en_US") -filter messages.json -Recurse).FullName
            # If en and en_US both exist use en
            If($EnglishMessages -ne $null -and $EnglishMessages2 -ne $null){$EnglishMessages2 = $null}
            If($EnglishMessages2 -ne $null){$ENPath = $EnglishMessages2}
            Else{$ENPath = $EnglishMessages}
            # Loop through each ExtensionName looking for a match
            foreach($i in (0..((($ExtensionMessage).Count)-1))){
              Remove-Variable -Name label -Force
              Remove-Variable -Name NameToRecord -Force
              Remove-Variable -Name output -Force
              Remove-Variable -Name Value -Force
              # Call GetDisplayName Function
              $output = GetDisplayName $ENPath $ExtensionMessage[$i]
              # Fill in $NameToRecord if $Output is not empty
              If($output.count -eq 2){
                $label = $output[0]
                $Value = $output[1]
                If($label -eq "message"){$NameToRecord = $Value}
                Else{$NameToRecord = "Unknown"}
                # Break out of the foreach loop
                break
              }
            }
          }
          #  Save to WMI
          (Set-WmiInstance -Namespace root/$Namespace -Class $Class -Arguments @{
              Counter=$j;
              Name=$NameToRecord;
              ProfilePath=$Userpath;
              ManifestFolder=$ManifestFileFolder
              FolderDate=$FolderDate;
              Version=$Version;
          ScriptLastRan=Get-Date})
          $j=$j+1
        }
      }
    }
  }
  $output = 0
}CATCH{
  $output =1
}FINALLY{
  $output
}