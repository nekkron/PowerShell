$DCUcli = 'C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe'
$RXpro = 'path to reboot restore'
$timestamp = Get-Date -UFormat "%Y%m%d-%R" | ForEach-Object { $_ -replace ":", "." }

START-TRANSCRIPT

# lock computer screen

TASKKILL /IM MSEDGE.EXE
TASKKILL /IM CHROME.EXE
TASKKILL /IM ACROBAT.EXE
TASKKILL /IM ACRO32.EXE # VERIFY FILENAME
TASKKILL /IM WINWORD.EXE
TASKKILL /IM POWERPNT.EXE
TASKKILL /IM OUTLOOK.EXE
TASKKILL /IM EXCEL.EXE
cleanmgr.exe /VERYLOWDISK
cleanmgr.exe /AUTOCLEAN

# check to see if module is already installed, if not, install, otherwise, execute
IF (DCU-CLI exists){
cmd /c $DCUcli /scan -outputLog=C:\ProgramData\Powershell\Dell\DCU-updates.log
}

# check to see if module is already installed, if not, install, otherwise, execute
IF (!(PSWIndowsUpdate exists) {
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PSWindowsUpdate -Force
}
Install-WindowsUpdate -AcceptAll
Restart-Computer -Delay 300
STOP-TRANSCRIPT
