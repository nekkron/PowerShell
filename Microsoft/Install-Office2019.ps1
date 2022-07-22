<#	
	.NOTES
	===========================================================================
	 Created with: 	Windows PowerShell ISE x64
	 Created on:   	2022-06-20
	 Created by:   	James Kasparek
	 Filename:     	Install-Office2019.ps1
    	 URL:           https://github.com/nekkron/PowerShell/blob/main/Install-Office2019.ps1
	===========================================================================
	.DESCRIPTION
		Downloads Office Deployment Tool & configuration from dropbox, then downloads Office 2019 Standard from the Microsoft CDN, if not on an attached USB.
#>

# Variables
$WorkingDir = "$env:ProgramData\Powershell"
$USBWorkingDir = "D:\SOFTWARE\Office2019"
$OfficeUrl = "location of zipped setup.exe and configuration.xml"
$OfficeOutFile = "$env:ProgramData\Powershell\Office2019Standard.zip"
$OfficeExtractPath = "$env:ProgramData\Powershell\Office2019"

# Creates working directory & begins logging
if(!(Test-Path $WorkingDir)) { New-Item -ItemType Directory -Path $WorkingDir -Force | Out-Null }
Start-Transcript -Path $WorkingDir\Install-Office2019.log

# Looks for local install path in $USBWorkingDir for limited bandwidth locations
    if(Test-Path $USBWorkingDir\configuration.xml) {
        Write-Host "Installing Microsoft Office 2019 Standard from USB drive"
        Start-Process -WorkingDirectory $USBWorkingDir -FilePath .\setup.exe -ArgumentList "/configure .\configuration.xml" -Wait
        Write-Host "Installation completed."
        Exit
    }

# Downloads & Extracts installer files
Write-Host "Downloading the Microsoft Office 2019 Standard configuration files"
Write-Progress -Activity "Powershell Software Installer" -CurrentOperation "Downloading configuration files" -PercentComplete 1
Invoke-WebRequest $OfficeUrl -OutFile $OfficeOutFile
Write-Progress -Activity "Powershell Software Installer" -PercentComplete 5
Expand-Archive -Path $OfficeOutFile -DestinationPath $OfficeExtractPath -Force
Write-Progress -Activity "Powershell Software Installer" -PercentComplete 10

# Downloading the Office 2019 Standard files
    if(!(Test-Connection www.dropbox.com | Out-Null)) { 
        Write-Warning "Cannot ping dropbox!"
        Write-Host "Verify Internet connectivity and that Dropbox is not a blocked domain!" -BackgroundColor Red -ForegroundColor White
        Start-Sleep -Seconds 30
        Write-Error -Message "Unable to download files from Dropbox"
        Exit
    }
Write-Host "Downloading the Microsoft Office 2019 Standard binaries"
Write-Progress -Activity "Powershell Software Installer" -CurrentOperation "Downloading configuration files" -PercentComplete 15
$Date = Get-Date -Format yyyymmdd-HHmm
Write-Host "View download activity log here: $env:LocalAppData\Temp\$env:COMPUTERNAME-$date.log" -ForegroundColor Black -BackgroundColor Yellow
Start-Process -WorkingDirectory $OfficeExtractPath -FilePath .\setup.exe -ArgumentList "/download .\configuration.xml" -WindowStyle Minimized -Wait # MS Log can be found $env:LocalAppData\Temp\$env:computername-<installdateandtime>.log
Write-Progress -Activity "Powershell Software Installer" -CurrentOperation "Finished downloading configuration files" -PercentComplete 55

# Installing Microsoft Office 2019 Standard
Write-Host "Installing Microsoft Office 2019 Standard"
Write-Progress -Activity "Powershell Software Installer" -CurrentOperation "Installing Microsoft Office 2019 Standard" -PercentComplete 60
Start-Process -WorkingDirectory $OfficeExtractPath -FilePath .\setup.exe -ArgumentList "/configure .\configuration.xml" -WindowStyle Minimized -Wait
Write-Progress -Activity "Powershell Software Installer" -CurrentOperation "Finished installing Microsoft Office 2019 Standard" -PercentComplete 90

# Cleanup
Write-Host "Cleaning up temporary files"
Write-Progress -Activity "Powershell Software Installer" -CurrentOperation "Cleaning up temporary files" -PercentComplete 95
Remove-Item -Path $OfficeExtractPath -Recurse
Remove-Item -Path $OfficeOutFile -Force
Write-Progress -Activity "Powershell Software Installer" -CurrentOperation "Temporary files have been removed. Installation completed." -PercentComplete 100
Stop-Transcript
