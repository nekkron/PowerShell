Add-Type -AssemblyName System.Speech
$Speaker = [Speech.Synthesis.SpeechSynthesizer]::new()
$Speaker.Speak((Invoke-RestMethod 'https://catfact.ninja/fact').fact)
