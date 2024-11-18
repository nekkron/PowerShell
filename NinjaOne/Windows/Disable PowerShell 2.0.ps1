#Requires -Version 5.1

<#
.SYNOPSIS
    Disables PowerShell 2.0.
.DESCRIPTION
    Disables PowerShell 2.0 by removing the feature.
    This script does require that PowerShell 5.1 be installed before hand.
    See: https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/wmf/setup/install-configure
.EXAMPLE
    No parameters needed.
.OUTPUTS
    String[]
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes:
    Initial Release
#>

[CmdletBinding()]
param ()

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}
process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }
    if ($PSVersionTable.PSVersion -ge [Version]::new(5, 1)) {
        if ($(Get-Command "Disable-WindowsOptionalFeature" -ErrorAction SilentlyContinue).Name -like "Disable-WindowsOptionalFeature") {
            if ($(Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 -ErrorAction SilentlyContinue).State -like "Enabled") {
                # Remove PowerShell 2.0 on Windows 10,11
                try {
                    Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 -ErrorAction Stop
                    Write-Host "Disabled PowerShell 2.0"
                }
                catch {
                    Write-Error $_
                    Write-Host "Unable to disable PowerShell 2.0"
                    exit 1
                }
            }
            if ($(Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -ErrorAction SilentlyContinue).State -like "Enabled") {
                # Remove PowerShell 2.0 on Windows 10, 11, Server 2016
                try {
                    Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -ErrorAction Stop
                    Write-Host "Disabled PowerShell 2.0"
                }
                catch {
                    Write-Error $_
                    Write-Host "Unable to disable PowerShell 2.0"
                    exit 1
                }
            }
            else {
                Write-Host "PowerShell is already disabled."
            }
        }
        if ($(Get-Command "Uninstall-WindowsFeature" -ErrorAction SilentlyContinue).Name -like "Uninstall-WindowsFeature") {
            if ($(Get-WindowsFeature -Name PowerShell-V2) -and $(Get-WindowsFeature -Name PowerShell-V2).InstallState -like "Installed") {
                # Remove PowerShell 2.0 on Windows Server
                try {
                    Uninstall-WindowsFeature -Name PowerShell-V2 -ErrorAction Stop
                    Write-Host "Disabled PowerShell 2.0"
                }
                catch {
                    Write-Error $_
                    Write-Host "Unable to disable PowerShell 2.0"
                    exit 1
                }
            }
            else {
                Write-Host "PowerShell is already disabled."
            }
        }
        if (
            $(Get-Command "Disable-WindowsOptionalFeature" -ErrorAction SilentlyContinue).Name -notlike "Disable-WindowsOptionalFeature" -and 
            $(Get-Command "Uninstall-WindowsFeature" -ErrorAction SilentlyContinue).Name -notlike "Uninstall-WindowsFeature"
        ) {
            Write-Host "Running on an unsupported version of Windows."
            exit 1
        }
    }
    else {
        Write-Host "Please upgrade to 5.1 before disabling PowerShell 2.0."
        exit 1
    }
}
end {}