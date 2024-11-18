#Requires -Version 4.0

<#
.SYNOPSIS
    This script allows you to Install, Uninstall, or Upgrade an application using Chocolatey. If Chocolatey is not present or outdated, options are available to install or upgrade it before proceeding with the application action.
.DESCRIPTION
    This script allows you to Install, Uninstall, or Upgrade an application using Chocolatey. 
    If Chocolatey is not present or outdated, options are available to install or upgrade it before proceeding with the application action.
.EXAMPLE
    (No Params)

    Invalid action selected! Only the following actions are supported. 'Install','Uninstall','Upgrade'

PARAMETER: -Name "NameOfApplication"
    Name of the application you would like to uninstall, upgrade, or install. 
    https://community.chocolatey.org/packages may be a good resource to find this.

PARAMETER: -Action "ReplaceMeWithValidAction"
    Valid actions are 'Install', 'Upgrade', or 'Uninstall' your desired package.

.EXAMPLE
    -Action "Install" -Name "firefox"
    'choco' was found at 'C:\ProgramData\chocolatey\bin\choco.exe'.
    Installing the following packages:
    firefox
    By installing, you accept licenses for the packages.

    Firefox v117.0.1 [Approved]
    Firefox package files install completed. Performing other installation steps.
    Using locale 'en-US'...
    Downloading Firefox 64 bit
        from 'https://download.mozilla.org/?product=firefox-117.0.1-ssl&os=win64&lang=en-US'

    Download of Firefox Setup 117.0.1.exe (55.52 MB) completed.
    Hashes match.
    Installing Firefox...
    Firefox has been installed.
    WARNING: No registry key found based on  'Mozilla Firefox'
    Firefox may be able to be automatically uninstalled.
    The install of Firefox was successful.
    Software installed to 'C:\Program Files\Mozilla Firefox'

    Chocolatey installed 1/1 packages. 
    See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
    Exit Code: 0
    Successfully completed action 'Install' for package firefox..

PARAMETER: -InstallChocolateyIfMissing
    If Chocolatey isn't installed, this option will install it prior to starting your action.

PARAMETER: -UpgradeChocolatey
    If Chocolatey is outdated, this option will upgrade it before completing your action.

PARAMETER: -SkipSleep
    The script will wait at a random interval between 1 and 15 minutes prior to installing chocolatey in an effort to avoid rate limiting. 
    Use this option to skip the wait. https://docs.chocolatey.org/en-us/community-repository/community-packages-disclaimer#excessive-use
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 8, Windows Server 2012
    Release Notes: Renamed script, added Script Variable support, fixed bug for existing installations, added server 2012 and win 8 support, added support for uninstall and upgrade.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Name,
    [Parameter()]
    [String]$Action,
    [Parameter()]
    [Switch]$InstallChocolateyIfMissing = [System.Convert]::ToBoolean($env:installChocolateyIfNecessary),
    [Parameter()]
    [Switch]$UpgradeChocolatey = [System.Convert]::ToBoolean($env:upgradeChocolateyItselfIfAvailable),
    [Parameter()]
    [Switch]$SkipSleep = [System.Convert]::ToBoolean($env:skipSleep)
)
# Helper functions and input validation
begin {
    # URL to Chocolatey installation script. Feel free to replace this with your own link.
    $InstallUri = "https://community.chocolatey.org/install.ps1"

    if ($env:packageName -and $env:packageName -notlike "null") { $Name = $env:packageName }
    if ($env:action -and $env:action -notlike "null") { $Action = $env:action }

    # Validate we were given a proper action.
    if ($Action -ne "Install" -and $Action -ne "Upgrade" -and $Action -ne "Uninstall") {
        Write-Error "Invalid action selected! Only the following actions are supported. 'Install','Uninstall','Upgrade'"
        exit 1
    }

    # Prevent dangerous action
    if ($Name -like "All" -and $Action -ne "Upgrade") {
        Write-Error "Uninstalling all packages is not supported!"
        exit 1
    }

    # If Name or Action is missing
    if (-not ($Name) -or -not ($Action)) {
        Write-Error "A package name and action is required!"
        exit 1
    }

    # Check if we're running with administrator rights
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Local Administrator privileges or run as SYSTEM. https://ninjarmm.zendesk.com/hc/en-us/articles/360016094532-Credential-Exchange"
        exit 1
    }

    # Test for Chocolatey
    function Test-ChocolateyInstalled {
        [CmdletBinding()]
        param()
    
        $Command = Get-Command choco -ErrorAction Ignore

        if ($Command.Path -and (Test-Path -Path $Command.Path)) {
            # choco is in the %PATH% environment variable, assume it's installed
            Write-Host "'choco' was found at '$($Command.Path)'."
            $true
        }
        else {
            Write-Warning "Chocolatey is missing!"
            $false
        }
    }

    # Occasionally System doesn't have all of its environmental variables. This will add them back in and set $env:TEMP to one it can reach.
    function Update-EnvironmentVariables {
        $TempFolder = $env:TEMP
        foreach ($level in "Machine", "User") {
            [Environment]::GetEnvironmentVariables($level).GetEnumerator() | ForEach-Object {
                # For Path variables, append the new values, if they're not already in there
                if ($_.Name -match 'Path$') {
                    $_.Value = ($((Get-Content "Env:$($_.Name)") + ";$($_.Value)") -split ';' | Select-Object -Unique) -join ';'
                }
                $_
            } | Set-Content -Path { "Env:$($_.Name)" }
        }
        $env:TEMP = $TempFolder
    }

    # Download helper
    function Invoke-Download {
        param(
            [Parameter()]
            [String]$URL,
            [Parameter()]
            [String]$Path,
            [Parameter()]
            [Switch]$SkipSleep
        )
        Write-Host "URL Given, Downloading the file..."

        $i = 1
        While ($i -lt 4) {
            if (-not ($SkipSleep)) {
                $SleepTime = Get-Random -Minimum 1 -Maximum 15
                Write-Host "Sleeping for $SleepTime minutes."
                Start-Sleep -Seconds ($SleepTime * 60)
            }

            Write-Host "Download Attempt $i"

            try {
                Invoke-WebRequest -Uri $URL -OutFile $Path -MaximumRedirection 10 -UseBasicParsing
                $File = Test-Path -Path $Path -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "An error has occurred while downloading!"
                Write-Warning $_.Exception.Message
            }

            if ($File) {
                $i = 4
            }
            else {
                $i++
            }
        }

        if (-not (Test-Path $Path)) {
            Write-Error "Failed to download file!"
            Exit 1
        }
        else {
            Write-Host "Success!"
            $Path
        }
    }
}
process {
    # Main script logic

    # Chocolatey requires TLS1.2 but we'll also enable TLS1.3 as its more secure.
    $SupportedTLSversions = [enum]::GetValues('Net.SecurityProtocolType')
    if ( ($SupportedTLSversions -contains 'Tls13') -and ($SupportedTLSversions -contains 'Tls12') ) {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol::Tls13 -bor [System.Net.SecurityProtocolType]::Tls12
    }
    elseif ( $SupportedTLSversions -contains 'Tls12' ) {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    }
    else {
        Write-Warning "TLS 1.2 and TLS 1.3 isn't supported on this system. This operation may fail! https://blog.chocolatey.org/2020/01/remove-support-for-old-tls-versions/"
    }

    # Sometimes SYSTEM doesn't have the environmental variables it needs to check if Chocolatey is installed.
    Update-EnvironmentVariables

    # We only need to install Chocolatey if it's missing AND the user requested it.
    if (-not $(Test-ChocolateyInstalled) -and $InstallChocolateyIfMissing) {
        Write-Host "Chocolatey not installed."
        Write-Host "Installing Chocolatey."

        $DownloadArguments = @{
            Path = "$env:TEMP\install.ps1"
            URL  = $InstallUri
        }
        if ($SkipSleep) { $DownloadArguments["SkipSleep"] = $True }
        
        # We're going to use Chocolatey's installation script to install Chocolatey
        $ChocolateyScript = [scriptblock]::Create($(Invoke-Download @DownloadArguments))
        try {
            $ChocolateyScript.Invoke()
            if (-not (Test-ChocolateyInstalled)) {
                throw "Chocolatey is missing but the script didn't throw any terminating errors?"
            }
        }
        catch {
            Write-Error $_
            Write-Host "Failed to install Chocolatey."
            exit 1
        }

        if (Test-Path "$env:TEMP\install.ps1" -ErrorAction SilentlyContinue) {
            Remove-Item -Path "$env:TEMP\install.ps1"
        }
    }
    elseif (-not $(Test-ChocolateyInstalled)) {
        Write-Error "Install Chocolatey If Necessary is not selected. Unable to continue."
        exit 1
    }

    # If Chocolatey is outdated and we were requested to update it let's go ahead and update it.
    $ChocolateyOutdated = & choco outdated --limitoutput
    if ($env:ChocolateyInstall -and ($ChocolateyOutdated -match "chocolatey\|") -and $UpgradeChocolatey) {
        Write-Host "The installed version of Chocolatey is outdated."
        Write-Host ""
        Write-Host "Installed Package | Installed Version | Current Version | Pinned?"
        $ChocolateyOutdated | Write-Host
        Write-Host ""
        Write-Host "Upgrading...."
        
        $ChocoUpdateArgs = New-Object System.Collections.Generic.List[string]
        $ChocoUpdateArgs.Add("upgrade")
        $ChocoUpdateArgs.Add("chocolatey")
        $ChocoUpdateArgs.Add("--yes")
        $ChocoUpdateArgs.Add("--nocolor")
        $ChocoUpdateArgs.Add("--no-progress")
        $ChocoUpdateArgs.Add("--limitoutput")

        $chocoupdate = Start-Process "choco" -ArgumentList $ChocoUpdateArgs -Wait -PassThru -NoNewWindow
        Write-Host "Exit Code: $($chocoupdate.ExitCode)"
        switch ($chocoupdate.ExitCode) {
            0 { Write-Host "Successfully updated chocolatey." }
            default { 
                Write-Error "Exit code does not indicate success."
                exit 1
            }
        }
    }

    # Time to actually perform the chocolatey action requested
    $ChocoArguments = New-Object System.Collections.Generic.List[string]
    switch ($Action) {
        "Install" { $ChocoArguments.Add("install") }
        "Uninstall" { $ChocoArguments.Add("uninstall") }
        "Upgrade" { $ChocoArguments.Add("upgrade") }
    }

    $ChocoArguments.Add($Name)
    $ChocoArguments.Add("--yes")
    $ChocoArguments.Add("--nocolor")
    $ChocoArguments.Add("--no-progress")
    $ChocoArguments.Add("--limitoutput")

    $chocolatey = Start-Process "choco" -ArgumentList $ChocoArguments -Wait -PassThru -NoNewWindow

    # If we get a good exit code we can exit the script but we should provide feedback incase something isn't working right.
    Write-Host "Exit Code: $($chocolatey.ExitCode)"
    switch ($chocolatey.ExitCode) {
        0 { Write-Host "Successfully completed action '$Action' for package $Name." }
        default { Write-Error "Exit code does not indicate success." }
    }

    exit $($chocolatey.ExitCode)
}
end {
    
    
    
}

