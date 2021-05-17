# Find if BMC Cliemt Management Agent is installed
If (-not (Test-Path -Path "$env:ProgramFiles\Cylance\Desktop\CyProtect.exe")){
    Write-Host Cylance is not present on this machine! -ForegroundColor Yellow
    Exit 0
} Else {
	Write-Host BMC Agent is installed. Executing uninstaller.
}

If (-not (Test-Path -Path "$env:ProgramFiles\Cylance\Desktop\CyProtect.exe")){
Write-Host Cylance was successfully uninstalled. -ForegroundColor Green
exit 0
} Else {
Write-Host Cylance is still installed! -ForegroundColor Red
exit 1618
}
