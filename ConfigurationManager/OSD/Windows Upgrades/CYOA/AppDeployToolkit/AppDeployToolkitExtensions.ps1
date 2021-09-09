<#
.SYNOPSIS
	This script is a template that allows you to extend the toolkit with your own custom functions.
.DESCRIPTION
	The script is automatically dot-sourced by the AppDeployToolkitMain.ps1 script.
.NOTES
    Toolkit Exit Code Ranges:
    60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
    69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
    70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
PARAM (
)

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

# Variables: Script
[string]$appDeployToolkitExtName = 'PSAppDeployToolkitExt'
[string]$appDeployExtScriptFriendlyName = 'App Deploy Toolkit Extensions'
[version]$appDeployExtScriptVersion = [version]'1.5.0'
[string]$appDeployExtScriptDate = '02/12/2017'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters

##*===============================================
##* FUNCTION LISTINGS
##*===============================================

# <Your custom functions go here>
#region Remove-DesktopShortcut
FUNCTION Remove-DesktopShortcut {
<#
	.SYNOPSIS
		Removes Desktop Shortcuts - requires PSADT toolkit functions
	.DESCRIPTION
		Specify file name, without file extension, to delete Desktop Shortcuts that applications create during install. Support wildcards
	.PARAMETER Name
		File name without file extension
	.PARAMETER UseWildCard
		A description of the UseWildCard parameter.
	.EXAMPLE
		PS C:\> Remove-DesktopShortcut -Name 'Value1'
	.NOTES
		Additional information about the function.
#>
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true,
				   Position = 1)][SupportsWildcards()][ValidateNotNullOrEmpty()][Alias('N')][string]$Name,
		[Parameter(Position = 2)][Alias('WC')][switch]$UseWildCard = $false
	)
	SWITCH ($UseWildCard) {
		true {
			$FileName = $Name + '.lnk'
		}
		false {
			$FileName = $Name + '*' + '.lnk'
		}
	}
	TRY {
		$Paths = "$envCommonDesktop", "$envUserDesktop"
		$Paths | ForEach-Object{
			IF (!(Test-Path -Path $_\$FileName)) {
				Write-Log -Message "$FileName doesn't exist, nothing to remove." -severity 1 -Source ${CmdletName}
			} ELSEIF (Test-Path -Path $_\$FileName) {
				Remove-File -Path $_\$FileName
			}
		}
		Refresh-Desktop
	} CATCH {
		Write-Log -Message "Unable to remove $FileName or syntax error." -severity 3 -Source ${CmdletName}
	}
}
#endregion Remove-DesktopShortcut

#region Show-CYOA_Form_psf
FUNCTION Show-CYOA_Form_psf {
	
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$FullName,
		[ValidateNotNullOrEmpty()][datetime]$DeadlineDate
	)
	
	#----------------------------------------------
	#region Import the Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load('System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
	[void][reflection.assembly]::Load('System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
	#endregion Import Assemblies
	
	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$formWindows10Upgrade = New-Object 'System.Windows.Forms.Form'
	$combobox2 = New-Object 'System.Windows.Forms.ComboBox'
	$combobox1 = New-Object 'System.Windows.Forms.ComboBox'
	$textbox6 = New-Object 'System.Windows.Forms.TextBox'
	$textbox5 = New-Object 'System.Windows.Forms.TextBox'
	$textbox4 = New-Object 'System.Windows.Forms.TextBox'
	$buttonReschedule = New-Object 'System.Windows.Forms.Button'
	$buttonLetsDoThis = New-Object 'System.Windows.Forms.Button'
	$datetimepicker1 = New-Object 'System.Windows.Forms.DateTimePicker'
	$checkbox5 = New-Object 'System.Windows.Forms.CheckBox'
	$checkbox4 = New-Object 'System.Windows.Forms.CheckBox'
	$checkbox3 = New-Object 'System.Windows.Forms.CheckBox'
	$checkbox2 = New-Object 'System.Windows.Forms.CheckBox'
	$checkbox1 = New-Object 'System.Windows.Forms.CheckBox'
	$textbox3 = New-Object 'System.Windows.Forms.TextBox'
	$textbox2 = New-Object 'System.Windows.Forms.TextBox'
	$buttonNotNow = New-Object 'System.Windows.Forms.Button'
	$buttonYes = New-Object 'System.Windows.Forms.Button'
	$textbox1 = New-Object 'System.Windows.Forms.TextBox'
	$picturebox1 = New-Object 'System.Windows.Forms.PictureBox'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	#endregion Generated Form Objects
	
	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$formWindows10Upgrade_Load = {
		#TODO: Initialize Form Controls here
		
	}
	
	#region Control Helper Functions
	FUNCTION Update-ComboBox {
    <#
        .SYNOPSIS
        This functions helps you load items into a ComboBox.
		
        .DESCRIPTION
        Use this function to dynamically load items into the ComboBox control.
		
        .PARAMETER ComboBox
        The ComboBox control you want to add items to.
		
        .PARAMETER Items
        The object or objects you wish to load into the ComboBox's Items collection.
		
        .PARAMETER DisplayMember
        Indicates the property to display for the items in this control.
		
        .PARAMETER Append
        Adds the item(s) to the ComboBox without clearing the Items collection.
		
        .EXAMPLE
        Update-ComboBox $combobox1 "Red", "White", "Blue"
		
        .EXAMPLE
        Update-ComboBox $combobox1 "Red" -Append
        Update-ComboBox $combobox1 "White" -Append
        Update-ComboBox $combobox1 "Blue" -Append
		
        .EXAMPLE
        Update-ComboBox $combobox1 (Get-Process) "ProcessName"
		
        .NOTES
        Additional information about the function.
    #>
		
		PARAM
		(
			[Parameter(Mandatory = $true)][ValidateNotNull()][System.Windows.Forms.ComboBox]$ComboBox,
			[Parameter(Mandatory = $true)][ValidateNotNull()]$Items,
			[Parameter(Mandatory = $false)][string]$DisplayMember,
			[switch]$Append
		)
		
		IF (-not $Append) {
			$ComboBox.Items.Clear()
		}
		
		IF ($Items -is [Object[]]) {
			$ComboBox.Items.AddRange($Items)
		} ELSEIF ($Items -is [System.Collections.IEnumerable]) {
			$ComboBox.BeginUpdate()
			FOREACH ($obj IN $Items) {
				$ComboBox.Items.Add($obj)
			}
			$ComboBox.EndUpdate()
		} ELSE {
			$ComboBox.Items.Add($Items)
		}
		
		$ComboBox.DisplayMember = $DisplayMember
	}
	
	FUNCTION Update-ListBox {
    <#
        .SYNOPSIS
        This functions helps you load items into a ListBox or CheckedListBox.
		
        .DESCRIPTION
        Use this function to dynamically load items into the ListBox control.
		
        .PARAMETER ListBox
        The ListBox control you want to add items to.
		
        .PARAMETER Items
        The object or objects you wish to load into the ListBox's Items collection.
		
        .PARAMETER DisplayMember
        Indicates the property to display for the items in this control.
		
        .PARAMETER Append
        Adds the item(s) to the ListBox without clearing the Items collection.
		
        .EXAMPLE
        Update-ListBox $ListBox1 "Red", "White", "Blue"
		
        .EXAMPLE
        Update-ListBox $listBox1 "Red" -Append
        Update-ListBox $listBox1 "White" -Append
        Update-ListBox $listBox1 "Blue" -Append
		
        .EXAMPLE
        Update-ListBox $listBox1 (Get-Process) "ProcessName"
		
        .NOTES
        Additional information about the function.
    #>
		
		PARAM
		(
			[Parameter(Mandatory = $true)][ValidateNotNull()][System.Windows.Forms.ListBox]$ListBox,
			[Parameter(Mandatory = $true)][ValidateNotNull()]$Items,
			[Parameter(Mandatory = $false)][string]$DisplayMember,
			[switch]$Append
		)
		
		IF (-not $Append) {
			$listBox.Items.Clear()
		}
		
		IF ($Items -is [System.Windows.Forms.ListBox+ObjectCollection]) {
			$listBox.Items.AddRange($Items)
		} ELSEIF ($Items -is [Array]) {
			$listBox.BeginUpdate()
			FOREACH ($obj IN $Items) {
				$listBox.Items.Add($obj)
			}
			$listBox.EndUpdate()
		} ELSE {
			$listBox.Items.Add($Items)
		}
		
		$listBox.DisplayMember = $DisplayMember
	}
	#endregion
	
	$Output = New-Object -TypeName PSObject
	$Properties = @{
		'UpgradeNow'   = ''; 'DeferDate' = ''; 'UpgradeDate' = ''
	}
	$Output | Add-Member -NotePropertyMembers $Properties
	
	$buttonYes_Click = {
		#Enable Left side
		$textbox2.Enabled = $True
		$checkbox1.Enabled = $True
		$checkbox2.Enabled = $True
		$checkbox3.Enabled = $True
		$checkbox4.Enabled = $True
		$checkbox5.Enabled = $True
		$textbox2.Visible = $True
		$checkbox1.Visible = $True
		$checkbox2.Visible = $True
		$checkbox3.Visible = $True
		$checkbox4.Visible = $True
		$checkbox5.Visible = $True
		$buttonLetsDoThis.Visible = $true
		#Disable right side
		$textbox3.Enabled = $False
		$textbox4.Enabled = $False
		$textbox5.Enabled = $False
		$textbox6.Enabled = $False
		$datetimepicker1.Enabled = $False
		$buttonReschedule.Enabled = $False
		$combobox1.Enabled = $false
		$combobox2.Enabled = $false
		$textbox3.Visible = $False
		$textbox4.Visible = $False
		$textbox5.Visible = $False
		$textbox6.Visible = $False
		$datetimepicker1.Visible = $False
		$buttonReschedule.Visible = $False
		$combobox1.Visible = $false
		$combobox2.Visible = $false
		$combobox1.Items.Clear
		$combobox2.Items.Clear
	}
	
	$buttonNotNow_Click = {
		#Disable Left side
		$textbox2.Enabled = $False
		$checkbox1.Enabled = $False
		$checkbox2.Enabled = $False
		$checkbox3.Enabled = $False
		$checkbox4.Enabled = $False
		$checkbox5.Enabled = $False
		$textbox2.Visible = $False
		$checkbox1.Visible = $False
		$checkbox2.Visible = $False
		$checkbox3.Visible = $False
		$checkbox4.Visible = $False
		$checkbox5.Visible = $False
		$buttonLetsDoThis.Visible = $False
		$buttonLetsDoThis.Enabled = $False
		#Uncheck boxes on Left
		$checkbox1.Checked = $false
		$checkbox2.Checked = $false
		$checkbox3.Checked = $false
		$checkbox4.Checked = $false
		$checkbox5.Checked = $false
		#Enable Right side
		$textbox3.Enabled = $True
		$textbox4.Enabled = $True
		$textbox5.Enabled = $True
		$textbox6.Enabled = $True
		$datetimepicker1.Enabled = $true
		$buttonReschedule.Enabled = $false
		$combobox1.Enabled = $true
		$combobox2.Enabled = $true
		#Make Visible
		$textbox3.Visible = $true
		$textbox4.Visible = $true
		$textbox5.Visible = $true
		$textbox6.Visible = $true
		$datetimepicker1.Visible = $true
		$buttonReschedule.Visible = $True
		$combobox1.Visible = $true
		$combobox2.Visible = $true
	}
	
	$checkboxesALL_CheckedChanged = {
		IF ($checkbox1.Checked -and $checkbox2.Checked -and $checkbox3.Checked -and $checkbox4.Checked -and $checkbox5.Checked) {
			$buttonLetsDoThis.Visible = $True
			$buttonLetsDoThis.Enabled = $True
		} ELSE {
			$buttonLetsDoThis.Enabled = $False
			$buttonLetsDoThis.Visible = $True
		}
	}
	
	$comboboxesALL_SelectedIndexChanged = {
		IF ($combobox1.Text.Length -gt '0' -and $combobox2.Text.Length -gt '0') {
			$buttonReschedule.Enabled = $true
			$buttonReschedule.Visible = $true
		}
		
	}
	
	# --End User Generated Script--
	#----------------------------------------------
	#region Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load =
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$formWindows10Upgrade.WindowState = $InitialFormWindowState
	}
	
	$Form_Cleanup_FormClosed =
	{
		#Remove all event handlers from the controls
		TRY {
			$combobox2.remove_SelectedValueChanged($comboboxesALL_SelectedIndexChanged)
			$combobox1.remove_SelectedValueChanged($comboboxesALL_SelectedIndexChanged)
			$checkbox5.remove_CheckedChanged($checkboxesALL_CheckedChanged)
			$checkbox4.remove_CheckedChanged($checkboxesALL_CheckedChanged)
			$checkbox3.remove_CheckedChanged($checkboxesALL_CheckedChanged)
			$checkbox2.remove_CheckedChanged($checkboxesALL_CheckedChanged)
			$checkbox1.remove_CheckedChanged($checkboxesALL_CheckedChanged)
			$buttonNotNow.remove_Click($buttonNotNow_Click)
			$buttonNotNow.remove_ControlAdded($buttonNotNow_Click)
			$buttonNotNow.remove_MouseClick($buttonNotNow_Click)
			$buttonYes.remove_Click($buttonYes_Click)
			$buttonYes.remove_ControlAdded($buttonYes_Click)
			$buttonYes.remove_MouseClick($buttonYes_Click)
			$formWindows10Upgrade.remove_Load($formWindows10Upgrade_Load)
			$formWindows10Upgrade.remove_Load($Form_StateCorrection_Load)
			$formWindows10Upgrade.remove_FormClosed($Form_Cleanup_FormClosed)
		} CATCH {
			Out-Null <# Prevent PSScriptAnalyzer warning #>
		}
	}
	#endregion Generated Events
	
	#----------------------------------------------
	#region Generated Form Code
	#----------------------------------------------
	$formWindows10Upgrade.SuspendLayout()
	#
	# formWindows10Upgrade
	#
	$formWindows10Upgrade.Controls.Add($combobox2)
	$formWindows10Upgrade.Controls.Add($combobox1)
	$formWindows10Upgrade.Controls.Add($textbox6)
	$formWindows10Upgrade.Controls.Add($textbox5)
	$formWindows10Upgrade.Controls.Add($textbox4)
	$formWindows10Upgrade.Controls.Add($buttonReschedule)
	$formWindows10Upgrade.Controls.Add($buttonLetsDoThis)
	$formWindows10Upgrade.Controls.Add($datetimepicker1)
	$formWindows10Upgrade.Controls.Add($checkbox5)
	$formWindows10Upgrade.Controls.Add($checkbox4)
	$formWindows10Upgrade.Controls.Add($checkbox3)
	$formWindows10Upgrade.Controls.Add($checkbox2)
	$formWindows10Upgrade.Controls.Add($checkbox1)
	$formWindows10Upgrade.Controls.Add($textbox3)
	$formWindows10Upgrade.Controls.Add($textbox2)
	$formWindows10Upgrade.Controls.Add($buttonNotNow)
	$formWindows10Upgrade.Controls.Add($buttonYes)
	$formWindows10Upgrade.Controls.Add($textbox1)
	$formWindows10Upgrade.Controls.Add($picturebox1)
	$formWindows10Upgrade.AccessibleDescription = 'Windows 10 Upgrade - Choose your upgrade date'
	$formWindows10Upgrade.AccessibleName = 'Windows 10 Upgrade'
	$formWindows10Upgrade.AutoScaleDimensions = '6, 13'
	$formWindows10Upgrade.AutoScaleMode = 'Font'
	$formWindows10Upgrade.ClientSize = '584, 461'
	#region Binary Data
	$formWindows10Upgrade.Icon = [System.Convert]::FromBase64String('
      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')
	#endregion
	$formWindows10Upgrade.MaximizeBox = $False
	$formWindows10Upgrade.MinimizeBox = $False
	$formWindows10Upgrade.Name = 'formWindows10Upgrade'
	$formWindows10Upgrade.ShowInTaskbar = $False
	$formWindows10Upgrade.StartPosition = 'CenterScreen'
	$formWindows10Upgrade.Text = 'Windows 10 Upgrade'
	$formWindows10Upgrade.TopMost = $True
	$formWindows10Upgrade.add_Load($formWindows10Upgrade_Load)
	#$formWindows10Upgrade.Add_FormClosing({$_.Cancel = $true})
	$formWindows10Upgrade.ControlBox = $false
	#
	# combobox2
	#
	$combobox2.Enabled = $False
	$combobox2.FormattingEnabled = $True
	[void]$combobox2.Items.Add('00')
	[void]$combobox2.Items.Add('15')
	[void]$combobox2.Items.Add('30')
	[void]$combobox2.Items.Add('45')
	$combobox2.Location = '465, 303'
	$combobox2.Name = 'combobox2'
	$combobox2.Size = '52, 21'
	$combobox2.TabIndex = 21
	$combobox2.Visible = $False
	$combobox2.add_SelectedValueChanged($comboboxesALL_SelectedIndexChanged)
	#
	# combobox1
	#
	$combobox1.Enabled = $False
	$combobox1.FormattingEnabled = $True
	[void]$combobox1.Items.Add('05 AM')
	[void]$combobox1.Items.Add('06 AM')
	[void]$combobox1.Items.Add('07 AM')
	[void]$combobox1.Items.Add('08 AM')
	[void]$combobox1.Items.Add('09 AM')
	[void]$combobox1.Items.Add('10 AM')
	[void]$combobox1.Items.Add('11 AM')
	[void]$combobox1.Items.Add('12 PM')
	[void]$combobox1.Items.Add('1 PM')
	[void]$combobox1.Items.Add('2 PM')
	[void]$combobox1.Items.Add('3 PM')
	[void]$combobox1.Items.Add('4 PM')
	[void]$combobox1.Items.Add('5 PM')
	[void]$combobox1.Items.Add('6 PM')
	$combobox1.Location = '356, 303'
	$combobox1.Name = 'combobox1'
	$combobox1.Size = '52, 21'
	$combobox1.TabIndex = 20
	$combobox1.Visible = $False
	$combobox1.add_SelectedValueChanged($comboboxesALL_SelectedIndexChanged)
	#
	# textbox6
	#
	$textbox6.BackColor = 'Control'
	$textbox6.BorderStyle = 'None'
	$textbox6.Enabled = $False
	$textbox6.Location = '416, 307'
	$textbox6.Name = 'textbox6'
	$textbox6.Size = '43, 13'
	$textbox6.TabIndex = 19
	$textbox6.Text = 'Minute:'
	$textbox6.Visible = $False
	#
	# textbox5
	#
	$textbox5.BackColor = 'Control'
	$textbox5.BorderStyle = 'None'
	$textbox5.Enabled = $False
	$textbox5.Location = '321, 307'
	$textbox5.Name = 'textbox5'
	$textbox5.Size = '29, 13'
	$textbox5.TabIndex = 18
	$textbox5.Text = 'Hour:'
	$textbox5.Visible = $False
	#
	# textbox4
	#
	$textbox4.BackColor = 'Control'
	$textbox4.BorderStyle = 'None'
	$textbox4.Enabled = $False
	$textbox4.Location = '312, 279'
	$textbox4.Name = 'textbox4'
	$textbox4.Size = '260, 13'
	$textbox4.TabIndex = 14
	$textbox4.Text = 'at:'
	$textbox4.Visible = $False
	#
	# buttonReschedule
	#
	$buttonReschedule.Enabled = $False
	$buttonReschedule.DialogResult = 'OK'
	$buttonReschedule.Location = '407, 409'
	$buttonReschedule.Name = 'buttonReschedule'
	$buttonReschedule.Size = '110, 40'
	$buttonReschedule.TabIndex = 13
	$buttonReschedule.Text = 'Reschedule'
	$buttonReschedule.UseCompatibleTextRendering = $True
	$buttonReschedule.UseVisualStyleBackColor = $True
	$buttonReschedule.Add_Click({
			$TimeAMPM = ($($combobox1.SelectedItem)).split(' ')
			[int]$Hour = $TimeAMPM[0]
			$AMPM = $TimeAMPM[1]
			SWITCH ($AMPM) {
				PM {$Hour = $Hour + 12}	
			}
			$Output.UpgradeNow = 'No'
			$Output.DeferDate = Get-Date -Date $datetimepicker1.Value -Hour $Hour -Minute $combobox2.SelectedItem -Second '00' -Format 'yyyy-MM-dd HH:mm:ss'
		})
	$buttonReschedule.Visible = $False
	#
	# buttonLetsDoThis
	#
	$buttonLetsDoThis.Enabled = $False
	$buttonLetsDoThis.DialogResult = 'OK'
	$buttonLetsDoThis.Location = '67, 409'
	$buttonLetsDoThis.Name = 'buttonLetsDoThis'
	$buttonLetsDoThis.Size = '110, 40'
	$buttonLetsDoThis.TabIndex = 12
	$buttonLetsDoThis.Text = 'Let''s Do This!'
	$buttonLetsDoThis.UseCompatibleTextRendering = $True
	$buttonLetsDoThis.UseVisualStyleBackColor = $True
	$buttonLetsDoThis.Add_Click({
			$Output.UpgradeNow = 'Yes'; $Output.UpgradeDate = get-date -format 'yyyy-MM-dd HH:mm:ss'
		})
	$buttonLetsDoThis.Visible = $False
	#
	# datetimepicker1
	#
	$datetimepicker1.Enabled = $False
	$datetimepicker1.Location = '312, 242'
	$datetimepicker1.Name = 'datetimepicker1'
	$datetimepicker1.Size = '260, 20'
	$datetimepicker1.TabIndex = 11
	$datetimepicker1.MinDate = (get-date)
	IF ($DeadlineDate -as [datetime]) {
		$datetimepicker1.MaxDate = $DeadlineDate
	} ELSEIF (!($DeadlineDate -as [datetime])) {
		$datetimepicker1.MaxDate = (get-date).AddDays(35)
	}
	$datetimepicker1.Visible = $False
	#
	# checkbox5
	#
	$checkbox5.Enabled = $False
	$checkbox5.Location = '12, 336'
	$checkbox5.Name = 'checkbox5'
	$checkbox5.Size = '285, 24'
	$checkbox5.TabIndex = 10
	$checkbox5.Text = 'I''m ready to experience awesomeness'
	$checkbox5.UseCompatibleTextRendering = $True
	$checkbox5.UseVisualStyleBackColor = $True
	$checkbox5.Visible = $False
	$checkbox5.add_CheckedChanged($checkboxesALL_CheckedChanged)
	#
	# checkbox4
	#
	$checkbox4.Enabled = $False
	$checkbox4.Location = '12, 305'
	$checkbox4.Name = 'checkbox4'
	$checkbox4.Size = '285, 24'
	$checkbox4.TabIndex = 9
	$checkbox4.Text = 'I will NOT close the lid to my laptop or put it to sleep'
	$checkbox4.UseCompatibleTextRendering = $True
	$checkbox4.UseVisualStyleBackColor = $True
	$checkbox4.Visible = $False
	$checkbox4.add_CheckedChanged($checkboxesALL_CheckedChanged)
	#
	# checkbox3
	#
	$checkbox3.Enabled = $False
	$checkbox3.Location = '12, 274'
	$checkbox3.Name = 'checkbox3'
	$checkbox3.Size = '285, 24'
	$checkbox3.TabIndex = 8
	$checkbox3.Text = 'My computer is connected to power'
	$checkbox3.UseCompatibleTextRendering = $True
	$checkbox3.UseVisualStyleBackColor = $True
	$checkbox3.Visible = $False
	$checkbox3.add_CheckedChanged($checkboxesALL_CheckedChanged)
	#
	# checkbox2
	#
	$checkbox2.Enabled = $False
	$checkbox2.Location = '12, 243'
	$checkbox2.Name = 'checkbox2'
	$checkbox2.Size = '285, 24'
	$checkbox2.TabIndex = 7
	$checkbox2.Text = 'I have backed up my data to OneDrive'
	$checkbox2.UseCompatibleTextRendering = $True
	$checkbox2.UseVisualStyleBackColor = $True
	$checkbox2.Visible = $False
	$checkbox2.add_CheckedChanged($checkboxesALL_CheckedChanged)
	#
	# checkbox1
	#
	$checkbox1.Enabled = $False
	$checkbox1.Location = '12, 212'
	$checkbox1.Name = 'checkbox1'
	$checkbox1.Size = '285, 24'
	$checkbox1.TabIndex = 6
	$checkbox1.Text = 'I have 2 Hours of manager-approved time'
	$checkbox1.UseCompatibleTextRendering = $True
	$checkbox1.UseVisualStyleBackColor = $True
	$checkbox1.Visible = $False
	$checkbox1.add_CheckedChanged($checkboxesALL_CheckedChanged)
	#
	# textbox3
	#
	$textbox3.BackColor = 'Control'
	$textbox3.BorderStyle = 'None'
	$textbox3.Enabled = $False
	$textbox3.Location = '312, 185'
	$textbox3.Name = 'textbox3'
	$textbox3.Size = '260, 13'
	$textbox3.TabIndex = 5
	$textbox3.Text = 'I''ll have more time on:'
	$textbox3.Visible = $False
	#
	# textbox2
	#
	$textbox2.BackColor = 'Control'
	$textbox2.BorderStyle = 'None'
	$textbox2.Enabled = $False
	$textbox2.Location = '12, 185'
	$textbox2.Name = 'textbox2'
	$textbox2.Size = '260, 13'
	$textbox2.TabIndex = 4
	$textbox2.Text = 'I solemnly swear that:'
	$textbox2.Visible = $False
	#
	# buttonNotNow
	#
	$buttonNotNow.Location = '407, 139'
	$buttonNotNow.Name = 'buttonNotNow'
	$buttonNotNow.Size = '110, 40'
	$buttonNotNow.TabIndex = 3
	$buttonNotNow.Text = 'Not now'
	$buttonNotNow.UseCompatibleTextRendering = $True
	$buttonNotNow.UseVisualStyleBackColor = $True
	$buttonNotNow.add_Click($buttonNotNow_Click)
	$buttonNotNow.add_ControlAdded($buttonNotNow_Click)
	$buttonNotNow.add_MouseClick($buttonNotNow_Click)
	#
	# buttonYes
	#
	$buttonYes.Location = '67, 139'
	$buttonYes.Name = 'buttonYes'
	$buttonYes.Size = '110, 40'
	$buttonYes.TabIndex = 2
	$buttonYes.Text = 'Yes'
	$buttonYes.UseCompatibleTextRendering = $True
	$buttonYes.UseVisualStyleBackColor = $True
	$buttonYes.add_Click($buttonYes_Click)
	$buttonYes.add_ControlAdded($buttonYes_Click)
	$buttonYes.add_MouseClick($buttonYes_Click)
	#
	# textbox1
	#
	$textbox1.BackColor = 'Control'
	$textbox1.BorderStyle = 'None'
	$textbox1.Location = '67, 68'
	$textbox1.Multiline = $True
	$textbox1.Name = 'textbox1'
	$textbox1.Size = '450, 55'
	$textbox1.TabIndex = 1
	$textbox1.TabStop = $False
	$textbox1.Text = "Hello, $FullName! We are upgrading your computer to Windows 10.

    Do you want to do this now?
  (It will take approximately 2 HOURS.)"
	$textbox1.TextAlign = 'Center'
	#
	# picturebox1
	#
	#region Binary Data
	$picturebox1.Image = [System.Convert]::FromBase64String('
      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
  jkxHlEEOC+4AAAAASUVORK5CYII=')
	#endregion
	$picturebox1.Location = '242, 12'
	$picturebox1.Name = 'picturebox1'
	$picturebox1.Size = '100, 50'
	$picturebox1.SizeMode = 'CenterImage'
	$picturebox1.TabIndex = 0
	$picturebox1.TabStop = $False
	$formWindows10Upgrade.ResumeLayout()
	#endregion Generated Form Code
	
	#----------------------------------------------
	
	#Save the initial state of the form
	$InitialFormWindowState = $formWindows10Upgrade.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formWindows10Upgrade.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formWindows10Upgrade.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	$result = $formWindows10Upgrade.ShowDialog()
	IF ($result -eq [System.Windows.Forms.DialogResult]::OK) {
		$Output
	}
	#return $formWindows10Upgrade.ShowDialog()
	
}
#endregion Show-CYOA_Form_psf

#region Invoke-OSDInstall
FUNCTION Invoke-OSDInstall {
	PARAM
	(
		[Parameter(Mandatory = $true)][String]$OSDPackageID
	)
	
	TRY {
		$CIMClass = Get-CimClass -Namespace root\ccm\clientsdk -ClassName CCM_ProgramsManager
		$OSD = Get-CimInstance -ClassName CCM_Program -Namespace "root\ccm\clientSDK" | Where-Object {
			$_.PackageID -eq $OSDPackageID
		}
		$Args = @{
			PackageID	  = $OSD.PackageID
			ProgramID	  = $OSD.ProgramID
		}
		Invoke-CimMethod -CimClass $CIMClass -MethodName "ExecuteProgram" –Arguments $Args
		Write-Output $Error[0]
	} CATCH {
		Write-Output $Error[0]
	}
}
#endregion Invoke-OSDInstall

#region New-ICSEvent
FUNCTION New-ICSEvent {
  <#
        .SYNOPSIS
        A brief description of the Create-ICSEvent function.
	
        .DESCRIPTION
        A detailed description of the Create-ICSEvent function.
	
        .PARAMETER StartDate
        A description of the StartDate parameter.
	
        .PARAMETER EndDate
        A description of the EndDate parameter.
	
        .PARAMETER Subject
        A description of the Subject parameter.
	
        .PARAMETER Description
        A description of the Description parameter.
	
        .PARAMETER Location
        A description of the Location parameter.
	
        .PARAMETER FileName
        Must be .ics file name
	
        .PARAMETER Frequency
        A description of the Frequency parameter.
	
        .PARAMETER Cycle
        A description of the Cycle parameter.
	
        .PARAMETER Interval
        A description of the Interval parameter.
	
        .EXAMPLE
        PS C:\> Create-ICSEvent -StartDate $value1 -EndDate $value2 -Subject 'Value3' -Description $value4 -Location 'Value5' -FileName $value6
	
        .NOTES
        Additional information about the function.
    #>
	
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][datetime]$StartDate,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Subject,
		[Parameter(Mandatory = $true)][ValidatePattern('^.*\.(ics)$')][ValidateNotNullOrEmpty()]$FilePathAndName,
		[switch]$Frequency = $false,
		[ValidateSet('YEARLY', 'MONTHLY', 'WEEKLY', 'DAILY', 'HOURLY', 'MINUTELY', 'SECONDLY')]$Cycle,
		[ValidatePattern('\d')]$Interval = '1'
	)
	# Set Variables
	[datetime]$EndDate = $StartDate.AddHours(2)
	$Location = "At my desk"
	#$FileName = Split-Path $FilePathAndName -Leaf
	$FilePath = Split-Path $FilePathAndName -Parent
	
	#region Custom date formats that we want to use
	$dateFormat = "yyyyMMdd"
	$longDateFormat = "yyyyMMdd'T'HHmmss'Z'"
	$StartDate = $StartDate.ToUniversalTime()
	$EndDate = $EndDate.ToUniversalTime()
	$StartDateFormatted = $StartDate.ToString($longDateFormat)
	$EndDateFormatted = $EndDate.ToString($longDateFormat)
	#endregion
	
	#region Machine info
	$MachineInfo = Get-WmiObject -Class Win32_ComputerSystem
	$OSInfo = Get-WmiObject -Class Win32_OperatingSystem
	$Serial = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber
	$MachineName = $machineinfo.Name
	SWITCH ($OSInfo.Version) {
		6.3.9600 {
			$OSVersion = ('Windows 8.1 ({0})' -f $OSInfo.Version)
		}
		10.0.16299 {
			$OSVersion = ('Windows 10 1709 ({0})' -f $OSInfo.Version)
		}
		10.0.15063 {
			$OSVersion = ('Windows 10 1703 ({0})' -f $OSInfo.Version)
		}
		10.0.14393 {
			$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
		}
		10.0.10586 {
			$OSVersion = ('Windows 10 1511 ({0})' -f $OSInfo.Version)
		}
		10.0.16299 {
			$OSVersion = ('Windows 10 1709 ({0})' -f $OSInfo.Version)
		}
		10.0.15063 {
			$OSVersion = ('Windows 10 1703 ({0})' -f $OSInfo.Version)
		}
		10.0.14393 {
			$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
		}
		10.0.10586 {
			$OSVersion = ('Windows 10 1511 ({0})' -f $OSInfo.Version)
		}
		10.0.14393 {
			$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
		}
		10.0.10240 {
			$OSVersion = ('Windows 10 1507 (RTM) ({0})' -f $OSInfo.Version)
		}
	}
	$OSArch = $OSInfo.OSArchitecture
	$MachineManuf = $machineinfo.Manufacturer
	$MachineModelNo = $machineinfo.Model
	$MachineModelName = $machineinfo.SystemFamily
	$NICIndex = Get-CimInstance -ClassName Win32_IP4RouteTable | Where-Object {
		$_.Destination -eq '0.0.0.0' -and $_.Mask -eq '0.0.0.0'
	} | Sort-Object Metric1 | Select-Object -First 1 | Select-Object -ExpandProperty InterfaceIndex
	$AdapterConfig = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object {
		$_.InterfaceIndex -eq $NICIndex
	} | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration
	$IPAddress = $AdapterConfig.IPAddress
	$MachineInfoText = @"
Here's my machine info:
Machine Name: $MachineName
OS: $OSVersion $OSArch
Manufacturer: $MachineManuf
Model: $MachineModelName ($($MachineModelNo))
Serial Number: $Serial
Last IP address: $IPAddress
"@
	$MachineInfoTextCalString = "Here's my machine info:\nMachine Name: $MachineName\nOS: $OSVersion $OSArch\nManufacturer: $MachineManuf\nModel: $MachineModelName ($MachineModelNo)\nSerial Number: $Serial\nLast IP address: $IPAddress"
	#endregion
	$Description = $MachineInfoTextCalString
	
	TRY {
		
		
		
		#region .NET StringBuilder
		#$sb = [System.Text.StringBuilder]::new()
		# Use this because Windows 8.1 sucks
		$sb = New-Object Text.StringBuilder
		#endregion
		
		#region ICS Properties. See RFC2445 specs at http://www.ietf.org/rfc/rfc2445.txt
		[void]$sb.AppendLine('BEGIN:VCALENDAR')
		[void]$sb.AppendLine('VERSION:2.0')
		[void]$sb.AppendLine('METHOD:PUBLISH')
		[void]$sb.AppendLine('X-PRIMARY-CALENDAR:TRUE')
		[void]$sb.AppendLine('PRODID:-//contoso//EUC Engineering ICS Builder//EN')
		[void]$sb.AppendLine('BEGIN:VEVENT')
		[void]$sb.AppendLine("UID:" + [guid]::NewGuid())
		[void]$sb.AppendLine("CREATED:" + [datetime]::Now.ToUniversalTime().ToString($longDateFormat))
		[void]$sb.AppendLine("DTSTAMP:" + [datetime]::Now.ToUniversalTime().ToString($longDateFormat))
		[void]$sb.AppendLine("LAST-MODIFIED:" + [datetime]::Now.ToUniversalTime().ToString($longDateFormat))
		[void]$sb.AppendLine("SEQUENCE:0")
		[void]$sb.AppendLine("DTSTART:" + $StartDateFormatted)
		[void]$sb.AppendLine("DTEND:" + $EndDateFormatted)
		# If Frequency param used, sets values
		IF ($Frequency) {
			IF ($Cycle -and $Interval) {
				[void]$sb.AppendLine("RRULE:FREQ=$Cycle;INTERVAL=$interval")
			} ELSEIF (!$Cycle -or !$Interval) {
				Write-Output "Missing Cycle or Interval values. Exiting"
				$ExitCode = '1'
				BREAK
			}
		}
		[void]$sb.AppendLine("DESCRIPTION:" + $MachineInfoTextCalString)
		[void]$sb.AppendLine("SUMMARY:" + $Subject)
		[void]$sb.AppendLine("LOCATION:" + $Location)
		[void]$sb.AppendLine("TRANSP:TRANSPARENT")
		[void]$sb.AppendLine('END:VEVENT')
		
		[void]$sb.AppendLine('END:VCALENDAR')
		#endregion
		
		#region Create Folder if needed
		IF (!(Test-Path -Path "$FilePath" -PathType Container)) {
			New-Item -Path "$FilePath" -ItemType Directory -Force
			$ExitCode = $LASTEXITCODE
		}
		#endregion
		
		#region Test path created. If so, create ICS File
		IF (Test-Path -Path "$FilePath" -PathType Container) {
			$sb.ToString() | Out-File -FilePath "$FilePathAndName" -Force -ErrorAction Stop
		} ELSEIF (!(Test-Path -Path "$FilePath" -PathType Container)) {
			Write-Output 'Failed to create directory' -ErrorAction Stop
		}
		#endregion
		
		#region Output to custom PSObject  
		$Output = New-Object -TypeName PSObject
		$Properties = @{
			'FilePath'  = $FilePathAndName
		}
		$Output | Add-Member -NotePropertyMembers $Properties
		$Output
		#endregion
		
	} CATCH {
		THROW $_
	}
}
#endregion

#region New-EMailGun
FUNCTION New-EMailGun {
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$UserName,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$MailTo,
		[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$DeferDate,
		[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$AttachmentPath,
		[switch]$Reminder = $false
	)
	
	# Variables
	$TLD = '.com'
	$Domain = 'contoso'
	$EmailDomain = 'euc.' + $Domain + $TLD
	$From = "Windows10Upgrade@euc." + $Domain + $TLD
	$CC = $UserName + '@' + $Domain + $TLD
	$APIkey = 'key-fb6c06b57f4a97350a08d2dd8b93a09b'
	$URL = "https://api.mailgun.net/v3/$($EmailDomain)/messages"
	$DateFull = Get-Date -Format "dddd, MMMM dd 'at' hh:mmtt"
	$DeferDateFull = $DeferDate | Get-Date -Format "dddd, MMMM dd 'at' hh:mmtt" -ErrorAction SilentlyContinue
	
	#region Machine Info
	$MachineInfo = Get-WmiObject -Class Win32_ComputerSystem
	$OSInfo = Get-WmiObject -Class Win32_OperatingSystem
	$Serial = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber
	$MachineName = $machineinfo.Name
	SWITCH ($OSInfo.Version) {
		6.3.9600 {
			$OSVersion = ('Windows 8.1 ({0})' -f $OSInfo.Version)
		}
		10.0.16299 {
			$OSVersion = ('Windows 10 1709 ({0})' -f $OSInfo.Version)
		}
		10.0.15063 {
			$OSVersion = ('Windows 10 1703 ({0})' -f $OSInfo.Version)
		}
		10.0.14393 {
			$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
		}
		10.0.10586 {
			$OSVersion = ('Windows 10 1511 ({0})' -f $OSInfo.Version)
		}
		10.0.16299 {
			$OSVersion = ('Windows 10 1709 ({0})' -f $OSInfo.Version)
		}
		10.0.15063 {
			$OSVersion = ('Windows 10 1703 ({0})' -f $OSInfo.Version)
		}
		10.0.14393 {
			$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
		}
		10.0.10586 {
			$OSVersion = ('Windows 10 1511 ({0})' -f $OSInfo.Version)
		}
		10.0.14393 {
			$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
		}
		10.0.10240 {
			$OSVersion = ('Windows 10 1507 (RTM) ({0})' -f $OSInfo.Version)
		}
	}
	$OSArch = $OSInfo.OSArchitecture
	$MachineManuf = $machineinfo.Manufacturer
	$MachineModelNo = $machineinfo.Model
	$MachineModelName = $machineinfo.SystemFamily
	$NICIndex = Get-CimInstance -ClassName Win32_IP4RouteTable | Where-Object {
		$_.Destination -eq '0.0.0.0' -and $_.Mask -eq '0.0.0.0'
	} | Sort-Object Metric1 | Select-Object -First 1 | Select-Object -ExpandProperty InterfaceIndex
	$AdapterConfig = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object {
		$_.InterfaceIndex -eq $NICIndex
	} | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration
	$IPAddress = $AdapterConfig.IPAddress
	$MachineInfoText = @"
Here's my machine info:
Machine Name: $MachineName
OS: $OSVersion $OSArch
Manufacturer: $MachineManuf
Model: $MachineModelName ($($MachineModelNo))
Serial Number: $Serial
Last IP address: $IPAddress
"@
	#endregion Machine Info
	
	#region Set Subject and Body based on Deferral or Reminder
	IF ($Reminder) {
		$Subject = ('Windows 10 In-Place Upgrade / {0} / TOMORROW' -f $UserName)
		$BodyText = @"
This is a reminder that you chose to upgrade your machine to Windows 10 tomorrow, $DateFull.


Thank you and we hope you enjoy the new hotness!

- EUC Engineering

"@
	} ELSEIF ([string]$DeferDate -as [datetime]) {
		$Subject = ('Windows 10 In-Place Upgrade / {0} / Deferred Until {1}' -f $UserName, $DeferDate)
		$BodyText = @"
This is a record of my In-Place Upgrade choice:

On $DateFull, I was prompted to Upgrade to Win10. I chose to defer until $DeferDateFull.

$MachineInfoText

"@
	} ELSE {
		$Subject = ('Windows 10 In-Place Upgrade / {0} / Today - {1}' -f $UserName, (Get-Date -Format "dd/MM/yyyy HH:mm:ss"))
		$BodyText = @"
On $DateFull I was prompted to Upgrade to Windows 10 and I have chosen to upgrade now.

Please contact me in about 2 hours to see how it's going.

$MachineInfoText


"@
	}
	#endregion Set Subject and Body based on Deferral
	
	#region function ConvertTo-MimeMultiPartBody
	FUNCTION ConvertTo-MimeMultiPartBody {
		PARAM ([Parameter(Mandatory = $true)][string]$Boundary,
			[Parameter(Mandatory = $true)][hashtable]$Data)
		
		$body = "";
		$Data.GetEnumerator() | ForEach-Object {
			$name = $_.Key
			$value = $_.Value
			
			$body += "--$Boundary`r`n"
			$body += "Content-Disposition: form-data; name=`"$name`""
			IF ($value -is [byte[]]) {
				$fileName = $Data['FileName']
				IF (!$fileName) {
					$fileName = $name
				}
				$body += "; filename=`"$fileName`"`r`n"
				$body += 'Content-Type: application/octet-stream'
				$value = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($value)
			}
			$body += "`r`n`r`n" + $value + "`r`n"
		}
		RETURN $body + "--$boundary--"
	}
	#endregion function ConvertTo-MimeMultiPartBody
	
	#region Mail Attachment
	
	FUNCTION New-MailGunAttachment ($From, $Mailto, $Subject, $BodyText, $EmailDomain, $APIkey) {
		$headers = @{
			Authorization   = "Basic " + ([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("api:$($apikey)")))
		}
		#region Set Attachment if exist
		IF ($AttachmentPath) {
			$AttachmentFileName = Split-Path -Path $AttachmentPath -Leaf
			$email_parms = @{
				from	   = "$From";
				to		   = "$MailTo";
				cc		   = "$CC";
				subject    = "$Subject";
				text	   = "$BodyText";
				filename   = "$AttachmentFileName"
				attachment = ([IO.File]::ReadAllBytes("$AttachmentPath"));
			}
		} ELSE {
			$email_parms = @{
				from	  = "$From";
				to	      = "$MailTo";
				cc	      = "$CC";
				subject   = "$Subject";
				text	  = "$BodyText";
			}
		}
		#endregion Set Attachment if exist
		
		$boundary = [guid]::NewGuid().ToString()
		$body = ConvertTo-MimeMultiPartBody $boundary $email_parms
		$RestResult = (Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ContentType "multipart/form-data; boundary=$boundary").message
		$RestOutput = New-Object -TypeName psobject
		$RestProperties = @{
			'Result'  = $RestResult
		}
		$RestOutput | Add-Member -NotePropertyMembers $RestProperties
		$RestOutput
	}
	#endregion Mail Attachment
	
	# Generate Email
	$FunctionResult = New-MailGunAttachment -From $From -Mailto $MailTo -Subject $Subject -BodyText $BodyText -EmailDomain $EmailDomain -APIkey $APIkey
	$FunctionResult
}
#endregion New-EMailGun

#region New-TaskScheduler
FUNCTION New-TaskScheduler {
	PARAM (
		$LibraryPath,
		$TaskName,
		$Description,
		$ActionEXE,
		$Arguments,
		$Trigger_Date
	)
	TRY {
		# Set Trigger
		$Trigger = New-ScheduledTaskTrigger -Once -At $Trigger_Date
		
		# Check existing
		$GetExisting = Get-ScheduledTask -TaskName "$TaskName" -ErrorAction SilentlyContinue
		
		# Add if exist, new if not
		IF ($GetExisting) {
			Set-ScheduledTask -TaskName $TaskName -Trigger $Trigger
			$Trigger_Status = 'Added'
		}
		IF (!$GetExisting) {
			$Action = New-ScheduledTaskAction -Execute $ActionEXE -Argument $Arguments
			$RegisterTask = Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName $TaskName -Description $Description -TaskPath $LibraryPath
			$Trigger_Status = 'New'
		}
		
		# Output results
		SWITCH ($Trigger_Status) {
			Added {
				Write-Output 'Added'
			}
			New {
				Write-Output 'New'
			}
		}
	} CATCH {
		Write-Output $LASTEXITCODE
	}
}
#endregion New-TaskScheduler

#region Function New-ScheduledTaskAsUser
FUNCTION New-ScheduledTaskAsUser {
<#
	.SYNOPSIS
		Execute a process with a logged in user account, by using a scheduled task, to provide interaction with user in the SYSTEM context.
	
	.DESCRIPTION
		Execute a process with a logged in user account, by using a scheduled task, to provide interaction with user in the SYSTEM context.
	
	.PARAMETER UserName
		Logged in Username under which to run the process from. Default is: The active console user. If no console user exists but users are logged in, such as on terminal servers, then the first logged-in non-console user.
	
	.PARAMETER Path
		Path to the file being executed.
	
	.PARAMETER Parameters
		Arguments to be passed to the file being executed.
	
	.PARAMETER STFolder
		A description of the STFolder parameter.
	
	.PARAMETER TaskName
		A description of the TaskName parameter.
	
	.PARAMETER Trigger_Date
		A description of the Trigger_Date parameter.
	
	.PARAMETER SecureParameters
		Hides all parameters passed to the executable from the Toolkit log file.
	
	.PARAMETER RunLevel
		Specifies the level of user rights that Task Scheduler uses to run the task. The acceptable values for this parameter are:
		- HighestAvailable: Tasks run by using the highest available privileges (Admin privileges for Administrators). Default Value.
		- LeastPrivilege: Tasks run by using the least-privileged user account (LUA) privileges.
	
	.PARAMETER Wait
		Wait for the process, launched by the scheduled task, to complete execution before accepting more input. Default is $false.
	
	.PARAMETER PassThru
		Returns the exit code from this function or the process launched by the scheduled task.
	
	.PARAMETER ContinueOnError
		Continue if an error is encountered. Default is $true.
	
	.EXAMPLE
		New-ScheduledTaskAsUser -UserName 'CONTOSO\User' -Path "$PSHOME\powershell.exe" -Parameters "-Command & { & `"C:\Test\Script.ps1`"; Exit `$LastExitCode }" -Wait
		Execute process under a user account by specifying a username under which to execute it.
	
	.EXAMPLE
		New-ScheduledTaskAsUser -Path "$PSHOME\powershell.exe" -Parameters "-Command & { & `"C:\Test\Script.ps1`"; Exit `$LastExitCode }" -Wait
		Execute process under a user account by using the default active logged in user that was detected when the toolkit was launched.
	
	.NOTES
		
	
	.LINK
		http://psappdeploytoolkit.com
#>
	
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$DomUserName = $RunAsActiveUser.NTAccount,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Path,
		[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$Parameters = '',
		[ValidateNotNullOrEmpty()][string]$STFolder,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$TaskName,
		[Parameter(Mandatory = $true)][ValidateScript({
				$_ -ge (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
			})][ValidateNotNullOrEmpty()][datetime]$Trigger_Date,
		[Parameter(Mandatory = $false)][switch]$SecureParameters = $false,
		[Parameter(Mandatory = $false)][ValidateSet('HighestAvailable', 'LeastPrivilege')][string]$RunLevel = 'HighestAvailable',
		[Parameter(Mandatory = $false)][switch]$Wait = $false,
		[Parameter(Mandatory = $false)][switch]$PassThru = $false,
		[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][boolean]$ContinueOnError = $true
	)
	
	BEGIN {
		## Get the name of this function and write header
		[string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -CmdletBoundParameters $PSBoundParameters -Header
	}
	PROCESS {
		## Initialize exit code variable
		[int32]$executeProcessAsUserExitCode = 0
		
		## Confirm that the username field is not empty
		IF (-not $DomUserName) {
			[int32]$executeProcessAsUserExitCode = 60009
			Write-Log -Message "The function [${CmdletName}] has a -UserName parameter that has an empty default value because no logged in users were detected when the toolkit was launched." -Severity 3 -Source ${CmdletName}
			IF (-not $ContinueOnError) {
				THROW "The function [${CmdletName}] has a -UserName parameter that has an empty default value because no logged in users were detected when the toolkit was launched."
			} ELSE {
				RETURN
			}
		}
		
		## Confirm if the toolkit is running with administrator privileges
		IF (($RunLevel -eq 'HighestAvailable') -and (-not $IsAdmin)) {
			[int32]$executeProcessAsUserExitCode = 60003
			Write-Log -Message "The function [${CmdletName}] requires the toolkit to be running with Administrator privileges if the [-RunLevel] parameter is set to 'HighestAvailable'." -Severity 3 -Source ${CmdletName}
			IF (-not $ContinueOnError) {
				THROW "The function [${CmdletName}] requires the toolkit to be running with Administrator privileges if the [-RunLevel] parameter is set to 'HighestAvailable'."
			} ELSE {
				RETURN
			}
		}
		
		## Build the scheduled task XML name
		[char[]]$invalidFileNameChars = [IO.Path]::GetInvalidFileNameChars()
		[string]$TaskName = $TaskName -replace "[$invalidFileNameChars]", '' -replace ' ', ''
		[string]$schTaskName = "$TaskName-ExecuteAsUser"
		
		##  Create the temporary App Deploy Toolkit files folder if it doesn't already exist
		IF (-not (Test-Path -LiteralPath $dirAppDeployTemp -PathType 'Container')) {
			New-Item -Path $dirAppDeployTemp -ItemType 'Directory' -Force -ErrorAction 'Stop'
		}
		
		## If PowerShell.exe is being launched, then create a VBScript to launch PowerShell so that we can suppress the console window that flashes otherwise
		IF (($Path -eq 'PowerShell.exe') -or ((Split-Path -Path $Path -Leaf) -eq 'PowerShell.exe')) {
			# Permit inclusion of double quotes in parameters
			IF ($($Parameters.Substring($Parameters.Length - 1)) -eq '"') {
				[string]$executeProcessAsUserParametersVBS = 'chr(34) & ' + "`"$($Path)`"" + ' & chr(34) & ' + '" ' + ($Parameters -replace '"', "`" & chr(34) & `"" -replace ' & chr\(34\) & "$', '') + ' & chr(34)'
			} ELSE {
				[string]$executeProcessAsUserParametersVBS = 'chr(34) & ' + "`"$($Path)`"" + ' & chr(34) & ' + '" ' + ($Parameters -replace '"', "`" & chr(34) & `"" -replace ' & chr\(34\) & "$', '') + '"'
			}
			[string[]]$executeProcessAsUserScript = "strCommand = $executeProcessAsUserParametersVBS"
			$executeProcessAsUserScript += 'set oWShell = CreateObject("WScript.Shell")'
			$executeProcessAsUserScript += 'intReturn = oWShell.Run(strCommand, 0, true)'
			$executeProcessAsUserScript += 'WScript.Quit intReturn'
			$executeProcessAsUserScript | Out-File -FilePath "$dirAppDeployTemp\$($schTaskName).vbs" -Force -Encoding 'default' -ErrorAction 'SilentlyContinue'
			$Path = 'wscript.exe'
			$Parameters = "`"$dirAppDeployTemp\$($schTaskName).vbs`""
		}
		#Convert Date
		$TriggerDate = $Trigger_Date | Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
		## Specify the scheduled task configuration in XML format
		[string]$UserSID = $RunAsActiveUser.SID
		[string]$xmlSchTask = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Author>$DomUserName</Author>
  </RegistrationInfo>
  <Triggers>
    <TimeTrigger>
      <StartBoundary>$TriggerDate</StartBoundary>
      <ExecutionTimeLimit>P3D</ExecutionTimeLimit>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$UserSID</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>$RunLevel</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>$Path</Command>
      <Arguments>$Parameters</Arguments>
    </Exec>
  </Actions>
</Task>
"@
<# old xml		
		[string]$xmlSchTask = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo />
  <Triggers>
    <TimeTrigger>
      <StartBoundary>$TriggerDate</StartBoundary>
      <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Settings>
	<MultipleInstancesPolicy>StopExisting</MultipleInstancesPolicy>
	<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
	<StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
	<AllowHardTerminate>true</AllowHardTerminate>
	<StartWhenAvailable>false</StartWhenAvailable>
	<RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
	<IdleSettings>
	  <StopOnIdleEnd>false</StopOnIdleEnd>
	  <RestartOnIdle>false</RestartOnIdle>
	</IdleSettings>
	<AllowStartOnDemand>true</AllowStartOnDemand>
	<Enabled>true</Enabled>
	<Hidden>false</Hidden>
	<RunOnlyIfIdle>false</RunOnlyIfIdle>
	<WakeToRun>false</WakeToRun>
	<ExecutionTimeLimit>P3D</ExecutionTimeLimit>
	<Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
	<Exec>
	  <Command>$Path</Command>
	  <Arguments>$Parameters</Arguments>
	</Exec>
  </Actions>
  <Principals>
	<Principal id="Author">
	  <UserId>$DomUserName</UserId>
	  <LogonType>InteractiveToken</LogonType>
	  <RunLevel>$RunLevel</RunLevel>
	</Principal>
  </Principals>
</Task>
"@
		 End old xml #>
		
		## Export the XML to file
		TRY {
			#  Specify the filename to export the XML to
			[string]$xmlSchTaskFilePath = "$dirAppDeployTemp\$schTaskName.xml"
			[string]$xmlSchTask | Out-File -FilePath $xmlSchTaskFilePath -Force -ErrorAction 'Stop'
		} CATCH {
			[int32]$executeProcessAsUserExitCode = 60007
			Write-Log -Message "Failed to export the scheduled task XML file [$xmlSchTaskFilePath]. `n$(Resolve-Error)" -Severity 3 -Source ${CmdletName}
			IF (-not $ContinueOnError) {
				THROW "Failed to export the scheduled task XML file [$xmlSchTaskFilePath]: $($_.Exception.Message)"
			} ELSE {
				RETURN
			}
		}
		
		## Create Scheduled Task to run the process with a logged-on user account
		IF ($Parameters) {
			IF ($SecureParameters) {
				Write-Log -Message "Create scheduled task to run the process [$Path] (Parameters Hidden) as the logged-on user [$DomUserName]..." -Source ${CmdletName}
			} ELSE {
				Write-Log -Message "Create scheduled task to run the process [$Path $Parameters] as the logged-on user [$DomUserName]..." -Source ${CmdletName}
			}
		} ELSE {
			Write-Log -Message "Create scheduled task to run the process [$Path] as the logged-on user [$DomUserName]..." -Source ${CmdletName}
		}
		[psobject]$schTaskResult = Execute-Process -Path $exeSchTasks -Parameters "/create /f /tn $STFolder\$schTaskName /xml `"$xmlSchTaskFilePath`"" -WindowStyle 'Hidden' -CreateNoWindow -PassThru
		IF ($schTaskResult.ExitCode -ne 0) {
			[int32]$executeProcessAsUserExitCode = $schTaskResult.ExitCode
			Write-Log -Message "Failed to create the scheduled task by importing the scheduled task XML file [$xmlSchTaskFilePath]." -Severity 3 -Source ${CmdletName}
			IF (-not $ContinueOnError) {
				THROW "Failed to create the scheduled task by importing the scheduled task XML file [$xmlSchTaskFilePath]."
			} ELSE {
				RETURN
			}
		}
		## Trigger the Scheduled Task
		IF ($Parameters) {
			IF ($SecureParameters) {
				Write-Log -Message "Trigger execution of scheduled task with command [$Path] (Parameters Hidden) as the logged-on user [$DomUserName]..." -Source ${CmdletName}
			} ELSE {
				Write-Log -Message "Trigger execution of scheduled task with command [$Path $Parameters] as the logged-on user [$DomUserName]..." -Source ${CmdletName}
			}
		} ELSE {
			Write-Log -Message "Trigger execution of scheduled task with command [$Path] as the logged-on user [$DomUserName]..." -Source ${CmdletName}
		}
		#[psobject]$schTaskResult = Execute-Process -Path $exeSchTasks -Parameters "/run /i /tn $STFolder\$schTaskName" -WindowStyle 'Hidden' -CreateNoWindow -Passthru
		IF ($schTaskResult.ExitCode -ne 0) {
			[int32]$executeProcessAsUserExitCode = $schTaskResult.ExitCode
			#Write-Log -Message "Failed to trigger scheduled task [$schTaskName]." -Severity 3 -Source ${CmdletName}
			##  Delete Scheduled Task
			#Write-Log -Message 'Delete the scheduled task which did not trigger.' -Source ${CmdletName}
			#Execute-Process -Path $exeSchTasks -Parameters "/delete /tn $schTaskName /f" -WindowStyle 'Hidden' -CreateNoWindow -ContinueOnError $true
			#IF (-not $ContinueOnError) {
			#	THROW "Failed to trigger scheduled task [$schTaskName]."
			#} ELSE {
			#	RETURN
			#}
		}
	}
	END {
		IF ($PassThru) {
			Write-Output -InputObject $executeProcessAsUserExitCode
		}
		
		Write-FunctionHeaderOrFooter -CmdletName ${CmdletName} -Footer
	}
}
#endregion

##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

IF ($scriptParentPath) {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
} ELSE {
	Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
}

##*===============================================
##* END SCRIPT BODY
##*===============================================
