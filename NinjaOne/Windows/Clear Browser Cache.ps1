#Requires -Version 5.1

<#
.SYNOPSIS
    Clear the browser cache for all users (when run as system), some users (when a user is specified), or just the current user (when run as current user) depending on how the script is run.
.DESCRIPTION
    Clear the browser cache for all users (when run as system), some users (when a user is specified), or just the current user (when run as current user) depending on how the script is run.
.EXAMPLE
    -Firefox -ForceCloseBrowsers
    
    WARNING: Running Mozilla Firefox processess detected.

    Clearing browser cache for tuser1
    Closing Mozilla Firefox processes for tuser1 as requested.
    Clearing Mozilla Firefox's browser cache for tuser1.


    Clearing browser cache for cheart
    Closing Mozilla Firefox processes for cheart as requested.
    Clearing Mozilla Firefox's browser cache for cheart.

PARAMETER: -Usernames "ReplaceWithYourDesiredUsername"
    Clear the browser cache for only this comma-separated list of users.

PARAMETER: -Firefox
    Clear the browser cache for Mozilla Firefox.

PARAMETER: -Chrome
    Clear the browser cache for Google Chrome.

PARAMETER: -Edge
    Clear the browser cache for Microsoft Edge.

PARAMETER: -ForceCloseBrowsers
    Force close the browser prior to clearing the browser cache.

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Usernames,
    [Parameter()]
    [Switch]$Firefox = [System.Convert]::ToBoolean($env:mozillaFirefox),
    [Parameter()]
    [Switch]$Chrome = [System.Convert]::ToBoolean($env:googleChrome),
    [Parameter()]
    [Switch]$Edge = [System.Convert]::ToBoolean($env:microsoftEdge),
    [Parameter()]
    [Switch]$ForceCloseBrowsers = [System.Convert]::ToBoolean($env:forceCloseBrowsers)
)

begin {
    if ($env:usernames -and $env:usernames -notlike "null") { $Usernames = $env:usernames }

    # Check if none of the browser checkboxes (Firefox, Chrome, Edge) are selected
    if (!$Firefox -and !$Chrome -and !$Edge) {
        # Output an error message and exit the script if no browser is selected
        Write-Host -Object "[Error] You must select a checkbox for a browser whose cache you would like to clear."
        exit 1
    }

    # Define a function to get the list of logged-in users
    function Get-LoggedInUsers {
        # Run the 'quser.exe' command to get the list of logged-in users
        $quser = quser.exe
        # Replace multiple spaces with a comma, then convert the output to CSV format
        $quser -replace '\s{2,}', ',' -replace '>' | ConvertFrom-Csv
    }

    function Get-UserHives {
        param (
            [Parameter()]
            [ValidateSet('AzureAD', 'DomainAndLocal', 'All')]
            [String]$Type = "All",
            [Parameter()]
            [String[]]$ExcludedUsers,
            [Parameter()]
            [switch]$IncludeDefault
        )
    
        # User account SIDs follow specific patterns depending on if they are Azure AD, Domain, or local accounts.
        $Patterns = switch ($Type) {
            "AzureAD" { "S-1-12-1-(\d+-?){4}$" }
            "DomainAndLocal" { "S-1-5-21-(\d+-?){4}$" }
            "All" { "S-1-12-1-(\d+-?){4}$" ; "S-1-5-21-(\d+-?){4}$" } 
        }
    
        # Retrieve user profiles by matching account SIDs to the defined patterns.
        $UserProfiles = Foreach ($Pattern in $Patterns) { 
            Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
                Where-Object { $_.PSChildName -match $Pattern } | 
                Select-Object @{Name = "SID"; Expression = { $_.PSChildName } },
                @{Name = "UserName"; Expression = { "$($_.ProfileImagePath | Split-Path -Leaf)" } }, 
                @{Name = "UserHive"; Expression = { "$($_.ProfileImagePath)\NTuser.dat" } }, 
                @{Name = "Path"; Expression = { $_.ProfileImagePath } }
        }
    
        # Optionally include the .Default user profile if requested.
        switch ($IncludeDefault) {
            $True {
                $DefaultProfile = "" | Select-Object UserName, SID, UserHive, Path
                $DefaultProfile.UserName = "Default"
                $DefaultProfile.SID = "DefaultProfile"
                $DefaultProfile.Userhive = "$env:SystemDrive\Users\Default\NTUSER.DAT"
                $DefaultProfile.Path = "C:\Users\Default"

                # Add default profile to the list if it's not in the excluded users list
                $DefaultProfile | Where-Object { $ExcludedUsers -notcontains $_.UserName }
            }
        }

        # Filter out the excluded users from the user profiles list and return the result.
        $UserProfiles | Where-Object { $ExcludedUsers -notcontains $_.UserName }
    }
    
    # Function to find installation keys based on the display name
    function Find-InstallKey {
        [CmdletBinding()]
        param (
            [Parameter(ValueFromPipeline = $True)]
            [String]$DisplayName,
            [Parameter()]
            [Switch]$UninstallString,
            [Parameter()]
            [String]$UserBaseKey
        )
        process {
            # Initialize an empty list to hold installation objects
            $InstallList = New-Object System.Collections.Generic.List[Object]
            
            # Search for programs in 32-bit and 64-bit system locations. Then add them to the list if they match the display name
            $Result = Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
            if ($Result) { $InstallList.Add($Result) }

            $Result = Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
            if ($Result) { $InstallList.Add($Result) }

            # If a user base key is specified, search in the user-specified 64-bit and 32-bit paths.
            if ($UserBaseKey) {
                $Result = Get-ChildItem -Path "$UserBaseKey\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
                if ($Result) { $InstallList.Add($Result) }
    
                $Result = Get-ChildItem -Path "$UserBaseKey\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Get-ItemProperty | Where-Object { $_.DisplayName -like "*$DisplayName*" }
                if ($Result) { $InstallList.Add($Result) }
            }
    
            # If the UninstallString switch is specified, return only the uninstall strings; otherwise, return the full installation objects.
            if ($UninstallString) {
                $InstallList | Select-Object -ExpandProperty UninstallString -ErrorAction SilentlyContinue
            }
            else {
                $InstallList
            }
        }
    }

    function Test-IsSystem {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
    }

    if (!$ExitCode) {
        $ExitCode = 0
    }
}
process {
    # Initialize a list to store users whose cache needs to be cleared
    $UsersToClear = New-Object System.Collections.Generic.List[object]

    # Get all user profiles
    $AllUserProfiles = Get-UserHives

    # If specific usernames are provided
    if ($Usernames) {
        $Usernames -split "," | ForEach-Object {
            $User = $_.Trim()

            # Check if different user to existing user
            if (!(Test-IsSystem) -and $User -ne $env:username) {
                Write-Host -Object "[Error] Unable to clear cache for $User."
                Write-Host -Object "[Error] Please run as 'System' to clear the cache for users other than the currently logged-on user."
                $ExitCode = 1
                return
            }

            # Ensure username does not contain illegal characters.
            if ($_.Trim() -match '\[|\]|:|;|\||=|\+|\*|\?|<|>|/|\\|"|@') {
                Write-Host -Object ("[Error] '$User' contains one of the following invalid characters." + ' " [ ] : ; | = + * ? < > / \ @')
                $ExitCode = 1
                return
            }

            # Ensure the username does not contain spaces.
            if ($User -match '\s') {
                Write-Host -Object ("[Error] '$User' is an invalid username because it contains a space.")
                $ExitCode = 1
                return
            }

            # Ensure the username is not longer than 20 characters.
            $UserNameCharacters = $User | Measure-Object -Character | Select-Object -ExpandProperty Characters
            if ($UserNameCharacters -gt 20) {
                Write-Host -Object "[Error] '$($_.Trim())' is an invalid username because it is too long. The username needs to be less than or equal to 20 characters."
                $ExitCode = 1
                return
            }

            # Check if the user exists in the user profiles.
            if ($($AllUserProfiles.Username) -notcontains $User) {
                Write-Host "[Error] User '$User' either does not exist or has not signed in yet. Please see the table below for initialized profiles."
                $AllUserProfiles | Format-Table Username, Path | Out-String | Write-Host
                $ExitCode = 1
                return
            }

            # Add the user profile to the list of users to clear.
            $UsersToClear.Add(( $AllUserProfiles | Where-Object { $_.Username -eq $User }  ))
        }

        # Check if no valid usernames were given.
        if ($UsersToClear.Count -eq 0) { 
            Write-Host -Object "[Error] No valid username was given."
            exit 1
        }
    }
    elseif (Test-IsSystem) {
        # If running as System, add all user profiles to the list
        $AllUserProfiles | ForEach-Object {
            $UsersToClear.Add($_)
        }
    }
    else {
        # Otherwise, add the currently logged-in user to the list
        $UsersToClear.Add(( $AllUserProfiles | Where-Object { $_.Username -eq $env:USERNAME } ))
    }

    $LoadedProfiles = New-Object System.Collections.Generic.List[string]

    # Iterate over each user in the list of users to clear
    $UsersToClear | ForEach-Object {
        # Load the user's registry hive (ntuser.dat) if it's not already loaded
        if ((Test-Path Registry::HKEY_USERS\$($_.SID)) -eq $false) {
            $LoadedProfiles.Add("$($_.SID)")

            Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe LOAD HKU\$($_.SID) `"$($_.UserHive)`"" -Wait -WindowStyle Hidden
        }

        # Find the Firefox installation for the user
        if ($Firefox) {
            $FirefoxInstallation = Find-InstallKey -DisplayName "Mozilla Firefox" -UserBaseKey "Registry::HKEY_USERS\$($_.SID)"
        }

        # Find the Chrome installation for the user
        if ($Chrome) {
            $ChromeInstallation = Find-InstallKey -DisplayName "Google Chrome" -UserBaseKey "Registry::HKEY_USERS\$($_.SID)"
        }

        # Find the Edge installation for the user
        if ($Edge) {
            $EdgeInstallation = Find-InstallKey -DisplayName "Microsoft Edge" -UserBaseKey "Registry::HKEY_USERS\$($_.SID)"
        }
    }

    # If force closing browsers is requested
    if ($ForceCloseBrowsers) {
        # Check and handle running Firefox processes
        if ($Firefox -and (Get-Process -Name "firefox" -ErrorAction SilentlyContinue)) {
            Write-Warning -Message "Running Mozilla Firefox processess detected."
            $FirefoxProcesses = Get-Process -Name "firefox" -ErrorAction SilentlyContinue
        }

        # Check and handle running Chrome processes
        if ($Chrome -and (Get-Process -Name "chrome" -ErrorAction SilentlyContinue)) {
            Write-Warning -Message "Running Google Chrome processess detected."
            $ChromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
        }

        # Check and handle running Edge processes
        if ($Edge -and (Get-Process -Name "msedge" -ErrorAction SilentlyContinue)) {
            Write-Warning -Message "Running Microsoft Edge processess detected."
            $EdgeProcesses = Get-Process -Name "msedge" -ErrorAction SilentlyContinue
        }
    }

    # Iterate over each user in the list of users to clear
    $UsersToClear | ForEach-Object {
        Write-Host -Object "`nClearing browser cache for $($_.Username)"

        # Handle Firefox cache clearing
        if ($Firefox -and !$FirefoxInstallation) {
            Write-Warning -Message "Mozilla Firefox is not installed!"
        }
        elseif ($Firefox) {
            if (Test-Path -Path "$($_.Path)\AppData\Local\Mozilla\Firefox\Profiles") {

                if ($ForceCloseBrowsers -and $FirefoxProcesses) {
                    Write-Host -Object "Closing Mozilla Firefox processes for $($_.Username) as requested."

                    $User = $_.Username
                    $RelevantAccount = Get-LoggedInUsers | Where-Object { $User -match $_.USERNAME }
                    $RelevantProcess = $FirefoxProcesses | Where-Object { $RelevantAccount.ID -contains $_.SI }

                    try {
                        $RelevantProcess | ForEach-Object { $_ | Stop-Process -Force -ErrorAction Stop }
                    }
                    catch {
                        Write-Host -Object "[Error] Failed to close one of Mozilla Firefox's processes."
                        Write-Host -Object "[Error] $($_.Exception.Message)"
                        $ExitCode = 1
                    }
                }

                Write-Host -Object "Clearing Mozilla Firefox's browser cache for $($_.Username)."

                try {
                    Get-ChildItem -Path "$($_.Path)\AppData\Local\Mozilla\Firefox\Profiles\*\cache2" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $False } | Remove-Item -ErrorAction Stop
                }
                catch {
                    Write-Host -Object "[Error] Unable to clear Mozilla Firefox's cache."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    $ExitCode = 1
                }
            }
            else {
                Write-Host -Object "[Error] Mozilla Firefox's local appdata folder is not at '$($_.Path)\AppData\Local\Mozilla\Firefox\Profiles'. Unable to clear cache."
                $ExitCode = 1
            }
        }

        # Handle Chrome cache clearing
        if ($Chrome -and !$ChromeInstallation) {
            Write-Warning -Message "Google Chrome is not installed!"
        }
        elseif ($Chrome) {
            if (Test-Path -Path "$($_.Path)\AppData\Local\Google") {

                if ($ForceCloseBrowsers -and $ChromeProcesses) {
                    Write-Host -Object "Closing Google Chrome processes for $($_.Username) as requested."

                    $User = $_.Username
                    $RelevantAccount = Get-LoggedInUsers | Where-Object { $User -match $_.USERNAME }
                    $RelevantProcess = $ChromeProcesses | Where-Object { $RelevantAccount.ID -contains $_.SI }

                    try {
                        $RelevantProcess | ForEach-Object { $_ | Stop-Process -Force -ErrorAction Stop }
                    }
                    catch {
                        Write-Host -Object "[Error] Failed to close one of Google Chrome's processes."
                        Write-Host -Object "[Error] $($_.Exception.Message)"
                        $ExitCode = 1
                    }
                }

                Write-Host -Object "Clearing Google Chrome's browser cache for $($_.Username)."

                try{
                    Get-ChildItem -Path "$($_.Path)\AppData\Local\Google\Chrome\User Data\*\Cache" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $False } | Remove-Item -ErrorAction Stop
                    Get-ChildItem -Path "$($_.Path)\AppData\Local\Google\Chrome\User Data\*\Code Cache" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $False } | Remove-Item -ErrorAction Stop
                    Get-ChildItem -Path "$($_.Path)\AppData\Local\Google\Chrome\User Data\*\GPUCache" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $False } | Remove-Item -ErrorAction Stop
                }catch{
                    Write-Host -Object "[Error] Unable to clear Google Chrome's cache."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    $ExitCode = 1
                }
            }else {
                Write-Host -Object "[Error] Chrome's local appdata folder is not at '$($_.Path)\AppData\Local\Google'. Unable to clear cache."
                $ExitCode = 1
            }
        }

        # Handle Edge cache clearing
        if ($Edge -and !$EdgeInstallation) {
            Write-Warning -Message "Microsoft Edge is not installed!"
        }
        elseif ($Edge) {
            if (Test-Path -Path "$($_.Path)\AppData\Local\Microsoft\Edge") {
                if ($ForceCloseBrowsers -and $ChromeProcesses) {
                    Write-Host -Object "Closing Microsoft Edge processes for $($_.Username) as requested."
                    
                    $User = $_.Username
                    $RelevantAccount = Get-LoggedInUsers | Where-Object { $User -match $_.USERNAME }
                    $RelevantProcess = $EdgeProcesses | Where-Object { $RelevantAccount.ID -contains $_.SI }

                    try {
                        $RelevantProcess | ForEach-Object { $_ | Stop-Process -Force -ErrorAction Stop }
                    }
                    catch {
                        Write-Host -Object "[Error] Failed to close one of Microsoft Edge's processes."
                        Write-Host -Object "[Error] $($_.Exception.Message)"
                        $ExitCode = 1
                    }
                }

                Write-Host -Object "Clearing Microsoft Edge's browser cache for $($_.Username)."

                try{
                    Get-ChildItem -Path "$($_.Path)\AppData\Local\Microsoft\Edge\User Data\*\Cache" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $False } | Remove-Item -ErrorAction Stop
                    Get-ChildItem -Path "$($_.Path)\AppData\Local\Microsoft\Edge\User Data\*\Code Cache" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $False } | Remove-Item -ErrorAction Stop
                    Get-ChildItem -Path "$($_.Path)\AppData\Local\Microsoft\Edge\User Data\*\GPUCache" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.PSIsContainer -eq $False } | Remove-Item -ErrorAction Stop
                }catch{
                    Write-Host -Object "[Error] Unable to clear Microsoft Edge's cache."
                    Write-Host -Object "[Error] $($_.Exception.Message)"
                    $ExitCode = 1
                }
            }
            else {
                Write-Host -Object "[Error] Microsoft Edge's local appdata folder is not at '$($_.Path)\AppData\Local\Microsoft\Edge'. Unable to clear cache."
                $ExitCode = 1
            }
        }

        Write-Host ""
    }

    # Iterate over each loaded profile
    Foreach ($LoadedProfile in $LoadedProfiles) {
        [gc]::Collect()
        Start-Sleep -Seconds 1
        Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe UNLOAD HKU\$($LoadedProfile)" -Wait -WindowStyle Hidden | Out-Null
    }

    exit $ExitCode
}
end {
    
    
    
}