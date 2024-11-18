
<#
.SYNOPSIS
    Disables Windows 11 upgrade by locking the TargetReleaseVersion and TargetReleaseVersionInfo to the currently installed version.
.DESCRIPTION
    Disables Windows 11 upgrade by locking the TargetReleaseVersion and TargetReleaseVersionInfo to the currently installed version.
.EXAMPLE
    -TargetReleaseVersion "22H2"
    Disables Windows 11 upgrade by setting the TargetReleaseVersion to 22H2
.EXAMPLE
    -TargetReleaseVersion "22H1"
    Disables Windows 11 upgrade by setting the TargetReleaseVersion to 22H1
.EXAMPLE
    -TargetReleaseVersion "2009"
    Disables Windows 11 upgrade by setting the TargetReleaseVersion to 2009
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10
    Release Notes: Updated Calculated Name
#>
[CmdletBinding()]
param (
    [string]
    $TargetReleaseVersion = "22H2"
)

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    function Set-ItemProp {
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet("DWord", "QWord", "String", "ExpandedString", "Binary", "MultiString", "Unknown")]
            $PropertyType = "DWord"
        )
        # Do not output errors and continue
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue
        if (-not $(Test-Path -Path $Path)) {
            # Check if path does not exist and create the path
            New-Item -Path $Path -Force | Out-Null
        }
        if ((Get-ItemProperty -Path $Path -Name $Name)) {
            # Update property and print out what it was changed from and changed to
            $CurrentValue = Get-ItemProperty -Path $Path -Name $Name
            try {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Error $_
            }
            Write-Host "$Path\$Name changed from $CurrentValue to $(Get-ItemProperty -Path $Path -Name $Name)"
        }
        else {
            # Create property with value
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Error $_
            }
            Write-Host "Set $Path$Name to $(Get-ItemProperty -Path $Path -Name $Name)"
        }
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue
    }
}
process {
    if ([System.Environment]::OSVersion.Version.Build -lt 10240 -or [System.Environment]::OSVersion.Version.Build -gt 22000) {
        Write-Error "OS Version is not Windows 10."
        exit 1
    }

    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }
    if ($env:targetRelease -and $env:targetRelease -notlike "null") {
        if ($env:targetRelease -like "Current") {
            # Get Current Version
            $release = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId).ReleaseId
            $ver = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion).DisplayVersion
            $TargetReleaseVersion = if ($release -eq '2009') { $ver } Else { $release }
        }
        else {
            $TargetReleaseVersion = $env:targetRelease
        }
    }

    # Block Windows 11 Upgrade by changing the target release version to the current version
    try {
        Set-ItemProp -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "TargetReleaseVersion" -Value 1 -PropertyType DWord
        Set-ItemProp -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "TargetReleaseVersionInfo" -Value "$TargetReleaseVersion" -PropertyType String
        Set-ItemProp -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "SvOfferDeclined" -Value 1646085160366 -PropertyType QWord
    }
    catch {
        Write-Error $_
        Write-Host "Failed to block Windows 11 Upgrade."
        exit 1
    }
    exit 0
}
end {
    
    
    
}

