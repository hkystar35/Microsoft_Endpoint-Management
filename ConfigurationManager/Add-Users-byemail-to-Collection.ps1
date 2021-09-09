Param(            
    $SiteCode,                        
    $CollectionName,                        
    $Action,
    $FilePath
    )

function GetCMSiteConnection
{
  param ($siteCode)
  $CMModulePath = Join-Path -Path (Split-Path -Path "${Env:SMS_ADMIN_UI_PATH}" -ErrorAction Stop) -ChildPath "ConfigurationManager.psd1"
  Import-Module $CMModulePath -ErrorAction Stop
  $CMProvider = Get-PSDrive -PSProvider CMSite -Name $siteCode -ErrorAction Stop
  CD "$($CMProvider.SiteCode):\"
  $global:CMProvider = $CMProvider
  return $CMProvider
}

function GetCMSiteConnections
{
  $CMModulePath = Join-Path -Path (Split-Path -Path "${Env:SMS_ADMIN_UI_PATH}" -ErrorAction Stop) -ChildPath "ConfigurationManager.psd1"
  Import-Module $CMModulePath -ErrorAction Stop
  return (Get-PSDrive -PSProvider CMSite -ErrorAction Stop)
}

function GetMembersFromTxtFile
{
  param($filePath)
  $members = Get-Content $filePath -ErrorAction SilentlyContinue
  if (!($?))
  {
    Write-Host "Failed to read file, exiting:"$filePath -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    exit
  }
  $ht = @{}
  foreach ($member in $members) { $ht.Add($member.ToString().ToUpper(), $member.ToString()) }
  return $ht
}

function GetCollectionType
{
  param($collectionName)
  $collection = Get-CMDeviceCollection -Name $collectionName
  if ($collection) { $collectionType = 'DEVICE' }
  else 
  {
    $collection = Get-CMUserCollection -Name $collectionName
    if ($collection) { $collectionType = 'USER' }
    else { $collectionType = 'NEW'  }
  }
  return $collectionType
}

function GetCollections
{
  $a = @()
  $collections = Get-CMDeviceCollection
  foreach ($collection in $collections) { $a += $collection.Name.ToString() }
  $collections = Get-CMUserCollection
  foreach ($collection in $collections) { $a += $collection.Name.ToString() }
  return ($a | sort)
}

function GetMembersFromCollection
{
  param($collectionName, $collectionType)
  if ($collectionType -eq 'DEVICE') { $members = Get-CMDeviceCollection -Name $collectionName | select -ExpandProperty CollectionRules | where {$_.ResourceID -ne $null} | select RuleName }
  elseif ($collectionType -eq 'USER') { $members = Get-CMUserCollection -Name $collectionName | select -ExpandProperty CollectionRules | where {$_.ResourceID -ne $null} | select RuleName }
  else { Write-Host "Collection"$collectionName" does not exist" -ForegroundColor Red }
  $ht = @{}
  foreach ($member in $members) { $ht.Add($member.RuleName.ToString().ToUpper(), $member.RuleName.ToString()) }
  return $ht
}

function GetArrayOfMembersFromCollection
{
  param($collectionName)
  $a = @()
  $collectionType = GetCollectionType -collectionName $collectionName
  $ht = GetMembersFromCollection -collectionName $collectionName -collectionType $collectionType
  foreach ($h in $ht.GetEnumerator()) { $a += $h.Value }
  return ($a | sort)
}

function AddMembersToCollection
{
  param($collectionName, $collectionType, $existingMembers, $newMembers)
  Write-Host $newMembers.Count"members to add to collection"$collectionName
  
  #NEW 
  if ($collectionType -eq 'DEVICE') 
  { 
    $collectionId = Get-CMDeviceCollection -Name $collectionName | select -ExpandProperty CollectionID | select -first 1
  }
  else
  {
    $collectionId = Get-CMUserCollection -Name $collectionName | select -ExpandProperty CollectionID | select -first 1
  }
  
  $SccmServer = $global:CMProvider.Root 
  $SccmNamespace = "root\sms\site_$($global:CMProvider.Name)"
  $coll = [wmi]"\\$($SccmServer)\root\sms\site_$($global:CMProvider.Name):SMS_Collection.CollectionId='$collectionId'"
  $ruleClass = [WMICLASS]"\\$($SccmServer)\root\sms\site_$($global:CMProvider.Name):SMS_CollectionRuleDirect"   
  [array]$rules = $null
  #END NEW
  
  $count = 0
  foreach ($newMember in $newMembers.GetEnumerator())  
  {
    if ($existingMembers.ContainsKey($newMember.Key.ToString()))
    {
      Write-Host " "$newMember.Value.ToString()"already exists in collection, skipping" -ForegroundColor Yellow
      if ($UI) { UpdateUI -member $newMember.Value.ToString() -status " already exists in collection, skipping" }
    }
    else
    {
      if ($collectionType -eq 'DEVICE') 
      { 
        $resource = gwmi -ComputerName $SccmServer -Namespace $SccmNamespace -Class "SMS_R_System" -Filter "Name = '$($newMember.Value.ToString())'" | select name,resourceid
      }
      else 
      { 
        $resource = gwmi -ComputerName $SccmServer -Namespace $SccmNamespace -Class "SMS_R_User" -Filter "Mail = '$($newMember.Value.ToString())'" | select name,resourceid
      }
      if ($resource -ne $null)
      {
        if ($collectionType -eq 'DEVICE') 
        { 
            #NEW
            $newRule = $ruleClass.CreateInstance()     
            $newRule.RuleName = $($resource.name)
            $newRule.ResourceClassName = "SMS_R_System"       
            $newRule.ResourceID = $($resource.resourceid)
            $rules += $newRule
            #END NEW
        }
        else 
        { 
            #NEW
            $newRule = $ruleClass.CreateInstance()     
               $newRule.RuleName = $($resource.name)
            $newRule.ResourceClassName = "SMS_R_User"  
            $newRule.ResourceID = $($resource.resourceid)
            $rules += $newRule
            #END NEW
        }
        
        Write-Host " "$newMember.Value.ToString()"added to collection" -ForegroundColor Green
        if ($UI) { UpdateUI -member $newMember.Value.ToString() -status " added to collection" }
        $count++
      }
      else
      {
        Write-Host " "$newMember.Value.ToString()"was not found in SCCM, skipping" -ForegroundColor Red
        if ($UI) { UpdateUI -member $newMember.Value.ToString() -status " was not found in SCCM, skipping" }
      }
    }
  }
    
  #NEW
  If($rules.Count -gt 0)
  {
      #Add all the rules in the array    
      #See: http://msdn.microsoft.com/en-us/library/hh949023.aspx         
      $coll.AddMembershipRules($rules) | Out-Null

      #Refresh the collection
      $coll.requestrefresh()      | Out-Null
  }
  #END NEW

  Write-Host $count" new members added to collection "$collectionName
} 


function RemoveMembersFromCollection
{
  param($collectionName, $collectionType, $existingMembers, $oldMembers)
  Write-Host $oldMembers.Count"members to remove from collection"$collectionName
  $count = 0
  foreach ($oldMember in $oldMembers.GetEnumerator())
  {
    if (!($existingMembers.ContainsKey($oldMember.Key.ToString())))
    {
      Write-Host " "$oldMember.Value.ToString()"does not exist in collection, skipping" -ForegroundColor Yellow
      if ($UI) { UpdateUI -member $oldMember.Value.ToString() -status " does not exist in collection, skipping" }
    }
    else
    {
      if ($collectionType -eq 'DEVICE') { Remove-CMDeviceCollectionDirectMembershipRule -CollectionName $collectionName -ResourceName $oldMember.Value.ToString() -Force }
      else { Remove-CMUserCollectionDirectMembershipRule -CollectionName $collectionName -ResourceName $oldMember.Value.ToString() -Force }
      Write-Host " "$oldMember.Value.ToString()"removed from collection" -ForegroundColor Green
      if ($UI) { UpdateUI -member $oldMember.Value.ToString() -status " removed from collection" }
      $count++
    }
  }
  Write-Host $count" members removed from collection "$collectionName
}

function GetCollectionTypeFromMember
{
  param($newMember)
  $resource = Get-CMDevice -Name $newMember
  if ($resource) { $ret = 'DEVICE' }
  else
  {
    $resource = Get-CMUser -Name $newMember
    if ($resource) { $ret = 'USER' }
    else
    {
      Write-Host "Unable to find first member specified in txt file and there is no existing collection, exiting:"$newMember -ForegroundColor Red
      exit
    }
  }
  return $ret
}

function CreateNewCollection
{
  param($collectionName, $limitingCollectionName, $newMembers)
  foreach ($newMember in $newMembers.GetEnumerator()) { $member = $newMember.Value.ToString(); break }
  $collectionType = GetCollectionTypeFromMember -newMember $member
  if ($collectionType -eq 'DEVICE')
  {
    if ($limitingCollectionName -eq $null) { $limitingCollectionName = 'All Systems' }
    $coll = New-CMDeviceCollection -Name $collectionName -LimitingCollectionName $limitingCollectionName
    Write-Host "New Device Collection Created:"$collectionName -ForegroundColor Green
  }
  else
  {
    if ($limitingCollectionName -eq $null) { $limitingCollectionName = 'All Users' }
    $coll = New-CMUserCollection -Name $collectionName -LimitingCollectionName $limitingCollectionName
    Write-Host "New User Collection Created:"$collectionName -ForegroundColor Green
  }
}

function ConvertArrayToHashTable
{
  param($array)
  $ht = @{}
  foreach ($a in $array)
  { try { $ht.Add($a.ToString(), $a.ToString()) } catch {} }
  return $ht
}

function UpdateUI
{
  param($member, $status)
  $a = $global:CollectionMembersTextBox.Lines
  $i = $a.IndexOf($member)
  $newString = $member + $status
  $a[$i] = $newString
  $global:CollectionMembersTextBox.Lines = $a
}

#Main User Interface Function
function UIMain
{
  #Create UI objects
  $cMCollectionManagerForm = New-Object System.Windows.Forms.Form
  $newCollectionTextBox = New-Object System.Windows.Forms.TextBox
  $existingCollectionButton = New-Object System.Windows.Forms.RadioButton
  $newCollectionButton = New-Object System.Windows.Forms.RadioButton
  $startButton = New-Object System.Windows.Forms.Button
  $chooseSiteCodeComboBox = New-Object System.Windows.Forms.ComboBox
  $existingCollectionComboBox = New-Object System.Windows.Forms.ComboBox
  $chooseActionComboBox = New-Object System.Windows.Forms.ComboBox
  $limitingCollectionComboBox = New-Object System.Windows.Forms.ComboBox
  $panel1 = New-Object System.Windows.Forms.Panel
  $panel2 = New-Object System.Windows.Forms.Panel
  $siteCodeLabel = New-Object System.Windows.Forms.Label
  $limitingCollectionLabel = New-Object System.Windows.Forms.Label
  $actionLabel = New-Object System.Windows.Forms.Label
  $collectionMembersLabel = New-Object System.Windows.Forms.Label
  $initialFormWindowState = New-Object System.Windows.Forms.FormWindowState

  #Load Form
  $handler_cMCollectionManagerForm_Load= 
  {
    #Get site codes
    $chooseSiteCodeComboBox.Items.AddRange((GetCMSiteConnections))
  }

  #Site Code Selected
  $handler_chooseSiteCodeComboBox_SelectedIndexChanged=
  {
    #Change to correct drive
    CD "$($chooseSiteCodeComboBox.SelectedItem):\"

    $CMProvider = Get-PSDrive -PSProvider CMSite -Name $chooseSiteCodeComboBox.SelectedItem -ErrorAction Stop
    $global:CMProvider = $CMProvider

    #Enable actions
    $chooseActionComboBox.Enabled = $true
    $actionLabel.Enabled = $true
  }

  #Action Selected
  $handler_chooseActionComboBox_SelectedIndexChanged=
  {
    #Get Members
    if ($chooseActionComboBox.SelectedItem -eq "Get Direct Members")
    {
      $existingCollectionButton.Enabled = $true
      $existingCollectionButton.Checked = $true
      $existingCollectionComboBox.Enabled = $true
      $newCollectionButton.Enabled = $false
      $newCollectionTextBox.Enabled = $false
      $limitingCollectionLabel.Enabled = $false
      $limitingCollectionComboBox.Enabled = $false
      $global:CollectionMembersTextBox.Enabled = $false
      $collectionMembersLabel.Enabled = $false
    }

    #Add Members
    if ($chooseActionComboBox.SelectedItem -eq "Add Direct Members")
    {
      $existingCollectionButton.Enabled = $true
      $newCollectionButton.Enabled = $true
      $global:CollectionMembersTextBox.Enabled = $true
      $collectionMembersLabel.Enabled = $true
    }

    #Remove Members
    if ($chooseActionComboBox.SelectedItem -eq "Remove Direct Members")
    {
      $existingCollectionButton.Enabled = $true
      $existingCollectionButton.Checked = $true
      $existingCollectionComboBox.Enabled = $true
      $newCollectionButton.Enabled = $false
      $newCollectionTextBox.Enabled = $false
      $limitingCollectionLabel.Enabled = $false
      $limitingCollectionComboBox.Enabled = $false
      $global:CollectionMembersTextBox.Enabled = $true
      $collectionMembersLabel.Enabled = $true
    }
  }

  #Existing Collection Selected
  $handler_existingCollectionComboBox_SelectedIndexChanged=
  { 
    #Get Members
    if ($chooseActionComboBox.SelectedItem -eq "Get Direct Members")
    {
      $startButton.Enabled = $true
    }

    #Add Members
    if ($chooseActionComboBox.SelectedItem -eq "Add Direct Members")
    {
      $startButton.Enabled = $true
      $collectionMembersLabel.Visible = $true
      $global:CollectionMembersTextBox.Enabled = $true
    }

    #Remove Members
    if ($chooseActionComboBox.SelectedItem -eq "Remove Direct Members")
    {
      $startButton.Enabled = $true
      $collectionMembersLabel.Visible = $true
      $global:CollectionMembersTextBox.Enabled = $true
    }
  }

  #Existing Collection Button Selected
  $handler_existingCollectionButton_CheckedChanged= 
  {
    if ($existingCollectionButton.Checked)
    {
      $existingCollectionComboBox.Enabled = $true
      if ($existingCollectionComboBox.Items.Count -eq 0) { $existingCollectionComboBox.Items.AddRange((GetCollections)) }
    }
    else
    {
      $existingCollectionComboBox.Enabled = $false
    }
  }

  #New Collection Button Selected
  $handler_newCollectionButton_CheckedChanged= 
  {
    if ($newCollectionButton.Checked)
    {
      $newCollectionTextBox.Enabled = $true
      $limitingCollectionLabel.Enabled = $true
      $limitingCollectionComboBox.Enabled = $true
      $startButton.Enabled = $true
      $global:CollectionMembersTextBox.Enabled = $true
      if ($limitingCollectionComboBox.Items.Count -eq 0) { $limitingCollectionComboBox.Items.AddRange((GetCollections)) }
    }
    else
    {
      $newCollectionTextBox.Enabled = $false
      $limitingCollectionLabel.Enabled = $false
      $limitingCollectionComboBox.Enabled = $false
    }
  }

  $startButton_OnClick= 
  {
    #Get Members
    if ($chooseActionComboBox.SelectedItem -eq "Get Direct Members")
    {
      $global:CollectionMembersTextBox.Enabled = $true
      $global:CollectionMembersTextBox.Lines = GetArrayOfMembersFromCollection -collectionName $existingCollectionComboBox.SelectedItem
    }

    #Add Members
    if ($chooseActionComboBox.SelectedItem -eq "Add Direct Members")
    {
      if (($newCollectionTextBox.Text -ne $null) -and ($newCollectionButton.Checked))
      {
        CreateNewCollection -collectionName $newCollectionTextBox.Text -limitingCollectionName $limitingCollectionComboBox.Text -newMembers (ConvertArrayToHashTable -array $global:CollectionMembersTextBox.Lines)
        $collectionType = GetCollectionType -collectionName $newCollectionTextBox.Text
        AddMembersToCollection -collectionName $newCollectionTextBox.Text -collectionType $collectionType -existingMembers @{} -newMembers (ConvertArrayToHashTable -array $global:CollectionMembersTextBox.Lines)
      }
      elseif (($existingCollectionComboBox.SelectedItem -ne $null) -and ($existingCollectionButton.Checked))
      {
        $collectionType = GetCollectionType -collectionName $existingCollectionComboBox.SelectedItem
        $existingMembers = GetMembersFromCollection -collectionName $existingCollectionComboBox.SelectedItem -collectionType $collectionType
        AddMembersToCollection -collectionName $existingCollectionComboBox.SelectedItem -collectionType $collectionType -existingMembers $existingMembers -newMembers (ConvertArrayToHashTable -array $global:CollectionMembersTextBox.Lines)
      }
    }

    #Remove Members
    if ($chooseActionComboBox.SelectedItem -eq "Remove Direct Members")
    {
      if (($existingCollectionComboBox.SelectedItem -ne $null) -and ($existingCollectionButton.Checked))
      {
        $collectionType = GetCollectionType -collectionName $existingCollectionComboBox.SelectedItem
        $existingMembers = GetMembersFromCollection -collectionName $existingCollectionComboBox.SelectedItem -collectionType $collectionType
        RemoveMembersFromCollection -collectionName $existingCollectionComboBox.SelectedItem -collectionType $collectionType -existingMembers $existingMembers -oldMembers (ConvertArrayToHashTable -array $global:CollectionMembersTextBox.Lines)
      }
    }
  }

  $onLoadForm_StateCorrection=
  {
    #Correct the initial state of the form to prevent the .Net maximized form issue
    $cMCollectionManagerForm.WindowState = $initialFormWindowState
  }

  #Main Form Settings
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 741
  $system_Drawing_Size.Width = 691
  $cMCollectionManagerForm.ClientSize = $system_Drawing_Size
  $cMCollectionManagerForm.DataBindings.DefaultDataSourceUpdateMode = 0
  $cMCollectionManagerForm.Name = "CMCollectionManager"
  $cMCollectionManagerForm.Text = "SCCM 2012 Direct Membership Collection Manager"
  $cMCollectionManagerForm.add_Load($handler_cMCollectionManagerForm_Load)

  #Start Button
  $startButton.Enabled = $false
  $startButton.DataBindings.DefaultDataSourceUpdateMode = 0
  $startButton.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",12,0,3,1)
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 196
  $system_Drawing_Point.Y = 698
  $startButton.Location = $system_Drawing_Point
  $startButton.Name = "StartButton"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 31
  $system_Drawing_Size.Width = 298
  $startButton.Size = $system_Drawing_Size
  $startButton.TabIndex = 14
  $startButton.Text = "Start"
  $startButton.UseVisualStyleBackColor = $true
  $startButton.add_Click($startButton_OnClick)
  $cMCollectionManagerForm.Controls.Add($startButton)

  #Collection Members Label
  $collectionMembersLabel.Visible = $false
  $collectionMembersLabel.DataBindings.DefaultDataSourceUpdateMode = 0
  $collectionMembersLabel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",12,0,3,1)
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 196
  $system_Drawing_Point.Y = 242
  $collectionMembersLabel.Location = $system_Drawing_Point
  $collectionMembersLabel.Name = "CollectionMembersLabel"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 32
  $system_Drawing_Size.Width = 320
  $collectionMembersLabel.Size = $system_Drawing_Size
  $collectionMembersLabel.TabIndex = 13
  $collectionMembersLabel.Text = "Paste Collection Members Below"
  $cMCollectionManagerForm.Controls.Add($collectionMembersLabel)

  #Collection Members Text Box
  $global:CollectionMembersTextBox.Enabled = $false
  $global:CollectionMembersTextBox.DataBindings.DefaultDataSourceUpdateMode = 0
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 25
  $system_Drawing_Point.Y = 277
  $global:CollectionMembersTextBox.Location = $system_Drawing_Point
  $global:CollectionMembersTextBox.MaxLength = 200000
  $global:CollectionMembersTextBox.Multiline = $true
  $global:CollectionMembersTextBox.Name = "CollectionMembersTextBox"
  $global:CollectionMembersTextBox.ScrollBars = 2
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 397
  $system_Drawing_Size.Width = 638
  $global:CollectionMembersTextBox.Size = $system_Drawing_Size
  $global:CollectionMembersTextBox.TabIndex = 12
  $cMCollectionManagerForm.Controls.Add($global:CollectionMembersTextBox)

  #Choose Action Combo Box
  $chooseActionComboBox.Enabled = $false
  $chooseActionComboBox.DataBindings.DefaultDataSourceUpdateMode = 0
  $chooseActionComboBox.FormattingEnabled = $true
  $chooseActionComboBox.ItemHeight = 17
  $chooseActionComboBox.Items.Add("Get Direct Members")|Out-Null
  $chooseActionComboBox.Items.Add("Add Direct Members")|Out-Null
  $chooseActionComboBox.Items.Add("Remove Direct Members")|Out-Null
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 196
  $system_Drawing_Point.Y = 75
  $chooseActionComboBox.Location = $system_Drawing_Point
  $chooseActionComboBox.Name = "chooseAction"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 21
  $system_Drawing_Size.Width = 453
  $chooseActionComboBox.Size = $system_Drawing_Size
  $chooseActionComboBox.TabIndex = 8
  $chooseActionComboBox.add_SelectedIndexChanged($handler_chooseActionComboBox_SelectedIndexChanged)
  $cMCollectionManagerForm.Controls.Add($chooseActionComboBox)

  #Limiting Collection Combo Box
  $limitingCollectionComboBox.Enabled = $false
  $limitingCollectionComboBox.DataBindings.DefaultDataSourceUpdateMode = 0
  $limitingCollectionComboBox.FormattingEnabled = $true
  $limitingCollectionComboBox.ItemHeight = 17
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 196
  $system_Drawing_Point.Y = 197
  $limitingCollectionComboBox.Location = $system_Drawing_Point
  $limitingCollectionComboBox.Name = "LimitingCollectionComboBox"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 21
  $system_Drawing_Size.Width = 453
  $limitingCollectionComboBox.Size = $system_Drawing_Size
  $limitingCollectionComboBox.TabIndex = 7
  $cMCollectionManagerForm.Controls.Add($limitingCollectionComboBox)

  #New Collection Text Box
  $newCollectionTextBox.Enabled = $false
  $newCollectionTextBox.DataBindings.DefaultDataSourceUpdateMode = 0
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 196
  $system_Drawing_Point.Y = 168
  $newCollectionTextBox.Location = $system_Drawing_Point
  $newCollectionTextBox.Name = "NewCollectionTextBox"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 23
  $system_Drawing_Size.Width = 453
  $newCollectionTextBox.Size = $system_Drawing_Size
  $newCollectionTextBox.TabIndex = 6
  $newCollectionTextBox.Text = "<Enter Collection Name>"
  $cMCollectionManagerForm.Controls.Add($newCollectionTextBox)

  #Existing Collection Combo Box
  $existingCollectionComboBox.Enabled = $false
  $existingCollectionComboBox.DataBindings.DefaultDataSourceUpdateMode = 0
  $existingCollectionComboBox.FormattingEnabled = $true
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 196
  $system_Drawing_Point.Y = 138
  $existingCollectionComboBox.Location = $system_Drawing_Point
  $existingCollectionComboBox.Name = "CollectionBox"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 25
  $system_Drawing_Size.Width = 453
  $existingCollectionComboBox.Size = $system_Drawing_Size
  $existingCollectionComboBox.TabIndex = 5
  $existingCollectionComboBox.add_SelectedIndexChanged($handler_existingCollectionComboBox_SelectedIndexChanged)
  $cMCollectionManagerForm.Controls.Add($existingCollectionComboBox)

  #Existing Collection Button
  $existingCollectionButton.Enabled = $false
  $existingCollectionButton.DataBindings.DefaultDataSourceUpdateMode = 0
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 36
  $system_Drawing_Point.Y = 138
  $existingCollectionButton.Location = $system_Drawing_Point
  $existingCollectionButton.Name = "ExitingCollectionButton"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 24
  $system_Drawing_Size.Width = 142
  $existingCollectionButton.Size = $system_Drawing_Size
  $existingCollectionButton.TabIndex = 4
  $existingCollectionButton.TabStop = $true
  $existingCollectionButton.Text = "Existing Collection"
  $existingCollectionButton.UseVisualStyleBackColor = $true
  $existingCollectionButton.add_CheckedChanged($handler_existingCollectionButton_CheckedChanged)
  $cMCollectionManagerForm.Controls.Add($existingCollectionButton)

  #New Collection Button
  $newCollectionButton.Enabled = $false
  $newCollectionButton.DataBindings.DefaultDataSourceUpdateMode = 0
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 36
  $system_Drawing_Point.Y = 168
  $newCollectionButton.Location = $system_Drawing_Point
  $newCollectionButton.Name = "NewCollectionButton"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 24
  $system_Drawing_Size.Width = 142
  $newCollectionButton.Size = $system_Drawing_Size
  $newCollectionButton.TabIndex = 3
  $newCollectionButton.TabStop = $true
  $newCollectionButton.Text = "New Collection"
  $newCollectionButton.UseVisualStyleBackColor = $true
  $newCollectionButton.add_CheckedChanged($handler_newCollectionButton_CheckedChanged)
  $cMCollectionManagerForm.Controls.Add($newCollectionButton)

  #Choose Site Code List
  $chooseSiteCodeComboBox.DataBindings.DefaultDataSourceUpdateMode = 0
  $chooseSiteCodeComboBox.FormattingEnabled = $true
  $chooseSiteCodeComboBox.ItemHeight = 17
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 196
  $system_Drawing_Point.Y = 47
  $chooseSiteCodeComboBox.Location = $system_Drawing_Point
  $chooseSiteCodeComboBox.Name = "<Choose Site Code>"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 21
  $system_Drawing_Size.Width = 453
  $chooseSiteCodeComboBox.Size = $system_Drawing_Size
  $chooseSiteCodeComboBox.TabIndex = 1
  $chooseSiteCodeComboBox.add_SelectedIndexChanged($handler_chooseSiteCodeComboBox_SelectedIndexChanged)
  $cMCollectionManagerForm.Controls.Add($chooseSiteCodeComboBox)

  #Site Code Label
  $siteCodeLabel.DataBindings.DefaultDataSourceUpdateMode = 0
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 54
  $system_Drawing_Point.Y = 45
  $siteCodeLabel.Location = $system_Drawing_Point
  $siteCodeLabel.Name = "SiteCodeLabel"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 23
  $system_Drawing_Size.Width = 124
  $siteCodeLabel.Size = $system_Drawing_Size
  $siteCodeLabel.TabIndex = 0
  $siteCodeLabel.Text = "Choose Site Code"
  $cMCollectionManagerForm.Controls.Add($siteCodeLabel)

  #First Panel
  $panel1.DataBindings.DefaultDataSourceUpdateMode = 0
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 25
  $system_Drawing_Point.Y = 127
  $panel1.Location = $system_Drawing_Point
  $panel1.Name = "panel1"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 100
  $system_Drawing_Size.Width = 638
  $panel1.Size = $system_Drawing_Size
  $panel1.TabIndex = 10
  $cMCollectionManagerForm.Controls.Add($panel1)

  #Second Panel
  $panel2.DataBindings.DefaultDataSourceUpdateMode = 0
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 25
  $system_Drawing_Point.Y = 23
  $panel2.Location = $system_Drawing_Point
  $panel2.Name = "panel2"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 100
  $system_Drawing_Size.Width = 638
  $panel2.Size = $system_Drawing_Size
  $panel2.TabIndex = 11
  $cMCollectionManagerForm.Controls.Add($panel2)

  #Limiting Collection Label
  $limitingCollectionLabel.Enabled = $false
  $limitingCollectionLabel.DataBindings.DefaultDataSourceUpdateMode = 0
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 29
  $system_Drawing_Point.Y = 70
  $limitingCollectionLabel.Location = $system_Drawing_Point
  $limitingCollectionLabel.Name = "limitingCollectionLabel"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 23
  $system_Drawing_Size.Width = 124
  $limitingCollectionLabel.Size = $system_Drawing_Size
  $limitingCollectionLabel.TabIndex = 0
  $limitingCollectionLabel.Text = "Limiting Collection"
  $panel1.Controls.Add($limitingCollectionLabel)

  #Action Label
  $actionLabel.Enabled = $false
  $actionLabel.DataBindings.DefaultDataSourceUpdateMode = 0
  $system_Drawing_Point = New-Object System.Drawing.Point
  $system_Drawing_Point.X = 29
  $system_Drawing_Point.Y = 52
  $actionLabel.Location = $system_Drawing_Point
  $actionLabel.Name = "ActionLabel"
  $system_Drawing_Size = New-Object System.Drawing.Size
  $system_Drawing_Size.Height = 23
  $system_Drawing_Size.Width = 124
  $actionLabel.Size = $system_Drawing_Size
  $actionLabel.TabIndex = 9
  $actionLabel.Text = "Choose Action"
  $panel2.Controls.Add($actionLabel)

  #Save the initial state of the form
  $initialFormWindowState = $cMCollectionManagerForm.WindowState

  #Init the OnLoad event to correct the initial state of the form
  $cMCollectionManagerForm.add_Load($onLoadForm_StateCorrection)

  #Show the Form
  $cMCollectionManagerForm.ShowDialog()| Out-Null
}  

#Main Console Routine
function ConsoleMain
{
  param($siteCode, $collectionName, $action, $filePath)
  Write-Host "SCCM 2012 SP1 Collection Manager"
  Write-Host "Version 1.0"
  Write-Host "Parameters"
  Write-Host "  SiteCode: "$siteCode -ForegroundColor Green
  Write-Host "  CollectionName: "$collectionName -ForegroundColor Green
  Write-Host "  Action: "$action -ForegroundColor Green
  Write-Host "  FilePath: "$filePath -ForegroundColor Green

  #Connect to SCCM, must have SCCM Admin Console installed for this to work
  #If this fails then connect with the console to the site you want to use, then open PowerShell from that console
  $cm = GetCMSiteConnection -siteCode $siteCode
  Write-Host "Connected to:" $cm.SiteServer

  #Start processing
  switch ($action.ToUpper())
  {
    'GET'
    {
      $collectionType = GetCollectionType -collectionName $collectionName
      $existingMembers = GetMembersFromCollection -collectionName $collectionName -collectionType $collectionType
      foreach ($member in $existingMembers.GetEnumerator()) { Write-Host $member.Key }
    }
    'ADD'
    {
      $collectionType = GetCollectionType -collectionName $collectionName
      $newMembers = GetMembersFromTxtFile -filePath $filePath
      if ($collectionType -eq 'NEW')
      {
        CreateNewCollection -collectionName $collectionName -newMembers $newMembers
        $collectionType = GetCollectionType -collectionName $collectionName
      }
      $existingMembers = GetMembersFromCollection -collectionName $collectionName -collectionType $collectionType
      AddMembersToCollection -collectionName $collectionName -collectionType $collectionType -existingMembers $existingMembers -newMembers $newMembers 
    }
    'REMOVE'
    {
      $collectionType = GetCollectionType -collectionName $collectionName
      $existingMembers = GetMembersFromCollection -collectionName $collectionName -collectionType $collectionType
      $oldMembers = GetMembersFromTxtFile -filePath $filePath
      RemoveMembersFromCollection -collectionName $collectionName -collectionType $collectionType -existingMembers $existingMembers -oldMembers $oldMembers
    }
    default
    {
      Write-Host "Invalid Action, exiting:" $action
      exit
    }
  }
}

#Main

#Load modules needed for Windows Forms
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

#Set globals
$global:UI = $false
$global:CollectionMembersTextBox = New-Object System.Windows.Forms.TextBox
$global:CMProvider = $null

#Check for arguments, if none then display user interface
if (!($FilePath) -and (!($Action))) 
{ 
  $global:UI = $true
  UIMain 
}
else { ConsoleMain -siteCode $SiteCode -collectionName $CollectionName -action $Action -filePath $FilePath }