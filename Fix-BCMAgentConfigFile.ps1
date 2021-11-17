#Variables
$path = "C:\Program Files\BMC Software\Client Management\Client\config\mtxagent.ini"

# Mark file as writable
ATTRIB -r $path

#Certificate Authority fix
$text = (Get-Content -Path $path -ReadCount 0) -join "`n"
$text -replace 'CertAuth=', 'CertAuth=ABC' | Set-Content -Path $path
#If config file already has correct value, this fixes the previous command to add it
$text = (Get-Content -Path $path -ReadCount 0) -join "`n"
$text -replace 'CertTrusted=', 'CertTrusted=ABC' | Set-Content -Path $path

#Certificate Trusted fix
$text = (Get-Content -Path $path -ReadCount 0) -join "`n"
$text -replace 'CertAuth=ABCABC', 'CertAuth=ABC' | Set-Content -Path $path
#If config file already has correct value, this fixes the previous command to add it
$text = (Get-Content -Path $path -ReadCount 0) -join "`n"
$text -replace 'CertTrusted=ABCABC', 'CertTrusted=ABC' | Set-Content -Path $path

# Mark file as read-only
ATTRIB +R $path
