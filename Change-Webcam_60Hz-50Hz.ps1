<#
    ===========================================================================
	 Created on:   	2025/02/09
	 Created by:   	James Kasparek
	 Filename:     	Change-Webcam_60Hz-50Hz.ps1
     URL:           https://github.com/nekkron/PowerShell/
	===========================================================================

.DESCRIPTION
    This script will modify the PowerFrequency key of USB webcams to 50Hz

.NOTES
    When computers or webcams are purchased from the USA or Japan and used elsewhere in the world, 
    video flickering can be extremely annoying. As Europe uses 220v (50Hz) electricity, compared to 110v (60Hz)
    this script forces the camera frequency from 60Hz to 50Hz to match with the electrical frequency the light
    emits around the user.

.LINK
    https://microsoftteams.uservoice.com/forums/555103-public/suggestions/35661376-allow-selection-of-camera-flicker-frequency-betwee
    https://devblogs.microsoft.com/scripting/update-or-add-registry-key-value-with-powershell/
#>
Start-Transcript -Path "$env:TEMP\Change-WebcamFrequency_60Hz-50Hz.log" -Append
$webcams = (Get-CimInstance Win32_PnPEntity | Where-Object caption -Match "web cam").pnpDeviceID
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Enum"
$Name = "PowerlineFrequency"
$Value = 1 # 1 for 50Hz , 2 for 60Hz

foreach ($webcam in $webcams) {
    if ($webcam -like "USB\*") {
        $WebcamPath = "$registryPath\$webcam\Device Parameters"
        $originalValue = (Get-ItemProperty -Path $WebcamPath -Name $Name).$Name
        if ($originalValue -ne $Value) {
            Set-ItemProperty -Path $WebcamPath -Name $Name -Value $Value
            Write-Output "Webcam: $webcam - Original Value: $originalValue, Modified Value: $Value"
        } else {
            Write-Output "Webcam: $webcam - Value already set to $Value"
        }
    }
}
Stop-Transcript
