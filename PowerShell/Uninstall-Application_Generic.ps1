<#
    Script to Remove existing MSI installations
    Credit to: Patch My PC (patchmypc.com), original script https://patchmypc.com/scupcatalog/downloads/scripts/PatchMyPC-Remove-JDK8-64bit-Only.ps1
    Version 1.1
    Updated by: Nicolas Wendlowsky (https://github.com/hkystar35)
    Updated on: 2021/05/03
    
    Version 1.1 - Changed line 127 to log entry instead of of EXIT since it's inside a foreach loop and could exit before trying other values in App name array
                - Added ShouldProcess for testing
                - Forced log entries during ShouldProcess
                - Created $AppNameStringToMatch variable to change line 122 from static LIKE string
                - Added MSI Product Code regex to filter non-MSI values
                

#> 
[CmdletBinding(SupportsShouldProcess = $true)]
PARAM ()
begin {
    #Set variables#
    $AppsToUninstall = "TeamViewer*"
    $AppNameStringToMatch = "*" # Leave * to not filter any titles. Example value "*(64-bit)*" will only find App Names that have "(64-bit)" in the DisplayName
    $PublisherToUninstall = "TeamViewer*"
    #Set log  path desired if you want to change simply change the loglocation parameter to a folder path the log will alwyays be the name of the script.

    [string]$MSIProductCodeRegExPattern = '^(\{{0,1}([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}\}{0,1})$'
    Function Get-InstSoftware {
        if ([IntPtr]::Size -eq 4) {
            $regpath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        }
        else {
            $regpath = @(
                'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
                'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            )
        }
        Get-ItemProperty $regpath | . { process { if ($_.DisplayName -and $_.UninstallString) { $_ } } } | Select-Object DisplayName, UninstallString, PSChildName, Publisher, InstallDate | Sort-Object -Property DisplayName
    }
    
    Function Start-TSxLog
    { #Set global variable for the write-TSxInstallLog function in this session or script.
        [CmdletBinding()]
        param (
            #[ValidateScript({ Split-Path $_ -Parent | Test-Path })]
            [string]$FilePath
        )
        try {
            if (!(Split-Path $FilePath -Parent | Test-Path)) {
                New-Item (Split-Path $FilePath -Parent) -Type Directory -WhatIf:$false | Out-Null
            }
            #Confirm the provided destination for logging exists if it doesn't then create it.
            if (!(Test-Path $FilePath)) {
                ## Create the log file destination if it doesn't exist.
                New-Item $FilePath -Type File -WhatIf:$false | Out-Null
            }
            ## Set the global variable to be used as the FilePath for all subsequent write-TSxInstallLog
            ## calls in this session
            $global:ScriptLogFilePath = $FilePath
        }
        catch {
            #In event of an error write an exception
            Write-Error $_.Exception.Message
        }
    }

    Function Write-TSxLog
    { #Write the log file if the global variable is set
        param (
            [Parameter(Mandatory = $true)]
            [string]$Message,
            [Parameter()]
            [ValidateSet(1, 2, 3)]
            [string]$LogLevel = 1,
            [Parameter(Mandatory = $false)]
            [bool]$writetoscreen = $true   
        )
        $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
        $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
        $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)", $LogLevel
        $Line = $Line -f $LineFormat
        Add-Content -Value $Line -Path $ScriptLogFilePath -WhatIf:$false
        if ($writetoscreen) {
            switch ($LogLevel) {
                '1' {
                    Write-Verbose -Message $Message
                }
                '2' {
                    Write-Warning -Message $Message
                }
                '3' {
                    Write-Error -Message $Message
                }
                Default {
                }
            }
        }
        if ($writetolistbox -eq $true) {
            $result1.Items.Add("$Message")
        }
    }

    function set-TSxDefaultLogPath {
        #Function to set the default log path if something is put in the field then it is sent somewhere else. 
        [CmdletBinding()]
        param
        (
            [parameter(Mandatory = $false)]
            [bool]$defaultLogLocation = $true,
            [parameter(Mandatory = $false)]
            [string]$LogLocation
        )
        if ($defaultLogLocation) {
            $LogPath = Split-Path $script:MyInvocation.MyCommand.Path
            $LogFile = "$($($script:MyInvocation.MyCommand.Name).Substring(0,$($script:MyInvocation.MyCommand.Name).Length-4)).log"     
            Start-TSxLog -FilePath $($LogPath + "\" + $LogFile)
        }
        else {
            $LogPath = $LogLocation
            $LogFile = "$($($script:MyInvocation.MyCommand.Name).Substring(0,$($script:MyInvocation.MyCommand.Name).Length-4)).log"     
            Start-TSxLog -FilePath $($LogPath + "\" + $LogFile)
        }
    }

}
process {
    set-TSxDefaultLogPath -defaultLogLocation:$false -LogLocation $ENV:TEMP
    foreach ($AppToUninstall in $AppsToUninstall) {
        $Software = Get-InstSoftware | Where-Object { ($_.DisplayName -like $AppToUninstall) -and ($_.DisplayName -like $AppNameStringToMatch) -and ($_.Publisher -like $PublisherToUninstall) -and $_.PSChildName -match $MSIProductCodeRegExPattern}
        Write-TSxLog -Message "Starting log for $(($AppToUninstall.Replace('*', ''))) removal for Patch My PC"
        If ($null -eq $Software) { 
            Write-TSxLog -Message "No match found for $AppToUninstall with string filter $AppNameStringToMatch"
         }
        Else {    
            foreach ($Install in $Software) {
                Write-TSxLog -Message "Now removing $($Install.DisplayName) using command $($Install.PSChildName)"
                Write-TSxLog -Message "Now building the MSI arguments for start process"
                $MSIArguments = @(
                    '/x'
                    $Install.PSChildName
                    '/qn'    
                    '/L*v "C:\Windows\Temp\Uninstall-' + $($Install.DisplayName) + '.log"'
                    'REBOOT=REALLYSUPPRESS'
                )
                
                try {
					IF ($PSCmdlet.ShouldProcess((Write-TSxLog -Message "WHAT IF: Submitting the following arguments to start-process using MSIExec.exe $($MSIArguments)"))) {
                        Write-TSxLog -Message "Now submitting the following arguments to start-process using MSIExec.exe $($MSIArguments)"
						$Results = Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow -ErrorAction Stop -PassThru
						Write-TSxLog -Message "The application was uninstalled with Exit Code: $($Results.ExitCode)"
					}
				}
				CATCH {
					Write-TSxLog -Message "An error occured trying to remove a version of the software it terminated with the error $($_.Exception.Message)" -LogLevel 3
					Write-TSxLog -Message "The Exit code was $($Results.ExitCode)"
				}
				Write-TSxLog -Message "The application has been succesfully removed"
            }
        }
    }
}