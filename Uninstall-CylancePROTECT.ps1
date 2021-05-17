# Uninstall Cylance PROTECT
# https://support.cylance.com/s/article/How-to-Uninstall-CylancePROTECT62

msiexec /x {2E64FC5C-9286-4A31-916B-0D8AE4B22954} /quiet UNINSTALLKEY="CylancePassword"

If ((Test-Path 'C:\Program Files\Cylance\Desktop\CyProtect.exe')) {
    Write-Error -Message "Cylance PROTECT is still installed!" -ErrorId 1618
    exit 1
} ELSE {
    Write-Host Cyclance was successfully uninstalled
    exit 0
}
