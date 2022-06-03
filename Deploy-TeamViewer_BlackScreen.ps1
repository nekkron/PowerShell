<# 
The purpose of this script is to download an image from the Internet and install it into the TeamViewer folder for a custom black (lockout) screen.
Reference: https://community.teamviewer.com/English/kb/articles/50966-teamviewer-black-screen
  20220411 - James Kasparek - Senior Regional IT Support Technician
#>

#Image location on the Internet. File must be .png for TeamViewer!
$url = "https://us.v-cdn.net/6032394/uploads/R2SWSOWXQ8U6/6-black-screen-community.png"
#Path for where file is being downloaded
$TVlockout = "${env:ProgramFiles(x86)}\TeamViewer"

if (Test-Path -Path "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" -PathType Leaf) {
     try {
        #Downloads the above URL to the specified directory with the desired filename
        Invoke-WebRequest $url -OutFile $TVlockout\LockoutScreen.png
        #Add registry key to allow custom black (lockout) screen
        New-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\TeamViewer" -Name "CustomBlackScreen" -Value "$TVlockout\LockoutScreen.png"
        Write-Host "The TeamViewer custom black screen imagery and settings have been applied."
     }
     catch {
         throw $_.Exception.Message
     }
 }
# If TeamViewer isn't installed
 else {
     Write-Host "TeamViewer is not installed on this device!"
 }
