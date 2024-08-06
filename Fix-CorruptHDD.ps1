Chkdsk
Chkdsk /r /f /x
Get-Volume | Where Drivetype -eq 'fixed' | foreach {repair-volume -driveletter $_.driveletter -Scan}
Get-Volume | Where Drivetype -eq 'fixed' | foreach {repair-volume -driveletter $_.driveletter -SpotFix}
Get-Volume | Where Drivetype -eq 'fixed' | foreach {repair-volume -driveletter $_.driveletter -OfflineScanandFix}
Repair-Volume -Driveletter C -Scan ; Repair-Volume -DriveLetter C -SpotFix ; Repair-Volume -DriveLetter C -OfflineScanAndFix
C:\Windows\Sysnative\DISM.exe /online /cleanup-image /scanhealth
C:\Windows\Sysnative\DISM.exe /online /cleanup-image /checkhealth
C:\Windows\Sysnative\DISM.exe /online /cleanup-image /repairhealth
sfc /scannow
chkdsk
chkdsk /f /r /x
bootrec /rebuildbcd
bootrec /fixboot
bootrec /fixmbr
Write-Host "Filesystem corruption has been corrected. Rebooting in 15 seconds..."
Restart-Computer -delay 15