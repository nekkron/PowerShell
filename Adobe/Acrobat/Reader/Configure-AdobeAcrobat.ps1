$RegLocal = "$env:ProgramData\Powershell\Adobe.reg"
$RegRemote = "https://raw.githubusercontent.com/nekkron/PowerShell/main/Adobe/Acrobat/Reader/AdobeAcrobat.reg"

Start-Transcript $env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Configure-AcrobatReader.log
Write-Host "Downloading registry file"
    Invoke-WebRequest -Uri $RegRemote -OutFile $RegLocal
    Start-Sleep -Seconds 2
Write-Host "Backup existing Adobe registry keys"
try {
    regedit /e C:\Windows\Acrobat_Previous.reg HKLM\SOFTWARE\Policies\Adobe
}
catch {
    Write-Host "An error occurred:"
    Write-Output $_
}

Write-Host "A backup of the current registry has been saved to:" -NoNewline
Write-Host '"C:\Windows\Acrobat_Default.reg"'

if (Test-Path -Path $RegLocal) {
    Write-Host "Injecting registry keys into registry editor"
    regedit /s $RegLocal
} ELSE {
    Write-Host "An error occurred:"
    Write-Output $_
    Exit 1
}
Stop-Transcript
Write-Output "Success!"
Exit 0
