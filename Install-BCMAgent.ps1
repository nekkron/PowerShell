Write-Host Installing, Repairing or Updating BMC Agent
# Find if BMC Cliemt Management Agent is installed
If (-not (Test-Path -Path "$env:ProgramFiles\BMC Software\Client Management\Client\bin\mtxagent.exe")){
    Write-Host BMC Client Management Agent is not present on this machine!
    Write-Host Now installing BMC Client Management Software
    Start-Process -FilePath .\BCM_Silent_Installer.exe -Wait
    Copy-Item -Path BCM_Silent_Installer.log -Destination C:\support\BCM_Install.log -Force
} Else {
	Write-Host BMC Agent is already installed. Executing reinstaller.
	Start-Process -FilePath BCM_Silent_Reinstaller.exe -Wait
    Copy-Item -Path BCM_Silent_Reinstaller.log -Destination C:\support\BCM_Reinstall.log -Force
	Write-Host BMC Client Management Agent has been reinstalled.
	Write-Host Now updating configuration files.
    Copy-Item -Path mtxagent.ini -Destination "$env:ProgramFiles\BMC Software\Client Management\Client\config\" -Force
	ATTRIB +R "$env:ProgramFiles\BMC Software\Client Management\Client\config\mtxagent.ini"
}

If (Test-Path -Path "$env:ProgramFiles\BMC Software\Client Management\Client\bin\mtxagent.exe"){
Write-Host BMC Client Management installed Successfully. -ForegroundColor Green
exit 0
} Else {
Write-Host BMC Client Management failed to install. -ForegroundColor Red
exit 1
}
