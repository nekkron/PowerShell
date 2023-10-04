<#
Update-Chrome.ps1
Adapted from https://github.com/richeaston/Intune-Proactive-Remediation/tree/main/Chrome-Forced-Update
This script should be run as user if Chrome is installed per user.
#>

$ProcessName = "chrome"

function Show-Window {
    param(
        [Parameter(Mandatory)]
        [string] $ProcessName
    )
  
    # As a courtesy, strip '.exe' from the name, if present.
    $ProcessName = $ProcessName -replace '\.exe$'
  
    # Get the ID of the first instance of a process with the given name
    # that has a non-empty window title.
    # NOTE: If multiple instances have visible windows, it is undefined
    #       which one is returned.
    $procId = (Get-Process -ErrorAction Ignore $ProcessName).Where({ $_.MainWindowTitle }, 'First').Id
  
    
    # Note: 
    #  * This can still fail, because the window could have been closed since
    #    the title was obtained.
    #  * If the target window is currently minimized, it gets the *focus*, but is
    #    *not restored*.
    #  * The return value is $true only if the window still existed and was *not
    #    minimized*; this means that returning $false can mean EITHER that the
    #    window doesn't exist OR that it just happened to be minimized.
    $null = (New-Object -ComObject WScript.Shell).AppActivate($procId)
  
}

function Get-ChromeVersion {

    $Version = Get-ItemPropertyValue -Path 'HKCU:\Software\Google\Chrome\BLBeacon' -Name version -ErrorAction SilentlyContinue
        
    return $Version
}


$mode = $MyInvocation.MyCommand.Name.Split(".")[0]

if ($mode -eq "detect") {

    try { 

        #check Chrome version installed    
        #$GCVersionInfo = (Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction Ignore).'(Default)').VersionInfo
        #$GCVersion = $GCVersionInfo.ProductVersion
        #$GCVersion = Get-ItemPropertyValue -Path 'HKCU:\Software\Google\Chrome\BLBeacon' -Name version -ErrorAction SilentlyContinue
        
        $GCVersion = Get-ChromeVersion
        Write-Output "Installed Chrome Version: $GCVersion" 

        #Get latest version of Chrome
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $j = Invoke-WebRequest 'https://omahaproxy.appspot.com/all.json' | ConvertFrom-Json

        foreach ($ver in $j) {
            if ($ver.os -like '*win') {
                $GCVer = $ver.versions.Current_Version
                foreach ($GCV in $GCVer[4]) {
                    if ($GCV -eq $GCVersion) {
                        # Installed version is latest
                        Write-Output "Latest: $GCV == Installed: $GCVersion, no update required $(Get-Date)"
                        Exit 0
                    }
                    else {
                        # Installed version is not latest
                        Write-Output "Latest: $GCV > Installed: $GCVersion, remediation required $(Get-Date)" 
                        Exit 1
                    }
                }
            }
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        if ($errmsg -eq "Cannot bind argument to parameter 'Path' because it is null.") {
            Write-Output "Google Chrome version not found - $(Get-Date)"
            Exit 0
        }
        else {
            Write-Output $errMsg
            Exit 1
        }
    }

}
else {
 
    Write-Output " Running Google Chrome Update $(Get-Date)"

    if (Test-Path -Path "C:\Program Files (x86)\Google\Update\GoogleUpdate.exe" ) {
        
        if (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
            Write-Output " $ProcessName running, closing to update"
            Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
        }
        else {
            Write-Output " $ProcessName not running, updating"
        }

        & "C:\Program Files (x86)\Google\Update\GoogleUpdate.exe" /c
        & "C:\Program Files (x86)\Google\Update\GoogleUpdate.exe" /ua /installsource scheduler
        # Have to start the browser to complete the install
        Start-Sleep 30        
       Start-Process $ProcessName
    }

    Exit 0

}
