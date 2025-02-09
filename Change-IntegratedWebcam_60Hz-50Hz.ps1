# This script will modify the PowerFrequency key in the Integrated Webcam of Dell laptop computers
# https://microsoftteams.uservoice.com/forums/555103-public/suggestions/35661376-allow-selection-of-camera-flicker-frequency-betwee
# https://devblogs.microsoft.com/scripting/update-or-add-registry-key-value-with-powershell/

$integratedWebcam = (Get-CimInstance Win32_PnPEntity | where caption -Match 'integrated webcam').pnpDeviceID
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Enum"
$WebcamPath = "$registryPath\$integratedWebcam\Device Parameters"
$Name = "PowerlineFrequency"
$Value = 1 # 1 for 50Hz , 2 for 60Hz

# This command will tell you what PowerlineFreqency is set
# (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Enum\$integratedWebcam\Device Parameters" -Name PowerlineFrequency).PowerlineFrequency

Set-ItemProperty -Path $WebcamPath -Name $Name -Value $Value
