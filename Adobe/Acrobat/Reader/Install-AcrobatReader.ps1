# Variables
$Log = "$env:ProgramData\Powershell\Install-AcrobatReader.log"
$RegLocal = "$env:ProgramData\Powershell\AdobeAcrobat.reg"
$RegRemote = "https://raw.githubusercontent.com/nekkron/PowerShell/main/Adobe/Acrobat/Reader/AdobeAcrobat.reg"
$ErrorOccurred = 0
#########################################
New-Item -ItemType Directory -Path "$env:ProgramData\Powershell" -Force | Out-Null
Start-Transcript -Path $log
try {
    Write-Host "Downloading WinGet and its dependencies..." # https://learn.microsoft.com/en-us/windows/package-manager/winget/
    Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
    Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx -OutFile Microsoft.UI.Xaml.2.7.x64.appx
    Invoke-WebRequest -Uri https://cdn.winget.microsoft.com/cache/source.msix -OutFile Microsoft.Winget.Source.msix
    Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx
    Add-AppxPackage Microsoft.UI.Xaml.2.7.x64.appx
    Add-AppxPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    Add-AppxPackage Microsoft.Winget.Source.msix # allows for admins to use winget
}
catch {
    Write-Host "An error occurred:"
    Write-Host $_
}
Write-Host
    winget --info
Write-Host
try {
        winget install Adobe.Acrobat.Reader.64-bit --override '/sAll /rs /l /msi /qn /L*v C:\ProgramData\AdobeAcrobatReader64-bit.log EULA_ACCEPT=YES' --force --accept-package-agreements --accept-source-agreements
    } 
    catch
    {
        $ErrorOccurred = 1
        Write-Error "An error occurred:"
        Write-Error $_
    }
Write-Host "Adobe Acrobat Reader verbose log file: C:\ProgramData\AdobeAcrobatReader64-bit.log"
    if (Test-Path -Path "$env:ProgramFiles\Adobe\Acrobat DC\Acrobat\Acrobat.exe") {
        winget list Adobe.Acrobat.Reader.64-bit
    }
Write-Host "Backing up current registry"
try {
    regedit /e C:\Windows\Acrobat_Previous.reg HKLM\SOFTWARE\Policies\Adobe
}
catch {
    $ErrorOccurred = 1
    Write-Error "An error occurred:"
    Write-Error $_
}
if (Test-Path "C:\Windows\Acrobat_Previous.reg"){
    Write-Host "Backup successful" -ForegroundColor Green}
Write-Host "Downloading registry file"
    Invoke-WebRequest -Uri $RegRemote -OutFile $RegLocal
    Start-Sleep -Seconds 2
Write-Host "Importing custom registry keys"
 try {
    regedit /s $RegLocal
}
catch 
{
    $ErrorOccurred = 1
    Write-Error "An error occurred:"
    Write-Error $_
}

if ($ErrorOccurred -eq 1){
    Write-Error "An error occurred! Review the log."
    Exit 1
}
Write-Host "Installation was a success!"
Stop-Transcript
Write-Host "Success"
Exit 0
