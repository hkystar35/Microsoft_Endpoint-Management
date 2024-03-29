
 #############################################################################
# Author  : Eswar Koneti 
# Website : www.eskonr.com
# Twitter : @eskonr
# Created : 22/June/2016
#updated  : 29/08/2017
# Purpose : This script create software update deployments based on the information you provide in CSV file
# Supported on ConfigMgr 1702 and above versions due to change in powershell cmdlets

#############################################################################

Try
{
  import-module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
  $SiteCode=Get-PSDrive -PSProvider CMSITE
  cd ((Get-PSDrive -PSProvider CMSite).Name + ':')

}
Catch
{
  Write-Host "[ERROR]`t SCCM Module couldn't be loaded. Script will stop!"
  Exit 1
}

# Determine script location
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
$CSVFile  = "$ScriptDir\Create_SUDeployments.csv"
$log      = "$ScriptDir\CreateSUDeployments.log"
$date     = Get-Date -Format "dd-MM-yyyy hh:mm:ss"
"---------------------  Script started at $date (DD-MM-YYYY hh:mm:ss) ---------------------" + "`r`n" | Out-File $log -append

$vars=Import-CSV $CSVFile #| ForEach-Object 

foreach ($var in $vars)
{

 $GroupName=$var.SUName
 $CollName=$var.CollName
 $DeploymentName=$var.DeploymentName
 $DeployType=$var.DeployType
 $AvailableDate=$var.AvailableDate
 $AvailableTime=$var.AvailableTime
 $DeadlineDate=$var.DeadlineDate
 $DeadlineTime=$var.DeadlineTime
 [boolean]$IgnoreMWforInstall=[System.Convert]::ToBoolean($var.MWInstall)
 [boolean]$IgnoreMWforRestart=[System.Convert]::ToBoolean($var.MWRestart)
 [boolean]$RestartServer= [System.Convert]::ToBoolean($var.RestartSer)
 [boolean] $RestartWorkstation=[System.Convert]::ToBoolean($var.Restartwrk)

#Get the deployments
$Deployments=gwmi -Namespace root\sms\site_$($SiteCode) -Class SMS_UpdatesAssignment -Filter "AssignmentName=""$DeploymentName"""
#Check if the deployment name already exist or not
if($Deployments.AssignmentName)
        {
		Write-Host "[INFO]`t Deployment $DeploymentName already exist ,Please use different name"
		"Deployment $DeploymentName already exist ,Please use different name" | Out-File $log -append }
else {
# if the deployment doesnt exist ,start creating it
New-CMSoftwareUpdateDeployment -SoftwareUpdateGroupName "$GroupName" -CollectionName "$CollName" `
-DeploymentName "$DeploymentName" -DeploymentType "$DeployType" -SendWakeUpPacket $False -VerbosityLevel AllMessages `
-TimeBasedOn LocalTime -AvailableDateTime $AvailableDate  -DeadlineDateTime $DeadlineDate `
-UserNotification DisplayAll -SoftwareInstallation $IgnoreMWforInstall -AllowRestart $IgnoreMWforRestart `
-RestartServer $RestartServer -RestartWorkstation $RestartWorkstation -PersistOnWriteFilterDevice $False -GenerateSuccessAlert $false `
-DisableOperationsManagerAlert $false -GenerateOperationsManagerAlert $false -ProtectedType RemoteDistributionPoint -UseBranchCache $false `
-DownloadFromMicrosoftUpdate $false -UseMeteredNetwork $false -RequirePostRebootFullScan $True

if ($error) {
Write-Host "[INFO]`t Could not create SU Deployment $($DeploymentName) ,Please check further"
            "$date [INFO]`t Could not SU Deployment $($DeploymentName) ,Please check further: $error"| Out-File $log -append
            $error.Clear()
            }
    else {                    
    Write-Host "[INFO]`t Created SU Deployment : $($DeploymentName)"
            "$date [INFO]`t Created SU Deployment : $($DeploymentName)" | Out-File $log -append
         }
	}
}	
  "---------------------  Script finished at $date (DD-MM-YYYY hh:mm:ss) ---------------------" + "`r`n" | Out-File $log -append