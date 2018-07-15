#FUNCTION New-EMailGun {
	[CmdletBinding()]
	PARAM
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$UserName,
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$MailTo,
		[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$DeferDate,
		[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][string]$AttachmentPath,
		[switch]$Reminder = $false
	)
	
	# Variables
	$TLD = '.com'
	$Domain = 'yourdomain'
	$EmailDomain = 'euc.' + $Domain + $TLD
	$From = "email@subdomain." + $Domain + $TLD
	$CC = $UserName + '@' + $Domain + $TLD
	$APIkey = 'yourMailGunAPIkey'
	$URL = "https://api.mailgun.net/v3/$($EmailDomain)/messages"
	$DateFull = Get-Date -Format "dddd, MMMM dd 'at' hh:mmtt"
	$DeferDateFull = $DeferDate | Get-Date -Format "dddd, MMMM dd 'at' hh:mmtt" -ErrorAction SilentlyContinue
	
	#region Machine Info
	$MachineInfo = Get-WmiObject -Class Win32_ComputerSystem
	$OSInfo = Get-WmiObject -Class Win32_OperatingSystem
	$Serial = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber
	$MachineName = $machineinfo.Name
	SWITCH ($OSInfo.Version) {
		6.3.9600 {
			$OSVersion = ('Windows 8.1 ({0})' -f $OSInfo.Version)
		}
		10.0.16299 {
			$OSVersion = ('Windows 10 1709 ({0})' -f $OSInfo.Version)
		}
		10.0.15063 {
			$OSVersion = ('Windows 10 1703 ({0})' -f $OSInfo.Version)
		}
		10.0.14393 {
			$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
		}
		10.0.10586 {
			$OSVersion = ('Windows 10 1511 ({0})' -f $OSInfo.Version)
		}
		10.0.16299 {
			$OSVersion = ('Windows 10 1709 ({0})' -f $OSInfo.Version)
		}
		10.0.15063 {
			$OSVersion = ('Windows 10 1703 ({0})' -f $OSInfo.Version)
		}
		10.0.14393 {
			$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
		}
		10.0.10586 {
			$OSVersion = ('Windows 10 1511 ({0})' -f $OSInfo.Version)
		}
		10.0.14393 {
			$OSVersion = ('Windows 10 1607 ({0})' -f $OSInfo.Version)
		}
		10.0.10240 {
			$OSVersion = ('Windows 10 1507 (RTM) ({0})' -f $OSInfo.Version)
		}
	}
	$OSArch = $OSInfo.OSArchitecture
	$MachineManuf = $machineinfo.Manufacturer
	$MachineModelNo = $machineinfo.Model
	$MachineModelName = $machineinfo.SystemFamily
	$NICIndex = Get-CimInstance -ClassName Win32_IP4RouteTable | Where-Object {
		$_.Destination -eq '0.0.0.0' -and $_.Mask -eq '0.0.0.0'
	} | Sort-Object Metric1 | Select-Object -First 1 | Select-Object -ExpandProperty InterfaceIndex
	$AdapterConfig = Get-CimInstance -ClassName Win32_NetworkAdapter | Where-Object {
		$_.InterfaceIndex -eq $NICIndex
	} | Get-CimAssociatedInstance -ResultClassName Win32_NetworkAdapterConfiguration
	$IPAddress = $AdapterConfig.IPAddress
	$MachineInfoText = @"
Here's my machine info:
Machine Name: $MachineName
OS: $OSVersion $OSArch
Manufacturer: $MachineManuf
Model: $MachineModelName ($($MachineModelNo))
Serial Number: $Serial
Last IP address: $IPAddress
"@
	#endregion Machine Info
	
	#region Set Subject and Body based on Deferral or Reminder
	IF ($Reminder) {
		$Subject = ('Windows 10 In-Place Upgrade / {0} / TOMORROW' -f $UserName)
		$BodyText = @"
This is a reminder that you chose to upgrade your machine to Windows 10 tomorrow, $DateFull.


Thank you and we hope you enjoy the new hotness!


"@
	}ELSEIF ([string]$DeferDate -as [datetime]) {
		$Subject = ('Windows 10 In-Place Upgrade / {0} / Deferred Until {1}' -f $UserName, $DeferDate)
		$BodyText = @"
This is a record of my In-Place Upgrade choice:

On $DateFull, I was prompted to Upgrade to Windows 10. I chose to defer until $DeferDateFull.

$MachineInfoText

"@
	} ELSE {
		$Subject = ('Windows 10 In-Place Upgrade / {0} / Today - ({1})' -f $UserName, (Get-Date -Format "dd/MM/yyyy HH:mm:ss"))
		$BodyText = @"
On $DateFull I was prompted to Upgrade to Windows 10 and I have chosen to upgrade now.

Please contact me in about 2 hours to see how it's going.

$MachineInfoText


"@
	}
	#endregion Set Subject and Body based on Deferral
	
	#region function ConvertTo-MimeMultiPartBody
	FUNCTION ConvertTo-MimeMultiPartBody {
		PARAM ([Parameter(Mandatory = $true)][string]$Boundary,
			[Parameter(Mandatory = $true)][hashtable]$Data)
		
		$body = "";
		$Data.GetEnumerator() | ForEach-Object {
			$name = $_.Key
			$value = $_.Value
			
			$body += "--$Boundary`r`n"
			$body += "Content-Disposition: form-data; name=`"$name`""
			IF ($value -is [byte[]]) {
				$fileName = $Data['FileName']
				IF (!$fileName) {
					$fileName = $name
				}
				$body += "; filename=`"$fileName`"`r`n"
				$body += 'Content-Type: application/octet-stream'
				$value = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($value)
			}
			$body += "`r`n`r`n" + $value + "`r`n"
		}
		RETURN $body + "--$boundary--"
	}
	#endregion function ConvertTo-MimeMultiPartBody
	
	#region Mail Attachment
	
	FUNCTION New-MailGunAttachment ($From, $Mailto, $Subject, $BodyText, $EmailDomain, $APIkey) {
		$headers = @{
			Authorization  = "Basic " + ([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("api:$($apikey)")))
		}
		#region Set Attachment if exist
		IF ($AttachmentPath) {
			$AttachmentFileName = Split-Path -Path $AttachmentPath -Leaf
			$email_parms = @{
				from	  = "$From";
				to	      = "$MailTo";
				cc	      = "$CC";
				subject   = "$Subject";
				text	  = "$BodyText";
				filename  = "$AttachmentFileName"
				attachment = ([IO.File]::ReadAllBytes("$AttachmentPath"));
			}
		} ELSE {
			$email_parms = @{
				from	 = "$From";
				to	     = "$MailTo";
				cc	     = "$CC";
				subject  = "$Subject";
				text	 = "$BodyText";
			}
		}
		#endregion Set Attachment if exist
		
		$boundary = [guid]::NewGuid().ToString()
		$body = ConvertTo-MimeMultiPartBody $boundary $email_parms
		$RestResult = (Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ContentType "multipart/form-data; boundary=$boundary").message
		$RestOutput = New-Object -TypeName psobject
		$RestProperties = @{
			'Result' = $RestResult
		}
		$RestOutput | Add-Member -NotePropertyMembers $RestProperties
		$RestOutput
	}
	#endregion Mail Attachment
	
	# Generate Email
	$FunctionResult = New-MailGunAttachment -From $From -Mailto $MailTo -Subject $Subject -BodyText $BodyText -EmailDomain $EmailDomain -APIkey $APIkey
	$FunctionResult
#}