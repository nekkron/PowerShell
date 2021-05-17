# Find if BMC Cliemt Management Agent is installed
If (-not (Test-Path -Path "$env:ProgramFiles\BMC Software\Client Management\Client\bin\mtxagent.exe")){
    Write-Host BMC Client Management Agent is not present on this machine! -ForegroundColor Yellow
    Exit 0
} Else {
	Write-Host BMC Agent is installed. Executing uninstaller.
	Start-Process -FilePath BCM_Silent_Uninstaller.exe -Wait
    Copy-Item -Path BCM_Silent_Uninstaller.log -Destination C:\support\BCM_Uninstall.log -Force
}

If (-not (Test-Path -Path "$env:ProgramFiles\BMC Software\Client Management\Client\bin\mtxagent.exe")){
Write-Host BMC Client Management Agent was successfully uninstalled. -ForegroundColor Green
exit 0
} Else {
Write-Host BMC Client Management Agent is still installed! -ForegroundColor Red
exit 1618
}
