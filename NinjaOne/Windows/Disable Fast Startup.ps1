<#
.SYNOPSIS
    Disable Windows Fast Boot, also known as Hiberboot or Fast Startup.
.DESCRIPTION
    Disable Windows Fast Boot, also known as Hiberboot or Fast Startup.
.EXAMPLE
    No parameter needed.
    Disables Windows Fast Boot
.OUTPUTS
    None
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

    $Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
    $Name = "HiberbootEnabled"
    $Value = "0"

    try {
        if (-not $(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
        }
        else {
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
        }
    }
    catch {
        Write-Error $_
        Write-Host "Failed to disable Fast Boot."
        exit 1
    }
    exit 0
}
end {}