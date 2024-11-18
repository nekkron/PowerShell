#Requires -Version 5.1

<#
.SYNOPSIS
    Disables Autorun(Autoplay) on all drives.
.DESCRIPTION
    Disables Autorun(Autoplay) on all drives.
.EXAMPLE
    No parameters needed.
.EXAMPLE
    PS C:\> Disable-Autorun.ps1
    No parameters needed.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes:
    Initial Release
.COMPONENT
    DataIOSecurity
#>

[CmdletBinding()]
param ()

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
        { Write-Output $true }
        else
        { Write-Output $false }
    }
    function Set-ItemProp {
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet("DWord", "QWord", "String", "ExpandedString", "Binary", "MultiString", "Unknown")]
            $PropertyType = "DWord"
        )
        New-Item -Path $Path -Force | Out-Null
        if ((Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue)) {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false | Out-Null
        }
        else {
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false | Out-Null
        }
    }
}
process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }
    $Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\Explorer'
    $Name = "NoDriveTypeAutorun"
    $Value = 0xFF
    # Sets NoDriveTypeAutorun to 0xFF
    Set-ItemProp -Path $Path -Name $Name -Value $Value
}
end {}