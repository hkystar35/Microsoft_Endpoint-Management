<#PSScriptInfo

.VERSION 
    2.0

.GUID 
    72473955-670b-4c99-80f8-663f749b3762

.AUTHOR 
    Joachim Bryttmar

.COMPANYNAME 
    Contribit AB

.COPYRIGHT 
    The MIT License (MIT)

.TAGS 
    SCCM ConfigMgr "Configuration Manager" "System Center Configuration Manager" Automation Applications

.LICENSEURI 
    https://opensource.org/licenses/MIT

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>

<#
.SYNOPSIS
    This script is used with System Center Configuration Manager Current Branch (only tested with v1602).
    The script can automatically create an Application and optionally add a deployment type, either a manual or based on an MSI- or App-V-package. 
    It can also create a group in Active Directory, a User/Device Collection based on that AD-group and finally deploy the application to this collection.
    All user input is made in a simple Windows Form GUI.
        
    The following requirements must be installed on the computer where the script is run:
    - System Center Configuration Manager Console / Configuration Manager Powershell Module
    - Active Directory PowerShell module
    - PowerShell v4.0 or higher
    - .Net Framework
    
    NOTE: The script has only been fully tested and verified with PowerShell v5.0, on Windows Server 2012 R2 with SCCM v1602 and SCCM Powershell module 1604.

.DESCRIPTION
    Use this script to create a new Application in SCCM. The minimum required input is a name for the Application. This will simply create an empty Application with that name, but no deployment type.
    Everything else is optional, such as selecting an MSI file for example. By doing so, a deployment type will be created for the Application, and textboxes such as name and version
    will be populated with the information from the MSI, but can optionally be modified manually.
    By selecting an App-V 5 file (App-V 4 is NOT supported), an App-V deployment type will be created.
    
    If an installation program and a content source path is specified, a manual deployment type will be created with a dummy detection method. 
    IMPORTANT: Remember to manually change this detection method in the SCCM console afterwards.

    Please note that all source paths must be specified in the UNC-format. Local paths are not supported.
    
    The GUI is dynamic and different controls will be enabled or disabled depending on other controls. An MST file for example, can only be selected if an MSI file has been selected first.
    Creating a deployment is only available if a deployment type (manual, MSI or App-V) is also being created, etc.
    
    The button "Use PADT" can be used if you are using "PowerShell App Deployment Toolkit". Clicking the button will change the installation and uninstallation programs, and also
    check the source path and remove the folder "Files" from the end of the path if it exists.
    
    To keep the GUI as clean as possible, some required input that probably rarely change, are defined as script parameters instead. Such as SCCM site code, the path in AD to where
    the groups should be created, the domain name, limiting collections, etc.

    CHANGELOG
        Version 2.0 (2016-06-18)
            - Various improvements and bugfixes. The script has been rewritten, cleaned up and reorganized.
            - Updated SCCM-cmdlets and parameters to reflect changes made in updated SCCM PowerShell module. Tested and only supported with SCCM PowerShell module version 1604 (5.0.8373.1189).
            - Added support for App-V 5 deployment types.
            - Added support to create a manual/scripted deployment type. If you don't pick an MSI- or App-V-package and specify an installation program and source path, and
              a deployment type will be created with a dummy detection method that must be manually changed afterwards.
            - Improved error handling. The script will now, for example, check if an AD-group and collection already exist.
            - It is now possible to create a deployment to an existing collection.
            - It is now possible to use an existing AD group.
            - Better logic in the GUI, updated dependencies between different options to determine which check boxes etc will be enabled or disabled.
            - Added support to create new collection without membership rule. Just leave the AD group textbox empty.
            - Added textbox for collection name.
            - Added colors to the script output to improve readability.

.NOTES
    Author: Joachim Bryttmar

.LINK
    Author's blog: http://www.infogeek.se
    Author's workplace: http://www.contribit.se
    PowerShell App Deployment Toolkit : http://psappdeploytoolkit.com/

.PARAMETER SiteCode
    Enter your site code here.

.PARAMETER DPGroup
    The name of a distribution point group in SCCM. Whenever the option "Distribute Content" is selected, the application will be distributed to this DP group.
    Distribution to individual distribution points is not supported.

.PARAMETER DomainNetbiosName
    The Netbios name of your Active Directory domain.

.PARAMETER UserOUPath
    The path to the OU in Active Directory where all groups will be created when the options "Create AD Group" and Target "User" are selected.
    Must use the distinguished name format, for example: "OU=UserGroups,OU=MyOrganisation,DC=MyDomain,DC=Local"

.PARAMETER DeviceOUPath
    The path to the OU in Active Directory where all groups will be created when the options "Create AD Group" and Target "Device" are selected.
    Must use the distinguished name format, for example: "OU=ComputerGroups,OU=MyOrganisation,DC=MyDomain,DC=Local"

.PARAMETER ADGroupNamePrefix
    A prefix that will be added to the name for the AD group, if one is being created. By default the group will be called "<prefix><Name of Application>" but can be manually edited in the GUI.

.PARAMETER CreateApplicationFolder
    If this is set to $true an Application folder will be created and the Application will be moved to that folder. If set to $false, no folder will be created and the Application will be placed in the root.
    
.PARAMETER ApplicationFolderName
    The name of the Application folder where the application will be placed. By default, if an Application folder is created it will be named by the publisher of the application (i.e. Microsoft). If you wish a different name, specify it here. If you leave this empty, and also leave the publisher/manufacturer empty, then no folder will be created.

.PARAMETER CollectionFolderName
    The name of the collection folder where the new collection, if one is being created, will be placed. If you leave this blank, no folder will be created and the collection will be created in the root.

.PARAMETER DeviceLimitingCollection
    The name of a limiting collection for the new device collection, if one is being created.

.PARAMETER UserLimitingCollection
    The name of a limiting collection for the new user collection, if one is being created.

.PARAMETER RunInstallAs32Bit
    If set to $true, and if an MSI or manual deployment type is being created, the option to run the installation as a 32-bit process on 64-bit systems will be enabled.
    This flag will automatically be set to true if button "Use PADT" is clicked.
    The default behavior is $false.

.PARAMETER DownloadOnSlowNetwork
    This parameter determines the behavior for clients on a slow network, and will change the option on MSI- and manual deployment types. For App-V applications, use the parameter StreamAppVOnSlowNetwork.
    If set to $true, the deployment type will be configured to "Download content from distribution point and run locally" for clients on a slow network.
    If set to $false, the deployment type will be configured to "Do not download content" for clients on a slow network. This is the default behavior.

.PARAMETER AllowFallbackSourceLocation
    This parameter enables or disables the option "Allow clients to use a fallback source location for content" on the deployment type.
    The default behavior is to not enable this option.

.PARAMETER StreamAppVOnFastNetwork
    This parameter determines the behavior for App-V applications for clients on fast networks.
    If set to $false, the client will download the App-V application and run it locally. This is the default behavior.
    If set to $true, the client will stream the App-V application from the distribution point.

.PARAMETER StreamAppVOnSlowNetwork
    This parameter determines the behavior for App-V applications for clients on slow networks.
    DoNothing - The client will not run the application. This is the default behavior.
    Download - The client will download the App-V application and run it locally.
    DownloadContentForStreaming - The client will stream the App-V application from the distribution point.

.PARAMETER PADTInstallProgram
    This parameter contains the command line that will replace the installation program if the button "Use PADT" is clicked.
    If you leave this empty, the installation program will remain unchanged when the button "Use PADT" is clicked.

.PARAMETER PADTUninstallProgram
    This parameter contains the command line that will replace the uninstall program if the button "Use PADT" is clicked.
    If you leave this empty, the uninstall program will remain unchanged when the button "Use PADT" is clicked.

.EXAMPLE
    Run the script on a site with site code "S01":
        
    .\Create-Application.ps1 -SiteCode "S01"

.EXAMPLE
    Run the script on a site with site code "S01" and the domain NetBios name is "MyDomain":

    .\Create-Application.ps1 -SiteCode "S01" -DomainNetBiosName "MyDomain"

.EXAMPLE
    Run the script without creating an Application folder . The Application will be created in the root.

    .\Create-Application.ps1 -CreateApplicationFolder $false

.EXAMPLE
    Run the script and create a collection folder called "MyCollectionFolder". Create a collection and move it to that folder.

    .\Create-Application.ps1 -CollectionFolderName "MyCollectionFolder"
#>

# Parameters
[CmdletBinding()]
param(
	$SiteCode = "S01",
	$DPGroup = "All DPs",
	$DomainNetbiosName = "MYDOMAIN",    
	$UserOUPath = "OU=Application Groups,OU=User Groups,DC=MYDOMAIN,DC=LOCAL", 
    $DeviceOUPath = "OU=Application Groups,OU=Computer Groups,DC=MYDOMAIN,DC=LOCAL",    
	$ADGroupNamePrefix = "APP-",
	[bool]$CreateApplicationFolder = $true,
	$ApplicationFolderName = "",
	$CollectionFolderName = "Applications",   
	$DeviceLimitingCollection = "All Systems", 
    $UserLimitingCollection = "All Users and User Groups",
	[bool]$RunInstallAs32Bit = $false,
    [bool]$DownloadOnSlowNetwork = $false,
    [bool]$AllowFallbackSourceLocation = $false,
    [bool]$StreamAppVOnFastNetwork = $false,
    [parameter()]
    [ValidateSet("DoNothing", "Download", "DownloadContentForStreaming")]
        $StreamAppVOnSlowNetwork = "DoNothing",
    $PADTInstallProgram = "Deploy-Application.exe",
    $PADTUninstallProgram = "Deploy-Application.exe Uninstall"
)

# We set the RunInstallAs32Bit parameter to a global variable, because it can be modified in multiple functions
[bool]$global:RunInstallAs32Bit = $RunInstallAs32Bit

#region Script Settings
#<ScriptSettings xmlns="http://tempuri.org/ScriptSettings.xsd">
#  <ScriptPackager>
#    <process>powershell.exe</process>
#    <arguments />
#    <extractdir>%TEMP%</extractdir>
#    <files />
#    <usedefaulticon>true</usedefaulticon>
#    <showinsystray>false</showinsystray>
#    <altcreds>false</altcreds>
#    <efs>true</efs>
#    <ntfs>true</ntfs>
#    <local>false</local>
#    <abortonfail>true</abortonfail>
#    <product />
#    <version>1.0.0.1</version>
#    <versionstring />
#    <comments />
#    <company />
#    <includeinterpreter>false</includeinterpreter>
#    <forcecomregistration>false</forcecomregistration>
#    <consolemode>false</consolemode>
#    <EnableChangelog>false</EnableChangelog>
#    <AutoBackup>false</AutoBackup>
#    <snapinforce>false</snapinforce>
#    <snapinshowprogress>false</snapinshowprogress>
#    <snapinautoadd>2</snapinautoadd>
#    <snapinpermanentpath />
#    <cpumode>1</cpumode>
#    <hidepsconsole>false</hidepsconsole>
#  </ScriptPackager>
#</ScriptSettings>
#endregion

#region ScriptForm Designer

#region Constructor

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

#endregion

#region Post-Constructor Custom Code

# The version of the script (displayed in the GUI)
$ScriptVersion = "2.0"

# Import the SCCM powershell module
$CurrentLocation = Get-Location
Import-Module(Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
Set-Location($SiteCode + ":")

#endregion

#region Form Creation
#Warning: It is recommended that changes inside this region be handled using the ScriptForm Designer.
#When working with the ScriptForm designer this region and any changes within may be overwritten.
#~~< Form1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$Form1 = New-Object System.Windows.Forms.Form
$Form1.ClientSize = New-Object System.Drawing.Size(689, 502)
$Form1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$Form1.MaximizeBox = $false
$Form1.MinimizeBox = $false
$Form1.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$Form1.Text = "SCCM Application Creator"
$Form1.BackColor = [System.Drawing.SystemColors]::Control
$Form1.Icon = [System.Convert]::FromBase64String('
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aACze20As39vALZ/bgCpe3AAtn5wALl/cgDBfF8Awn5iALWCZQC4gGYAsoFqALSCbgC6hGoAvIhvAK2CdwCxgnMAt4VyALWCdAC4gXEAu4V1AL2GdwC1iXAAvIlxALqKdwC9iXUAuo53AL+NdAC8iXkAvI56AL2MfQC8kXsAu5F9AMSAYwDAj3UAyox0AMOTewDHmH4As4uBALeQhwC/koEAv5eAALOUjAC4kooAv5mIALqbkwDCkYAAxJeBAMWShADAmYIAx5mBAMWZhQDDnYYAyJqBAMqcgwDKnoUAxpmJAMOeiADEn4kAyp+KAMyghwDHoo0AyqCIAMyiiQDOpIsAyqKMAM6kjQDPqI8A0KaOANCojwDMoZQAyKaXAM6llQDPq5YAyqmZAM+tmgDKqpwA1aaVANGpkQDRqpYA16iVANKslADUrpYA066bANWxmgDOr6AAz7KpANO0oQDauaUA27yrANa/uQDdwK8A3sKyANrEuQDgxbQA4cm3AOXHugDiy7sA5dDAAOHRzQDp1cgA6tjLAObY0gDn2dUA6NvVAOzh3gDu5eMA8+fiAPLp5QDy6+kA9/PyAPj08wD49fQA+/n4APz6+gD///8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABLJCEhISEhISEhISEhISEhISEhISEhISRLAAAAAACcfavGxqaiorW9xuPXyb2ioqKioqKioqKiopdtgAAAAIyrgGiIiH2IakRafZeiqal9RERERERERERFbZdttgBjfat9bTUyRG1tbaJaWlpabX2rbTIyMjIyMjIySYhIACupWh0kWlo3GxsygF56Y21EakiXnWMbGxsdGxsdfSQAIXptNzIEBBIXHRACAgIBBxQCAgIhNVghCAgSEhJ6IQAhtQwIFSH//////////7ey////////////dwcICGMhACGOGyQbAv89PT09PT09Hf/////////////2GwcCWiEAIZwIAgIC/z09PT09PTpH//////////////ohHQJhIQAhVgQEBAH/PT09PT09Okr/////////////+iQMF2EhACFmBwcHAv89PT09PT06Sv/////////////6CDEWkiEAIYwNDQ0C/z09PT09PTpK///////6//////odIRe8IQAhkhcWFgL/PT3//z3/+yr/////+fX6////8ysYQaEhACGdISEhAv89Pf//Pf//IbP//+YMFXf///qQKztBvCEAIZ0xMTEC/z09PT09PT09MEabFQcHByuQKlYxejHSIQAhoTo2NgL/PT09PT09PT09sge37/rvtwwrijeKO9IkACGpRjs7Af89Pf//Pf//PT12t///////txhWikGExCEAIbRBQUEC/z09//89//89PR3v///////vDFaMV5LGIQAhvGFhVgL/PT09PT09PT09B/z///////8CYZFmndshACHKaWleA/9PTz9PPT8/T1FI7///////7zemw8PD6yEAIctycnIJ/z9S//9S//9wcdjY///////jiK/D28PwIQAhy3Nyhgn/UlL//3D//3Fx+CTW9P/0122wwcHgw/EhACTUhoaGCf9SUmdnZ3BwhpP/J25OQmiVsMPDyuDe8CEAIduGlpYK/1JnZ3BwcJN0k/8nwcHDw8PLy8zM4OXsJAAh35aWmgr/1K+TcHB0k5OU/0LDw8PLy8vM1NHR5OwkACHhp6aaEeL0+v/37NyvlK3/QsrLy9TR29Hb0dvk7CQAK9+np6dMIx0fWrzp+P////9MzNTR29vR297e3uXsJABj28OnsLCwsJqIWkInJ0JCWELb0dvb3t7e3t7e6utJAACm38u8wcHDw8PKy8vL28/P29ve3t7e3t7e4OTuvbkAAJ2m3+Xl5efn6Ojo7Ovr6+zt6+7s7u7u7u7r5bCAAAAAAAB/KyQhISEhISEhISEkJCAkICQgICQgJCd9AAAAAP/////gAAAPgAAAA4AAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABgAAAAYAAAAPgAAAPKAAAABAAAAAgAAAAAQAIAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAEAAAAAAAB0LRMAdi8VAHYwFgB4MxsAazcsAGw5LQB6NSAAfTYmAHk6LAB6PC4Abj0xAH5SSAB/VEoAgj8lAIA6KgCAPSkAgDssAII+LQCDQC8AjEEqAItFKwCORC0Ag0AwAIRCMgCGRjYAjUc2AIpMPgCPTj4Alk42AJFOPACVWD8AkVBBAJdWRgCRVkkAm15OAJ5d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Lf+oblr/kE088gAAACMAAAAaAAAACJFOPP+eZFP/fDYk/5FPPP+bW0j/ikUz/3s0I/+IQzL/k1E//41JN/97NCP/fzkn/5FPPP+TUT//gTop/3s0I/97NCP/ezQj/3s0I/97NCP/ezQj/3s0I/97NCP/ezQj/3s0I/97NCP/ezQj/3s0I/97NCP/ezQj/3s0I/97NCP/hD8s/4dDMf+cXEr/ikY0/5FPPP+PTDr/ezQj/3s0I/97NCP/ezQj/344J/+kaVf/kE088gAAACMAAAAaAAAACJFOPP+0f3H/kU07/3wzI/+NRzX/jEc1/5FNO/+EPi3/eC8f/4E6Kv+PTDj/ikQz/3gvH/94Lx//eC8f/3gvH/94Lx//eC8f/3gvH/94Lx//eC8f/3gvH/94Lx//eC8f/3gvH/94Lx//eC8f/3gvH/94Lx//eC8f/3gvH/94Lx//eC8f/45JN/+PTDj/h0Ew/49KOP+IQzD/jUc1/3gvH/94Lx//eC8f/3szI/+jZVT/kE088gAAACMAAAAaAAAACJFOPP+eX0//fDMj/49KOP+dXEj/fjUl/3gvH/+IQzD/jkk3//79/f/+/f3//f38//39/P/8+/v//Pv7//z7+//8+vr//Pr6//v5+P/7+fj/zrOs/5ljV/+BPC3/fTcn/3w2Jv98NSX/ezQk/3s0JP96MyP/ejIi/3kxIf95MSH/eTAg/384J/+STzv/jkk3/3oxIf+PSjj/kU07/341Jf94Lx//eC8f/3szI/+jZVX/kE088gAAACMAAAAaAAAACJFOPP+yfW//jUc1/3gvH/+PSjj/jkk3/41HNf9+NSX/eC8f//////+uXUz/rl5N/65eTf+vX0//r19P/69fT/+vYE//r2BP/7BhUf+USzv/pHJn/+PT0P/8+vr////////////////////////////////////////////p3dv/vJmR/3w1Jf+PTDj/ezIi/41HNf+JQzL/fTUk/5FMOv94Lx//eC8f/3szI/+kZlX/kE088gAAACMAAAAaAAAACJFOPP+gYVL/gzsq/5FNO/+TTj3/fDIj/3owIf96MCH/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/rVxL/5VMO/+whnz//////////////////////////////////////////////////////////////////////93Kxf+LRjb/gDgp/5FNO/96MCH/kU07/4lCMv+GPi3/ejAh/300Jf+mZ1f/kE088gAAACMAAAAaAAAACJFOPP+1gHL/j0k4/3wyI/98MiP/fDIj/3wyI/98MiP/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/qlpJ/4tMP//59vX///////////////////////////////////////////////////////////////////////////+md2z/lVFA/4M7K/+LRDT/j0o5/340Jf+VUD//fDIj/382J/+naVr/kE088gAAACMAAAAaAAAACJFOPP+kZVb/fzUm/381Jv9/NSb/fzUm/381Jv9/NSb/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/oVRD/6d4bf/////////////////////////////////////////////////////////////////////////////////KrKb/lFE//381Jv+UTz//gDcn/5JNPf+WU0L/hT0u/4E5Kv+qbFz/kE088gAAACMAAAAaAAAACJFOPP+naFr/gjgp/4I4Kf+COCn/gjgp/4I4Kf+COCn/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/n1NC/66Eev/////////////////////////////////////////////////////////////////////////////////QtrD/j0g4/4tENP+WUkP/gzoq/5VRQf+VUUH/mVZG/4Q8Lf+sb17/kE088gAAACMAAAAaAAAACJFOPP+pbF7/hTwt/4U8Lf+FPC3/hTwt/4U8Lf+FPC3/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/n1ND/6+Ee//////////////////////////////////////////////////////////////////////////////////RtrH/fjYm/5tYSf+KQjP/lE9A/5RPQP+cWkr/nVtM/4dAMf+ucWP/kE088gAAACMAAAAaAAAACJFOPP+scWH/iUEx/4lBMf+JQTH/iUEx/4lBMf+JQTH/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/n1RD/6+Fe//////////////////////////////////////////////////////////////////////////////////Rt7H/gDgo/5tZSf+JQTH/mldI/5VQQP+iYlH/kk08/5hXR/+xd2f/kE088gAAACMAAAAaAAAACJFOPP+vdGb/jUU2/41FNv+NRTb/jUU2/41FNv+NRTb/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/n1RD/7CGe//////////////////////////////////////////////////////////////////////////////////Rt7H/gToq/51aS/+ORzj/nVtN/6FgUf+hYVL/jUU2/6RlWP+0emv/kE088gAAACMAAAAaAAAACJFOPP+yeWr/kUo6/5FKOv+RSjr/kUo6/5FKOv+RSjr/eC8f//////+tXEv/rVxL////////////rVxL////////////n1RE/7CGfP/////////////////////////////////////////////////////////////////////////////////Rt7L/gzws/5ROP/+dWUr/mlZG/6doWP+jYlP/lE09/6dqWv+2f27/kE088gAAACMAAAAaAAAACJFOPP+1fW3/lU4+/5VOPv+VTj7/lU4+/5VOPv+VTj7/eC8f//////+tXEv/rVxL////////////rVxL////////////o1ZG/6V1av/////////////////////////////////////////////////////////////////////////////////Hp6D/h0Aw/5VOPv+lZFT/pmZX/6lqWv+ZVET/qGhZ/6BeT/+/jH3/kE088gAAACMAAAAaAAAACJFOPP+3gXL/mFJD/5hSQ/+YUkP/mFJD/5hSQ/+YUkP/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/rFxL/4lKO//y6+r///////////////////////fz8v/Lrqf/fjgp/8uup//38/L///////////////////////////+bZFj/kkw9/5hSQ/+oaVv/q2xe/6tsXv+YUkP/q21f/5pVR//ImYv/kE088gAAACMAAAAaAAAACJFOPP+6hnb/m1ZG/5tWRv+bVkb/m1ZG/5tWRv+bVkb/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/rVxL/5tSQf+icWX/+PTz/////////////////8Ggmf94Lx//eC8f/3gvH//BoJn//////////////////////7yZkP+KRTX/m1ZG/5tWRv+vc2T/n1xM/61wYf+bVkb/rG9g/51ZSv/LnY//kE088gAAACMAAAAaAAAACJFOPP+7iXn/nVpK/51aSv+dWkr/nVpK/51aSv+dWkr/eC8f//////+tXEv/rVxL////////////rVxL////////////rVxL//////+/nZX/k1lM/8Ojm//dy8X/2sXA/6BsYP+CQDH/ezUl/4E9Lv+eaV7/2MO+/+PU0f/KrKX/nGdb/4tIOP+bWEj/nVpK/51aSv+kY1T/p2lZ/6lrXP+jY1P/rG9g/6JhUv/LoJH/kE088gAAACMAAAAaAAAACJFOPP+9i3v/n1xM/59cTP+fXEz/n1xM/59cTP+fXEz/eC8f//////+tXEv/rVxL////////////rVxL////////////rVxL////////////qVpJ/5lRQf+fa17/j1NF/7yYkP/i08//+/r5/+LSzv+6lY3/i0w+/4VAMP+OSzv/mFVF/59cTP+fXEz/n1xM/59cTP+fXEz/sHVn/59dTf+vdGT/oV9P/7F2Z//InY//kE088gAAACMAAAAaAAAACJFOPP++jn7/oV5O/6FeTv+hXk7/oV5O/6FeTv+hXk7/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/rVxL/6dYR/+RVUf/07m0////////////////////////////0bex/4tMPv+cWEj/oV5O/6FeTv+hXk7/oV5O/6FeTv+hXk7/sndo/6FeTv+xdWb/oV5O/7N5av/NpZX/kE088gAAACMAAAAaAAAACJFOPP/AkYH/o2FR/6NhUf+jYVH/o2FR/6NhUf+jYVH/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/rVxL/5hOPv+9m5L//////////////////////////////////////7qVjf+PSzv/o2FR/6NhUf+jYVH/o2FR/6NhUf+jYVH/s3pr/6NhUf+yd2n/o2FR/7R6bP/Op5f/kE088gAAACMAAAAaAAAACJFOPP/El4L/p2hT/6ZmU/+lZVP/pWVT/6VkU/+kZFT/eC8f//////+tXEv/rVxL////////////rVxL////////////rVxL////////////rVxL/4xHN//j1dH//////////////////////////////////////+LSzv+EPy//pGRU/6RkVP+kZFT/pGRU/6RkVP+lZFP/tX1s/6ptWv+6hXT/snhj/8qcif/VsZ//kE088gAAACMAAAAaAAAACJFOPP/Im4P/rW5T/6xuU/+sbVP/q21U/6trVP+ra1T/fTQd//////+xYEn/sF9K////////////rl1J////////////rl1K////////////rlxK/4VDNP/8+vn///////////////////////////////////////v6+f+EPyv/r3Rf/7B0Yf+yd2P/tX1n/7qEbv+9i3P/yZmC/8qbhf/KnYX/yZuB/9e0nv/cuqf/kE088gAAACMAAAAaAAAACJFOPP/Kn4f/r3JW/69yVv+vclb/r3JW/69yVv+vclb/gTkc//////+2ZUj/tmdJ/7doSv+2aUz/t2pN/7hqTv+4a1D/uGxR/7lsU/+5bFP/uW1S/5xcQ//o2tX//////////////////////////////////////+nc1v+mbFL/wI1z/8GOdP/CkXX/wpF3/8SSeP/Dk3n/xJZ7/9Cokf/Fl3z/0amR/9Kpk//gxbL/kE088gAAACMAAAAaAAAACJFOPP/MoYv/sXVZ/7F1Wf+xdVn/sXVZ/7F1Wf+xdVn/gTkc//////+2Z0n/t2hK/7dpS/+4akz/uWpN/7lsT/+6bVD/um5R/7twUv+7cVP/u3NV/6xqTv/MrJ3//////////////////////////////////////86voP+yfGD/wpF2/8OSeP/Ek3n/xJV7/8WVfP/Flnz/x5h9/9Krlf/Imn//2rmm/8uehP/hybb/kE088gAAACMAAAAaAAAACJFOPP/No43/snZc/7J2XP+ydlz/snZc/7J2XP+ydlz/gTod//////+3aEr/t2lL////////////uWxP////////////u3BS////////////vHNX/7lzVv+ndV7/3Me+////////////////////////////38q//6x7Y/+/jnT/w5R6/8SWfP/Fl33/xZd+/8eZf//ImYD/yZqB/9OtmP/KnIP/2bei/8ygh//iyrj/kE088gAAACMAAAAaAAAACJFOPP/OpZH/tHlf/7R5X/+0eV//tHlf/7R5X/+1emD/gjse//////+3aUv/uGpM////////////um1Q////////////u3FT////////////vXVY/753Wf/o29X/rHph/86wof/q3dj//fv5/+re1//QsqP/rn1l/7uMcv/El3z/xZd+/8eYf//Im4D/yZuC/8mbgv/KnIP/y52E/9Svmf/RqZL/2bah/86jiv/izLr/kE088gAAACMAAAAaAAAACJFOPP/Pp5X/tXxi/7V8Yv+1fGL/tXxi/7d+Yv+2fmP/gzwf//////+4akz/uWpN/7lsT/+6bVD/um5R/7twUv+7cVP/u3NV/7xzV/+9dVj/vndZ/795XP//////l1k7/7J/ZP+odFj/o21Q/6t2Wv+2gmj/wJJ4/8eYf//HmYD/yZqB/8mcg//KnYT/y56F/8ufhv/MoIf/zKGI/9aynf/Wspz/17Kc/8+ljP/jzb3/kE088gAAACMAAAAaAAAACJFOPP/QqZb/tn5k/7Z+ZP+2fmT/tn9k/7eAZf+4gWb/hD0i//////+5ak3/uWxP/7ptUP+6blH/u3BS/7txU/+7c1X/vHNX/711WP++d1n/v3lc/8B7Xf//////l1g7/8OUev/Elnz/xZd9/8eXfv/ImH//yJmA/8ibgv/JnIP/yp2E/8qfhv/Ln4f/zKGH/8yhif/No4n/zqOK/9Wwmv/Vspv/1K+X/9Kokf/hyrv/kE088gAAACMAAAAaAAAACJFOPP/Rq5n/uIFn/7iBZ/+4gmf/uYJo/7qDaf+6hGr/hT4j//////+5bE//um1Q/7puUf+7cFL/u3FT/7tzVf+8c1f/vXVY/753Wf+/eVz/wHtd/8F8X///////mFo9/8eYfv/HmYD/yJqB/8magv/KnIP/yp2E/8qfhv/LoIf/zKCJ/8yjiv/No4r/zqSL/86jjP/PpYz/z6WN/9Opk//WsZ3/0aaQ/9aynf/gxbb/kE088gAAACMAAAAaAAAACJFOPP/SrZv/uoRq/7qFav+7hWv/u4Zs/7yHbf+8iG3/hkAk//////+6bVD/um5R/7twUv+7cVP/u3NV/7xzV/+9dVj/vndZ/795XP/Ae13/wXxf/8J9Yf//////mVw//8mbgv/KnIT/y52E/8ufhv/Mn4j/zKGI/82hiv/NpIv/zqWM/8+mjf/PpY3/0KaO/9Cmjv/QqI//0amQ/9GpkP/Zt6L/0amQ/9i2ov/gxbj/kE088gAAACMAAAAaAAAACJFOPP/Srp3/u4ds/7yHbf+8iG//vYlw/72KcP++i3L/hkIl/////////////Pn3//nz7//y5d//7NfR/+PBtP/dtaT/zZV//8yRe//BfF//wn1h/8N/Yv//////ml5A/8qfhv/Ln4b/zJ+I/82iif/No4r/zaSL/86ljP/PpY7/z6aO/9Cnj//QqI//0amQ/9Gokf/RqZH/0amR/9Gpkf/Zt6P/0amR/9m3o//hyLn/kE088gAAACMAAAAaAAAACJFOPP/UsZ//vYpx/72Lcv++jHP/vo1z/7+OdP/Aj3X/iEMn/5leRP+ncl3/uo9//8+ypv/ezMP/7d/b//fx7f/7+Pf///7+//38/P///////v39//v18f//////nGBD/8yiif/No4r/zaOL/86kjP/OpY3/z6aP/8+nkP/QqJH/0KmR/9Gqkv/Sq5L/0quT/9Krk//Sq5P/0quT/9Krk//ZuaT/0quT/9q6pf/hybv/kE088gAAACMAAAAZAAAACJFOPP/Ws6D/v41z/8COdf/AjnX/wZB2/8GRd//Cknj/u4hu/7WAZf+veV7/qnJX/6VrUP+gZEj/m15C/5dYPf+UVDf/mFo8/6JqT/+sfGX/vZWC/9G2qf/Zwbb/nmJF/86ki//PpI3/0KWO/9Cmj//QqZD/0aiR/9Gqkv/SqpP/0quU/9OslP/TrJT/1K2V/9Stlf/UrZX/1K2V/9Stlf/cvKf/1K2V/9u7p//iyrv/kE088gAAACEAAAAWAAAABpFOPPnWsqH/wpF4/8GQd//CkXj/wZF5/8KUev/Dk3v/w5V7/8SWfP/Fln7/x5d//8eYgP/ImoL/yJuD/8mchP/Jm4P/xJZ9/7+ReP+7i3H/toVq/7J+ZP+zgGX/tIJm/9Cmjv/QqI//0aiR/9Gqkf/RqpP/0quT/9KslP/TrJX/062W/9Sulv/Urpb/1K6W/9Sulv/Urpb/1K6W/9Sulv/cvKj/1K6W/9y+qv/hybv/j0077QAAAB0AAAAPAAAABJFOPNLRq5r/yJuG/8KSev/Ck3v/w5R8/8OVff/Eln3/xZZ+/8eYgP/HmYH/yJqC/8mbg//JnYT/yZ6G/8qeh//Lnoj/zKGK/82ji//No4z/zqWN/8+mjv/Qp4//0aiQ/9Gokf/SqZL/0qqT/9KrlP/TrJX/062W/9Sul//Ur5f/1K+Y/9WwmP/VsJj/1bCY/9WwmP/VsJj/1bCY/9WwmP/cvan/1bCY/+HHtP/Yuqn/jEs6ygAAABMAAAAHAAAAAZFOPHW9inT/1LCe/8uijP/Fl3//xJd//8WYf//HmID/x5qB/8ibgv/JnYX/yp6G/8qfh//KoYj/y6GJ/8yiiv/NpIv/zqWM/86ljv/Ppo//0KeQ/9Cpkf/RqZH/0qqT/9Krk//TrJX/062V/9Oul//Urpf/1K+Y/9Wwmf/VsJn/1bGa/9Wxmv/VsZr/1bGa/9Wxmv/VsZr/1bGa/9Wxmv/dv6v/3Lyn/+XQwv+5hnT/hUc3bwAAAAcAAAABAAAAAJFOPAOdWke3u4Zy/86rm//Xuav/2buu/9q8rv/bva7/276v/9u+sP/cv7H/3cCy/93Bsv/dwbP/3sG0/9/Ctf/fw7b/38S2/+DFt//gxbf/4ce4/+HIuf/iyLn/4sm6/+LKu//iyrv/4su8/+LLvP/jy73/48u9/+TMvv/kzL7/5My+/+TMvv/kzL7/5My+/+TMvv/kzL7/5My+/+TMvv/kzsL/2Lur/7mHcf+UU0CqAAAAAwAAAAEAAAAAAAAAAAAAAAAAAAAAkU48Y5FOPMORTjz2kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjzzkU48wJFOPFoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOAAAAAAAwAAwAAAAAABAACAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAMAAMAAAAAAHwAA////////AAD///////8AACgAAAAgAAAAQAAAAAEAIAAAAAAAgBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAASAAAAIwAAAC0AAAAuAAAALgAAAC4AAAAuAAAALgAAAC4AAAAuAAAALgAAAC4AAAAuAAAALgAAAC4AAAAuAAAALgAAAC4AAAAuAAAALgAAAC4AAAAuAAAALgAAAC4AAAAtAAAAIwAAABIAAAAAAAAAAAAAAAAAAAABeEEyd4lKOc6QTjz6kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kE48+olKOc5xPS9/AAAALgAAACAAAAABkU48A5haR8GveWT/vJF7/8Sfiv/Dnoj/uY93/7aKcf+2inH/v5eA/8CZgv/En4n/07Sh/8+tmv/Hoo3/w52G/7aKcf+2inH/topx/7aKcf+2inH/topx/7aKcf+2inH/topx/7aKcf+1iXH/soFp/6tzXf+MTz7DCQUEMAAAABWRTjx1sX1o/7uRfP+vf2n/o21T/7F/Z/+xf2f/rn1k/69+Zv+nclr/nmVL/6JrUf+vfmb/sH5n/7aIcP+6jXf/u453/617Y/+eZUv/nmVL/55lS/+eZUv/nmVL/55lS/+eZUv/nmVL/59nTf+pdl//soJr/6hvWf93QDGOAAAAJpFOPNKve2X/u5F+/6t2YP+pdV7/mF1G/5VZQf+cYkv/qXRd/6l0Xf+pdV7/t4dz/6JrVP+ia1T/omtU/6JrVP+pdV7/r3xn/7yOev+pdV7/lVlB/5VZQf+VWUH/lVlB/5VZQf+VWUH/lVlB/5VZQf+faFL/sHxm/4xLOtoAAAAtkU48+bqKd/+ka1f/jU03/5NVP/+haVP/o2tV/5pfSf+NTTf/jU03/5daRf+teWT/o2lV/6hyXv+kbFj/qHJe/5xgS/+ncFv/n2RP/7SCbv+3hHH/pWxY/4xLNv+LSjT/jEw2/41NN/+NTTf/jU03/45POf+vemX/kE48+gAAAC6RTjz/qnVh/6hwW/+cX0v/lVdD/3gvH/94Lx//h0Av/4tGM/+PTDj/hT4t/3gvH/94Lx//eC8f/3gvH/99Nyf/g0Aw/3gvH/94Lx//eC8f/5NPPf+aWEX/pGVR/5JPO/99Nyf/fjgm/4VCLv+FQi7/hUIu/6t0YP+RTjz/AAAALpFOPP+/k4L/gTwp/345Jv+FQi//k089////////////////////////////////////////////uJKK/7OLgf/+/f3///////////////////////////////////////z5+f+kcWX/fDUk/345Jv9+OSb/p25a/5FOPP8AAAAukU48/7N/b/+NSjf/lFE+/41KN/94Lx///////61cS/+tXEv/rVxL/61cS/+tXEv/rVxL/6taSv+KTD3//Pv6/////////////////////////////////////////////////+7l4/+MSDX/ejIh/3oyIf+maVf/kU48/wAAAC6RTjz/toJ0/384J/94Lx//eC8f/3gvH///////rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/plhH/5pjV///////////////////////////////////////////////////////+PT0/5FPPP+RTDr/eC8f/6VnVv+RTjz/AAAALpFOPP+gYVL/eS8g/3kvIP95LyD/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+mWEf/mmRY///////////////////////////////////////////////////////49fT/klA//4M7K/+JQzP/p2dY/5FOPP8AAAAukU48/6xuX/99MyT/fTMk/30zJP94Lx///////61cS/+tXEv/rVxL/61cS/+tXEv/rVxL/6ZYR/+aZlj///////////////////////////////////////////////////////n29f98NiX/l1ND/4hBMP+5f3L/kU48/wAAAC6RTjz/tXlp/4Q6K/+EOiv/hDor/3gvH///////rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/plhH/5tmWf///////////////////////v39//j09P//////////////////////9/Py/49MOv+UTz//jkY3/8WShP+RTjz/AAAALpFOPP+5gHD/i0Mz/4tDM/+LQzP/eC8f//////+tXEv/rVxL////////////rVxL///////49PP/jlFD//v5+P/////////////////y6+n/7OHe//r39//////////////////n2tf/llVF/4tDM/+hYFD/vYZ3/5FOPP8AAAAukU48/7uFdf+STDz/kkw8/5JMPP94Lx///////61cS/+tXEv///////////+tXEv///////////+YUED/t5CH//79/f//////1r+5/4M+Lv+DPi7/o3Bk////////////+fb1/6p6b/+UUUL/nl1N/6FfUf/CkYD/kU48/wAAAC6RTjz/uINz/5lURP+ZVET/mVRE/3gvH///////rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+XUED/mGBT/62Cd/+FQjP/fTYm/3kwIP99Nib/kFNG/6l7cP+MT0H/oGJS/5lURP+tcWL/mVRE/8yhlP+RTjz/AAAALpFOPP+8iXn/nlpK/55aSv+eWkr/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+zi4L/ejIj/7mTi//h0c3/+/n5/+HRzf+5k4v/gjsr/5dSQv+vc2X/nltL/7F2aP+fXEz/zqWW/5FOPP8AAAAukU48/72Mff+gXU3/oF1N/6BdTf94Lx///////61cS/+tXEv///////////+tXEv///////////+tXEv/rVxL/59sYf+5k4v///////////////////////////+5k4v/jUc3/6RjU/+wdGX/pGNT/7B0Zf/HmYr/kU48/wAAAC6RTjz/v5GB/6JhUf+iYVH/omFR/3gvH///////rVxL/61cS////////////61cS////////////61cS/+tXEv/iUk7/+HRzf///////////////////////////+HRzf+BOir/omFR/7N7bf+iYVH/tn5w/8WZiP+RTjz/AAAALpFOPP/El4P/pmZT/6ZmVP+mZVT/eC8f//////+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/+tXEv/rVxL/61cS/96MiL/+/n5////////////////////////////+/n5/3owH/+mZlT/tn9u/6psWf+9iXX/0KuX/5FOPP8AAAAukU48/8meh/+tcVf/rG9X/6xuWP99NB3//////7FgSf+wYEv/sWFL/7BfS/+vX0z/r19M/7BgTf+wX0z/sGFO/5piVP/i0s7////////////////////////////m2NL/m15H/72Jc//Kn4r/yp6E/8mbg//iy7f/kU48/wAAAC6RTjz/zKGL/7F1Wf+xdVn/sXVZ/4E5HP//////tmZI/7doSv///////////7psT////////////7tyVv+9c1j/yqqc/8iml////////////////////////////86voP+zf2P/xZZ8/8eYff/Vrpn/yZqB/+rZy/+RTjz/AAAALpFOPP/OpI//s3dd/7N3Xf+zd13/gTkc//////+3aEr/t2lM////////////um5R////////////vXRX/753Wf/y6ub/lVU5/8qpmf/o29T//Pr6/+nc1v/Or6D/rXhc/8KTef/ImYD/ypuC/9Wxmv/Ln4b/6tjM/5FOPP8AAAAukU48/8+mlP+2e2H/tnth/7Z7Yf+COR7//////7dpTP+5ak3/umxP/7puUf+7cFP/u3NV/710V/++d1n/v3pd//////+XWTz/rnhd/6RrTv+fZEb/p3BT/7WCZf/ElXv/y52E/8ufhv/MoIf/17We/9Stl//p1cj/kU48/wAAAC6RTjz/0aqX/7d/Zf+3f2X/uIBm/4M8H///////uWpN/7psT/+6blH/u3BT/7tzVf+9dFf/vndZ/796Xf/BfF///////5lcP//HmH//yJmA/8mbgv/KnIT/y5+H/8yhiP/Noon/zqOK/8+ki//Vr5n/3b2q/+PLvP+RTjz/AAAALpFOPP/SrJv/uYNp/7qEav+7hWv/hT0j///////VppX/yYx1/754XP+7c1X/vXRX/753Wf+/el3/wXxf/8J+Yv//////m2BB/8qcg//Ln4b/y6GI/8yiiv/NpIv/zqSM/8+ljf/Qpo7/0KiP/9Coj//ZuKP/4sq8/5FOPP8AAAAukU48/9Kvnv+8iG//vIlw/72Kcf+GQCT/z7Kp/+fZ1P/59fT//fv7//Pn4v/lx7r/16iV/8uNdP/CfmL/xIBj//////+eYkX/zKKJ/82ji//OpI3/z6aO/8+oj//QqJD/0amR/9Gpkv/RqZL/0amS/9u6pv/jzL3/kU48/wAAAC2RTjz51K+f/7+NdP+/jXT/wI91/59hRf+VVTn/jUsv/5BPMv+jbFX/v5mI/9rEuf/y6OT//////////////////////6BlR//PpY3/z6aP/9CpkP/RqZL/0quT/9Krk//TrJT/06yU/9OslP/TrJT/3b2p/+PMvv+QTjz6AAAAJpFOPNLPq5b/x5mC/8KReP/Dk3n/w5N7/8SUfP/DlHz/vIty/7F7YP+lbFH/nGBD/5dZPP+ZXD//m2BB/55iRf+gZUf/oWdJ/9Gokf/RqpP/0quU/9Oslf/Trpb/1K6W/9Sulv/Urpb/1K6W/9Sulv/gxbP/38W0/4xLOtoAAAAVkU48db+Odf/UsJ3/yqKM/8SXgP/Fl3//x5mA/8ibgv/JnYX/yZ6H/8mfh//KoIn/zKKL/86ljf/PqI//0KiQ/9Gpkv/Sq5P/0qyV/9Otlv/Ur5f/1K+Y/9Wxmf/VsZn/1bGZ/9Wxmf/VsZv/27um/+XQwP/FmYX/fkM0hwAAAAGRTjwGnFlGvb2Jcf/PrZv/2bqr/9y+rf/cv67/3cCv/97BsP/ewrL/38Oz/+DEtP/hxbX/4ce2/+HJt//iybf/4su5/+LLuf/iy7r/48y7/+PNvP/kzbz/5M28/+TNvP/kzbz/5M28/+HJuv/Zu6n/wZJ7/5JQPr+RTjwGAAAAAAAAAAAAAAAAkU48Y5FOPMORTjz2kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU489pFOPMORTjxjAAAAAAAAAAAAAAAA4AAAA4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAcAAAAcoAAAAEAAAACAAAAABACAAAAAAAEAEAAAAAAAAAAAAAAAAAAAAAAAAkU48SJFOPOeRTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjznkU48SJFOPOSlaVb/omZT/6BjT/+gYk3/n2FM/59hTP+fYUz/n2FM/59hTP+fYUz/oGJN/6BjT/+iZlP/pWlW/5FOPOSRTjz/nl1M/3QtE/90LRP/dC0T/3QtE/90LRP/dC0T/302J/99Nif/fTYm/3w1Jv99Nyf/gDss/55dTP+RTjz/kU48/6BcS/90LRP/sXBX/4xBKv+MQSr/sXBX/3o1IP+RVkn/nWhc/5xmWv+aZFj/mmNX/4pMPv+NRzb/kU48/5FOPP+mYVH/dC0T/7FwV/+MQSr/jEEq/7FwV/+BPy3/8Ojn///////////////////////v5+X/fjcn/5FOPP+RTjz/rWtb/3QtE/+xcFf///////////+xcFf/g0Av//Hp5///////////////////////8Ofl/4A6Kv+RTjz/kU48/7V3Zv90LRP/sXBX////////////sXBX/4RCMv/x6ef///////////////////////Do5v+DPi7/kU48/5FOPP+7gXD/dC0T/7FwV/+MQSr/jEEq/7FwV/+APSn/0rmz//////+3kYn/t5GJ///////Lrqf/l1ZG/5FOPP+RTjz/v4p5/3QtE/+xcFf/jEEq/4xBKv+xcFf/eDMb/5FQQf+GRjb/ejwu/3k6LP+DQDD/j04+/7R8a/+RTjz/kU48/8mXfv90LRP/sXBX////////////sXBX/3QtE/+rbVr/azcs/31RSP99UUj/bDkt/7mDbf/TrJT/kU48/5FOPP/Noof/dC0T/7FwV////////////7FwV/90LRP/o21X/35TSf///////////39TSv+rfGf/3Lui/5FOPP+RTjz/0auQ/3QtE/+0dFv/lk42/45ELf+xcFf/dC0T/6d0Xv9/U0n///////////9/VEr/r4Jt/9/Dqf+RTjz/kU48/9SxnP92MBb/i0Ur/6BdRP+0dVz/tXVc/3QtE//ImoL/bj0x/39USv9/VEv/bz0y/9KrlP/iybT/kU48/5FOPP/Xt6f/r3ph/5VYP/+CPyX/djAW/3YvFf90LRP/zqSO/9Cnj/+yh3T/soh1/9SvmP/Wspv/4su8/5FOPP+RTjzn0K2T/9y+rv/cwK3/3cCv/97Bsf/RsJ7/zqya/+DItv/hyrj/4cq5/+PLuv/kzbz/5M2+/9q9pf+RTjznkU48P5FOPMmRTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjz/kU48/5FOPP+RTjzJkU48PwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
')
$Form1.add_Load({Load-Form})
#~~< LabelCollection >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelCollection = New-Object System.Windows.Forms.Label
$LabelCollection.Location = New-Object System.Drawing.Point(12, 336)
$LabelCollection.Size = New-Object System.Drawing.Size(100, 23)
$LabelCollection.TabIndex = 36
$LabelCollection.Text = "Collection:"
#~~< TextBoxCollection >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBoxCollection = New-Object System.Windows.Forms.TextBox
$TextBoxCollection.Location = New-Object System.Drawing.Point(139, 333)
$TextBoxCollection.Size = New-Object System.Drawing.Size(428, 20)
$TextBoxCollection.TabIndex = 7
$TextBoxCollection.Text = ""
$TextBoxCollection.add_TextChanged({CollectionName-Changed})
#~~< ButtonAppV >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ButtonAppV = New-Object System.Windows.Forms.Button
$ButtonAppV.Location = New-Object System.Drawing.Point(582, 123)
$ButtonAppV.Size = New-Object System.Drawing.Size(75, 23)
$ButtonAppV.TabIndex = 34
$ButtonAppV.Text = "Browse"
$ButtonAppV.UseVisualStyleBackColor = $true
$ButtonAppV.Add_Click({ButtonAppVClick})
#~~< LabelAppVPackage >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelAppVPackage = New-Object System.Windows.Forms.Label
$LabelAppVPackage.Location = New-Object System.Drawing.Point(12, 128)
$LabelAppVPackage.Size = New-Object System.Drawing.Size(95, 13)
$LabelAppVPackage.TabIndex = 33
$LabelAppVPackage.Text = "App-V 5 Package:"
#~~< TextBoxAppVPackage >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBoxAppVPackage = New-Object System.Windows.Forms.TextBox
$TextBoxAppVPackage.Location = New-Object System.Drawing.Point(139, 125)
$TextBoxAppVPackage.ReadOnly = $true
$TextBoxAppVPackage.Size = New-Object System.Drawing.Size(428, 20)
$TextBoxAppVPackage.TabIndex = 32
$TextBoxAppVPackage.Text = ""
$TextBoxAppVPackage.add_TextChanged({AppVName-Changed})
#~~< ProgressBar1 >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ProgressBar1 = New-Object System.Windows.Forms.ProgressBar
$ProgressBar1.Location = New-Object System.Drawing.Point(301, 472)
$ProgressBar1.Size = New-Object System.Drawing.Size(100, 23)
$ProgressBar1.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$ProgressBar1.TabIndex = 28
$ProgressBar1.Text = ""
#~~< TextBoxMSIPackage >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBoxMSIPackage = New-Object System.Windows.Forms.TextBox
$TextBoxMSIPackage.Location = New-Object System.Drawing.Point(139, 73)
$TextBoxMSIPackage.ReadOnly = $true
$TextBoxMSIPackage.Size = New-Object System.Drawing.Size(428, 20)
$TextBoxMSIPackage.TabIndex = 10
$TextBoxMSIPackage.Text = ""
$TextBoxMSIPackage.add_TextChanged({MSIFile-Changed})
#~~< TextBoxMSTFile >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBoxMSTFile = New-Object System.Windows.Forms.TextBox
$TextBoxMSTFile.Location = New-Object System.Drawing.Point(139, 99)
$TextBoxMSTFile.ReadOnly = $true
$TextBoxMSTFile.Size = New-Object System.Drawing.Size(428, 20)
$TextBoxMSTFile.TabIndex = 10
$TextBoxMSTFile.Text = ""
#~~< TextBoxAppName >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBoxAppName = New-Object System.Windows.Forms.TextBox
$TextBoxAppName.Location = New-Object System.Drawing.Point(139, 151)
$TextBoxAppName.Size = New-Object System.Drawing.Size(428, 20)
$TextBoxAppName.TabIndex = 0
$TextBoxAppName.Text = ""
$TextBoxAppName.add_TextChanged({AppName-Changed})
#~~< TextBoxPublisher >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBoxPublisher = New-Object System.Windows.Forms.TextBox
$TextBoxPublisher.Location = New-Object System.Drawing.Point(139, 177)
$TextBoxPublisher.Size = New-Object System.Drawing.Size(428, 20)
$TextBoxPublisher.TabIndex = 1
$TextBoxPublisher.Text = ""
#~~< TextBoxVersion >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBoxVersion = New-Object System.Windows.Forms.TextBox
$TextBoxVersion.Location = New-Object System.Drawing.Point(139, 203)
$TextBoxVersion.Size = New-Object System.Drawing.Size(428, 20)
$TextBoxVersion.TabIndex = 2
$TextBoxVersion.Text = ""
#~~< TextBoxInstallProgram >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBoxInstallProgram = New-Object System.Windows.Forms.TextBox
$TextBoxInstallProgram.Location = New-Object System.Drawing.Point(139, 229)
$TextBoxInstallProgram.Size = New-Object System.Drawing.Size(428, 20)
$TextBoxInstallProgram.TabIndex = 3
$TextBoxInstallProgram.Text = ""
$TextBoxInstallProgram.add_TextChanged({InstallProgram-Changed})
#~~< TextBoxUnInstallProgram >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBoxUnInstallProgram = New-Object System.Windows.Forms.TextBox
$TextBoxUnInstallProgram.Location = New-Object System.Drawing.Point(139, 255)
$TextBoxUnInstallProgram.Size = New-Object System.Drawing.Size(428, 20)
$TextBoxUnInstallProgram.TabIndex = 4
$TextBoxUnInstallProgram.Text = ""
#~~< TextBoxSourcePath >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBoxSourcePath = New-Object System.Windows.Forms.TextBox
$TextBoxSourcePath.Location = New-Object System.Drawing.Point(139, 281)
$TextBoxSourcePath.Size = New-Object System.Drawing.Size(428, 20)
$TextBoxSourcePath.TabIndex = 5
$TextBoxSourcePath.Text = ""
$TextBoxSourcePath.add_TextChanged({SourcePath-Changed})
#~~< TextBoxADGroup >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$TextBoxADGroup = New-Object System.Windows.Forms.TextBox
$TextBoxADGroup.Location = New-Object System.Drawing.Point(139, 307)
$TextBoxADGroup.Size = New-Object System.Drawing.Size(428, 20)
$TextBoxADGroup.TabIndex = 6
$TextBoxADGroup.Text = ""
$TextBoxADGroup.add_TextChanged({ADGroup-Changed})
#~~< ButtonMSI >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ButtonMSI = New-Object System.Windows.Forms.Button
$ButtonMSI.Location = New-Object System.Drawing.Point(582, 71)
$ButtonMSI.Size = New-Object System.Drawing.Size(75, 23)
$ButtonMSI.TabIndex = 10
$ButtonMSI.Text = "Browse"
$ButtonMSI.UseVisualStyleBackColor = $true
$ButtonMSI.Add_Click({ButtonMSIClick})
#~~< ButtonMST >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ButtonMST = New-Object System.Windows.Forms.Button
$ButtonMST.Enabled = $false
$ButtonMST.Location = New-Object System.Drawing.Point(582, 97)
$ButtonMST.Size = New-Object System.Drawing.Size(75, 23)
$ButtonMST.TabIndex = 10
$ButtonMST.Text = "Browse"
$ButtonMST.UseVisualStyleBackColor = $true
$ButtonMST.Add_Click({ButtonMSTClick})
#~~< ButtonCreate >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ButtonCreate = New-Object System.Windows.Forms.Button
$ButtonCreate.Font = New-Object System.Drawing.Font("Microsoft Sans Serif", 8.25, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
$ButtonCreate.Location = New-Object System.Drawing.Point(582, 416)
$ButtonCreate.Size = New-Object System.Drawing.Size(95, 37)
$ButtonCreate.TabIndex = 9
$ButtonCreate.Text = "Create"
$ButtonCreate.UseVisualStyleBackColor = $true
$ButtonCreate.add_Click({ButtonCreateClick})
#~~< ButtonPADT >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ButtonPADT = New-Object System.Windows.Forms.Button
$ButtonPADT.Location = New-Object System.Drawing.Point(582, 373)
$ButtonPADT.Size = New-Object System.Drawing.Size(95, 37)
$ButtonPADT.TabIndex = 25
$ButtonPADT.Text = "Use PADT"
$ButtonPADT.UseVisualStyleBackColor = $true
#~~< ToolTip >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ToolTip = New-Object System.Windows.Forms.ToolTip
$ToolTip.AutoPopDelay = 5000
$ToolTip.InitialDelay = 500
$ToolTip.IsBalloon = $true
$ToolTip.ReshowDelay = 500
$ToolTip.BackColor = [System.Drawing.Color]::LightGoldenrodYellow
$ToolTip.SetToolTip($ButtonPADT, "Click here if you are using Powershell Application Deployment Toolkit.")
$ButtonPADT.add_Click({ButtonPADTClick})
#~~< LabelAuthor >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelAuthor = New-Object System.Windows.Forms.Label
$LabelAuthor.Location = New-Object System.Drawing.Point(12, 466)
$LabelAuthor.Size = New-Object System.Drawing.Size(140, 15)
$LabelAuthor.TabIndex = 29
$LabelAuthor.Text = "Author: Joachim Bryttmar"
#~~< LabelBlog >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelBlog = New-Object System.Windows.Forms.Label
$LabelBlog.Location = New-Object System.Drawing.Point(12, 481)
$LabelBlog.Size = New-Object System.Drawing.Size(40, 23)
$LabelBlog.TabIndex = 30
$LabelBlog.Text = "Blog:"
#~~< LinkLabelBlog >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LinkLabelBlog = New-Object System.Windows.Forms.LinkLabel
$LinkLabelBlog.Location = New-Object System.Drawing.Point(50, 481)
$LinkLabelBlog.Size = New-Object System.Drawing.Size(140, 23)
$LinkLabelBlog.TabIndex = 31
$LinkLabelBlog.TabStop = $true
$LinkLabelBlog.Text = "infogeek.se"
#~~< LabelPurpose >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelPurpose = New-Object System.Windows.Forms.Label
$LabelPurpose.Location = New-Object System.Drawing.Point(124, 367)
$LabelPurpose.Size = New-Object System.Drawing.Size(100, 23)
$LabelPurpose.TabIndex = 14
$LabelPurpose.Text = "Purpose:"
$ToolTip.SetToolTip($LabelPurpose, "Choose if the deployment should be Available or Required.")
#~~< LabelTarget >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelTarget = New-Object System.Windows.Forms.Label
$LabelTarget.Location = New-Object System.Drawing.Point(12, 367)
$LabelTarget.Size = New-Object System.Drawing.Size(100, 23)
$LabelTarget.TabIndex = 11
$LabelTarget.Text = "Target:"
$ToolTip.SetToolTip($LabelTarget, "Choose target. This setting controls the deployment and the path of the AD group.")
#~~< PanelPurpose >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$PanelPurpose = New-Object System.Windows.Forms.Panel
$PanelPurpose.Location = New-Object System.Drawing.Point(124, 378)
$PanelPurpose.Size = New-Object System.Drawing.Size(116, 81)
$PanelPurpose.TabIndex = 24
$PanelPurpose.Text = ""
#~~< RadioButtonAvailable >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RadioButtonAvailable = New-Object System.Windows.Forms.RadioButton
$RadioButtonAvailable.Location = New-Object System.Drawing.Point(0, 38)
$RadioButtonAvailable.Size = New-Object System.Drawing.Size(104, 24)
$RadioButtonAvailable.TabIndex = 15
$RadioButtonAvailable.TabStop = $true
$RadioButtonAvailable.Text = "Available"
$RadioButtonAvailable.UseVisualStyleBackColor = $true
#~~< RadioButtonRequired >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RadioButtonRequired = New-Object System.Windows.Forms.RadioButton
$RadioButtonRequired.Location = New-Object System.Drawing.Point(0, 12)
$RadioButtonRequired.Size = New-Object System.Drawing.Size(104, 24)
$RadioButtonRequired.TabIndex = 16
$RadioButtonRequired.Text = "Required"
$RadioButtonRequired.UseVisualStyleBackColor = $true
$PanelPurpose.Controls.Add($RadioButtonAvailable)
$PanelPurpose.Controls.Add($RadioButtonRequired)
#~~< PanelTarget >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$PanelTarget = New-Object System.Windows.Forms.Panel
$PanelTarget.Location = New-Object System.Drawing.Point(12, 378)
$PanelTarget.Size = New-Object System.Drawing.Size(116, 81)
$PanelTarget.TabIndex = 23
$PanelTarget.Text = ""
#~~< RadioButtonDevice >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RadioButtonDevice = New-Object System.Windows.Forms.RadioButton
$RadioButtonDevice.Location = New-Object System.Drawing.Point(2, 12)
$RadioButtonDevice.Size = New-Object System.Drawing.Size(104, 24)
$RadioButtonDevice.TabIndex = 12
$RadioButtonDevice.TabStop = $true
$RadioButtonDevice.Text = "Device"
$RadioButtonDevice.UseVisualStyleBackColor = $true
#~~< RadioButtonUser >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$RadioButtonUser = New-Object System.Windows.Forms.RadioButton
$RadioButtonUser.Location = New-Object System.Drawing.Point(2, 38)
$RadioButtonUser.Size = New-Object System.Drawing.Size(104, 24)
$RadioButtonUser.TabIndex = 13
$RadioButtonUser.Text = "User"
$RadioButtonUser.UseVisualStyleBackColor = $true
$PanelTarget.Controls.Add($RadioButtonDevice)
$PanelTarget.Controls.Add($RadioButtonUser)
#~~< CheckBoxCreateDeployment >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$CheckBoxCreateDeployment = New-Object System.Windows.Forms.CheckBox
$CheckBoxCreateDeployment.Checked = $true
$CheckBoxCreateDeployment.CheckState = [System.Windows.Forms.CheckState]::Checked
$CheckBoxCreateDeployment.Location = New-Object System.Drawing.Point(407, 421)
$CheckBoxCreateDeployment.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
$CheckBoxCreateDeployment.Size = New-Object System.Drawing.Size(131, 24)
$CheckBoxCreateDeployment.TabIndex = 22
$CheckBoxCreateDeployment.Text = "Create Deployment"
$CheckBoxCreateDeployment.UseVisualStyleBackColor = $true
$CheckBoxCreateDeployment.add_CheckedChanged({CheckBoxCreateDeploymentChanged})
#~~< CheckBoxDistributeContent >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$CheckBoxDistributeContent = New-Object System.Windows.Forms.CheckBox
$CheckBoxDistributeContent.Checked = $true
$CheckBoxDistributeContent.CheckState = [System.Windows.Forms.CheckState]::Checked
$CheckBoxDistributeContent.Location = New-Object System.Drawing.Point(406, 391)
$CheckBoxDistributeContent.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
$CheckBoxDistributeContent.Size = New-Object System.Drawing.Size(132, 24)
$CheckBoxDistributeContent.TabIndex = 21
$CheckBoxDistributeContent.Text = "Distribute Content"
$CheckBoxDistributeContent.UseVisualStyleBackColor = $true
$CheckBoxDistributeContent.add_CheckedChanged({CheckBoxDistributeContentChanged})
#~~< CheckBoxCreateADGroup >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$CheckBoxCreateADGroup = New-Object System.Windows.Forms.CheckBox
$CheckBoxCreateADGroup.Checked = $true
$CheckBoxCreateADGroup.CheckState = [System.Windows.Forms.CheckState]::Checked
$CheckBoxCreateADGroup.Location = New-Object System.Drawing.Point(278, 421)
$CheckBoxCreateADGroup.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
$CheckBoxCreateADGroup.Size = New-Object System.Drawing.Size(123, 24)
$CheckBoxCreateADGroup.TabIndex = 20
$CheckBoxCreateADGroup.Text = "Create AD Group"
$CheckBoxCreateADGroup.UseVisualStyleBackColor = $true
$CheckBoxCreateADGroup.add_CheckedChanged({CheckBoxCreateADGroupChanged})
#~~< CheckBoxCreateCollection >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$CheckBoxCreateCollection = New-Object System.Windows.Forms.CheckBox
$CheckBoxCreateCollection.Checked = $true
$CheckBoxCreateCollection.CheckState = [System.Windows.Forms.CheckState]::Checked
$CheckBoxCreateCollection.Location = New-Object System.Drawing.Point(277, 391)
$CheckBoxCreateCollection.RightToLeft = [System.Windows.Forms.RightToLeft]::Yes
$CheckBoxCreateCollection.Size = New-Object System.Drawing.Size(124, 24)
$CheckBoxCreateCollection.TabIndex = 19
$CheckBoxCreateCollection.Text = "Create Collection"
$CheckBoxCreateCollection.UseVisualStyleBackColor = $true
$CheckBoxCreateCollection.add_CheckedChanged({CheckBoxCreateCollectionChanged})
#~~< LabelSCCMApplicationCreator >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelSCCMApplicationCreator = New-Object System.Windows.Forms.Label
$LabelSCCMApplicationCreator.AutoSize = $true
$LabelSCCMApplicationCreator.Font = New-Object System.Drawing.Font("Times New Roman", 24.0, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
$LabelSCCMApplicationCreator.Location = New-Object System.Drawing.Point(12, 12)
$LabelSCCMApplicationCreator.Size = New-Object System.Drawing.Size(392, 36)
$LabelSCCMApplicationCreator.TabIndex = 9
$LabelSCCMApplicationCreator.Text = "SCCM Application Creator"
$LabelSCCMApplicationCreator.ForeColor = [System.Drawing.Color]::RoyalBlue
#~~< LabelScriptVersion >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelScriptVersion = New-Object System.Windows.Forms.Label
$LabelScriptVersion.Font = New-Object System.Drawing.Font("Times New Roman", 12.0, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Point, ([System.Byte](0)))
$LabelScriptVersion.Location = New-Object System.Drawing.Point(600, 475)
$LabelScriptVersion.Size = New-Object System.Drawing.Size(100, 23)
$LabelScriptVersion.TabIndex = 27
$LabelScriptVersion.Text = "Version $ScriptVersion"
$LabelScriptVersion.ForeColor = [System.Drawing.Color]::RoyalBlue
#~~< LabelADGroup >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelADGroup = New-Object System.Windows.Forms.Label
$LabelADGroup.AutoSize = $true
$LabelADGroup.Location = New-Object System.Drawing.Point(12, 310)
$LabelADGroup.Size = New-Object System.Drawing.Size(55, 13)
$LabelADGroup.TabIndex = 8
$LabelADGroup.Text = "AD group:"
#~~< LabelSourcePath >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelSourcePath = New-Object System.Windows.Forms.Label
$LabelSourcePath.AutoSize = $true
$LabelSourcePath.Location = New-Object System.Drawing.Point(12, 284)
$LabelSourcePath.Size = New-Object System.Drawing.Size(109, 13)
$LabelSourcePath.TabIndex = 8
$LabelSourcePath.Text = "Content Source Path:"
#~~< LabelUnInstallProgram >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelUnInstallProgram = New-Object System.Windows.Forms.Label
$LabelUnInstallProgram.AutoSize = $true
$LabelUnInstallProgram.Location = New-Object System.Drawing.Point(12, 258)
$LabelUnInstallProgram.Size = New-Object System.Drawing.Size(115, 13)
$LabelUnInstallProgram.TabIndex = 7
$LabelUnInstallProgram.Text = "Uninstallation Program:"
#~~< LabelInstallProgram >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelInstallProgram = New-Object System.Windows.Forms.Label
$LabelInstallProgram.AutoSize = $true
$LabelInstallProgram.Location = New-Object System.Drawing.Point(12, 232)
$LabelInstallProgram.Size = New-Object System.Drawing.Size(102, 13)
$LabelInstallProgram.TabIndex = 6
$LabelInstallProgram.Text = "Installation Program:"
#~~< LabelVersion >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelVersion = New-Object System.Windows.Forms.Label
$LabelVersion.AutoSize = $true
$LabelVersion.Location = New-Object System.Drawing.Point(12, 206)
$LabelVersion.Size = New-Object System.Drawing.Size(45, 13)
$LabelVersion.TabIndex = 5
$LabelVersion.Text = "Version:"
#~~< LabelPublisher >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelPublisher = New-Object System.Windows.Forms.Label
$LabelPublisher.AutoSize = $true
$LabelPublisher.Location = New-Object System.Drawing.Point(12, 180)
$LabelPublisher.RightToLeft = [System.Windows.Forms.RightToLeft]::No
$LabelPublisher.Size = New-Object System.Drawing.Size(53, 13)
$LabelPublisher.TabIndex = 4
$LabelPublisher.Text = "Publisher:"
#~~< LabelAppName >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelAppName = New-Object System.Windows.Forms.Label
$LabelAppName.AutoSize = $true
$LabelAppName.Location = New-Object System.Drawing.Point(12, 154)
$LabelAppName.Size = New-Object System.Drawing.Size(93, 13)
$LabelAppName.TabIndex = 3
$LabelAppName.Text = "Application Name:"
#~~< LabelMSTFile >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelMSTFile = New-Object System.Windows.Forms.Label
$LabelMSTFile.AutoSize = $true
$LabelMSTFile.Location = New-Object System.Drawing.Point(12, 102)
$LabelMSTFile.Size = New-Object System.Drawing.Size(52, 13)
$LabelMSTFile.TabIndex = 2
$LabelMSTFile.Text = "MST File:"
#~~< LabelMSIPackage >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$LabelMSIPackage = New-Object System.Windows.Forms.Label
$LabelMSIPackage.AutoSize = $true
$LabelMSIPackage.Location = New-Object System.Drawing.Point(12, 76)
$LabelMSIPackage.Size = New-Object System.Drawing.Size(75, 13)
$LabelMSIPackage.TabIndex = 1
$LabelMSIPackage.Text = "MSI Package:"
$Form1.Controls.Add($LabelCollection)
$Form1.Controls.Add($TextBoxCollection)
$Form1.Controls.Add($ButtonAppV)
$Form1.Controls.Add($LabelAppVPackage)
$Form1.Controls.Add($TextBoxAppVPackage)
$Form1.Controls.Add($ProgressBar1)
$Form1.Controls.Add($TextBoxMSIPackage)
$Form1.Controls.Add($TextBoxMSTFile)
$Form1.Controls.Add($TextBoxAppName)
$Form1.Controls.Add($TextBoxPublisher)
$Form1.Controls.Add($TextBoxVersion)
$Form1.Controls.Add($TextBoxInstallProgram)
$Form1.Controls.Add($TextBoxUnInstallProgram)
$Form1.Controls.Add($TextBoxSourcePath)
$Form1.Controls.Add($TextBoxADGroup)
$Form1.Controls.Add($ButtonMSI)
$Form1.Controls.Add($ButtonMST)
$Form1.Controls.Add($ButtonCreate)
$Form1.Controls.Add($ButtonPADT)
$Form1.Controls.Add($LabelAuthor)
$Form1.Controls.Add($LabelBlog)
$Form1.Controls.Add($LinkLabelBlog)
$Form1.Controls.Add($LabelPurpose)
$Form1.Controls.Add($LabelTarget)
$Form1.Controls.Add($PanelPurpose)
$Form1.Controls.Add($PanelTarget)
$Form1.Controls.Add($CheckBoxCreateDeployment)
$Form1.Controls.Add($CheckBoxDistributeContent)
$Form1.Controls.Add($CheckBoxCreateADGroup)
$Form1.Controls.Add($CheckBoxCreateCollection)
$Form1.Controls.Add($LabelSCCMApplicationCreator)
$Form1.Controls.Add($LabelScriptVersion)
$Form1.Controls.Add($LabelADGroup)
$Form1.Controls.Add($LabelSourcePath)
$Form1.Controls.Add($LabelUnInstallProgram)
$Form1.Controls.Add($LabelInstallProgram)
$Form1.Controls.Add($LabelVersion)
$Form1.Controls.Add($LabelPublisher)
$Form1.Controls.Add($LabelAppName)
$Form1.Controls.Add($LabelMSTFile)
$Form1.Controls.Add($LabelMSIPackage)
$Form1.add_Load({Load-Form})
#~~< OpenFileDialogMSI >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$OpenFileDialogMSI = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialogMSI.Filter = "MSI Files | *.msi"
$OpenFileDialogMSI.ShowHelp = $true
$OpenFileDialogMSI.Title = "Select MSI File"
$OpenFileDialogMSI.add_FileOK({OpenMSIFile})
#~~< OpenFileDialogMST >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$OpenFileDialogMST = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialogMST.Filter = "MST Files | *.mst"
$OpenFileDialogMST.ShowHelp = $true
$OpenFileDialogMST.Title = "Select MST File"
$OpenFileDialogMST.add_FileOK({OpenMSTFile})
#~~< OpenFileDialogAppV >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$OpenFileDialogAppV = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialogAppV.Filter = "App-V Files | *.appv"
$OpenFileDialogAppV.ShowHelp = $true
$OpenFileDialogAppV.Title = "Select App-V Package"
$OpenFileDialogAppV.add_FileOK({OpenAppVFile})
#~~< ErrorProviderMSIPackage >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ErrorProviderMSIPackage = New-Object System.Windows.Forms.ErrorProvider
$ErrorProviderMSIPackage.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink
$ErrorProviderMSIPackage.ContainerControl = $Form1
#~~< ErrorProviderAppVPackage >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ErrorProviderAppVPackage = New-Object System.Windows.Forms.ErrorProvider
$ErrorProviderAppVPackage.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink
$ErrorProviderAppVPackage.ContainerControl = $Form1
#~~< ErrorProviderAppName >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ErrorProviderAppName = New-Object System.Windows.Forms.ErrorProvider
$ErrorProviderAppName.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink
$ErrorProviderAppName.ContainerControl = $Form1
#~~< ErrorProviderInstallProgram >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ErrorProviderInstallProgram = New-Object System.Windows.Forms.ErrorProvider
$ErrorProviderInstallProgram.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink
$ErrorProviderInstallProgram.ContainerControl = $Form1
#~~< ErrorProviderSourcePath >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ErrorProviderSourcePath = New-Object System.Windows.Forms.ErrorProvider
$ErrorProviderSourcePath.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink
$ErrorProviderSourcePath.ContainerControl = $Form1
#~~< ErrorProviderCollection >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ErrorProviderCollection = New-Object System.Windows.Forms.ErrorProvider
$ErrorProviderCollection.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink
$ErrorProviderCollection.ContainerControl = $Form1
#~~< ErrorProviderADGroup >~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$ErrorProviderADGroup = New-Object System.Windows.Forms.ErrorProvider
$ErrorProviderADGroup.BlinkStyle = [System.Windows.Forms.ErrorBlinkStyle]::NeverBlink
$ErrorProviderADGroup.ContainerControl = $Form1

#endregion

#region Custom Code

# Function with actions when form is loaded
function Load-Form
{
	$ErrorProviderAppName.SetError($TextBoxAppName, "As a minimum, please specify a name for the application")
	$ButtonCreate.Enabled = $False
	$ButtonPADT.Enabled = $false
	$RadioButtonAvailable.Enabled = $false
	$RadioButtonRequired.Enabled = $false
	$TextBoxMSIPackage.Clear()
	$TextBoxMSTFile.Clear()
    $TextBoxAppVPackage.Clear()
	$TextBoxAppName.Clear()
	$TextBoxPublisher.Clear()
	$TextBoxVersion.Clear()
	$TextBoxInstallProgram.Clear()
	$TextBoxInstallProgram.Enabled = $true
	$TextBoxUnInstallProgram.Clear()
	$TextBoxUnInstallProgram.Enabled = $true
	$TextBoxSourcePath.Clear()
	$TextBoxSourcePath.Enabled = $true
    $TextBoxADGroup.Clear()
    $TextBoxADGroup.Enabled = $true
	$RadioButtonRequired.Checked = $true
	$RadioButtonDevice.Checked = $true
	$CheckBoxCreateCollection.Checked = $false
	$CheckBoxCreateCollection.Enabled = $false
    $CheckBoxCreateADGroup.Checked = $false
    $CheckBoxCreateADGroup.Enabled = $false
    $CheckBoxDistributeContent.Checked = $false
	$CheckBoxDistributeContent.Enabled = $false
	$CheckBoxCreateDeployment.Checked = $false
	$CheckBoxCreateDeployment.Enabled = $false
	$ProgressBar1.Visible = $false
	$ProgressBar1.Minimum = 1
	$ProgressBar1.Maximum = 15
	$ProgressBar1.Value = 1
	$ProgressBar1.Step = 1
}


# Function to validate all input in the form. Initiated by clicking the Create-button, and must return True before an application is created.
function Validate-Form
{
    $OkToProceed = $true
    $MSIPackageName = $TextBoxMSIPackage.Text
    $MSTFileName = $TextBoxMSTFile.Text
    $AppVFileName = $TextBoxAppVPackage.Text
    $ApplicationVersion = $TextBoxVersion.Text
    if ($ApplicationVersion -ne "" -and $ApplicationVersion -ne $null)
    {
        $ApplicationName = $TextBoxAppName.Text + " " + $ApplicationVersion
    }
    else
    {
        $ApplicationName = $TextBoxAppName.Text
    }
  	$Publisher = $TextBoxPublisher.Text
	$ApplicationVersion = $TextBoxVersion.Text
	$InstallationProgram = $TextBoxInstallProgram.Text
	$UninstallationProgram = $TextBoxUnInstallProgram.Text
	$ContentSourcePath = $TextBoxSourcePath.Text
    $InstallCollectionName = $TextBoxInstallCollection.Text
    $UninstallCollectionName = $TextBoxUninstallCollection.Text
    $ADGroupName = $TextBoxADGroup.Text

    # Clear the error providers
    $ErrorProviderMSIPackage.Clear()
    $ErrorProviderAppVPackage.Clear()
    $ErrorProviderAppName.Clear()
    $ErrorProviderCollection.Clear()
    $ErrorProviderADGroup.Clear()
    $ErrorProviderSourcePath.Clear()
    $ErrorProviderInstallProgram.Clear()

    # Clear the progress bar
    $ProgressBar1.Visible = $false
	$ProgressBar1.Minimum = 1
	$ProgressBar1.Maximum = 15
	$ProgressBar1.Value = 1
	$ProgressBar1.Step = 1

    # Check if an Application exists in SCCM with the same name
    if ((Check-ApplicationExist $ApplicationName) -eq $true)
    {
    	$OkToProceed = $false	
        $ErrorProviderAppName.SetError($TextBoxAppName, "An application called $ApplicationName already exists. Please check the name and try again.")
    }

    # Check if we try to create a new collection with the same name as one that already exists
    if ($TextBoxCollection.Text.Length -gt 0 -and (Check-CollectionExist $CollectionName) -eq $true -and $CheckBoxCreateCollection.Checked -eq $true)
    {
    	$OkToProceed = $false	
        $ErrorProviderCollection.SetError($TextBoxCollection, "A collection called $CollectionName already exists. Please change the name or clear the Create Collection checkbox.")
    }

    # Check if a collection name is specified, but the Create Collection checkbox is unchecked, and the collection does not already exist
    if ($TextBoxCollection.Text.Length -gt 0 -and (Check-CollectionExist $CollectionName) -eq $false -and $CheckBoxCreateCollection.Checked -eq $false)
    {
    	$OkToProceed = $false	
        $ErrorProviderCollection.SetError($TextBoxCollection, "The collection $CollectionName does not exist. Please clear the collection name or change it to the name of an existing collection, or check the Create Collection checkbox to create a new collection.")
    }

    # Check if we try to create a new AD-group with the same name as one that already exists
    if ($TextBoxADGroup.Text.Length -gt 0 -and (Check-ADGroupExist $ADGroupName) -eq $true -and $CheckBoxCreateADGroup.Checked -eq $true)
    {
    	$OkToProceed = $false	
        $ErrorProviderADGroup.SetError($TextBoxADGroup, "An AD Group called $ADGroupName already exists. Please change the name or clear the Create AD Group checkbox.")
    }

    # Validate that the path to the MSI-package is a UNC-path
    if ($TextBoxMSIPackage.Text.Length -gt 0)
    {
        if (-not $MSIPackageName.StartsWith("\\"))
        {
            $OkToProceed = $false
            $ErrorProviderMSIPackage.SetError($TextBoxMSIPackage, "Local paths are not supported. Please specify a UNC-path.")
        }
    }

    # Validate that the path to the AppV-Package is a UNC-path
    if ($TextBoxAppVPackage.Text.Length -gt 0)
    {
        if (-not $AppVFileName.StartsWith("\\"))
        {
            $OkToProceed = $false
            $ErrorProviderAppVPackage.SetError($TextBoxAppVPackage, "Local paths are not supported. Please specify a UNC-path.")
        }
    }

    # Validate that the content source path is a UNC-path
    if ($TextBoxSourcePath.Text.Length -gt 0)
    {
        if (-not $ContentSourcePath.StartsWith("\\"))
        {
            $OkToProceed = $false
            $ErrorProviderSourcePath.SetError($TextBoxSourcePath, "Local paths are not supported. Please specify a UNC-path.")
        }
    }

    # If only the content source path is specified but not the installation program, we can't proceed
    if ($TextBoxSourcePath.Text.Length -gt 0 -and $TextBoxInstallProgram.Text -eq "")
    {
        $OkToProceed = $false
        $ErrorProviderInstallProgram.SetError($TextBoxInstallProgram, "If you specify a content source path, you must also specify an installation program.")
    }

    # If only the installation program is specified but not the content source path, we can't proceed
    if ($TextBoxInstallProgram.Text -gt 0 -and $TextBoxSourcePath.Text -eq "")
    {
        $OkToProceed = $false
        $ErrorProviderSourcePath.SetError($TextBoxSourcePath, "If you specify an installation program, you must also specify a content source path.")
    }

    # If we're ok to proceed, return True
    if ($OkToProceed)
    {
        Return $true
    }
    else
    {
        Return $false
    }
}

# Function to control actions when clicking on button 'Create'. All logic to create the application, the deployment type, and other objects such as collection and AD-group, is in this function.
function ButtonCreateClick
{
    $MSIFile = $TextBoxMSIPackage.Text
    $AppVFile = $TextBoxAppVPackage.Text
    $ApplicationVersion = $TextBoxVersion.Text
    if ($ApplicationVersion -ne "" -and $ApplicationVersion -ne $null)
    {
        $ApplicationName = $TextBoxAppName.Text + " " + $ApplicationVersion
    }
    else
    {
        $ApplicationName = $TextBoxAppName.Text
    }
	$Publisher = $TextBoxPublisher.Text
	$InstallationProgram = $TextBoxInstallProgram.Text
	$UninstallationProgram = $TextBoxUnInstallProgram.Text
	$ContentSourcePath = $TextBoxSourcePath.Text
    $CollectionName = $TextBoxCollection.Text
    $ADGroupName = $TextBoxADGroup.Text
    $ADGroupDescription = "Members of this group will be targeted for deployment of " + $TextBoxAppName.Text + " in SCCM"

    $OkToProceed = Validate-Form


	# Check if ok to proceed
	if ($OkToProceed)
	{
        # Show the progress bar
	    $ProgressBar1.Visible = $true
	    $ProgressBar1.PerformStep()		

        # Create the application
		New-CMApplication -Name $ApplicationName -Publisher $Publisher -AutoInstall $true -SoftwareVersion $ApplicationVersion -LocalizedName $TextBoxAppName.Text
		Write-Host "Created application " -NoNewline; Write-Host $ApplicationName -ForegroundColor Green
		$ProgressBar1.PerformStep()
		
		# Check if a publisher was specified
		if ($TextBoxPublisher.Text -ne "")
		{
			# Check if a name for the application folder has been specified in the script parameters, if not the folder will get the same name as the publisher
			if ($ApplicationFolderName -eq "")
			{
				$FolderName = $Publisher
			}
			else
			{
				$FolderName = $ApplicationFolderName
			}
		}
		else
		{
			# Check if a name for the application folder has been specified in the script parameters, if not a folder will not be created
			if ($ApplicationFolderName -eq "")
			{
				$FolderName = ""
			}
			else
			{
				$FolderName = $ApplicationFolderName
			}
		}
		
		# Check if an application folder should be created and if it already exists, if not create it
		if ($CreateApplicationFolder -and $FolderName -ne "")
		{
			$ApplicationFolderPath = $SiteCode + ":" + "\Application\$FolderName"
			if (-not (Test-Path $ApplicationFolderPath))
			{
				New-Item $ApplicationFolderPath
				Write-Host "Created application folder " -NoNewline; Write-Host $FolderName -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}
			# Move the application to folder
			$ApplicationObject = Get-CMApplication -Name $ApplicationName
			Move-CMObject -FolderPath $ApplicationFolderPath -InputObject $ApplicationObject
			Write-Host "Moved application " -NoNewline; Write-Host $ApplicationName -ForegroundColor Green -NoNewline; Write-Host " to folder " -NoNewline; Write-Host $FolderName -ForegroundColor Green
			$ProgressBar1.PerformStep()
		}
		
		    
		# Set path to OU and collection folder depending on selected target
		if ($RadioButtonUser.Checked)
		{
			$OUPath = $UserOUPath
			$CollectionFolderPath = $SiteCode + ":" + "\UserCollection\$CollectionFolderName"
		}
        if ($RadioButtonDevice.Checked)
        {
            $OUPath = $DeviceOUPath
            $CollectionFolderPath = $SiteCode + ":" + "\DeviceCollection\$CollectionFolderName"
        }
		        
		# Create the AD group, if check box is selected
		if ($CheckBoxCreateADGroup.Checked)
		{
			New-ADGroup -Name $ADGroupName -Path $OUPath -Description $ADGroupDescription -GroupScope Global
			Write-Host "Created AD group " -NoNewline; Write-Host $ADGroupName -ForegroundColor Green -NoNewline; Write-Host " in " -NoNewline; Write-Host $OUPath -ForegroundColor Green
			$ProgressBar1.PerformStep()
		}
		
		# Create the user/device-collection folder, if one has been specified in the parameters and if it does not exist
		if ($CollectionFolderName -ne "")
		{
			if (-not (Test-Path $CollectionFolderPath))
			{
				New-Item $CollectionFolderPath
				Write-Host "Created collection folder " -NoNewline; Write-Host $CollectionFolderName -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}
		}
		
		# Create the collection if check box is selected, and move it a collection folder if one is specified in the parameters
		if ($CheckBoxCreateCollection.Checked)
		{
			$Schedule = New-CMSchedule -Start(Random-StartTime) –RecurInterval Days –RecurCount 1
			if ($RadioButtonDevice.Checked)
			{
				$AppCollection = New-CMDeviceCollection -Name $CollectionName -LimitingCollectionName $DeviceLimitingCollection -RefreshType Both -RefreshSchedule $Schedule
				Write-Host "Created device collection " -NoNewline; Write-Host $CollectionName -ForegroundColor Green
				$ProgressBar1.PerformStep()
				
                # If an AD group was specified, add a query membership rule based on that group
                if ($TextBoxADGroup.Text.Length -gt 0)
                {
                    Add-CMDeviceCollectionQueryMembershipRule -Collection $AppCollection -QueryExpression "select *  from  SMS_R_System where SMS_R_System.SystemGroupName = ""$DomainNetbiosName\\$ADGroupName""" -RuleName "Members of AD group $ADGroupName"
                }
				# Check if a collection folder name has been specified, then move the collection there
				If ($CollectionFolderName -ne "")
				{
					Move-CMObject -FolderPath $CollectionFolderPath -InputObject $AppCollection
					Write-Host "Moved collection " -NoNewline; Write-Host $CollectionName -ForegroundColor Green -NoNewline; Write-Host " to folder " -NoNewline; Write-Host $CollectionFolderName -ForegroundColor Green
					$ProgressBar1.PerformStep()
				}
			}
			
			if ($RadioButtonUser.Checked)
			{
				$AppCollection = New-CMUserCollection -Name $CollectionName -LimitingCollectionName $UserLimitingCollection -RefreshType Both -RefreshSchedule $Schedule
				Write-Host "Created user collection " -NoNewline; Write-Host $CollectionName -ForegroundColor Green
				$ProgressBar1.PerformStep()
				Add-CMUserCollectionQueryMembershipRule -Collection $AppCollection -QueryExpression "select * from SMS_R_User where SMS_R_User.SecurityGroupName = ""$DomainNetbiosName\\$ADGroupName""" -RuleName "Members of AD group $ADGroupName"
				# Check if a collection folder name has been specified, then move the collection there
				if ($CollectionFolderName -ne "")
				{
					Move-CMObject -FolderPath $CollectionFolderPath -InputObject $AppCollection
					Write-Host "Moved collection " -NoNewline; Write-Host $CollectionName -ForegroundColor Green -NoNewline; Write-Host " to folder " -NoNewline; Write-Host $CollectionFolderName -ForegroundColor Green
					$ProgressBar1.PerformStep()
				}
			}
			            
		}
        else
        {
            if ($TextBoxCollection.Text.Length -gt 0)
            {
                $AppCollection = Get-CMCollection -Name $CollectionName
            }
        }
		
		# CREATE MSI DEPLOYMENT TYPE
        # If an MSI-package is selected, create a deployment type, add the application to distribution point group, and deploy the application
		if ($TextBoxMSIPackage.Text.Length -gt 0)
		{
            Add-CMMsiDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName "Install $ApplicationName" -ContentLocation $MSIFile -LogonRequirementType WhereOrNotUserLoggedOn -Force
			Write-Host "Created deployment type based on " -NoNewline; Write-Host $MSIFile -ForegroundColor Green -NoNewline; Write-Host " for " -NoNewline; Write-Host $ApplicationName -ForegroundColor Green
			$ProgressBar1.PerformStep()
			        
			# Update the deployment type
			$NewDeploymentType = Get-CMDeploymentType -ApplicationName $ApplicationName
            
            # Set the installation program
			if ($TextBoxInstallProgram.Text.Length -gt 0)
			{
                Set-CMMsiDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -InstallCommand $InstallationProgram
				Write-Host "Installation program set to: " -NoNewline; Write-Host $InstallationProgram -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}
			
            # Set the uninstallation program
            if ($TextBoxUnInstallProgram.Text.Length -gt 0)
			{
                Set-CMMsiDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -UninstallCommand $UninstallationProgram
				Write-Host "Uninstallation program set to: " -NoNewline; Write-Host $UninstallationProgram -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}
            else
            {
                Set-CMMsiDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -UninstallCommand " "
                $ProgressBar1.PerformStep()
            }

            # Set behavior for running installation as 32-bit process on 64-bit systems
            if ($global:RunInstallAs32Bit -eq $true)
            {
                Set-CMMsiDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -Force32Bit $true
                Write-Host "The option " -NoNewline; Write-Host "Run the installation and uninstall programs as 32-bit process on 64-bit clients " -ForegroundColor Green -NoNewline; Write-Host "is set to" -NoNewline; Write-Host " True" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }
            else
            {
                Write-Host "The option " -NoNewline; Write-Host "Run the installation and uninstall programs as 32-bit process on 64-bit clients " -ForegroundColor Green -NoNewline; Write-Host "is set to" -NoNewline; Write-Host " False" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }

            # Set the content source path
            if ($TextBoxSourcePath.Text.Length -gt 0)
			{
                # We have to use the old cmdlet Set-CMDeploymentType, even though it's deprecated, because Set-CMMsiDeploymentType -ContentLocation only works when an MSI-package is specified in the path. Thank you MS.
                Set-CMDeploymentType -MsiOrScriptInstaller -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -ContentLocation $ContentSourcePath -WarningAction SilentlyContinue
				Write-Host "Content source path set to: " -NoNewline; Write-Host $ContentSourcePath -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}
            
            # Set the option for fallback source location
            if ($AllowFallbackSourceLocation -eq $true)
            {
                Set-CMMsiDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -ContentFallback $true
                Write-Host "The option " -NoNewline; Write-Host "Allow clients to use a fallback source location for content" -ForegroundColor Green -NoNewline; Write-Host " is set to" -NoNewline; Write-Host " True" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }
            else
            {
                Write-Host "The option " -NoNewline; Write-Host "Allow clients to use a fallback source location for content" -ForegroundColor Green -NoNewline; Write-Host " is set to" -NoNewline; Write-Host " False" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }

            # Set the behavior for clients on slow networks
            if ($DownloadOnSlowNetwork -eq $true)
            {
                Set-CMMsiDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -SlowNetworkDeploymentMode Download
                Write-Host "The behavior for clients on slow networks is set to " -NoNewline; Write-Host "Download content from distribution point and run locally" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }
            else
            {
                Write-Host "The behavior for clients on slow networks is set to " -NoNewline; Write-Host "Do not download content" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }
			
			# Distribute content to DP group
			if ($CheckBoxDistributeContent.Checked)
			{
				Start-CMContentDistribution -ApplicationName $ApplicationName -DistributionPointGroupName $DPGroup
				Write-Host "Distributed content for " -NoNewline; Write-Host $ApplicationName -ForegroundColor Green -NoNewline; Write-Host " to " -NoNewline; Write-Host $DPGroup -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}
			
			# Check if deployment purpose is Available or Required
			if ($RadioButtonRequired.Checked)
			{
				$DeployPurpose = "Required"
			}
			if ($RadioButtonAvailable.Checked)
			{
				$DeployPurpose = "Available"
			}
			
			# Deploy the application
			if ($CheckBoxCreateDeployment.Checked)
			{
				Start-CMApplicationDeployment -CollectionName $AppCollection.Name -Name $ApplicationName -DeployPurpose $DeployPurpose
				Write-Host "Created " -NoNewline; Write-Host $DeployPurpose -ForegroundColor Green -NoNewline; Write-Host " deployment for " -NoNewline; Write-Host $ApplicationName -ForegroundColor Green -NoNewline; Write-Host " to collection " -NoNewline; Write-Host $CollectionName -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}
		}

        # CREATE APP-V 5 DEPLOYMENT TYPE
        # If an App-V-package is selected, create a deployment type, add the application to distribution point group, and deploy the application
        if ($TextBoxAppVPackage.Text.Length -gt 0)
        {
            Add-CMAppv5XDeploymentType -ContentLocation $AppVFile -ApplicationName $ApplicationName -DeploymentTypeName "Install $ApplicationName"
            Write-Host "Created deployment type based on " -NoNewline; Write-Host $AppVFile -ForegroundColor Green -NoNewline; Write-Host " for " -NoNewline; Write-Host $ApplicationName -ForegroundColor Green
            $ProgressBar1.PerformStep()

			# Update the deployment type
            $NewDeploymentType = Get-CMDeploymentType -ApplicationName $ApplicationName
            
            # Set the option for fallback source location
            if ($AllowFallbackSourceLocation -eq $true)
            {
                Set-CMAppv5XDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -ContentFallback $true
                Write-Host "The option " -NoNewline; Write-Host "Allow clients to use a fallback source location for content" -ForegroundColor Green -NoNewline; Write-Host " is set to" -NoNewline; Write-Host " True" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }
            else
            {
                Write-Host "The option " -NoNewline; Write-Host "Allow clients to use a fallback source location for content" -ForegroundColor Green -NoNewline; Write-Host " is set to" -NoNewline; Write-Host " False" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }

            # Set the behavior for clients on slow networks. NOTE: Due to a bug in the powershell module, this must run before we change the option for the behavior on fast networks. Or else the fast network option will be overwritten.
            Set-CMAppv5XDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -SlowNetworkDeploymentMode $StreamAppVOnSlowNetwork
            Write-Host "The behavior for clients on slow networks is set to " -NoNewline; Write-Host $StreamAppVOnSlowNetwork -ForegroundColor Green
            $ProgressBar1.PerformStep()

            # Set the behavior for clients on fast networks
            if ($StreamAppVOnFastNetwork -eq $true)
            {
                Set-CMAppv5XDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -FastNetworkDeploymentMode DownloadContentForStreaming
                Write-Host "The behavior for clients on fast networks is set to " -NoNewline; Write-Host "Stream content from distribution point" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }
            else
            {
                Write-Host "The behavior for clients on fast networks is set to " -NoNewline; Write-Host "Download content from distribution point and run locally" -ForegroundColor Green
            }

			# Distribute content to DP group
			if ($CheckBoxDistributeContent.Checked)
			{
				Start-CMContentDistribution -ApplicationName $ApplicationName -DistributionPointGroupName $DPGroup
                Write-Host "Distributed content for " -NoNewline; Write-Host $ApplicationName -ForegroundColor Green -NoNewline; Write-Host " to " -NoNewline; Write-Host $DPGroup -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}
			
			# Check if deployment purpose is Available or Required
			if ($RadioButtonRequired.Checked)
			{
				$DeployPurpose = "Required"
			}
			if ($RadioButtonAvailable.Checked)
			{
				$DeployPurpose = "Available"
			}
			
			# Deploy the application
			if ($CheckBoxCreateDeployment.Checked)
			{
				Start-CMApplicationDeployment -CollectionName $AppCollection.Name -Name $ApplicationName -DeployPurpose $DeployPurpose
                Write-Host "Created " -NoNewline; Write-Host $DeployPurpose -ForegroundColor Green -NoNewline; Write-Host " deployment for " -NoNewline; Write-Host $ApplicationName -ForegroundColor Green -NoNewline; Write-Host " to collection " -NoNewline; Write-Host $CollectionName -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}
        }

        # CREATE MANUAL DEPLOYMENT TYPE
        # If no MSI- or App-V-package is selected, and if a content source folder and install program is specified, then create a scripted deployment type with a dummy detection method
        if ($TextBoxMSIPackage.Text.Length -eq 0 -and $TextBoxAppVPackage.Text.Length -eq 0 -and ($TextBoxInstallProgram.Text.Length -gt 0 -and $TextBoxSourcePath.Text.Length -gt 0))
        {
            # Create the deployment type
            if ($TextBoxInstallProgram.Text.Length -gt 0)
            {
                Add-CMScriptDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName "Install $ApplicationName" -ContentLocation $ContentSourcePath -InstallCommand $InstallationProgram -ScriptLanguage PowerShell -ScriptText 'if (Test-Path C:\DummyDetectionMethod) {Write-Host "IMPORTANT! This detection method does not work. You must manually change it."}' -InstallationBehaviorType InstallForSystem -UserInteractionMode Normal -LogonRequirementType WhereOrNotUserLoggedOn
                Write-Host "Created a manual deployment type with a dummy detection method for " -NoNewline; Write-Host $ApplicationName -ForegroundColor Green
                Write-Host "Installation program set to: " -NoNewline; Write-Host $InstallationProgram -ForegroundColor Green
			    $ProgressBar1.PerformStep()
            }

			# Update the deployment type
			$NewDeploymentType = Get-CMDeploymentType -ApplicationName $ApplicationName

            # Set the uninstallation program
            if ($TextBoxUnInstallProgram.Text.Length -gt 0)
			{
                Set-CMScriptDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -UninstallCommand $UninstallationProgram
				Write-Host "Uninstallation program set to: " -NoNewline; Write-Host $UninstallationProgram -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}

            # Set behavior for running installation as 32-bit process on 64-bit systems
            if ($global:RunInstallAs32Bit -eq $true)
            {
                Set-CMScriptDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -Force32Bit $true
                Write-Host "The option " -NoNewline; Write-Host "Run the installation and uninstall programs as 32-bit process on 64-bit clients " -ForegroundColor Green -NoNewline; Write-Host "is set to" -NoNewline; Write-Host " True" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }
            else
            {
                Write-Host "The option " -NoNewline; Write-Host "Run the installation and uninstall programs as 32-bit process on 64-bit clients " -ForegroundColor Green -NoNewline; Write-Host "is set to" -NoNewline; Write-Host " False" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }
            
			Write-Host "Content source path set to: " -NoNewline; Write-Host $ContentSourcePath -ForegroundColor Green
			$ProgressBar1.PerformStep()
			
            # Set the option for fallback source location
            if ($AllowFallbackSourceLocation -eq $true)
            {
                Set-CMScriptDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -ContentFallback $true
                Write-Host "The option " -NoNewline; Write-Host "Allow clients to use a fallback source location for content" -ForegroundColor Green -NoNewline; Write-Host " is set to" -NoNewline; Write-Host " True" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }
            else
            {
                Write-Host "The option " -NoNewline; Write-Host "Allow clients to use a fallback source location for content" -ForegroundColor Green -NoNewline; Write-Host " is set to" -NoNewline; Write-Host " False" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }

            # Set the behavior for clients on slow networks
            if ($DownloadOnSlowNetwork -eq $true)
            {
                Set-CMScriptDeploymentType -ApplicationName $ApplicationName -DeploymentTypeName $NewDeploymentType.LocalizedDisplayName -SlowNetworkDeploymentMode Download
                Write-Host "The behavior for clients on slow networks is set to " -NoNewline; Write-Host "Download content from distribution point and run locally" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }
            else
            {
                Write-Host "The behavior for clients on slow networks is set to " -NoNewline; Write-Host "Do not download content" -ForegroundColor Green
                $ProgressBar1.PerformStep()
            }

			# Distribute content to DP group
			if ($CheckBoxDistributeContent.Checked)
			{
				Start-CMContentDistribution -ApplicationName $ApplicationName -DistributionPointGroupName $DPGroup
				Write-Host "Distributed content for " -NoNewline; Write-Host $ApplicationName -ForegroundColor Green -NoNewline; Write-Host " to " -NoNewline; Write-Host $DPGroup -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}

			# Check if deployment purpose is Available or Required
			if ($RadioButtonRequired.Checked)
			{
				$DeployPurpose = "Required"
			}
			if ($RadioButtonAvailable.Checked)
			{
				$DeployPurpose = "Available"
			}
			
			# Deploy the application
			if ($CheckBoxCreateDeployment.Checked)
			{
				Start-CMApplicationDeployment -CollectionName $AppCollection.Name -Name $ApplicationName -DeployPurpose $DeployPurpose
				Write-Host "Created " -NoNewline; Write-Host $DeployPurpose -ForegroundColor Green -NoNewline; Write-Host " deployment for " -NoNewline; Write-Host $ApplicationName -ForegroundColor Green -NoNewline; Write-Host " to collection " -NoNewline; Write-Host $CollectionName -ForegroundColor Green
				$ProgressBar1.PerformStep()
			}

            Write-Host "IMPORTANT! Remember to manually modify the detection method afterwards." -ForegroundColor Yellow
            $ProgressBar1.PerformStep()
        }

		# Clear the form
		Write-Host "Done!`n" -ForegroundColor Green
		$ProgressBar1.Step = 18
		$ProgressBar1.PerformStep()
		Start-Sleep 1
		Load-Form
	}
}

# Function to control actions when clicking on button 'Use PADT'
function ButtonPADTClick
{
	$SourcePath = $TextBoxSourcePath.Text
	if ($SourcePath -ne "" -and (Split-Path -Leaf $SourcePath) -eq "Files")
	{
		$SourcePath = (Split-Path -Parent $SourcePath)
	}
	
	# Populate text boxes
	$TextBoxMSTFile.Text = ""
	$TextBoxSourcePath.Text = $SourcePath
	if ($PADTInstallProgram -ne "" -and $PADTInstallProgram -ne $null)
    {
        $TextBoxInstallProgram.Text = $PADTInstallProgram
    }
	
    if ($PADTUninstallProgram -ne "" -and $PADTUninstallProgram -ne $null)
    {
        $TextBoxUnInstallProgram.Text = $PADTUninstallProgram
    }
	
	# Disable the MST browse button
	$ButtonMST.Enabled = $False
	$TextBoxMSTFile.Enabled = $False
	
	# Set flag to run installation as 32-bit process on 64-bit systems. This is necessary when using ServiceUI.exe, which is often used in combination with PADT, to display a UI for the user.
	$global:RunInstallAs32Bit = $true
}

# Function with actions when something is typed in the application name textbox
function AppName-Changed
{
	if ($TextBoxAppName.Text -ne "")
	{
    	$TextBoxADGroup.Text = $ADGroupNamePrefix + $TextBoxAppName.Text
        $TextBoxCollection.Text = $TextBoxAppName.Text
        $ErrorProviderAppName.Clear()
		$ButtonCreate.Enabled = $True
	}
	else
	{
		$TextBoxADGroup.Text = ""
        $TextBoxCollection.Text = ""
        $ErrorProviderAppName.SetError($TextBoxAppName, "Please enter a name for the application")
		$ButtonCreate.Enabled = $False
	}
}

# Function with actions when the MSI-package textbox is changed
function MSIFile-Changed
{
    $ErrorProviderMSIPackage.Clear()
    # Update textboxes
    if ($TextBoxMSIPackage.Text.Length -gt 0)
    {
        $TextBoxAppVPackage.Clear()
        $TextBoxInstallProgram.Enabled = $true
        $TextBoxUnInstallProgram.Enabled = $true
        $TextBoxSourcePath.Enabled = $true
    }
}

# Function with actions when the App-V textbox is changed
function AppVName-Changed
{
    $ErrorProviderAppVPackage.Clear()
    # Update textboxes
    $TextBoxSourcePath.Clear()
    $TextBoxSourcePath.Enabled = $false
    $TextBoxInstallProgram.Clear()
    $TextBoxInstallProgram.Enabled = $false
    $TextBoxUnInstallProgram.Clear()
    $TextBoxUnInstallProgram.Enabled = $false
    if ($TextBoxAppVPackage.Text.Length -gt 0)
    {
        $TextBoxMSIPackage.Clear()
        $TextBoxMSTFile.Clear()
        $TextBoxAppName.Text = (Split-Path -Leaf $TextBoxAppVPackage.Text).TrimEnd(".appv")
        $CheckBoxCreateDeployment.Enabled = $true
        $CheckBoxCreateDeployment.Checked = $true
        $CheckBoxDistributeContent.Enabled = $true
        $CheckBoxDistributeContent.Checked = $true
    }
}

# Function with actions when the collection name textbox is changed
function CollectionName-Changed
{
    $ErrorProviderCollection.Clear()
    if ($TextBoxCollection.Text -eq "")
    {
        # If no name for the collection has been specified, we disable the controls to create a collection and a deployment
        $CheckBoxCreateDeployment.Checked = $false
        $CheckBoxCreateDeployment.Enabled = $false
        $CheckBoxCreateCollection.Checked = $false
        $CheckBoxCreateCollection.Enabled = $false
    }
    else
    {
        # If a collection name is specified, we enable the control to create a collection
        $CheckBoxCreateCollection.Enabled = $true
        $CheckBoxCreateCollection.Checked = $true
        
        # If also an App-V package has been selected, or an install program and source path, then we enable the control to create a deployment
        if ($TextBoxAppVPackage.Text.Length -gt 0 -or ($TextBoxInstallProgram.Text.Length -gt 0 -and $TextBoxSourcePath.Text.Length -gt 0))
        {
            $CheckBoxCreateDeployment.Checked = $true
            $CheckBoxCreateDeployment.Enabled = $true
        }
    }
}

# Function with actions when the AD group textbox is changed
function ADGroup-Changed
{
    $ErrorProviderADGroup.Clear()
    if ($TextBoxADGroup.Text -eq "")
    {
        # If no name for the AD group has been specified, we disable the control to create a new group
        $CheckBoxCreateADGroup.Checked = $false
        $CheckBoxCreateADGroup.Enabled = $false
    }
    else
    {
        # If a name for the AD group has been specified, we enable the control to create a new group
        $CheckBoxCreateADGroup.Checked = $true
        $CheckBoxCreateADGroup.Enabled = $true
    }
}

# Function with actions when the source path textbox is changed
function SourcePath-Changed
{
    $ErrorProviderSourcePath.Clear()
    # If both a source path and an installation program has been specified, then we can enable the controls for distributing content and creating deployment and the PADT-button
    if ($TextBoxSourcePath.Text.Length -gt 0 -and $TextBoxInstallProgram.Text.Length -gt 0)
    {
        $CheckBoxDistributeContent.Enabled = $true
        $CheckBoxDistributeContent.Checked = $true
        $ButtonPADT.Enabled = $true
        
        # If a collection is also specified, we enable the control to create a deployment
        if ($TextBoxCollection.Text.Length -gt 0)
        {
            $CheckBoxCreateDeployment.Enabled = $true
            $CheckBoxCreateDeployment.Checked = $true
        }
        else
        {
            $CheckBoxCreateDeployment.Enabled = $false
            $CheckBoxCreateDeployment.Checked = $false
        }
    }
    else
    {
        $CheckBoxDistributeContent.Enabled = $false
        $CheckBoxDistributeContent.Checked = $false
        $CheckBoxCreateDeployment.Enabled = $false
        $CheckBoxCreateDeployment.Checked = $false
        $ButtonPADT.Enabled = $false
    }
}

# Function with actions when the installation program textbox is changed
function InstallProgram-Changed
{
    $ErrorProviderInstallProgram.Clear()
    # If both a source path and an installation program has been specified, then we can enable the controls for distributing content and creating deployment and the PADT-button
    if ($TextBoxSourcePath.Text.Length -gt 0 -and $TextBoxInstallProgram.Text.Length -gt 0)
    {
        $CheckBoxDistributeContent.Enabled = $true
        $CheckBoxDistributeContent.Checked = $true
        $ButtonPADT.Enabled = $true
        
        # If a collection is also specified, we enable the control to create a deployment
        if ($TextBoxCollection.Text.Length -gt 0)
        {
            $CheckBoxCreateDeployment.Enabled = $true
            $CheckBoxCreateDeployment.Checked = $true
        }
        else
        {
            $CheckBoxCreateDeployment.Enabled = $false
            $CheckBoxCreateDeployment.Checked = $false
        }
    }
    else
    {
        $CheckBoxDistributeContent.Enabled = $false
        $CheckBoxDistributeContent.Checked = $false
        $CheckBoxCreateDeployment.Enabled = $false
        $CheckBoxCreateDeployment.Checked = $false
        $ButtonPADT.Enabled = $false
    }
}

# Function to control actions when the create collection checkbox is checked or unchecked
function CheckBoxCreateCollectionChanged
{
    # Currently not in use
}

# Function to control actions when the distribute content checkbox is checked or unchecked
function CheckBoxDistributeContentChanged
{
	# If checkbox to distribute content is not selected, then clear selection to create deployment
	if ($CheckboxDistributeContent.Checked -eq $false)
	{
		$CheckBoxCreateDeployment.Checked = $false
	}
}

# Function to control actions when the create deployment checkbox is checked or unchecked
function CheckBoxCreateDeploymentChanged
{
	# If a deployment is selected to be created, then also create a collection and distribute the content
	if ($CheckboxCreateDeployment.Checked)
	{
		$CheckBoxCreateCollection.Checked = $true
		$CheckBoxDistributeContent.Checked = $true
		$RadioButtonAvailable.Enabled = $true
		$RadioButtonRequired.Enabled = $true
	}
	else
	{
		$RadioButtonAvailable.Enabled = $false
		$RadioButtonRequired.Enabled = $false
	}
}

# Function to control actions when the create AD Group checkbox is checked or unchecked
function CheckBoxCreateADGroupChanged
{
    # Currently not in use
}

# Function to control actions when clicking on button 'Browse' for MSI package
function ButtonMSIClick
{
	# Open the file dialog
	$OpenFileDialogMSI.ShowDialog()
}

# Function to control actions when clicking on button 'Browse' for App-V package
Function ButtonAppVClick
{
	# Open the file dialog
	$OpenFileDialogAppV.ShowDialog()
}

# Function to control actions when opening an MSI file in the file dialog
function OpenMSIFile
{    
	# Set variables based on properties from MSI file
	$MSIFilePath = $OpenFileDialogMSI.FileName
	[string]$MSIFileName = (Split-Path -leaf $MSIFilePath)
	[string]$SourcePath = (Split-Path -Parent $MSIFilePath)
	[string]$ApplicationName = Get-MsiProperty $MSIFilePath "'ProductName'"
	$ApplicationName = $ApplicationName.Trim()
	[string]$ApplicationPublisher = Get-MsiProperty $MSIFilePath "'Manufacturer'"
	$ApplicationPublisher = $ApplicationPublisher.Trim()
	[string]$ApplicationVersion = Get-MsiProperty $MSIFilePath "'ProductVersion'"
	$ApplicationVersion = $ApplicationVersion.Trim()
	[string]$ProductCode = Get-MsiProperty $MSIFilePath "'ProductCode'"
	$ProductCode = $ProductCode.Trim()
	
	# Enable and populate text boxes
	$TextBoxInstallProgram.Enabled = $true
	$TextBoxUnInstallProgram.Enabled = $true
	$TextBoxSourcePath.Enabled = $true
	$TextBoxMSIPackage.Text = $MSIFilePath
	$TextBoxMSTFile.Text = ""
	$TextBoxAppName.Text = $ApplicationName
	$TextBoxPublisher.Text = $ApplicationPublisher
	$TextBoxVersion.Text = $ApplicationVersion
	$TextBoxSourcePath.Text = $SourcePath
	$TextBoxInstallProgram.Text = "msiexec /i ""$MSIFileName"" /q /norestart"
	$TextBoxUnInstallProgram.Text = "msiexec /x $ProductCode /q /norestart"
	
	# Enable the MST browse button
	$ButtonMST.Enabled = $True
	$TextBoxMSTFile.Enabled = $True
	
	# Enable the PADT button
	$ButtonPADT.Enabled = $true
	
	# Enable and check the checkboxes for content and deployment
	$CheckBoxDistributeContent.Enabled = $true
	$CheckBoxDistributeContent.Checked = $true
	$CheckBoxCreateDeployment.Enabled = $true
	$CheckBoxCreateDeployment.Checked = $true
	$RadioButtonAvailable.Enabled = $true
	$RadioButtonRequired.Enabled = $true
}

# Function to control actions when clicking on button 'Browse' for MST file
function ButtonMSTClick
{
	$OpenFileDialogMST.ShowDialog()
	$MSTFile = $OpenFileDialogMST.FileName
	$TextBoxMSTFile.Text = $MSTFile
}

# Function to control actions when opening an MST file in the file dialog
function OpenMSTFile
{
	# Get name of the MST-file
	$MSTFilePath = $OpenFileDialogMST.FileName
	[string]$MSTFileName = (Split-Path -Leaf $MSTFilePath)
	
	# Populate text box
	$TextBoxInstallProgram.Text = $TextBoxInstallProgram.Text + " TRANSFORMS=""$MSTFileName"""
}

# Function to control actions when opening an App-V file in the file dialog
Function OpenAppVFile
{
	# Get name of the appv-file
	$AppVFilePath = $OpenFileDialogAppV.FileName
	
	# Set the App-V package textbox
	$TextBoxAppVPackage.Text = $AppVFilePath
}


# Function to get properties from an MSI package
function Get-MsiProperty
{
	param(
		[string]$Path,
		[string]$Property
	)
	    
	function Get-Property($Object, $PropertyName, [object[]]$ArgumentList)
	{
		return $Object.GetType().InvokeMember($PropertyName, 'Public, Instance, GetProperty', $null, $Object, $ArgumentList)
	}
	 
	function Invoke-Method($Object, $MethodName, $ArgumentList)
	{
		return $Object.GetType().InvokeMember($MethodName, 'Public, Instance, InvokeMethod', $null, $Object, $ArgumentList)
	}
	 
	$ErrorActionPreference = 'Stop'
	Set-StrictMode -Version Latest
	 
	$msiOpenDatabaseModeReadOnly = 0
	$Installer = New-Object -ComObject WindowsInstaller.Installer
	 
	$Database = Invoke-Method $Installer OpenDatabase @($Path, $msiOpenDatabaseModeReadOnly)
	 
	$View = Invoke-Method $Database OpenView  @("SELECT Value FROM Property WHERE Property=$Property")
	 
	Invoke-Method $View Execute
	 
	$Record = Invoke-Method $View Fetch
	if ($Record)
	{
		Write-Output(Get-Property $Record StringData 1)
	}
	 
	Invoke-Method $View Close @( )
	Remove-Variable -Name Record, View, Database, Installer
	 
}

# Function to create a random time stamp
function Random-StartTime
{
	[string]$RandomHour = (Get-Random -Maximum 12) 
	[string]$RandomMinute = (Get-Random -Maximum 59)
	[string]$RandomStartTime = $RandomHour + ":" + $RandomMinute
	return $RandomStartTime
}

# Function to check if an application exists
function Check-ApplicationExist
{
	param(
		[Parameter(
		Position = 0)]
		$AppName
	)
	
	if (Get-CMApplication -Name $AppName)
	{
		return $true
	}
    else
    {
        return $false
    }
}

# Function to check if a collection exists
function Check-CollectionExist
{
	param(
		[Parameter(
		Position = 0)]
		$CollectionName
	)
	
	if (Get-CMCollection -Name $CollectionName)
	{
		return $true
	}
    else
    {
        return $false
    }
}

# Function to check if an AD group exists
function Check-ADGroupExist
{
	param(
		[Parameter(
		Position = 0)]
		$ADGroupName
	)
	
    $GroupExist = Get-ADGroup -Filter {name -eq $ADGroupName}
	if ($GroupExist)
	{
		return $true
	}
    else
    {
        return $false
    }
}


#endregion

#region Event Loop

function Main{
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::Run($Form1)

# Return to the current drive
Set-Location $CurrentLocation
}

#endregion

#endregion

#region Event Handlers

Main # This call must remain below all other event functions

#endregion
