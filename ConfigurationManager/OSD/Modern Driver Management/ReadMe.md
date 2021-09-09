# Modern Driver Management
## Description
Modern Driver Management allows the dynamic downloading and installation of Driver Packages (Not _Driver Packs_) during a Task Sequence (TS) to reduce steps and updates when new hardware is added to the SCCM.
***
## How to set it up
***
### Create Folder Structure
1. On your content source, create a folder sctructure
   * [FileShare]\ModernDriverManagement
   * [FileShare]\ModernDriverManagement\Script
   * [FileShare]\ModernDriverManagement\EmptyFolder_doNOTdelete
2. Create a dummy file
   * [FileShare]\ModernDriverManagement\EmptyFolder_doNOTdelete\DummyFile.txt
3. Ensure these scripts are copied
   * [FileShare]\ModernDriverManagement\\[Create-PackageXMLfile.ps1](../Modern%20Driver%20Management/Create-PackageXMLfile.ps1)
   * [FileShare]\ModernDriverManagement\Script\\[Get-CMCEDynamicPackage.PS1](../Modern%20Driver%20Management/Script/Get-CMCEDynamicPackage.PS1)
4. Create this empty file
   * [FileShare]\Modern Driver Management\EmptyFolder_doNOTdelete\DummyFile.txt

### Create SCCM Packages with content
1. Package Name: **Modern Driver Management Script Package**
   * Content Source: _[FileShare]\ModernDriverManagement\Script_
2. Package Name: **Modern Driver Management EMPTY Package**
   * Content Source: _[FileShare]\ModernDriverManagement\EmptyFolder_doNOTdelete_
3. Do not create a Program
4. Distribute to all DPs

### Create Scheduled tasks/jobs
1. [Driver Automation Tool](https://gallery.technet.microsoft.com/Driver-Tool-Automate-9ddcc010) to download driver packages, extract drivers, and create SCCM Driver Packages
   * DO NOT use the Driver Pack option. Only use **Standard Package** option
   * Schedule regularly (Weekly, Daily, etc.)
2. After the above schedule is run, run the [Create-PackageXMLfile.ps1](../Modern%20Driver%20Management/Create-PackageXMLfile.ps1) file afterward
   * This will create a .\packages.xml file in the [Script](../Modern%20Driver%20Management/Script) folder and trigger an update to the **Modern Driver Management Script Package** content in SCCM
***
### Putting it together in a Task Sequence
1. Create New Group: **Install Drivers**
    > MUST be **_after_** _Apply Operating System_ step, but **_before_** _Apply Windows Settings_ and _Setup Windows and ConfigMgr_ steps
    > 
    > ![InstallDrivers_Order](../Modern%20Driver%20Management/InstallDrivers_Order.jpg)
2. Add a Run PowerShell Script step
   * Step Name: **Dynamically Set PackageID of Drivers to download**
   * Package: `Modern Driver Management Script Package`
   * Script Name: `Get-CMCEDynamicPackage.PS1`
   * Paramters: `-OSVersion 'Windows 10 X64'`
   * PowerShell Execution Policy: `ByPass`
1. Add a Download Package Content step
   * Step Name: **Download Drivers**
   * Add Package: `Modern Driver Management EMPTY Package`
   * Custom Path: `%_SMSTSMDataPath%\Drivers`
2. Add a Run Command Line step
   * Step Name: **DISM Driver Install**
   * Command Line: `DISM.exe /Image:%OSDTargetSystemDrive%\ /Add-Driver /Driver:%_SMSTSMDataPath%\Drivers /Recurse /logpath:%_SMSTSLogPath%\dism.log`
>IMPORTANT: Add Success Code `50` to the Options tab of this step
***
### Creating a Task Sequence to install drivers for Full Windows OS
> This is used for actively used Windows machines, not WinPE
>
> DO NOT add a Boot Image to this TS
1. Create a New Task sequence
2. Create 2 Groups:
   * Download Drivers
   * Install Drivers - Online
     * Add a **Condition** to the **Options** tab:
       * Condition: `Task Sequence Variable`
       * Variable:  `_SMSTSInWinPE`
       * Condition: `equals`
       * Value:     `false`
3. Copy the first two steps from [Putting it together in a Task Sequence](#putting-it-together-in-a-task-sequence) and place them in the **Download Drivers** Group
    * **Dynamically Set PackageID of Drivers to download**
    * **Download Drivers**
4. Create a new step in the **Install Drivers - Online** Group:
    * Type: `Run PowerShell Script`
    * Name: `Driver Install with PNPUtil`
    * Use pacakge with script, or enter it directly
      * [Install-DriversPNPUtil.ps1](../Modern%20Driver%20Management/Driver%20Install%20PNPUtil/Install-DriversPNPUtil.ps1)
      * Parameters: `-DriverFolder "%_SMSTSMDataPath%\Drivers" -StaticLogName`
        > Make sure the above TS Variable matches the Custom Path value from **Download Drivers**
      * Powershell Execution Policy: `Bypass`