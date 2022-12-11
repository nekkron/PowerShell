$DCUcli = 'C:\Program Files (x86)\Dell\CommandUpdate\dcu-cli.exe'
$RXpro = 'path to reboot restore'
$timestamp = Get-Date -UFormat "%Y%m%d-%R" | ForEach-Object { $_ -replace ":", "." }

Start-Transcript -Append -IncludeInvocationHeader -Path C:\ProgramData\Powershell\RebootRestoreMaintenance.log

# lock computer screen with rx pro

TASKKILL /IM MSEDGE.EXE
TASKKILL /IM CHROME.EXE
TASKKILL /IM ACROBAT.EXE
TASKKILL /IM ACRO32.EXE # VERIFY FILENAME
TASKKILL /IM WINWORD.EXE
TASKKILL /IM POWERPNT.EXE
TASKKILL /IM OUTLOOK.EXE
TASKKILL /IM EXCEL.EXE
Remove-Item C:\Users\USOTROOP\Desktop\* -Recurse -Force
Remove-Item C:\Users\USOTROOP\Documents\* -Recurse -Force
Remove-Item C:\Users\USOTROOP\Downloads\* -Recurse -Force
Remove-Item C:\Users\USOTROOP\Pictures\* -Recurse -Force

cleanmgr.exe /VERYLOWDISK
cleanmgr.exe /AUTOCLEAN

# check to see if DCU is already installed, if not, complain
IF (DCU-CLI exists){
cmd /c $DCUcli /scan -outputLog=C:\ProgramData\Dell\logs\updates\%timestamp.log
cmd /c $DCUcli /applyUpdates -reboot=disable -outputLog=C:\ProgramData\Dell\logs\updates\$timestamp.log
}ELSE{
Write-Warning "Dell Command Update is not installed!"
}

# check to see if module is already installed, if not, install, otherwise, execute
IF (!(PSWIndowsUpdate exists) {
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PSWindowsUpdate -Force
}

Install-WindowsUpdate -AcceptAll -IgnoreReboot

Get-ChildItem –Path "C:\ProgramData\Dell\logs\updates" -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-365))} | Remove-Item
Restart-Computer -Delay 300
STOP-TRANSCRIPT
