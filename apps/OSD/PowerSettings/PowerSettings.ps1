<#
.SYNOPSIS
  Changes Power Settings in Windows
.DESCRIPTION
  Tries first to use GWMI for setting. If fails, uses powercfg.exe
.PARAMETER -Plan
    Specifies the plan to set. Default = Bal
.INPUTS
  Bal = Balanced
  High = High Performance
  Save = Power Saver
  Conf = Client Conference - Always on all the time (High Perf + no sleep/dim)
.OUTPUTS
  none
.NOTES
  Version:        1.0
  Author:         Nicolas Wendlowsky
  Creation Date:  09/20/2017
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\PowerSettings.ps1 -Plan Bal
#>
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$false)]
  [ValidateSet('Bal','High','Save','Conf')]
  [string]$Plan = 'Bal'
)

Set-NetAdapterAdvancedProperty -Name Wi-Fi -DisplayName "Preferred Band" -DisplayValue "3. Prefer 5.2GHz band" -ErrorAction SilentlyContinue
Set-NetAdapterAdvancedProperty -Name Wi-Fi -DisplayName "Roaming Aggressiveness" -DisplayValue "5. Highest" -ErrorAction SilentlyContinue
$SetWirelessAdapter = 

if($plan -eq "High"){
    $PlanName = "High Performance"
    $PlanGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
}
if($plan -eq "Bal"){
    $PlanName = "Balanced"
    $PlanGUID = "381b4222-f694-41f0-9685-ff5bb260df2e"
}
if($plan -eq "Save"){
    $PlanName = "Power Saver"
    $PlanGUID = "a1841308-3541-4fab-bc81-f71556f20b4a"
}
if($plan -eq "Conf"){
    #$PlanName = "High Performance"
    $PlanGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
#
$PlanGUID = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
# scheme, wireless,                           Wireless Settings                    0 = (seconds = 20 mins)
    PowerCfg.exe /setacvalueindex  $PlanGUID 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0
# scheme, hard disk,                           powerdown after                      0 = (seconds = 20 mins)
    PowerCfg.exe /setacvalueindex  $PlanGUID 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0
# scheme, sleep,                               sleep after                          0 = NEVER SLEEP
    PowerCfg.exe /setacvalueindex  $PlanGUID 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0
# scheme, sleep,   allow hybrid sleep   0 = OFF (Don't allow hybrid)
    PowerCfg.exe /setacvalueindex  $PlanGUID 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0
# scheme, sleep,         hibernate after       0 = NEVER HIBERNATE
    PowerCfg.exe /setacvalueindex  $PlanGUID 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0
# scheme, sleep,          allow wake timers     1 = Enabled
    PowerCfg.exe /setacvalueindex  $PlanGUID 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d 1
# scheme, USB,         USB selective suspend    0 = Disabled (Don't allow selective suspend)
    PowerCfg.exe /setacvalueindex  $PlanGUID 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
# scheme, PCI Express,       Link state pwr management   0 = Off
    PowerCfg.exe /setacvalueindex  $PlanGUID 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0
# scheme, Processor power management,    Minimum processor state     100 = Max
    PowerCfg.exe /setacvalueindex  $PlanGUID 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100
# scheme, Processor power management,    Maximum processor state     100 = Max
    PowerCfg.exe /setacvalueindex  $PlanGUID 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100
# scheme, Display,        Dim Display after     0 = (seconds = 0 minutes)
    PowerCfg.exe /setacvalueindex  $PlanGUID 7516b95f-f776-4464-8c53-06167f40cc99 17aaa29b-8b43-4b94-aafe-35f64daaf1ee 0
# scheme, Display,        Turn off Display after      0 = (seconds = 0 minutes)
    PowerCfg.exe /setacvalueindex  $PlanGUID 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 0
# scheme, Multimedia settings,     When sharing media       1 = Prevent idling to sleep
    PowerCfg.exe /setacvalueindex  $PlanGUID 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 03680956-93bc-4294-bba6-4e0f09bb717f 1
# scheme, Multimedia settings,     When playing video       0 = Optimize video quality
    PowerCfg.exe /setacvalueindex  $PlanGUID 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0
# scheme, Internet Explorer,       JavaScript Timer Frequency     1 = Maximize performance
    PowerCfg.exe /setacvalueindex  $PlanGUID b14a8f96-7b67-4e78-8192-b890b1a62b8a 4c793e7d-a264-42e1-87d3-7a0d2f523ccd 1
# scheme, Buttons,       			Lid Close Action			   0 = Do Nothing
    PowerCfg.exe /setacvalueindex  $PlanGUID 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0
    PowerCfg.exe /setdcvalueindex $PlanGUID 4f971e89-eebd-4455-a8de-9e59040e7347 5ca83367-6e45-459f-a27b-476b1d01c936 0

# Sets pf as active
PowerCfg.exe /s "$PlanGUID"
#>
}

if($Plan -ne 'Conf'){
    $p = Get-CimInstance -Name root\cimv2\power -Class win32_PowerPlan -Filter "ElementName = `"$PlanName`"" -ErrorAction SilentlyContinue
    if($p){
        #write-host "Not empty: $p"
        Invoke-CimMethod -InputObject $p -MethodName Activate
    }elseif(!$p){
        #Write-Host "Empty. See? --> $p <--Nothing"
        PowerCfg.exe /s "$PlanGUID"
        }
}