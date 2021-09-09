﻿
Function New-ChromeExtension {
    <#
    
    .SYNOPSIS
    Add Chrome Extensions to PC via Powershell
    
    .PARAMETER ExtensionID
    String value of an extension ID taken from the Chrome Web Store URL for the extension
    
    .EXAMPLE
    This will install uBlock Origin
    New-ChromeExtension -ExtensionID 'cjpalhdlnbpafiamejdnhcphjbkeiagm'
    
    .EXAMPLE
    This will install uBlock Origin, and Zoom Meetings
    New-ChromeExtension -ExtensionID @('kgjfgplpablkjnlkjmjdecgdpfankdle', 'cjpalhdlnbpafiamejdnhcphjbkeiagm') -Verbose
    
    .EXAMPLE
    This will install uBlock Origin to the HKCU hive
    New-ChromeExtension -ExtensionID 'cjpalhdlnbpafiamejdnhcphjbkeiagm' -Hive 'HKCU'
    
    #>
    
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String[]]$ExtensionID,
        [Parameter(Mandatory)]
        [ValidateSet('Machine', 'User')]
        [String]$Hive

    )

    #Loop through each Extension in ExtensionID since it is an array.
    #Create a Key for every member of the ExtensionID Array
    Foreach ($Extension in $ExtensionID) {
      
        $regLocation = 'Software\Policies\Google\Chrome\ExtensionInstallForcelist'
        
        #Target HKLM or HKCU depending on whether you want to affect EVERY user, or just a single user.
        #If using HKCU, you'll need to run this script in that user context.
        Switch ($Hive) {
            'Machine' {
                If (!(Test-Path "HKLM:\$regLocation")) {
                    Write-Verbose -Message "No Registry Path, setting count to: 0"
                    [int]$Count = 0
                    Write-Verbose -Message "Count is now $Count" 
                    New-Item -Path "HKLM:\$regLocation" -Force
        
                }
        
                Else {
                    Write-Verbose -Message "Keys found, counting them..."
                    [int]$Count = (Get-Item "HKLM:\$regLocation").Count
                    Write-Verbose -Message "Count is now $Count"
                }
            }
            
            'User' {
                If (!(Test-Path "HKCU:\$regLocation")) {
                    
                    Write-Verbose -Message "No Registry Path, setting count to: 0"
                    [int]$Count = 0
                    Write-Verbose -Message "Count is now $Count" 
                    New-Item -Path "HKCU:\$regLocation" -Force
        
                }
        
                Else {
                    
                    Write-Verbose -Message "Keys found, counting them..."
                    [int]$Count = (Get-Item "HKCU:\$regLocation").Count
                    Write-Verbose -Message "Count is now $Count"
                
                }
            }
        }

        $regKey = $Count + 1
        Write-Verbose -Message "Creating reg key with value $regKey"
        
        $regData = "$Extension;https://clients2.google.com/service/update2/crx"

        Switch ($Hive) {
            
            'Machine' { New-ItemProperty -Path "HKLM:\$regLocation" -Name $regKey -Value $regData -PropertyType STRING -Force }
            'User' { New-ItemProperty -Path "HKCU:\$regLocation" -Name $regKey -Value $regData -PropertyType STRING -Force }
        
        }
    
    }

}
