$var = Start-Process -FilePath "$env:windir\system32\winrm.cmd" -ArgumentList 'quickconfig -force' -Wait -PassThru
$var.ExitCode$var
