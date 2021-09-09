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
  $Totalh = [math]::Round($TimeLeft.TotalHours)
  
  SWITCH($d){
    {$_ -eq 0 -or $_ -ge 2}{
      $day = "days"
      $Verb = 'are'
    }
    {$_ -eq 1}{
      $day = "day"
      $Verb = 'is'
    }
  }
  
  SWITCH($m){
    {$_ -eq 0 -or $_ -ge 2}{
      $minute = "minutes"
    }
    {$_ -eq 1}{
      $minute = "minute"
    }
  }
  
  SWITCH($d){
    {$_ -eq 0 -or $_ -ge 2}{
      $second = "seconds"
    }
    {$_ -eq 1}{
      $second = "second"
    }
  }

  SWITCH($Totalh){
    {$_ -eq 0 -or $_ -ge 2}{
      $hour = "hours"
    }
    {$_ -eq 1}{
      $hour = "hour"
    }
  }
  
  Add-Type -AssemblyName System.speech
  $speak = New-Object System.Speech.Synthesis.SpeechSynthesizer

  if ($DateTime.Day -eq 1 -and $DateTime.Month -eq 1 ) {
    $AlreadyNewYear = "It's 1st January so... HAPPY NEW YEAR $CurrentYear !!!"
    Write-Host $AlreadyNewYear -ForegroundColor Red -BackgroundColor Yellow
    $speak.Speak($AlreadyNewYear)
    $speak.Dispose()
    $newYear = $true
  }
  else {
    $GettingThere = "So... Be patient, the new year is in $Totalh $hour and $m $minute !"
    Write-Host "There $Verb $d $day, $m $minute and $s $second left before the New Year!"
    Write-Host $GettingThere
    $speak.Speak($GettingThere)
    $speak.Dispose()
    $newYear = $false
  }
}

Do {
  Clear-host
  Get-HappyNewYear
  sleep 1
} Until ($newYear -eq $true)