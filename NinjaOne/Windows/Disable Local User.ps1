#Requires -Version 5.1

<#
.SYNOPSIS
    Disable a local account
.DESCRIPTION
    Disable a local account
.EXAMPLE
     -UserName "AdminTest"
    Disables the account AdminTest
.EXAMPLE
    PS C:\> Disable-LocalAdminAccount.ps1 -UserName "Administrator"
    Disables the account AdminTest
.OUTPUTS
    None
    String[]
.NOTES
    Minimum Supported OS: Windows 10, Windows Server 2016+
    Release Notes: Renamed script and added Script Variable support
.COMPONENT
    LocalBuiltInAccountManagement
#>

[CmdletBinding()]
param (
    # User name of a local account
    [Parameter()]
    [String]$UserName
)

begin {
    if ($env:usernameToDisable -and $env:usernameToDisable -notlike "null") { $UserName = $env:usernameToDisable }
    if (-not $UserName) {
        Write-Host "UserName Parameter is required."
        exit 1
    }
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        if ($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
        { Write-Output $true }
        else
        { Write-Output $false }
    }
}
process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }
    if ($(Get-Command -Name "Disable-LocalUser" -ErrorAction SilentlyContinue)) {
        # Disables $UserName using Disable-LocalUser
        try {
            Disable-LocalUser $UserName -Confirm:$false -ErrorAction Stop
            if (-not $(Get-LocalUser $UserName | Select-Object -ExpandProperty Enabled)) {
                Write-Host "Disabled Account: $UserName"
            }
            else {
                Write-Host "[Error] Failed to Disabled Account: $UserName"
                exit 1
            }
        }
        catch {
            Write-Error $_
            Write-Host "[Error] Failed to Disabled Account: $UserName"
            exit 1
        }
    }
    else {
        # Disables $UserName using net.exe
        net.exe user $UserName /active:no
        if ($LASTEXITCODE -gt 0) {
            Write-Host "[Error] Failed to Disabled Account: $UserName"
            exit 1
        }
        if ($(net.exe user $UserName | Select-String -Pattern "Account active") -like "*Yes*") {
            Write-Host "Disabled Account: $UserName"
        }
        else {
            Write-Host "[Error] Failed to Disabled Account: $UserName"
            exit 1
        }
    }
}
end {
    
    
    
}
