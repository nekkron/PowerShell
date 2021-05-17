# Reference: https://www.powers-hell.com/2020/05/04/create-a-bootable-windows-10-autopilot-device-with-powershell/
# Download PowerShell 7
Invoke-Expression "& { $(Invoke-RestMethod -Method Get -Uri "https://aka.ms/install-powershell.ps1") } -UseMSI"
# Install helper modules & functions
Install-Module WindowsAutoPilotIntune -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Intune -Scope CurrentUser -Force
Install-Module Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser -Force
# Install USB creator module
Install-Module Intune.USB.Creator -Scope CurrentUser -Force

# Download the latest .ISO of Windows 10
# https://www.microsoft.com/en-us/software-download/windows10

# RUN AS ADMIN
Publish-ImageToUSB -winPEPath "https://githublfs.blob.core.windows.net/storage/WinPE.zip" -windowsIsoPath "C:\path\to\win10.iso" -getAutopilotCfg
