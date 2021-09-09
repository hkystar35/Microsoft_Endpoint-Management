<# Give you timeleft before NewYear
Wish you an happy NewYear if 1st january #>

Function Get-HappyNewYear {
  # Variables
  $DateTime = Get-Date
  $CurrentYear = $DateTime.Year
  $NextYear = $CurrentYear + 1
  $TimeLeft = New-TimeSpan -Start (Get-Date) -End ("01-01-$NextYear" -as [datetime])

  $d = $TimeLeft.Days
  $m = $TimeLeft.Minutes
  $s = $TimeLeft.Seconds
  
  if ($d -gt 1) { $day = "days";$Verb = 'are' } else { $day = "day";$Verb = 'is' }
  if ($m -gt 1) { $minute = "minutes" } else { $minute = "minute" }
  if ($s -gt 1) { $second = "seconds" } else { $second = "second" }
  $Totalh = [math]::Round($TimeLeft.TotalHours)
  if ($Totalh -gt 1) { $hour = "hours" } else { $hour = "hour" }

  # Job
  Write-Host "There $Verb $d $day, $m $minute and $s $second left before the New Year!"

  if ((Get-Date).Day -eq 1 -and (Get-Date).Month -eq 1 ) {
    Write-Host "But, actually it's 1st January so... HAPPY NEW YEAR $ActualYear !!!" -ForegroundColor Red -BackgroundColor Yellow
    Add-Type -AssemblyName System.speech
    $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer

    $speak.Speak("But, actually it's 1st January so... HAPPY NEW YEAR $ActualYear !!!")
    $speak.Dispose()
    $newYear = $true
  }
  else {
    Write-Host "So... Be patient, the new year is in $Totalh $hour and $m $minute !"
    Add-Type -AssemblyName System.speech
    $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer

    $speak.Speak("So... Be patient, the new year is in $Totalh $hour and $m $minute !")
    $speak.Dispose()
    $newYear = $false
  }
}

Do {
  Clear-host
  Get-HappyNewYear
  sleep 10
} Until ($newYear -eq $true)