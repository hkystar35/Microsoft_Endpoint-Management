$SoftwareName = 'LastLogon_2018-11-02'
$CollectionName = 'All Windows Workstations'

$strCurrentTimeZone = (Get-WmiObject win32_timezone).StandardName
$TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone)


#Run summary
Invoke-CMDeploymentSummarization -CollectionName $CollectionName -SoftwareName $SoftwareName

Start-Sleep -Seconds 30

$LastLogonDeployment = Get-CMDeployment -CollectionName $CollectionName -SoftwareName $SoftwareName
$Total = $LastLogonDeployment.NumberTargeted.ToString('N0')
$Compliant = $LastLogonDeployment.NumberSuccess.ToString('N0')
$CompliantPercent = ($Compliant/$Total).ToString("P")
$Noncompliant = $LastLogonDeployment.NumberOther.ToString('N0')
$NoncompliantPercent = ($Noncompliant/$Total).ToString("P")
$Unknown = $LastLogonDeployment.NumberUnknown.ToString('N0')
$UnknownPercent = ($Unknown/$Total).ToString("P")
$SummTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($LastLogonDeployment.SummarizationTime, $TZ)



$ToEmailAddresses = 'mkraemer@contoso.com'
$FromEmailAddresses = 'hkystar35@contoso.com'
$CCEmailAddresses = $FromEmailAddresses

$EmailSubject = "Outlook Disable Autocomplete - Numbers {0}" -f (Get-Date -Format yyyy-MM-dd)
$EmailBody = @"

Numbers accurate as of: {0} {5}

Total machines: {1}
Compliant: {2} ({6})
Noncompliant: {3} ({7})
Unknown: {4} ({8})

Compliant = Last logon event happened after we enforced the Autocomplete setting on Friday

Noncompliant = Last logon event happened prior to enforcing the Autocomplete setting on Friday

Unknown = Machine hasn’t reported back a status yet. Mix of offline and machines not on VPN or with slower connections



Nic hkystar35 | End User Computing Engineer

contoso | hkystar35@contoso.com

C: 208.972.1757 | O: 224.857.5353 | EUC: 888-729-5624 (4526 –internal)

EUC Self-Help | askeuc@contoso.com

"@ -f $SummTime,$Total,$Compliant,$Noncompliant,$Unknown,$tz.StandardName,$CompliantPercent,$NoncompliantPercent,$UnknownPercent

#Send-MailMessage -To $ToEmailAddresses -From $FromEmailAddresses -Cc $CCEmailAddresses -Subject $EmailSubject -Body $EmailBody -SmtpServer post.contoso.com
$EmailBody
#Clear-Variable EmailBody,LastLogonDeployment
