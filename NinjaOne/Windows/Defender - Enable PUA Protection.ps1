<#
.SYNOPSIS
    Enables PUA protection in MS Defender
.DESCRIPTION
    Enables PUA protection in MS Defender
.EXAMPLE
    No parameters needed.
    Enables PUA protection in MS Defender
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
    if ($(Get-Command -Name "Set-MpPreference").Name -like "Set-MpPreference") {
        if ($(Get-MpPreference | Select-Object PUAProtection -ExpandProperty PUAProtection) -eq 0) {
            try {
                Set-MpPreference -PUAProtection Enabled -ErrorAction Stop
            }
            catch {
                Write-Error $_
                exit 1
            }
            Write-Host "PUAProtection enabled."
        }
        else {
            Write-Host "PUAProtection already enabled."
        }
    }
    else {
        Write-Error "The module ConfigDefender was not found. Is MS Defender installed?"
    }
    exit 0
}
end {}