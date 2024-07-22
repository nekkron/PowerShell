#Requires -RunAsAdministrator
# ------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All Rights Reserved. Licensed under the MIT License. See License in the project root for license information.
# ------------------------------------------------------------------------------

# This tool can be run on a Windows PC to automate creation of a bootable USB
# recovery key to automate the steps recommended by CrowdStrike:
# https://www.crowdstrike.com/blog/statement-on-falcon-content-update-for-windows-hosts/

# Constant Paths
$ADKInstallLocation = [System.Environment]::ExpandEnvironmentVariables("%ProgramFiles(x86)%\Windows Kits\10")
$ADKInstaller = [System.Environment]::ExpandEnvironmentVariables("%TEMP%\ADKSetup.exe")

$ADKWinPELocation = [System.Environment]::ExpandEnvironmentVariables("%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\en-us\winpe.wim")
$ADKWinPEMediaLocation = [System.Environment]::ExpandEnvironmentVariables("%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\Media")
$ADKWinPEAddOnInstaller = [System.Environment]::ExpandEnvironmentVariables("%TEMP%\adkwinpesetup.exe")

$WorkingLocation = [System.Environment]::ExpandEnvironmentVariables("%TEMP%\WinPEMountLocation\")
$WorkingWinPELocation = [System.Environment]::ExpandEnvironmentVariables("%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\en-us\winpe-bak.wim")
$CmdPromptPath = [System.Environment]::ExpandEnvironmentVariables("%WinDir%\System32\cmd.exe")
$WinPEMountLocation = [System.Environment]::ExpandEnvironmentVariables("%TEMP%\WinPEMountLocation\Mount")
$RecoveryImageLocation = [System.Environment]::ExpandEnvironmentVariables("%TEMP%\MsftRecoveryToolForCS.iso")

$DandISetEnvPath = [System.Environment]::ExpandEnvironmentVariables("%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat")
$CopyPEPath = [System.Environment]::ExpandEnvironmentVariables("%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\copype.cmd")
$MakeWinPEMediaPath = [System.Environment]::ExpandEnvironmentVariables("%ProgramFiles(x86)%\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\MakeWinPEMedia.cmd")

# Details
Write-Host "This tool will build a recovery image."

#
# Check if the ADK is installed
#
Write-Host "Checking if ADK is installed..."

$ADKInstalled = Test-Path -Path "$ADKInstallLocation\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg"
if ($ADKInstalled)
{
    Write-Host "  -- An installation of ADK was found on device."
}
else
{
    Write-Host "  -- An installation of ADK was not found on the device."
    Write-Host "This tool will now download and install the Windows ADK."
    
    # Download the ADK Installer
    Write-Host "Downloading ADK..."
    
    # Remove existing installation file
    if (Test-Path $ADKInstaller)
    {
        Remove-Item $ADKInstaller -Verbose
    }
    
    # Download
    Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2271337" -OutFile $ADKInstaller
    
    # Verify hash
    if ((Get-FileHash $ADKInstaller).Hash -ne "3DBB9BF40E9CF5FACD9D770BE8EBA8F9509E77FC20A6051C0D9BAA1173F98E4B")
    {
        Write-Host "ERROR: Failed to verify ADK hash"
        Exit
    }

    $confirmation = Read-Host "Do you accept the Windows ADK license agreement (ADKLicenseAgreement.rtf) [Y]es or [N]o"
    if ($confirmation.ToUpperInvariant() -ne 'Y')
    {
        Exit
    }
    
    $confirmation = Read-Host "Allow Microsoft to collect insights for the Windows Kits as described in WindowsKitsPrivacy.rtf (optional) [Y]es or [N]o"
    $ceip = "/ceip off"

    if ($confirmation.ToUpperInvariant() -eq 'Y')
    {
        $ceip = "/ceip on"
    }

    Write-Host "Installing Windows ADK..."
    Start-Process -FilePath $ADKInstaller -ArgumentList '/features', '+', 'OptionId.DeploymentTools', '/q', $ceip -Wait
    Write-Host "  -- Successfully installed Windows ADK."
}

#
# Check if the ADK WinPE Addon is installed
#
Write-Host "Checking if ADK WinPE addon is installed..."
$ADKWinPEInstalled = Test-Path -Path $ADKWinPELocation
if ($ADKWinPEInstalled)
{
    Write-Host "  -- An installation of Windows ADK WinPE add-on was found on this device."
}
else
{
    Write-Host "  -- An installation for Windows ADK WinPE add-on was NOT found on this device."
    Write-Host "This tool will now download and install the Windows ADK WinPE add-on."
    
    # Download the Windows ADK WinPE add-on installer
    Write-Host "Downloading Windows ADK WinPE add-on..."
    
    # Remove existing installation file
    if (Test-Path $ADKWinPEAddOnInstaller)
    {
        Remove-Item $ADKWinPEAddOnInstaller -verbose
    }
    
    # Download
    Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2271338" -OutFile $ADKWinPEAddOnInstaller
    
    # Verify hash
    if ((Get-FileHash $ADKWinPEAddOnInstaller).Hash -ne "91AC010247B65244E5CD84C5F342D91B16501DBB08E422DE7DE06850CEF5680B")
    {
        Write-Host "ERROR: Failed to verify ADK WinPE add-on hash"
        Exit
    }
    
    # Confirm EULA
    $confirmation = Read-Host "Do you accept the Windows ADK license agreement (ADKLicenseAgreement.rtf) [Y]es or [N]o"
    if ($confirmation.ToUpperInvariant() -ne 'Y')
    {
        Exit
    }
    
    # Prompt for Ceip (if not already)
    if( $ceip.Length -eq 0 )
    {
        $confirmation = Read-Host "Allow Microsoft to collect insights for the Windows Kits as described in WindowsKitsPrivacy.rtf (optional) [Y]es or [N]o"
        $ceip = "/ceip off"

        if ($confirmation.ToUpperInvariant() -eq 'Y')
        {
            $ceip = "/ceip on"
        }
    }

    Write-Host "Installing the WinPE add-on..."
    Start-Process -FilePath $ADKWinPEAddOnInstaller -ArgumentList '/features', '+', 'OptionId.WindowsPreinstallationEnvironment', '/q', $ceip -Wait
    Write-Host "  -- Successfully installed Windows ADK WinPE add-on."
}

#
# Let admin pick safe boot or bitlocker key option before mounting the image
#
Write-Host ""
Write-Host "This script offers two options for recovering impacted devices:"
Write-Host "1. Boot to WinPE to remediate the issue. It requires entering bitlocker recovery key if system disk is bitlocker encrypted."
Write-Host "2. Boot to WinPE configure safe mode and run repair command after entering safe mode. This option is less likely to require bitlocker recovery key if system disk is bitlocker encrypted."
Write-Host ""
$winPEScriptOption = Read-Host "Which of the two options would you like to include in the WinPE image ? [1] or [2]"

# 
# Run the Deployment tools to set environment variables
#
Write-Host "Initializing Deployment Toolkit Environment..."

# Fetch the correct variables to be added.
$envVars = cmd.exe /c """$ADKInstallLocation\Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"" && set" | Out-String

$envVars -split "`r`n" | ForEach-Object {
    if ($_ -match "^(.*?)=(.*)$")
    {
        # Update the current execution environment
        [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], [System.EnvironmentVariableTarget]::Process)
    }
}

#
# Use Dism to mount the WinPE image
#
Write-Host "Mounting WinPE image..."

if (!(Test-Path -Path $WinPEMountLocation))
{
    $mtDirRes = New-Item -Path $WinPEMountLocation -ItemType Directory
}
if (!(Test-Path -Path $WorkingWinPELocation))
{
    $wkDirRes = Copy-Item -Path "$ADKWinPELocation" -Destination "$WorkingWinPELocation" -Force
}

$mtResult = Mount-WindowsImage -ImagePath "$ADKWinPELocation" -Index 1 -Path "$WinPEMountLocation"

# Repair cmd file is located in the root folder of the media
$RepairCmdFile = "$ADKWinPEMediaLocation\repair.cmd"

# Remove any existing batch files
if (Test-Path "$WinPEMountLocation\CSRemediationScript.bat")
{
    Remove-Item "$WinPEMountLocation\CSRemediationScript.bat"
}

if (Test-Path "$RepairCmdFile")
{
    Remove-Item "$RepairCmdFile"
}

#
# Generate batch files based on the earlier selection of the recovery option
#
if ($winPEScriptOption.ToUpperInvariant() -eq '2')
{
    "@echo off" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "echo This tool will configure this machine to boot in safe mode." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "echo WARNING: In some cases you may need to enter a BitLocker recovery key after running." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "pause" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "echo." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "bcdedit /set {default} safeboot network" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "echo." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "IF %ERRORLEVEL% EQU 0 (" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "     echo ................................................." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "     echo Your PC is configured to boot to Safe Mode now.   " | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "     echo ................................................." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "     echo If you manually changed the boot order on the device, restore the boot order to the previous state before rebooting. If BitLocker is enabled, make sure to remove the USB or bootable recovery device attached to prevent BitLocker recovery." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "     echo ................................................." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "echo." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    ") ELSE (" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "     echo Could not configure safe mode on this system." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "   )" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "echo." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "pause" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "exit 0" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii

    #
    # Generate Repair.cmd
    #
    "@echo off" | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "echo This tool will remove impacted files and restore normal boot configuration." | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "echo." | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "echo WARNING: You may need BitLocker recovery key in some cases."  | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "echo WARNING: This script must be run in an elevated command prompt." | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "echo." | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "pause" | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "echo Removing impacted files..."  | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "del %SystemRoot%\System32\drivers\CrowdStrike\C-00000291*.sys" | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "echo Restoring normal boot flow..."  | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "bcdedit /deletevalue {current} safeboot" | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "echo Success. System will now reboot." | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "pause" | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
    "shutdown -r -t 00" | Out-File -FilePath "$RepairCmdFile" -Append -Encoding ascii
}
else 
{
    #
    # Generate batch file
    #
    "@echo off" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "set drive=C:" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "echo Using drive %drive%" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Force -Append -Encoding ascii
    "echo If your device is BitLocker encrypted use your phone to log on to https://aka.ms/aadrecoverykey. Log on with your Email ID and domain account password to find the BitLocker recovery key associated with your device." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "echo." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "manage-bde -protectors %drive% -get -Type RecoveryPassword" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "echo." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "set /p reckey=""Enter recovery key for this drive if required: """ | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "IF NOT [%reckey%] == [] (" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "	echo Unlocking drive %drive%" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "	manage-bde -unlock %drive% -recoverypassword %reckey%" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    ")" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "del %drive%\Windows\System32\drivers\CrowdStrike\C-00000291*.sys" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "echo Done performing cleanup operation." | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "pause" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
    "exit 0" | Out-File -FilePath "$WinPEMountLocation\CSRemediationScript.bat" -Append -Encoding ascii
}

#
# Generate WinPEShl.ini file to autolaunch recovery script
#
"[LaunchApps]" | Out-File -FilePath "$WinPEMountLocation\Windows\system32\winpeshl.ini" -Force -Encoding ascii
"%SYSTEMDRIVE%\Windows\system32\cmd.exe /k %SYSTEMDRIVE%\CSRemediationScript.bat" | Out-File -FilePath "$WinPEMountLocation\Windows\system32\winpeshl.ini" -Append -Encoding ascii

# Add necessary packages
Write-Host "Adding necessary packages..."

# WinPE-WMI.cab
$pkgWmiResult = Add-WindowsPackage -Path "$WinPEMountLocation" -PackagePath "$ADKInstallLocation\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-WMI.cab"
$pkgWmiLngResult = Add-WindowsPackage -Path "$WinPEMountLocation" -PackagePath "$ADKInstallLocation\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"

# WinPE-SecureStartup.cab
$pkgStartResult=Add-WindowsPackage -Path "$WinPEMountLocation" -PackagePath "$ADKInstallLocation\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\WinPE-SecureStartup.cab"
$pkgStartLngResult = Add-WindowsPackage -Path "$WinPEMountLocation" -PackagePath "$ADKInstallLocation\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs\en-us\WinPE-SecureStartup_en-us.cab"

#
# Optionally add drivers to the WinPE image
#
$confirmation = Read-Host "Do you need to add drivers to the WinPE image ? [Y]es or [N]o"
if ($confirmation.ToUpperInvariant() -eq 'Y')
{
    $driverPath = Read-Host "Specify the folder that contains subfolders with driver (.ini) files or press Enter to skip"

    if ($driverPath -ne "")
    {
        Write-Host "Adding drivers..."
        Add-WindowsDriver -Path "$WinPEMountLocation" -Driver "$driverPath" -Recurse
    }
}

#
# Unmount and commit WinPE image
#
Write-Host "Saving the changes to the WinPE image..."
$disImgResult = Dismount-WindowsImage -Path "$WinPEMountLocation" -Save

#
# Creates working directories for WinPE media creation
#
$WinPEStagingLocation = [System.Environment]::ExpandEnvironmentVariables("%TEMP%\WinPEStagingLocation")

if ((Test-Path -Path $WinPEStagingLocation))
{
    $WinPeRemResult = Remove-Item -Path $WinPEStagingLocation -Force -Recurse
}

[System.Environment]::SetEnvironmentVariable("WinPERoot", "$ADKInstallLocation\Assessment and Deployment Kit\Windows Preinstallation Environment")
[System.Environment]::SetEnvironmentVariable("OSCDImgRoot", "$ADKInstallLocation\Assessment and Deployment Kit\Deployment Tools\AMD64\Oscdimg")

$cmdArgs = "amd64 " + "`"$WinPEStagingLocation`""
Start-Process -FilePath $CopyPEPath -ArgumentList $cmdArgs -Wait -NoNewWindow

Write-Host "Creating ISO..."

# Create the ISO
if (Test-Path -Path $RecoveryImageLocation)
{
    Remove-Item -Path $RecoveryImageLocation -Force
}

$CmdArgs = "/ISO " + "`"$WinPEStagingLocation`" `"$RecoveryImageLocation`""
Start-Process -FilePath $MakeWinPEMediaPath -ArgumentList $cmdArgs -Wait -NoNewWindow

#
# Prompt if iso or USB is needed
#
$isUsb = Read-Host "Do you need an ISO [1] or a USB [2] ?"
if ($isUsb.ToUpperInvariant() -eq '2')
{    
    #
    # Make USB Key
    #

    $USBDrive = Read-Host "What is the drive letter of your USB Key?"

    if ($USBDrive.Length -lt 1)
    {
        Write-Host "ERROR: Invalid drive letter"
        Exit
    }

    if ($USBDrive.Length -eq 1)
    {
        $USBDrive = -join ($USBDrive, ":")
    }

    if (!(Test-Path $USBDrive))
    {
        Write-Host "ERROR: Drive not found"
        Exit
    }

    $usbVolume = Get-Volume -DriveLetter $USBDrive[0]
    if (($usbVolume.Size) -gt 32GB)
    {
        Write-Host "ERROR: USB drives larger than 32GB are not supported. Please shrink the drive partitions and re-run the script."
        Exit
    }

    Format-Volume -DriveLetter $USBDrive[0] -FileSystem FAT32

    Write-Host "Making USB media..."

    # Mount the ISO
    $mountVolume = Mount-DiskImage -ImagePath "$RecoveryImageLocation" -PassThru
    $mountLetter = ($mountVolume | Get-Volume).DriveLetter + ":\*"

    Write-Host "Copying contents to the USB drive..."
    Copy-Item -Path $mountLetter -Destination "$USBDrive\" -Recurse

    Write-Host "Cleaning up..."
    $dismountResult = Dismount-DiskImage -ImagePath "$RecoveryImageLocation"

    Write-Host "DONE: You can now boot from the USB key."

}
else {
    Write-Host "ISO is available here: $RecoveryImageLocation"
}

if (Test-Path -Path $WinPEStagingLocation)
{
    $remStgResult = Remove-Item -Path $WinPEStagingLocation -Force -Recurse
}

if (($isUsb -eq $true) -and (Test-Path -Path $RecoveryImageLocation))
{
    $remImgResult = Remove-Item -Path $RecoveryImageLocation -Force
}

if (Test-Path -Path $WorkingLocation)
{
    $remWkResult = Remove-Item -Path $WorkingLocation -Force -Recurse
}



# SIG # Begin signature block
# MIIoLAYJKoZIhvcNAQcCoIIoHTCCKBkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCBnJYbCeb5BkrC
# H8TfvNK+S8i6zYuTNKMKyyftPXnZYaCCDXYwggX0MIID3KADAgECAhMzAAADrzBA
# DkyjTQVBAAAAAAOvMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjMxMTE2MTkwOTAwWhcNMjQxMTE0MTkwOTAwWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDOS8s1ra6f0YGtg0OhEaQa/t3Q+q1MEHhWJhqQVuO5amYXQpy8MDPNoJYk+FWA
# hePP5LxwcSge5aen+f5Q6WNPd6EDxGzotvVpNi5ve0H97S3F7C/axDfKxyNh21MG
# 0W8Sb0vxi/vorcLHOL9i+t2D6yvvDzLlEefUCbQV/zGCBjXGlYJcUj6RAzXyeNAN
# xSpKXAGd7Fh+ocGHPPphcD9LQTOJgG7Y7aYztHqBLJiQQ4eAgZNU4ac6+8LnEGAL
# go1ydC5BJEuJQjYKbNTy959HrKSu7LO3Ws0w8jw6pYdC1IMpdTkk2puTgY2PDNzB
# tLM4evG7FYer3WX+8t1UMYNTAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQURxxxNPIEPGSO8kqz+bgCAQWGXsEw
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzUwMTgyNjAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAISxFt/zR2frTFPB45Yd
# mhZpB2nNJoOoi+qlgcTlnO4QwlYN1w/vYwbDy/oFJolD5r6FMJd0RGcgEM8q9TgQ
# 2OC7gQEmhweVJ7yuKJlQBH7P7Pg5RiqgV3cSonJ+OM4kFHbP3gPLiyzssSQdRuPY
# 1mIWoGg9i7Y4ZC8ST7WhpSyc0pns2XsUe1XsIjaUcGu7zd7gg97eCUiLRdVklPmp
# XobH9CEAWakRUGNICYN2AgjhRTC4j3KJfqMkU04R6Toyh4/Toswm1uoDcGr5laYn
# TfcX3u5WnJqJLhuPe8Uj9kGAOcyo0O1mNwDa+LhFEzB6CB32+wfJMumfr6degvLT
# e8x55urQLeTjimBQgS49BSUkhFN7ois3cZyNpnrMca5AZaC7pLI72vuqSsSlLalG
# OcZmPHZGYJqZ0BacN274OZ80Q8B11iNokns9Od348bMb5Z4fihxaBWebl8kWEi2O
# PvQImOAeq3nt7UWJBzJYLAGEpfasaA3ZQgIcEXdD+uwo6ymMzDY6UamFOfYqYWXk
# ntxDGu7ngD2ugKUuccYKJJRiiz+LAUcj90BVcSHRLQop9N8zoALr/1sJuwPrVAtx
# HNEgSW+AKBqIxYWM4Ev32l6agSUAezLMbq5f3d8x9qzT031jMDT+sUAoCw0M5wVt
# CUQcqINPuYjbS1WgJyZIiEkBMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGgwwghoIAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAOvMEAOTKNNBUEAAAAAA68wDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJIJHqM7S9Dlg678FHTyZB07
# wvON0giPOxYi0BPaLrWEMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQBJAeNDxT6Qm2hw+FFJvcN/Tep56/lZpd8kMtePAnXoUo/DhQReMEGK
# RRfepxYLtdt1A3Fg9Rwxi4deR2jGMPd4q/9r32CjQMdDxt3grLbZJG18vaJS+AqG
# t0OGB91RmjS28u7E03AMPMxq7CYJ+Nc1fafIzKJg1aInkiErgSjbVJYbvWm/6eXB
# D6sPzKqUse1qstTaDiUwOlnF5dNQ/frtjy1DnMbjLf82UyiciVfJZTWUF7olH+/F
# 0VLO33OWsuxlKce++DCt3rMf/yfrH4DDTJ7B7aWMytD4MUQKOR2QI7juRFOvhp+y
# fGmOk6lYHUQuBQo4SpBsr8zYfBJPx/ZtoYIXlDCCF5AGCisGAQQBgjcDAwExgheA
# MIIXfAYJKoZIhvcNAQcCoIIXbTCCF2kCAQMxDzANBglghkgBZQMEAgEFADCCAVIG
# CyqGSIb3DQEJEAEEoIIBQQSCAT0wggE5AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIE2RgRk7vl4pvFsapmH5EPqJDinATVQBvPlblfKi7YABAgZmlV4U
# qAgYEzIwMjQwNzIxMjA1NTA0Ljg4NFowBIACAfSggdGkgc4wgcsxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo5MjAw
# LTA1RTAtRDk0NzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vydmlj
# ZaCCEeowggcgMIIFCKADAgECAhMzAAAB5y6PL5MLTxvpAAEAAAHnMA0GCSqGSIb3
# DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAk
# BgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIzMTIwNjE4
# NDUxOVoXDTI1MDMwNTE4NDUxOVowgcsxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlv
# bnMxJzAlBgNVBAsTHm5TaGllbGQgVFNTIEVTTjo5MjAwLTA1RTAtRDk0NzElMCMG
# A1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAMJXny/gi5Drn1c8zUO1pYy/38dFQLmR2IQXz1gE
# /r9GfuSOoyRnkRJ6Z/kSWLgIu1BVJ59GkXWPtLkssqKwxY4ZFotxpVsZN9yYjW8x
# EnW3MzAI0igKr+/LxYfxB1XUH8Bvmwr5D3Ii/MbDjtN9c8TxGWtq7Ar976dafAy3
# TrRqQRmIknPVWHUuFJgpqI/1nbcRmYYRMJaKCQpty4CeG+HfKsxrz24F9p4dBkQc
# ZCp2yQzjwQFxZJZ2mJJIGIDHKEdSRuSeX08/O0H9JTHNFmNTNYeD1t/WapnRwiIB
# YLQSMrs42GVB8pJEdUsos0+mXf/5QvheNzRi92pzzyA4tSv/zhP3/Ermvza6W9Gn
# YDz9qv1wbhbvrnS4poDFECaAviEqAhfn/RogCxvKok5ro4gZIX1r4N9eXUulA80p
# Hv3axwXu2MPlarAi6J9L1hSIcy9EuOMqTRJIJX+alcLQGg+STlqx/GuslsKwl48d
# I4RuWknNGbNo/o4xfBFytvtNcVA6xOQq6qRa+9gg+9XMLrxQz4yyQs+V3V6p044w
# rtJtt/a0ZJl/f6I7BZAxxZcH2DDmArcAhgrTxaQkm7LM+p+K2C5t1EKZiv0JWw06
# 5b7AcNgaFyIkMXYuSuOQVSNRxdIgl31/ayxiK1n0K6sZXvgFBx+vGO+TUvyO+03u
# a6UjAgMBAAGjggFJMIIBRTAdBgNVHQ4EFgQUz/7gmICfNjh2kR/9mWuHUrvej1gw
# HwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgwVjBUoFKg
# UIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0
# JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUFBwEBBGAw
# XjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9j
# ZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5jcnQw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAOBgNVHQ8BAf8E
# BAMCB4AwDQYJKoZIhvcNAQELBQADggIBAHSh8NuT6WVaLVwLqex+J7km2nT2jpvo
# BEKm+0M+rYoU/6GL5Q00/ssZyIq5ySpcKYFMUiF8F4ZLG+TrJyiR1CvfzXmkQ5ph
# ZOce9DT7yErLzqvUXit8G7igcHlxPLTxPiiGsb85gb8H+A2fPQ6Xq/u7+oSPPjzN
# dnpmXEobJnAqYplZoF3YNgTDMql0uQHGzoDp6dZlHSNj6rkV1tXjmCEZMqBKvkQI
# A6csPieMnB+MirSZFlbANlChe0lJpUdK7aUdAvdgcQWKS6dtRMl818EMsvsa/6xO
# ZGINmTLk4DGgsbaBpN+6IVt+mZJ89yCXkI5TN8xCfOkp9fr4WQjRBA2+4+lawNTy
# xH66eLZWYOjuuaomuibiKGBU10tox81Sq8EvlmJIrXOZoQsEn1r5g6MTmmZJqtbm
# wZufuJWQXZb0lAg4fq0ZYsUlLkezfrNqGSgeHyIP3rct4aNmqQW6wppRbvbIyP/L
# FN4YQM6givfmTBfGvVS77OS6vbL4W41jShmOmnOn3kBbWV6E/TFo76gFXVd+9oK6
# v8Hk9UCnbHOuiwwRRwDCkmmKj5Vh8i58aPuZ5dwZBhYDxSavwroC6j4mWPwh4VLq
# VK8qGpCmZ0HMAwao85Aq3U7DdlfF6Eru8CKKbdmIAuUzQrnjqTSxmvF1k+CmbPs7
# zD2Acu7JkBB7MIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQg
# VGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoC
# ggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+
# F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU
# 88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqY
# O7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzp
# cGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0Xn
# Rm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1
# zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZN
# N3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLR
# vWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTY
# uVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUX
# k8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB
# 2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKR
# PEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0g
# BFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQM
# MAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQ
# W9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNv
# bS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBa
# BggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqG
# SIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOX
# PTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6c
# qYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/z
# jj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz
# /AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyR
# gNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdU
# bZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo
# 3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4K
# u+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10Cga
# iQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9
# vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGC
# A00wggI1AgEBMIH5oYHRpIHOMIHLMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSUwIwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25z
# MScwJQYDVQQLEx5uU2hpZWxkIFRTUyBFU046OTIwMC0wNUUwLUQ5NDcxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoBATAHBgUrDgMCGgMV
# ALNyBOcZqxLB792u75w97U0X+/BDoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgUENBIDIwMTAwDQYJKoZIhvcNAQELBQACBQDqR8UQMCIYDzIwMjQwNzIxMTcz
# NDA4WhgPMjAyNDA3MjIxNzM0MDhaMHQwOgYKKwYBBAGEWQoEATEsMCowCgIFAOpH
# xRACAQAwBwIBAAICBEIwBwIBAAICErMwCgIFAOpJFpACAQAwNgYKKwYBBAGEWQoE
# AjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkq
# hkiG9w0BAQsFAAOCAQEAEnvQmNtYikoGrCuF7SWPkvMRxE9ro71OZFKbwv1EECkE
# u/E9G05mNOU8dMbUxcsbjpU9hs6+trMcN2ClzKhgnq8bIoXEfi0expnaNkq7qle0
# UE+wCDZlfHp+krDy+m/CuY/mzk0zOLDaF4I7lFdetKRFm6l6UTAAlu91SyM2hbVg
# Qhu2H3FjMPmcGLjtUyNhof/MiezsYLsKbc2azdw8AhUkyB5XhqNfrJlVihEx2v5h
# hlQr8TuxadVdZL3AJvP9Thc6frJp3/qJ4Z1hoUyNZ+zKtLAAocgoyOe+Qr4Mzy7k
# WQBF7fgmyPNfhsoO/e828cvujJYYuoGcF1M45BtTpjGCBA0wggQJAgEBMIGTMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB5y6PL5MLTxvpAAEAAAHn
# MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# LwYJKoZIhvcNAQkEMSIEIAFOzR69KxVs3HzvVQ3rLjbbAvr2damYHmQoNCujfKGf
# MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQg5TZdDXZqhv0N4MVcz1QUd4Rf
# vgW/QAG9AwbuoLnWc60wgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMAITMwAAAecujy+TC08b6QABAAAB5zAiBCAiuPHNorHprIf/bbDTyszOBLRx
# q8MBzrjD9AZ+79aCSDANBgkqhkiG9w0BAQsFAASCAgCLzaA1Kli3Dkspo+RxWX2k
# udbBeKIJnQzp2E36aqsz7Qn19F/mTdiDf2fyt6DuEAx1xpXcln+3/WTVHQgw/b5a
# WUAoqscSmZlQpRkzr5eBed0jokK61xDAE1SX80MqpNUsM7To8KW8+T0nFPSy5pgJ
# UVuk0S7bIGOmTzC4l9tZCU80j+URM/W/su3EidVkkl9EEjEt05lzatRac6yzm1nX
# 4nAnhH8S0sr2QFyxf/p220dhD4IVP9sh62ddQrCHOpP56X4KDa1y+cYwptSIOzto
# FA9x95T2cETZW4e4e5T/JQ5JVgfWWJ+josK5s/uKrFCKLqflIBBxMfC2RRGyL99x
# 3T9n9zfSPLgxnozgYeX8VdSYTeakeWUNOZLnWQJw0ae9ByUezlO6xobliOfBFQc9
# 6sNETnW0i5E1B1Vl+e+BJ0wSDvUdoMz399e9WS9fVXLh30aGe8p2oyyA8hEXQh56
# YQGq2TMxBBMF6tMYaIo70c0TkHNGBo3Qc9OGCy/DIKKk95tp1ThGUyZnj6E9gL+J
# 0rZ+Hq4W81bu7XzTsX9bkJY+eK2QVqznAJmFYR9LIJKbvk66UZPyzRI2c8jyU443
# q8ol8W4OCKlV4CZONcy/k5TwQ8dl4ir0m5BpJL4l+a4G5wIGziNHbDYYNZMgJwec
# f43INOAsF/SsC16VfovlQQ==
# SIG # End signature block
