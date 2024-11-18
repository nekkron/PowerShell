
<#
.SYNOPSIS
    This script creates a URL desktop shortcut with your specified options. It can create a shortcut for all users (including new ones) or for existing ones only.
.DESCRIPTION
    This script creates a URL desktop shortcut with your specified options. 
    It can create a shortcut for all users (including new ones) or for existing ones only.
.EXAMPLE
    To create a URL shortcut that opens in the default browser:
    
    -Name "Test" -URL "https://www.google.com" -AllUsers

    Creating Shortcut at C:\Users\JohnSmith\Desktop\Test.url

.PARAMETER NAME
    The name of the shortcut, e.g., "Login Portal".

.PARAMETER URL
    The website URL to open, e.g., "https://www.google.com".

.PARAMETER AllExistingUsers
    Creates the shortcut for all existing users but not for new users, e.g., C:\Users\*\Desktop\shortcut.url.

.PARAMETER AllUsers
    Creates the shortcut in C:\Users\Public\Desktop.

.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 7, Windows Server 2008
    Release Notes: Split the script into three separate scripts and added Script Variable support.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Name,
    [Parameter()]
    [String]$Url,
    [Parameter()]
    [Switch]$AllExistingUsers,
    [Parameter()]
    [Switch]$AllUsers
)
begin {
    # If Form Variables are used, replace the existing params with them.
    if ($env:shortcutName -and $env:shortcutName -notlike "null") { $Name = $env:shortcutName }
    if ($env:createTheShortcutFor -and $env:createTheShortcutFor -notlike "null") { 
        if ($env:createTheShortcutFor -eq "All Users") { $AllUsers = $True }
        if ($env:createTheShortcutFor -eq "All Existing Users") { $AllExistingUsers = $True }
    }
    if ($env:linkForUrlShortcut -and $env:linkForUrlShortcut -notlike "null") { $Url = $env:linkForUrlShortcut }

    # Double-check that a user was specified for shortcut creation.
    if (!$AllUsers -and !$AllExistingUsers) {
        Write-Error "You must specify which desktop to create the shortcut on!"
        exit 1
    }

    # Double-check that a shortcut name was given.
    if (-not $Name) {
        Write-Error "You must specify a name for the shortcut!"
        exit 1
    }

    # Creating a shortcut at C:\Users\Public\Desktop requires admin rights.
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (!(Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    # This will get all the registry paths for all actual users (not system or network service accounts, but actual users).
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

        # User account SIDs follow a particular pattern depending on whether they're Azure AD, a Domain account, or a local "workgroup" account.
        $Patterns = switch ($Type) {
            "AzureAD" { "S-1-12-1-(\d+-?){4}$" }
            "DomainAndLocal" { "S-1-5-21-(\d+-?){4}$" }
            "All" { "S-1-12-1-(\d+-?){4}$" ; "S-1-5-21-(\d+-?){4}$" } 
        }

        # We'll need the NTuser.dat file to load each user's registry hive. So, we grab it if their account SID matches the above pattern.
        $UserProfiles = Foreach ($Pattern in $Patterns) { 
            Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
                Where-Object { $_.PSChildName -match $Pattern } | 
                Select-Object @{Name = "SID"; Expression = { $_.PSChildName } }, 
                @{Name = "UserHive"; Expression = { "$($_.ProfileImagePath)\NTuser.dat" } }, 
                @{Name = "UserName"; Expression = { "$($_.ProfileImagePath | Split-Path -Leaf)" } },
                @{Name = "Path"; Expression = { $_.ProfileImagePath } }
        }

        # There are some situations where grabbing the .Default user's info is needed.
        switch ($IncludeDefault) {
            $True {
                $DefaultProfile = "" | Select-Object UserName, SID, UserHive, Path
                $DefaultProfile.UserName = "Default"
                $DefaultProfile.SID = "DefaultProfile"
                $DefaultProfile.Userhive = "$env:SystemDrive\Users\Default\NTUSER.DAT"
                $DefaultProfile.Path = "C:\Users\Default"

                $DefaultProfile | Where-Object { $ExcludedUsers -notcontains $_.UserName }
            }
        }

        $UserProfiles | Where-Object { $ExcludedUsers -notcontains $_.UserName }
    }

    # The actual shortcut creation
    function New-Shortcut {
        [CmdletBinding()]
        param(
            [Parameter()]
            [String]$Arguments,
            [Parameter()]
            [String]$IconPath,
            [Parameter(ValueFromPipeline = $True)]
            [String]$Path,
            [Parameter()]
            [String]$Target,
            [Parameter()]
            [String]$WorkingDir
        )
        process {
            Write-Host "Creating Shortcut at $Path"
            $ShellObject = New-Object -ComObject ("WScript.Shell")
            $Shortcut = $ShellObject.CreateShortcut($Path)
            $Shortcut.TargetPath = $Target
            if ($WorkingDir) { $Shortcut.WorkingDirectory = $WorkingDir }
            if ($Arguments) { $ShortCut.Arguments = $Arguments }
            if ($IconPath) { $Shortcut.IconLocation = $IconPath }
            $Shortcut.Save()

            if (!(Test-Path $Path -ErrorAction SilentlyContinue)) {
                Write-Error "Unable to create Shortcut at $Path"
                exit 1
            }
        }
    }
}
process {
    $ShortcutPath = New-Object System.Collections.Generic.List[String]

    # Creating the filenames for the path
    if ($Url) { 
        $File = "$Name.url"
        $Target = $Url 
    }

    # Building the path's and adding it to the ShortcutPath list
    if ($AllUsers) { $ShortcutPath.Add("$env:Public\Desktop\$File") }

    if ($AllExistingUsers) {
        $UserProfiles = Get-UserHives
        # Loop through each user profile
        $UserProfiles | ForEach-Object { $ShortcutPath.Add("$($_.Path)\Desktop\$File") }
    }

    $ShortcutPath | ForEach-Object { New-Shortcut -Target $Target -Path $_ }

    exit 0
}end {
    
    
    
}