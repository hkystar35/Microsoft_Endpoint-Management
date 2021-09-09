function Find-AzureADStaleDevice {

##########################################################################################################
<#
.SYNOPSIS
    Finds stale Azure Active Directory (AD) devices based on the ApproximateLastLogonTimeStamp attribute. 
    
    Targets either Azure AD joined, Azure AD hybrid joined or Azure AD workplace joined devices. 


.DESCRIPTION

    Get-MsolDevice –All is used by the function to get a list of stale devices, as it has built-in logic
    to skip auto-pilot devices and other system managed devices. It uses the ApproximateLastLogonTimeStamp 
    attribute with the DeviceTrustType attribute value of either 'Azure AD Joined' or 'Domain Joined' or 
    'Workplace Joined' to find stale Azure AD devices. Device trust types are targeted with the -AaDJoined, 
    -HybridJoined and -WorkPlaceJoined switches.
    
    For a cloud device, 'Stale' is defined as the device object in Azure AD as having an ApproximateLastLogonTimeStamp 
    value that is older than the supplied threshold of today minus 60, 90, 120, 150, 180 or 360 days. 
    
    The distinction between Azure AD joined, Azure AD hybrid joined and Azure AD workplace joined devices 
    is important: the -HybridJoined switch also checks if the computer object is 'Stale', 'NotStale' or 
    'Orphaned' in Windows Server Active Directory: 
    
        * 'Stale' is also defined as the on-premises computer account having a LastLogonTimeStamp value that 
          is older than the supplied threshold of today minus 60, 90, 120, 150, 180 or 360 days. 

        * 'NotStale' is defined as as the on-premises computer account having a LastLogonTimeStamp value that
          is NOT older than the supplied threshold of today minus 60, 90, 120, 150, 180 or 360 days. 

        * 'Orphaned' is defined as the device object existing in Azure AD but without a corresponding computer 
          account in Windows Server Active Directory.

    Furthermore, with the -HybridJoined switch, for a Windows 10 device, the function will attempt to 
    match the deviceID of the cloud device to the objectGUID of the on-premises computer account to prove 
    an association. For a down-level device, e.g. Windows 7 or Windows 8, the function will attempt to match
    the DisplayName of the cloud device to the DisplayName of the on-premises computer account to establish 
    an association.

    There are some additional switches only usable with the -HybridJoin switch:
    
        * The -Domain switch is used to specify the target on-premises domain (required)

        * The -IgnoreServers switch omits servers from the array of stale devices, busing the DeviceOSType attribute

        * The -IgnoreDownlevel switch omits down level clients, e.g. Windows 7 or Windows 8, from the array of
          stale devices, based on the DeviceOSVersion attribute


    Finally, some notes on running the function...
     
    IMPORTANT: 

        * The -Verbose switch will help you understand what the function is doing

        * The function requires the MSOnline (vn. 1.1.183.17+) PowerShell module

        * For hybrid Azure AD device matching, the function needs the Windows Server Active Directory PowerShell 
          module and has to be able to contact a domain controller from the target on-premises domain
          

.EXAMPLE

    Find-AzureADStaleDevice -StaleThreshold 60 -AadJoined

    Finds and lists any Azure AD joined devices that have an ApproximateLastLogonTimeStamp older than 
    60 days. 
                           

.EXAMPLE

    Find-AzureADStaleDevice -StaleThreshold 150 -HybridJoined -Domain contoso.com

    Finds and lists any Azure AD hybrid joined devices that have an ApproximateLastLogonTimeStamp older than 
    150 days, associating it with the corresponding on-premises computer account, in the contoso.com domain, 
    highlighting if the on-premises account is stale, notstale or orphaned. 


.EXAMPLE

    Find-AzureADStaleDevice -StaleThreshold 180 -HybridJoined -Domain wingtiptoys.com -IgnoreServers

    Finds and lists any Azure AD hybrid joined devices, ignoring servers, that have an ApproximateLastLogonTimeStamp 
    older than 180 days, associating it with the corresponding on-premises computer account, in the wingtiptoys.com 
    domain, highlighting if the on-premises account is stale, notstale or orphaned. 
                           

.EXAMPLE

    Find-AzureADStaleDevice -StaleThreshold 150 -HybridJoined -Domain fabrikam.com -IgnoreDownLevel 

    Finds and lists any Azure AD hybrid joined devices, ignoring down level clients, that have an 
    ApproximateLastLogonTimeStamp older than 150 days, associating it with the corresponding on-premises 
    computer account, in the fabrikam.com domain, highlighting if the on-premises account is stale, notstale 
    or orphaned. 
    

.EXAMPLE

    Find-AzureADStaleDevice -StaleThreshold 150 -HybridJoined -Domain adatum.com -IgnoreDownLevel -IgnoreServers

    Finds and lists any Azure AD hybrid joined devices, ignoring down level clients and servers, that have an 
    ApproximateLastLogonTimeStamp older than 60 days, associating it with the corresponding on-premises 
    computer account, in the adatum.com domain, highlighting if the on-premises account is stale, notstale 
    or orphaned. 


.EXAMPLE

    Find-AzureADStaleDevice -StaleThreshold 120 -WorkPlaceJoined -Verbose

    Finds and lists any WorkPlace joined devices that have an ApproximateLastLogonTimeStamp 
    older than 120 days. Shows verbose output during function execution.


.EXAMPLE

    Find-AzureADStaleDevice -StaleThreshold 90 -AadJoined | Export-Csv .\stale_aadjoined.csv

    Finds Azure AD joined devices that have an ApproximateLastLogonTimeStamp older than 
    90 days. Exports the findings to a csv file called stale_aadjoined.csv in the present working
    directory.


.NOTES
    THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED 
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR 
    FITNESS FOR A PARTICULAR PURPOSE.

    This sample is not supported under any Microsoft standard support program or service. 
    The script is provided AS IS without warranty of any kind. Microsoft further disclaims all
    implied warranties including, without limitation, any implied warranties of merchantability
    or of fitness for a particular purpose. The entire risk arising out of the use or performance
    of the sample and documentation remains with you. In no event shall Microsoft, its authors,
    or anyone else involved in the creation, production, or delivery of the script be liable for 
    any damages whatsoever (including, without limitation, damages for loss of business profits, 
    business interruption, loss of business information, or other pecuniary loss) arising out of 
    the use of or inability to use the sample or documentation, even if Microsoft has been advised 
    of the possibility of such damages, rising out of the use of or inability to use the sample script, 
    even if Microsoft has been advised of the possibility of such damages.

#>

##########################################################################################################

#Version: 3.1

##########################################################################################################

    ################################
    #Define and validate Parameters
    ################################

    [CmdletBinding(SupportsShouldProcess,DefaultParameterSetName="AadJoined")]
    param(

          #The number of days before which accounts are considered stale
          [Parameter(Mandatory,Position=0)]
          [ValidateSet(60,90,120,150,180,360)] 
          [int32]$StaleThreshold,

          #The switch targets Azure AD joined devices
          [Parameter(Position=1,ParameterSetName="AadJoined")]
          [switch]$AadJoined,

          #The switch targets Azure AD workplace joined devices
          [Parameter(Position=2,ParameterSetName="WorkPlaceJoined")]
          [switch]$WorkPlaceJoined,

          #The switch targets Azure AD hybrid joined devices
          [Parameter(Position=3,ParameterSetName="HybridJoined")]
          [switch]$HybridJoined,

          #The target Windows Server Active Directory domain in which to find Azure AD hybrid joined devices
          [Parameter(Mandatory,Position=4,ParameterSetName="HybridJoined")]
          #[ValidateScript({Get-ADDomain -Server $_})] 
          [string]$Domain,

          #Omits servers from the array of stale devices for -HybridJoined mode
          [Parameter(Position=5,ParameterSetName="HybridJoined")]
          [switch]$IgnoreServers,

          #Omits downlevel devices from the array of stale devices for -HybridJoined mode
          [Parameter(Position=6,ParameterSetName="HybridJoined")]
          [switch]$IgnoreDownLevel

          )


##########################################################################################################
    
    ##################
    #region FUNCTIONS
    ##################


    #############################################################################
    #The Windows Server AD get function used for additional hybrid join checking
    function Get-ADStaleDevice {

        #Define and validate Parameters
        [CmdletBinding()]
        param(
            #The number of days before which accounts are considered stale
            [Parameter(Mandatory,Position=0)]
            [int32]$StaleThreshold,

            #The target Windows Server Active Directory computer account
            [Parameter(Mandatory,Position=1)] 
            [string]$Computer,

            #The target Windows Server Active Directory computer account
            [Parameter(Mandatory,Position=2)] 
            [string]$Identity,

            #The target Windows Server Active Directory domain
            [Parameter(Position=3)]
            [string]$Domain

        )

        #Obtain a datetime object before which accounts are considered stale
        $DaysAgo = (Get-Date).AddDays(-$StaleThreshold) 


        #See if the computer exists in Windows Server Active Directory
        try {

            $CompAccount = Get-ADComputer -Identity $Identity -Property LastLogonDate -Server $Domain

        }

        catch {}


        #Check we have the stuff and return it
        if ($CompAccount) {

            #Write verbose output
            Write-Verbose -Message "$(Get-Date -f T) - Found Windows Server AD computer account for $Computer"
            Write-Verbose -Message "$(Get-Date -f T) - Checking if the computer account for $Computer is stale"

            #Check staleness
            if ($CompAccount.LastLogonDate -lt $DaysAgo) {
                
                #write verbose output 
                Write-Verbose -Message "$(Get-Date -f T) - $Computer is stale in Windows Server Active Directory"

                #Return that the computer is stale
                $OnPremComp = [pscustomobject]@{

                    ObjectGUID = $CompAccount.ObjectGUID
                    DistinguishedName = $CompAccount.DistinguishedName
                    Status = "Stale"
                    LastLogonDate = Get-Date $CompAccount.LastLogonDate -Format G
                    Enabled = $CompAccount.Enabled 

                }

            }
            else {

                #write verbose output 
                Write-Verbose -Message "$(Get-Date -f T) - $Computer is not stale in Windows Server Active Directory"

                #Return that the computer is stale
                $OnPremComp = [pscustomobject]@{

                    ObjectGUID = $CompAccount.ObjectGUID
                    DistinguishedName = $CompAccount.DistinguishedName
                    Status = "NotStale"
                    LastLogonDate = Get-Date $CompAccount.LastLogonDate -Format G
                    Enabled = $CompAccount.Enabled

                }
                

            }   #end of if / else 

        }
        else {

            #Write verbose output
            Write-Verbose -Message "$(Get-Date -f T) - No Windows Server Active Directory computer account found for $Computer"
            Write-Verbose -Message "$(Get-Date -f T) - Marking $Computer as orphaned"

            #Return that the computer is 'orphaned'
                $OnPremComp = [pscustomobject]@{
                    
                    ObjectGUID = "N/A"
                    DistinguishedName = "N/A"
                    Status = "Orphaned"
                    LastLogonDate = "N/A"
                    Enabled = "N/A"

                }           


        }   #end of if / else

        
        #Return the computer value
        return $OnPremComp


    }  #end of function


    #endregion FUNCTIONS


##########################################################################################################

    #############
    #region MAIN
    #############


    #######################################################
    #Check for modules and good version of MSOnline module
    
    #Try and get MSOnline module 
    $MSOnline = Get-Module -ListAvailable MSOnline -Verbose:$false -ErrorAction SilentlyContinue

    if ($MSOnline) {

        #Write verbose output
        Write-Verbose -Message "$(Get-Date -f T) - ============================"
        Write-Verbose -Message "$(Get-Date -f T) - STAGE 1 - PRELIMINARY CHECKS"
        Write-Verbose -Message "$(Get-Date -f T) - ============================"
        Write-Verbose -Message "$(Get-Date -f T) - MSOnline PowerShell module installed"

        #Variable for module version match
        $Match = $false

        #Check module version
        foreach ($Module in $MSOnline) {
            
            #Check each installed module version and set $Match to true if we get a version above 1.1.183.17
            if (($($Module.version.Major) -ge 1) -and  ($($Module.version.Minor) -ge 1) -and `
               ((($($Module.version.Build) -eq 183) -and ($($Module.version.Revision) -ge 17)) -or ($($Module.version.Build) -ge 184))) {

                $Match = $true
                $Version = "$($Module.version.Major).$($Module.version.Minor).$($Module.version.Build).$($Module.version.Revision)"

            }   #end of if version match


        }   #end of ForEach-Object 


        #Check if we have a module version match
        if ($Match) {

            #Write verbose output
            Write-Verbose -Message "$(Get-Date -f T) - MSOnline PowerShell module is a good version - $Version"

            #Check for Windows Server Active Directory if looking for hybrid joined machines
            if ($HybridJoined) {
            
                #Try and get Windows Server Active Directory module 
                $ActiveDirectory = Get-Module -ListAvailable ActiveDirectory -Verbose:$false -ErrorAction SilentlyContinue

                if ($ActiveDirectory) {

                    #Write verbose output
                    Write-Verbose -Message "$(Get-Date -f T) - ActiveDirectory PowerShell module installed"
                
                }
                else {

                    #Write error and exit
                    Write-Error -Message "For -Hybridjoined please install the Windows Server Active Directory PowerShell module and ensure you have line of site to a domain controller for the target domain - $Domain." `
                    -ErrorAction Stop

                }   #end of if ($ActiveDirectory)


            }   #end if ($HybridJoined)


                ################################
                #Now check for cloud connection

                $Connected = Get-MsolDomain -ErrorAction SilentlyContinue

                if (($Connected) -and ($Error[0].Exception -notlike "You must call*")) {


                    ################################################
                    #Set device trust type based on supplied switch
                    if ($AadJoined) {

                        $DeviceTrustType = "Azure AD Joined"

                        #Write verbose output
                        Write-Verbose -Message "$(Get-Date -f T) - ============================"
                        Write-Verbose -Message "$(Get-Date -f T) - STAGE 2 - SEARCHING DEVICES"
                        Write-Verbose -Message "$(Get-Date -f T) - ============================"
                        Write-Verbose -Message "$(Get-Date -f T) - Searching for Azure AD joined devices"

                    }
                    elseif ($HybridJoined) {

                        $DeviceTrustType = "Domain Joined"

                        #Write verbose output
                        Write-Verbose -Message "$(Get-Date -f T) - ============================"
                        Write-Verbose -Message "$(Get-Date -f T) - STAGE 2 - SEARCHING DEVICES"
                        Write-Verbose -Message "$(Get-Date -f T) - ============================"
                        Write-Verbose -Message "$(Get-Date -f T) - Searching for Azure AD hybrid joined devices"


                    }
                    elseif ($WorkPlaceJoined) {

                        $DeviceTrustType = "Workplace Joined"

                        #Write verbose output
                        Write-Verbose -Message "$(Get-Date -f T) - ============================"
                        Write-Verbose -Message "$(Get-Date -f T) - STAGE 2 - SEARCHING DEVICES"
                        Write-Verbose -Message "$(Get-Date -f T) - ============================"
                        Write-Verbose -Message "$(Get-Date -f T) - Searching for Azure AD hybrid joined devices"


                    }
                    else {
    
                        #Write an error to the host
                        Write-Error -Message "Please supply either the -AadJoined, -HybridJoined or the -WorkPlaceJoined switch" 
        
    
                    }   #end of if / elseif / else



                    #####################################################################
                    #Obtain a datetime object before which accounts are considered stale
                    $DaysAgo = Get-Date (Get-Date).AddDays(-$StaleThreshold) 


                    #Write verbose output
                    Write-Verbose -Message "$(Get-Date -f T) - Stale threshold set to $DaysAgo"



                    ##############################################################
                    #Check if we're ignoring servers or downlevel clients or both
                    if (($IgnoreServers) -and (!$IgnoreDownLevel)) {


                        #Write verbose output
                        Write-Verbose -Message "$(Get-Date -f T) - Running with -IgnoreServers switch"


                        #Get the stuff
                        $Devices = Get-MsolDevice -All -LogonTimeBefore $DaysAgo -ReturnRegisteredOwners -ErrorAction SilentlyContinue |  
                                    Where-Object {($_.DeviceTrustType -eq $DeviceTrustType) -and ($_.DeviceOSType -notlike "*Server*")}

                    }
                    elseif ((!$IgnoreServers) -and ($IgnoreDownLevel)) {


                        #Write verbose output
                        Write-Verbose -Message "$(Get-Date -f T) - Running with -IgnoreDownLevel switch"


                        $Devices = Get-MsolDevice -All -LogonTimeBefore $DaysAgo -ReturnRegisteredOwners -ErrorAction SilentlyContinue |  
                                    Where-Object {($_.DeviceTrustType -eq $DeviceTrustType) -and ($_.DeviceOSVersion -notlike "6*")}


                    }
                    elseif (($IgnoreServers) -and ($IgnoreDownLevel)) {


                        #Write verbose output
                        Write-Verbose -Message "$(Get-Date -f T) - Running with -IgnoreServers and -IgnoreDownLevel switches"


                        $Devices = Get-MsolDevice -All -LogonTimeBefore $DaysAgo -ReturnRegisteredOwners -ErrorAction SilentlyContinue |  
                                    Where-Object {($_.DeviceTrustType -eq $DeviceTrustType) `
                                                    -and ($_.DeviceOSVersion -notlike "6*" `
                                                    -and ($_.DeviceOSType -notlike "*Server*"))}

                    }
                    else {

                        #Get the stuff
                        $Devices = Get-MsolDevice -All -LogonTimeBefore $DaysAgo -ReturnRegisteredOwners -ErrorAction SilentlyContinue |  
                                    Where-Object {$_.DeviceTrustType -eq $DeviceTrustType}


                    }   #end of if ($IgnoreServers)



                    #######################################
                    #Check we have the stuff and return it
                    if ($Devices) {

                        #Write verbose output
                        Write-Verbose -Message "$(Get-Date -f T) - Found $($Devices.Count) Azure AD stale device(s)"
                        Write-Verbose -Message "$(Get-Date -f T) - ============================"


                        #Ascertain if we need to do an on-premises staleness check
                        if ($AadJoined -or $WorkPlaceJoined) {

                            $CloudDevices = $Devices | Select-Object DisplayName,DeviceTrustType,DeviceTrustLevel,DeviceOSType, `
                                                                        DeviceOSVersion,RegisteredOwners,ObjectId,DeviceId, `
                                                                        Enabled,@{n='Status';e={'Stale'}},ApproximateLastLogonTimeStamp
                                                                                                 
                        }
                        elseif ($HybridJoined) {


                            #Write verbose output
                            Write-Verbose -Message "$(Get-Date -f T) - Performing on-premises computer account check for each stale cloud device"
                            Write-Verbose -Message "$(Get-Date -f T) - ============================"


                            #loop through devices
                            foreach ($Device in $Devices) {


                                #run on-prem discovery function - for a downlevel device we attempt to match on display name rather than deviceID
                                if ($Device.DeviceOSVersion -like "6*") {

                                    #Write verbose output
                                    Write-Verbose -Message "$(Get-Date -f T) - Attempting match on display name for $($Device.DisplayName)"

                    
                                    #Call function with displayname / displayname match
                                    $OnPremComp = Get-ADStaleDevice -StaleThreshold $StaleThreshold -Identity $Device.DisplayName `
                                                                    -Computer $Device.DisplayName -Domain $Domain -ErrorAction SilentlyContinue
                
                                }
                                else {

                                    #Write verbose output
                                    Write-Verbose -Message "$(Get-Date -f T) - Attempting match on device ID for $($Device.DisplayName)"


                                    #Call function with Device ID / on-prem GUID match
                                    $OnPremComp = Get-ADStaleDevice -StaleThreshold $StaleThreshold -Identity $Device.DeviceId `
                                                                    -Computer $Device.DisplayName -Domain $Domain -ErrorAction SilentlyContinue

                                }   #end of if / else

                
                                #if we have a match create a custom object   
                                if ($OnPremComp) {
                        
                                    #Write verbose output
                                    Write-Verbose -Message "$(Get-Date -f T) - Creating PS custom object for hybrid device" 

                                    #create new PS object
                                    $HybridDevice = [pscustomobject]@{

                                        DisplayName = $Device.DisplayName 
                                        DeviceTrustType = $Device.DeviceTrustType
                                        DeviceTrustLevel = $Device.DeviceTrustLevel
                                        DeviceOSType = $Device.DeviceOSType
                                        DeviceOSVersion = $Device.DeviceOSVersion
                                        RegisteredOwners = $Device.RegisteredOwners
                                        CloudObjectId = $Device.ObjectId
                                        CloudDeviceId = $Device.DeviceId
                                        OnPremGUID = $OnPremComp.ObjectGUID
                                        OnPremDn = $OnPremComp.DistinguishedName
                                        CloudEnabled = $Device.Enabled
                                        OnPremEnabled = $OnPremComp.Enabled
                                        CloudStatus = "Stale"
                                        OnPremStatus = $OnPremComp.Status
                                        CloudLastLogonTimeStamp = $Device.ApproximateLastLogonTimeStamp
                                        OnPremLastLogonTimeStamp = $OnPremComp.LastLogonDate

                                    }

                                    #Write verbose output
                                    Write-Verbose -Message "$(Get-Date -f T) - Adding PS custom object for hybrid device to array"
                                    Write-Verbose -Message "$(Get-Date -f T) - ============================" 

                                    #add new object to array
                                    [array]$HybridDevices += $HybridDevice


                                }
                                else {

                                    #Write verbose output
                                    Write-Verbose -Message "$(Get-Date -f T) - Unable to retrieve on-premises computer account object for $($Device.DisplayName)"                  


                                }   #end of if /else ($OnPremCOmp)


                            }   #end of foreach
                

                        }   #end of if / elseif


                        ##########################################
                        #Now run one of the three execution modes
                        switch ($LifeCycleMode) {


                            ############
                            #Mode: List
                            default {

                                #Verbose output
                                Write-Verbose -Message "$(Get-Date -f T) - STAGE 3 - FUNCTION MODE"
                                Write-Verbose -Message "$(Get-Date -f T) - ============================"
                                Write-Verbose -Message "$(Get-Date -f T) - Using default list mode"


                                if ($CloudDevices) {

                                    if ($AadJoined) {
                    
                                        #Verbose output
                                        Write-Verbose -Message "$(Get-Date -f T) - Listing stale Azure AD joined devices"

                                    }
                                    elseif ($WorkPlaceJoined) {

                                        #Verbose output
                                        Write-Verbose -Message "$(Get-Date -f T) - Listing stale Azure AD registered devices"

                                    }

                                    #List cloud devices
                                    $CloudDevices

                                }
                                elseif ($HybridDevices) {
 
                                    #Verbose output
                                    Write-Verbose -Message "$(Get-Date -f T) - Listing Azure AD hybrid joined devices"

                                    #List cloud devices
                                    $HybridDevices                 
                   

                                }   #end of if / else


                            }   #end default


                        }   #end of switch

                    }
                    else {

                        #Write verbose output
                        Write-Verbose -Message "$(Get-Date -f T) - No stale devices found"
                        Write-Verbose -Message "$(Get-Date -f T) - Exiting function"


                    }   #end of if / else for device trust type


                }   
                else {
                
                    #Write error and exit
                    Write-Error "Please use Connect-MsolService to logon to your tenant"
               

                }   #end of if logon check


            #} #missing


        }
        else {

            #Write error and exit
            Write-Error "Please install a version of the MSOnline PowerShell module above 1.1.183.17"


        }   #end of if ($Match)


    } else {

        #Write error and exit
        Write-Error "Please install the latest MSOnline PowerShell module"


    }   #end of if ($MSOnline)


    #endregion MAIN


}   #end of function Find-AzureADStaleDevice


##########################################################################################################
