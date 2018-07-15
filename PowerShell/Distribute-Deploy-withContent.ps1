# prompt for name
[string]$AppInput = Read-Host -Prompt "`nApp Name? (Uses wildcard search)"

# find apps matching search, filter expired/retired
$CMAppNames = Get-CMApplication -Name "*$AppInput*" | Where-Object {$_.IsExpired -eq $false} | select LocalizedDisplayName,SoftwareVersion,IsEnabled,IsExpired,PackageID

# new psobject with choices for prompt
$i = 0
$Choices = @()
$CMAppNames | foreach{
    $i=$i+1
    $Choices += New-Object -TypeName 'PSObject' -Property @{
        Choice    = $i
        Name      = $($_.LocalizedDisplayName)
        Version   = $($_.SoftwareVersion)
        PackageID = $($_.PackageID)
    }
}
Write-Host ""
$Choices | foreach{Write-Host "$($_.Choice) - $($_.Name) ($($_.Version) - PkgID=$($_.PackageID))"}

    do {
        write-host -NoNewline "`nType your choice and press Enter: "
        
        $choice = read-host
        
        $ok = $choice -match '^[0-9]+$'
        
        if ( -not $ok) { write-host "Invalid selection" }
    } until ( $ok )
$Choice = $Choices | Where-Object {$_.Choice -eq $Choice}

$DeploymentTarget = Read-Host "`n1 EUC Testing`n2 All Users`n3 All Workstations`n4 All Workstations HelpDesk`nDeploy to"
switch($DeploymentTarget){
    1{$CollectionNames = 'EUC.Test Applications.Analysts','EUC.Test Applications.Leadership'}
    2{$CollectionNames = 'All Users and User Groups'}
    3{$CollectionNames = 'All Windows Workstations'}
    4{$CollectionNames = 'All Windows Workstations_HelpDesk'}
}

$DistroGroup = Get-CMDistributionPointGroup | select Name,Description
$DistroGroup | foreach{
    Write-Host "Distributing $($Choice.name) content to $($_.Name) ..." -NoNewline
    Start-CMContentDistribution -ApplicationName "$($Choice.name)" -DistributionPointGroupName $_.Name
    Write-Host " done!"
}

$CollectionNames | foreach{
    Write-Host "Deploying $($Choice.name) to collection $_ ..." -NoNewline
    New-CMApplicationDeployment -CollectionName "$_" -Name "$($Choice.name)" -ApprovalRequired $False -DeployAction Install -DeployPurpose Available -UserNotification DisplaySoftwareCenterOnly
    Write-Host " done!"
}


$BodyEUC = @"
All,

Please go to the AppStore and install this application and report back.

Name - $($Choice.name)
Version - $($Choice.version)
Deployed To - Collections
Expected Behavior - Will prompt to close existing processes before installing

Thank you!

Nic
"@
    
$CC = @("First Last <f.last@domain.com>")
$To = @("First Last <f.last@domain.com>")
$From = 'f.last@domain.com'
$SMTP = 'mail.domain.com'
$Subject = "New App Testing - $($Choice.name)"

if($DeploymentTarget -eq 1){
    $Email = Read-Host -Prompt "Send Email to EUC? Y/N"
    if($Email -eq 'y'){
        Send-MailMessage -Body $BodyEUC -Cc $CC -From $From -SmtpServer $SMTP -Subject $Subject -To $To -Bcc $From
    }
}