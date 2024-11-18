<#
.SYNOPSIS
    Enables Windows 11 upgrade.
.DESCRIPTION
    Enables Windows 11 upgrade.
.EXAMPLE
    No parameters needed
    Enables Windows 11 upgrade.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes:
    Allows the upgrade offer to Windows 11 to appear to users
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

    $Splat = @{
        Path        = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        Name        = @("TargetReleaseVersion", "TargetReleaseVersionInfo")
        ErrorAction = "SilentlyContinue"
    }

    Remove-ItemProperty @Splat -Force
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "SvOfferDeclined" -Force -ErrorAction SilentlyContinue
    $TargetResult = Get-ItemProperty @Splat
    $OfferResult = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "SvOfferDeclined" -ErrorAction SilentlyContinue
    if ($null -ne $TargetResult -or $null -ne $OfferResult) {
        Write-Host "Failed to enable Windows 11 Upgrade."
        exit 1
    }
    exit 0
}
end {}