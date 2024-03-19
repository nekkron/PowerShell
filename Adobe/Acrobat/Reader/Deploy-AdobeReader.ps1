<#	
	.NOTES
	===========================================================================
	 Created with: 	Microsoft Visual Studio Code
	 Created on:   	2024/03/19
	 Created by:   	James Kasparek
	 Filename:     	Deploy-AdobeReader.ps1
     URL:           https://github.com/nekkron/PowerShell/blob/main/Adobe/Acrobat/Reader/Deploy-AdobeReader.ps1
	===========================================================================
	.DESCRIPTION
		Installs Adobe Acrobat Reader DC (x64) with lockdown features. If version 24.1.20604.0 or older
    is already installed, this will upgrade to version 24.1.20604.0 and inject lockdown features.
#>

# Variables
$Log = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\Deploy-AcrobatReader.log"
$CurrentVer = "24.1.20604.0"
$AppRemote = "https://ardownload2.adobe.com/pub/adobe/acrobat/win/AcrobatDC/2400120604/AcroRdrDCx642400120604_MUI.exe"
$IniRemote = "https://raw.githubusercontent.com/nekkron/PowerShell/main/Adobe/Acrobat/Reader/setup.ini"
$MstRemote = "https://raw.githubusercontent.com/nekkron/PowerShell/main/Adobe/Acrobat/Reader/AcroPro.mst"
$InstalledVers = (Get-Item "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe").VersionInfo | Select-Object -ExpandProperty ProductVersion
$ErrorOccurred = 0
#########################################
Start-Transcript -Path $log
Write-Host "Checking to see if this version, or a newer version, is already installed"
if ([version]$InstalledVers -ge [version]$CurrentVer) {
    Write-Output "The same or newer version of this application is already installed."
    Exit 0
} Else {
    Write-Host "The current version is: " -NoNewline
    $InstalledVers
}
try {
    Write-Host "Downloading Adobe Acrobat Reader DC (x64)"
    Start-BitsTransfer -Source $AppRemote -Destination "$env:ProgramData\AdobeAcrobatReaderDC.exe"
    Write-Host "Extracting the binaries"
    Start-Process -FilePath "$env:ProgramData\AdobeAcrobatReaderDC.exe" -ArgumentList '-sfx_o"C:\ProgramData\AdobeAcrobatReaderDC" -sfx_ne -sfx_nu' -Wait
    Write-Host "Downloading custom .ini file"
    Invoke-WebRequest -Uri $IniRemote -OutFile "$env:ProgramData\AdobeAcrobatReaderDC\setup.ini"
    Write-Host "Downloading custom .mst file"
    Invoke-WebRequest -Uri $MstRemote -OutFile "$env:ProgramData\AdobeAcrobatReaderDC\AcroPro.mst"
    Start-Sleep -Seconds 2
    Write-Host "Starting the software installation with custom .ini and .mst files and verbose logging"
    Start-Process -FilePath "$env:ProgramData\AdobeAcrobatReaderDC\setup.exe" -ArgumentList '/msi /L*v C:\Windows\Logs\AdobeAcrobatReader64-bit.log' -Wait
} 
    catch
    {
        $ErrorOccurred = 1
        Write-Error "An error occurred:"
        Write-Error $_
    }
Write-Host "Adobe Acrobat Reader verbose installer log file: C:\Windows\Logs\AdobeAcrobatReader64-bit.log"
Write-Host "Performing cleanup"
if (Test-Path -Path "$env:ProgramData\AdobeAcrobatReaderDC.exe") {
    Remove-Item "$env:ProgramData\AdobeAcrobatReaderDC.exe" -Verbose
}
if (Test-Path -Path "$env:ProgramData\AdobeAcrobatReaderDC" -PathType Container) {
    Remove-Item "$env:ProgramData\AdobeAcrobatReaderDC" -Recurse -Verbose
}
Stop-Transcript

if ($ErrorOccurred -eq 1){
    Write-Output "Error: $_"
    Exit 1
}
Write-Output "Success!"
Exit 0
