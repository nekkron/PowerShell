#Requires -Version 5.1

<#
.SYNOPSIS
    Disables SMB v1
.DESCRIPTION
    Disables SMB v1 via Get-WindowsOptionalFeature, Set-SmbServerConfiguration, or Registry
.EXAMPLE
    No parameters needed.
.EXAMPLE
    PS C:\> Disable-SMBv1.ps1
    No parameters needed.
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
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Continue | Out-Null
            }
            catch {
                Write-Error $_
            }
            Write-Host "$Path\$Name changed from $CurrentValue to $(Get-ItemProperty -Path $Path -Name $Name)"
        }
        else {
            # Create property with value
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Continue | Out-Null
            }
            catch {
                Write-Error $_
            }
            Write-Host "Set $Path\$Name to $(Get-ItemProperty -Path $Path -Name $Name)"
        }
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Continue
    }
    $Disable = 0
    # $Enable = 1 # Not Used
}
process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }
    
    # Try using Get-WindowsOptionalFeature first
    if (-not $(Get-Command -Name "Get-WindowsOptionalFeature").Name -like "Get-WindowsOptionalFeature") {
        Write-Host "Get-WindowsOptionalFeature command not found. Continuing."
    }
    else {
        if ((Get-WindowsOptionalFeature -Online -FeatureName smb1protocol -ErrorAction SilentlyContinue).State -notlike "Disabled") {
            # Disables smb1protocol feature
            try {
                Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol
                # Disabled SMB1, exit
                exit 0
            }
            catch {
                Write-Host "smb1protocol feature not found. Continuing."
            }
        }
    }

    if (-not $(Get-Command -Name "Get-SmbServerConfiguration").Name -like "Get-SmbServerConfiguration") {
        Write-Host "Get-SmbServerConfiguration command not found. Continuing."
        $Path = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        $Name = "SMB1"
        # https://docs.microsoft.com/en-us/windows-server/storage/file-server/troubleshoot/detect-enable-and-disable-smbv1-v2-v3#registry-editor
        # Sets SMB1 to 0
        Set-ItemProp -Path $Path -Name $Name -Value $Disable
    }
    if ((Get-SmbServerConfiguration).EnableSMB1Protocol) {
        try {
            Set-SmbServerConfiguration -EnableSMB1Protocol $false            
        }
        catch {
            Write-Host "Failed to disable SMBv1."
            exit 1
        }
    }
}
end {}