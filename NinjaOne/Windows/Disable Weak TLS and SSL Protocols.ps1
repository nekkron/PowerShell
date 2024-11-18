#Requires -Version 5.1

<#
.SYNOPSIS
    Disables TLS 1.0, TLS 1.1, SSL 2.0, SSL 3.0. Enables TLS 1.2.
.DESCRIPTION
    Disables TLS 1.0, TLS 1.1, SSL 2.0, SSL 3.0. Enables TLS 1.2.
.EXAMPLE
    No Parameters Needed
    Disables TLS 1.0, TLS 1.1, SSL 2.0, SSL 3.0. Enables TLS 1.2.
.EXAMPLE
    -Restart
    Disables TLS 1.0, TLS 1.1, SSL 2.0, SSL 3.0. Enables TLS 1.2. Does Restart the computer.
.OUTPUTS
    String[]
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Could possibly run on Windows 7 and Server 2008 R2, but PowerShell 5.1 would be required.
    Release Notes: Renamed script and added Script Variable support
#>

[CmdletBinding()]
param (
    [Parameter()]
    [Switch]$Restart = [System.Convert]::ToBoolean($env:forceRestart)
)

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
    
    @(
        [PSCustomObject]@{
            Protocol = 'SSL 2.0'
            Value    = 0
            Default  = 1
        }
        [PSCustomObject]@{
            Protocol = 'SSL 3.0'
            Value    = 0
            Default  = 1
        }
        [PSCustomObject]@{
            Protocol = 'TLS 1.0'
            Value    = 0
            Default  = 1
        }
        [PSCustomObject]@{
            Protocol = 'TLS 1.1'
            Value    = 0
            Default  = 1
        }
        [PSCustomObject]@{
            Protocol = 'TLS 1.2'
            Value    = 1
            Default  = 0
        }
    ) | ForEach-Object {
        $RegServerBase = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$($_.Protocol)\Server"
        $RegClientBase = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$($_.Protocol)\Client"
        
        New-Item $RegServerBase -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $RegServerBase -Name 'Enabled' -Value $($_.Value) -PropertyType 'DWord' -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $RegServerBase -Name 'DisabledByDefault' -Value $($_.Default) -PropertyType 'DWord' -Force -ErrorAction SilentlyContinue | Out-Null
        
        New-Item $RegClientBase -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $RegClientBase -Name 'Enabled' -Value $($_.Value) -PropertyType 'DWord' -Force -ErrorAction SilentlyContinue | Out-Null
        New-ItemProperty -Path $RegClientBase -Name 'DisabledByDefault' -Value $($_.Default) -PropertyType 'DWord' -Force -ErrorAction SilentlyContinue | Out-Null

        $State = if (
            $(Get-ItemPropertyValue -Path $RegServerBase -Name 'Enabled') -eq 0 -and
            $(Get-ItemPropertyValue -Path $RegServerBase -Name 'DisabledByDefault') -eq 1
        ) { 'disabled' } else { 'enabled' }

        Write-Host "$($_.Protocol) has been $State."
    }

    if (-not $Restart) { 
        Write-Host "Please reboot for settings to take effect." 
    }
    else {
        Write-Host "Scheduling reboot for 30 seconds from now!"
        Start-Process cmd.exe -ArgumentList "/c shutdown.exe /r /t 30"
    }
}
end {
    
    
    
}
