# Attempt to uninstall any existing Cylance
if ((Get-Service CylanceSvc -ErrorAction SilentlyContinue)) {
    $cylanceGUID = Get-WmiObject -Class win32_Product | Where-Object {$_.Name -match "Cylance PROTECT"} | Select-Object -ExpandProperty IdentifyingNumber
#    Start-Process -FilePath "$Env:systemroot\system32\msiexec.exe" -ArgumentList "/x $cylanceGUID /qn /norestart /L*v C:\support\cylance-uninstall.log" -Wait
    Write-Host check log file
}

If ((Test-Path 'C:\Program Files\Cylance\Desktop\CyProtect.exe')) {
    Write-Error -Message "Cylance PROTECT is still installed!" -ErrorId 1618
    exit 1
} ELSE {
    Write-Host Cyclance was successfully uninstalled
    exit 0
}
