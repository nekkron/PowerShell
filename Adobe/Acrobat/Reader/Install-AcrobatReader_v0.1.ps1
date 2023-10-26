# Variables
$AcroRdr = "$env:ProgramFiles\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
$RegLocal = "$env:ProgramData\AdobeAcrobat.reg"
$RegRemote = "https://raw.githubusercontent.com/nekkron/PowerShell/main/Adobe/Acrobat/Reader/AdobeAcrobat.reg"

if (Test-Path $env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe){
winget --info
} ELSE {
    Write-Host "Downloading WinGet and its dependencies..." # https://learn.microsoft.com/en-us/windows/package-manager/winget/
    Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
    Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx -OutFile Microsoft.UI.Xaml.2.7.x64.appx
    Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx
    Add-AppxPackage Microsoft.UI.Xaml.2.7.x64.appx
    Add-AppxPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    Start-Sleep -Seconds 1
    winget --info
}

# Waving the magic wand
Write-Host "Determining if Adobe Acrobat is already installed"
if (Test-Path -Path "$env:ProgramFiles\Adobe\Acrobat DC\Acrobat\Acrobat.exe") {
        Write-Host "Adobe Acrobat is already installed!"
    } Else {
        Write-Host "Installing Adobe Acrobat Reader (64-bit) via winget"
        winget install Adobe.Acrobat.Reader.64-bit --override '/sAll /rs /l /msi /qn /L*v C:\ProgramData\AdobeInstall.log EULA_ACCEPT=YES' --force --accept-package-agreements --accept-source-agreements
    }
    
Write-Host "Downloading registry file"
    Invoke-WebRequest -Uri $RegRemote -OutFile $RegLocal
    Start-Sleep -Seconds 1
if (Test-Path -Path $RegLocal) {
    Write-Host "Injecting registry keys into registry editor"
        regedit /s $RegLocal
    Write-Host "Adobe Acrobat has been configured for guest use"
} ELSE {
        Write-Error "There was a problem downloading the registry file!"
        Exit 1
}
Exit 0
