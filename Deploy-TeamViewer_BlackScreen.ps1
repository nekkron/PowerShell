<# 
The purpose of this script is to download an image from the Internet and install it into the TeamViewer folder for a custom black (lockout) screen.
Reference: https://community.teamviewer.com/English/kb/articles/50966-teamviewer-black-screen
  20220603 - James Kasparek - Senior Regional IT Support Technician
#>

if (Test-Path -Path "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" -PathType Leaf) {
     try {
        Invoke-WebRequest https://us.v-cdn.net/6032394/uploads/R2SWSOWXQ8U6/6-black-screen-community.png -OutFile "C:\Program Files (x86)\TeamViewer\LockoutScreen.png" -ErrorAction Stop
        New-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\TeamViewer" -Name "CustomBlackScreen" -Value "C:\Program Files (x86)\TeamViewer\LockoutScreen.png" -Force -ErrorAction Stop
        Write-Host "The TeamViewer custom black screen imagery and settings have been applied."
     }
     catch {
         throw $_.Exception.Message
     }
 } 
 else {
     Write-Host "TeamViewer is not installed on this device!"
 }
