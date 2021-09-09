$Computers = 'nicwendlowsky' #,'clintsmith2','davidjohnson'
$CompInfoOutput = @()
$DriverInfo = @()

foreach($Computer in $Computers){
    $CompInfoOutput += Invoke-Command -ComputerName $Computer -ArgumentList $CompInfoArray -ScriptBlock {
        param($CompInfoArray)
        $CompInfoArray += Get-ComputerInfo | select *
        $CompInfoArray
    }
    $DriverInfo += Invoke-Command -ComputerName $Computer -ArgumentList $DriverInfoArray -ScriptBlock {
        param($DriverInfo){
            $DriverInfoArray += Get-WmiObject -Class Win32_PnPSignedDriver | select -Property PSComputerName,DeviceName,DeviceID,@{LABEL='DriverDate';EXPRESSION={$_.converttoDateTime($_.DriverDate)}},DriverVersion,IsSigned
            $DriverInfoArray
        }
    }
}

$HeaderOrder = "CsName,WindowsBuildLabEx,WindowsEditionId,WindowsProductId,WindowsProductName,WindowsSystemRoot,WindowsVersion,BiosCharacteristics,BiosBIOSVersion,BiosCaption,BiosCurrentLanguage,BiosDescription,BiosEmbeddedControllerMinorVersion,BiosFirmwareType,BiosInstallableLanguages,BiosListOfLanguages,BiosManufacturer,BiosName,BiosPrimaryBIOS,BiosReleaseDate,BiosSeralNumber,BiosSMBIOSBIOSVersion,BiosSMBIOSMajorVersion,BiosSMBIOSMinorVersion,BiosSMBIOSPresent,BiosSoftwareElementState,BiosStatus,BiosSystemBiosMajorVersion,BiosSystemBiosMinorVersion,BiosTargetOperatingSystem,BiosVersion,CsAdminPasswordStatus,CsAutomaticManagedPagefile,CsAutomaticResetBootOption,CsAutomaticResetCapability,CsBootOptionOnLimit,CsBootOptionOnWatchDog,CsBootROMSupported,CsBootStatus,CsBootupState,CsChassisBootupState,CsCurrentTimeZone,CsDaylightInEffect,CsDescription,CsDomainRole,CsEnableDaylightSavingsTime,CsFrontPanelResetStatus,CsHypervisorPresent,CsInfraredSupported,CsKeyboardPasswordStatus,CsManufacturer,CsModel,CsNetworkServerModeEnabled,CsNumberOfLogicalProcessors,CsNumberOfProcessors,CsPartOfDomain,CsPauseAfterReset,CsPCSystemType,CsPCSystemTypeEx,CsPowerOnPasswordStatus,CsPowerState,CsPowerSupplyState,CsResetCapability,CsResetCount,CsResetLimit,CsRoles,CsStatus,CsSystemFamily,CsSystemSKUNumber,CsSystemType,CsThermalState,CsTotalPhysicalMemory,CsPhyicallyInstalledMemory,CsWakeUpType,CsWorkgroup,OsName,OsType,OsOperatingSystemSKU,OsVersion,OsBuildNumber,OsHotFixes,OsBootDevice,OsSystemDevice,OsSystemDirectory,OsSystemDrive,OsWindowsDirectory,OsCountryCode,OsCurrentTimeZone,OsLocaleID,OsLocale,OsLocalDateTime,OsLastBootUpTime,OsUptime,OsBuildType,OsCodeSet,OsDataExecutionPreventionAvailable,OsDataExecutionPrevention32BitApplications,OsDataExecutionPreventionDrivers,OsDataExecutionPreventionSupportPolicy,OsDebug,OsDistributed,OsEncryptionLevel,OsForegroundApplicationBoost,OsTotalVisibleMemorySize,OsFreePhysicalMemory,OsTotalVirtualMemorySize,OsFreeVirtualMemory,OsInUseVirtualMemory,OsTotalSwapSpaceSize,OsSizeStoredInPagingFiles,OsFreeSpaceInPagingFiles,OsPagingFiles,OsHardwareAbstractionLayer,OsInstallDate,OsManufacturer,OsMaxNumberOfProcesses,OsMaxProcessMemorySize,OsMuiLanguages,OsNumberOfLicensedUsers,OsNumberOfProcesses,OsNumberOfUsers,OsArchitecture,OsLanguage,OsProductSuites,OsPortableOperatingSystem,OsPrimary,OsProductType,OsServicePackMajorVersion,OsServicePackMinorVersion,OsStatus,OsSuites,KeyboardLayout,TimeZone,PowerPlatformRole,HyperVisorPresent,DeviceGuardSmartStatus,DeviceGuardRequiredSecurityProperties,DeviceGuardAvailableSecurityProperties,DeviceGuardSecurityServicesConfigured,DeviceGuardSecurityServicesRunning,RunspaceId,PSShowComputerName"
$CompInfoOutput | Export-Excel -Path C:\Temp\BSOD-Info2.xlsx -WorkSheetname 'ComputerInfo'
$DriverInfo | Export-Excel -Path C:\Temp\BSOD-Info2.xlsx -WorkSheetname 'DriverInfo'