
<#
.SYNOPSIS
    Saves PowerShell Desktop and/or Core Version(s) to a Custom Field.
.DESCRIPTION
    Saves PowerShell Desktop and/or Core Version(s) to a Custom Field.

.EXAMPLE
    (No Parameters)
    ## EXAMPLE OUTPUT WITHOUT PARAMS ##
    PowerShell Desktop: 5.1.19041.3570 - PowerShell Core: 7.3.9

PARAMETER: -CustomField "PowerShellVersion"
    Name of the custom field to save the version of PowerShell to.
.EXAMPLE
    -CustomField "PowerShellVersion"
    ## EXAMPLE OUTPUT WITH CustomField ##
    PowerShell Desktop: 5.1.19041.3570 - PowerShell Core: 7.3.9

.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2012 R2
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$CustomField
)

begin {
    if ($env:customField) {
        $CustomField = $env:customField
    }
}
process {
    # Get PowerShell Desktop Version
    $PSDesktop = "PowerShell Desktop: $($PSVersionTable.PSVersion)"

    $PSVersionCF = if ($(Get-Command -Name "pwsh.exe" -ErrorAction SilentlyContinue)) {
        # Get PowerShell Core Version
        $pwshVersion = "$(pwsh.exe -version)" -split ' ' | Select-Object -Last 1
        $PSCore = "PowerShell Core: $($pwshVersion)"
        Write-Output "$PSDesktop - $PSCore"
    }
    else {
        Write-Output "$PSDesktop"
    }
    
    Write-Host "`n$PSVersionCF`n"

    if($PSVersionTable.PSVersion.Major -lt 3){
        Write-Error "Can only set Custom Fields on PowerShell Versions 3 or higher."
        exit 1
    }

    # Save Version(s) to custom field
    Ninja-Property-Set -Name $CustomField -Value $PSVersionCF
    
}
end {
    
    
    
}