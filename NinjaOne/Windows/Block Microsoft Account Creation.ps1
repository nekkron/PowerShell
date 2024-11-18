#Requires -Version 5.1 -RunAsAdministrator

<#
.SYNOPSIS
    Block or Allow the ability to create Microsoft Accounts.
.DESCRIPTION
    Block or Allow the ability to create Microsoft Accounts.
.EXAMPLE
    PS C:\> Disable-MicrosoftAccountCreation.ps1
    Blocks creation of Microsoft Accounts.
PARAMETER: -Allow
    Allows creation of Microsoft Accounts.
.EXAMPLE
    PS C:\> Disable-MicrosoftAccountCreation.ps1
    Allows creation of Microsoft Accounts.
PARAMETER: -ForceReboot
    Blocks creation of Microsoft Accounts and reboot after 2 minutes.
.EXAMPLE
    PS C:\> Disable-MicrosoftAccountCreation.ps1 -ForceReboot
    Blocks creation of Microsoft Accounts and reboot after 2 minutes.
.INPUTS
    None
.OUTPUTS
    String[]
.NOTES
    Release Notes: Updated Calculated Name
    Only usable on Windows 10, possible Windows 11(UNTESTED/UNVERIFIED).
.COMPONENT
    LocalBuiltInAccountManagement
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $Allow,
    [switch]
    $BlockLogin,
    [switch]
    $ForceReboot
)

begin {
    function Set-ItemProp {
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet("DWord", "QWord", "String", "ExpandedString", "Binary", "MultiString", "Unknown")]
            $PropertyType = "DWord"
        )
        if (-not $(Test-Path -Path $Path)) {
            # Check if path does not exist and create the path
            New-Item -Path $Path -Force | Out-Null
        }
        if ((Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue)) {
            # Update property and print out what it was changed from and changed to
            $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name
            try {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Error "[Error] Unable to Set registry key for $Name please see below error!"
                Write-Error $_
                exit 1
            }
            Write-Host "$Path\$Name changed from $CurrentValue to $($(Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name)"
        }
        else {
            # Create property with value
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Error "[Error] Unable to Set registry key for $Name please see below error!"
                Write-Error $_
                exit 1
            }
            Write-Host "Set $Path\$Name to $($(Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue).$Name)"
        }
    }
    if ($env:allowOrBlockMicrosoftAccountCreation -like "Allow") {
        $Allow = $true
    }
    elseif ($env:allowOrBlockMicrosoftAccountCreation -like "Block Creation" -or $env:allowOrBlockMicrosoftAccountCreation -like "Block Creation And Login") {
        $Allow = $false
    }
    if ($env:forceReboot -like "true") {
        $ForceReboot = $true
    }
}
process {
    if ($Allow) {
        # Allow
        Set-ItemProp -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "NoConnectedUser" -Value 0
        Set-ItemProp -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount" -Name "value" -Value 1
        Remove-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\MicrosoftAccount" -Name "DisableUserAuth" -ErrorAction SilentlyContinue

        Write-Host "Allowing Microsoft accounts to be created."
    }
    else {
        # Block
        if ($env:allowOrBlockMicrosoftAccountCreation -like "Block Creation And Login" -or $BlockLogin) {
            # Block MS Account Creation and Login
            Set-ItemProp -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "NoConnectedUser" -Value 3
            Set-ItemProp -Path "HKLM:\Software\Policies\Microsoft\MicrosoftAccount" -Name "DisableUserAuth" -Value 1
        }
        else {
            # Block MS Account Creation
            Set-ItemProp -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "NoConnectedUser" -Value 1
        }
        Set-ItemProp -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount" -Name "value" -Value 0

        Write-Host "Blocking Microsoft accounts from being created."
    }

    if ($ForceReboot) {
        # Reboot
        shutdown.exe -r -t 60
    }
    else {
        # Do not reboot
        Write-Host "Please restart $([System.Net.Dns]::GetHostName())"
    }
}
end {
    
    
    
}
