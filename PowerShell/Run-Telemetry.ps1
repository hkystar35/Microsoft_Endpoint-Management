$Output = Start-Process -FilePath "$env:windir\system32\CompatTelRunner.exe" -ArgumentList '-m:appraiser.dll -f:DoScheduledTelemetryRun ent' -PassThru -Wait
$Output