Add-Type -AssemblyName System.Speech
Invoke-WebRequest 'https://raw.githubusercontent.com/nekkron/PowerShell/main/ForFun/QuoteOfTheDay/QOTD.txt' -OutFile $env:USERPROFILE/QOTD.txt
$Speaker = [Speech.Synthesis.SpeechSynthesizer]::new()
$Speaker.Speak((Get-Random -InputObject (Get-Content "$env:USERPROFILE/QOTD.txt")))
