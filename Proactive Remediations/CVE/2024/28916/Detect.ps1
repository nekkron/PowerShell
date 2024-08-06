# https://www.cve.org/CVERecord?id=CVE-2024-28916
# https://msrc.microsoft.com/update-guide/vulnerability/CVE-2024-28916
$AppxVersion = (Get-AppxPackage Microsoft.GamingServices).Version

if ($AppxVersion -ge "19.87.13001.0") {
    Write-Output "Compliant"
    Exit 0
} else {
    Write-Output "Noncompliant"
    Exit 1
}
