
<#
.SYNOPSIS
    This script will create an rdp desktop shortcut with your specified options. It can create a shortcut for all users (including new ones) or existing ones only.
.DESCRIPTION
    This script will create an rdp desktop shortcut with your specified options. 
    It can create a shortcut for all users (including new ones) or existing ones only.
.EXAMPLE
    To Create a windowed RDP Shortcut simply specify the size, the name of the shortcut and which users the shortcut is for. You can also specify "MultiMon" for multi-monitor support. Or a gateway to use.
    
    PS C:\> ./Create-DesktopShortcut.ps1 -Name "Test" -RDPTarget "SRV19-TEST" -RDPUser "TEST\jsmith" -Width "1920" -Height "1080" -AllExistingUsers -ExcludeUsers "ChrisWashington,JohnLocke"
    
    Creating Shortcut at C:\Users\JohnSmith\Desktop\Test.rdp

.PARAMETER NAME
    Name of the shortcut ex. "Login Portal".

.PARAMETER RDPtarget
    IP Address or DNS Name and port to the RDS Host ex. "TEST-RDSH:28665".

.PARAMETER RDPuser
    Username to autofill in username field.

.PARAMETER AlwaysPrompt 
    Always Prompt for credentials.

.PARAMETER Gateway
    IP Address or DNS Name and port of the RD Gateway ex. "TESTrdp.example.com:4433".

.PARAMETER SeperateGateWayCreds
    If the RDS Gateway uses different creds than the Session Host use this parameter.

.PARAMETER FullScreen
    RDP Shortcut should open window in 'FullScreen' mode.

.PARAMETER MultiMon
    RDP Shortcut should open window with Multi-Monitor Support enabled.

.PARAMETER Width
    Width of RDP Window should open ex. "1920".

.PARAMETER Height
    Height of RDP Window shortcut should open ex. "1080".

.PARAMETER AllExistingUsers
    Create the Shortcut for all existing users but not new users ex. C:\Users\*\Desktop\shortcut.lnk.

.PARAMETER ExcludeUsers
    Comma seperated list of users to exclude from shortcut placement.

.PARAMETER AllUsers
    Create the Shortcut in C:\Users\Public\Desktop.

.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 7, Windows Server 2008
    Release Notes: Renamed script, Split script into three, added Script Variable support, fixed bugs in RDP Shortcut
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Name,
    [Parameter()]
    [String]$RDPtarget,
    [Parameter()]
    [String]$RDPuser,
    [Parameter()]
    [Switch]$AlwaysPrompt = [System.Convert]::ToBoolean($env:alwaysPromptForRdpCredentials),
    [Parameter()]
    [String]$Gateway,
    [Parameter()]
    [Switch]$SeparateGateWayCreds = [System.Convert]::ToBoolean($env:separateRdpGatewayCredentials),
    [Parameter()]
    [Switch]$FullScreen,
    [Parameter()]
    [Switch]$MultiMon,
    [Parameter()]
    [Int]$Width,
    [Parameter()]
    [Int]$Height,
    [Parameter()]
    [Switch]$AllExistingUsers,
    [Parameter()]
    [Switch]$AllUsers
)

begin {

    # Replace existing params with form variables if they're used.
    if ($env:shortcutName -and $env:shortcutName -notlike "null") { $Name = $env:shortcutName }
    if ($env:createTheShortcutFor -and $env:createTheShortcutFor -notlike "null") { 
        if ($env:createTheShortcutFor -eq "All Users") { $AllUsers = $True }
        if ($env:createTheShortcutFor -eq "All Existing Users") { $AllExistingUsers = $True }
    }
    if ($env:rdpServerAddress -and $env:rdpServerAddress -notlike "null") { $RDPtarget = $env:rdpServerAddress }
    if ($env:rdpUsername -and $env:rdpUsername -notlike "null") { $RDPuser = $env:rdpUsername }
    if ($env:rdpGatewayServerAddress -and $env:rdpGatewayServerAddress -notlike "null") { $Gateway = $env:rdpGatewayServerAddress }
    if ($env:rdpWindowSize -and $env:rdpWindowSize -notlike "null") {
        if ($env:rdpWindowSize -eq "Fullscreen Multiple Monitor Mode") { $MultiMon = $True }
        if ($env:rdpWindowSize -eq "Fullscreen") { $FullScreen = $True }
    }
    if ($env:customRdpWindowWidth -and $env:customRdpWindowWidth -notlike "null") { $Width = $env:customRdpWindowWidth }
    if ($env:customRdpWindowHeight -and $env:customRdpWindowHeight -notlike "null") { $Height = $env:customRdpWindowHeight }

    # Output warnings for conflicting options.
    if (($Width -and -not $Height ) -or ($Height -and -not $Width)) {
        Write-Warning "You forgot to include both the width and height. RDP Window will be in fullscreen mode."
    }

    if (($Width -or $Height) -and ($FullScreen -or $MultiMon)) {
        if ($MultiMon) {
            Write-Warning "Conflicting Display Option selected. Using Fullscreen Multi-monitor."
        }
        else {
            Write-Warning "Conflicting Display Option selected. Using Fullscreen."
        }
    }

    # Double-check that a user is specified for shortcut creation.
    if (-not $AllUsers -and -not $AllExistingUsers -and -not $User) {
        Write-Error "You must specify which desktop to create the shortcut on!"
        exit 1
    }

    # Double-check that a shortcut name was provided.
    if (-not $Name -or -not $RDPtarget) {
        Write-Error "You must specify a name and target for the shortcut!"
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

    # Retrieve all registry paths for actual users (excluding system or network service accounts).
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

        # User account SIDs follow a particular pattern depending on whether they're Azure AD, Domain, or local "workgroup" accounts.
        $Patterns = switch ($Type) {
            "AzureAD" { "S-1-12-1-(\d+-?){4}$" }
            "DomainAndLocal" { "S-1-5-21-(\d+-?){4}$" }
            "All" { "S-1-12-1-(\d+-?){4}$" ; "S-1-5-21-(\d+-?){4}$" } 
        }

        # We'll need the NTuser.dat file to load each users registry hive. So we grab it if their account sid matches the above pattern. 
        $UserProfiles = Foreach ($Pattern in $Patterns) { 
            Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
                Where-Object { $_.PSChildName -match $Pattern } | 
                Select-Object @{Name = "SID"; Expression = { $_.PSChildName } }, 
                @{Name = "UserHive"; Expression = { "$($_.ProfileImagePath)\NTuser.dat" } }, 
                @{Name = "UserName"; Expression = { "$($_.ProfileImagePath | Split-Path -Leaf)" } },
                @{Name = "Path"; Expression = { $_.ProfileImagePath } }
        }

        # In some cases, it's necessary to retrieve the .Default user's information.
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
}
process {
    $ShortcutPath = New-Object System.Collections.Generic.List[String]

    # Create the filenames for the path.
    if ($RDPTarget) { $File = "$Name.rdp" }

    # Build the paths and add them to the ShortcutPath list.
    if ($AllUsers) { $ShortcutPath.Add("$env:Public\Desktop\$File") }

    if ($AllExistingUsers) {
        $UserProfiles = Get-UserHives
        # Loop through each user profile
        $UserProfiles | ForEach-Object { $ShortcutPath.Add("$($_.Path)\Desktop\$File") }
    }

    if ($User) { 
        $UserProfile = Get-UserHives | Where-Object { $_.Username -like $User }
        $ShortcutPath.Add("$($UserProfile.Path)\Desktop\$File")
    }

    $RDPFile = New-Object System.Collections.Generic.List[String]

    # Base template of an .RDP file. Additional options will be appended based on user selection.
    $Template = @"
session bpp:i:32
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
audiomode:i:0
redirectprinters:i:1
redirectcomports:i:0
redirectsmartcards:i:1
redirectwebauthn:i:1
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:2
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:
shell working directory:s:
gatewaycredentialssource:i:4
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
enablerdsaadauth:i:0
"@
    $RDPFile.Add($Template)

    # This will generate the actual .rdp file
    $ShortcutPath | ForEach-Object {
        $RDPFile.Add("full address:s:$RDPTarget")
        $RDPFile.Add("gatewayhostname:s:$Gateway")

        if ($Width) { $RDPFile.Add("desktopwidth:i:$Width") }
        if ($Height) { $RDPFile.Add("desktopheight:i:$Height") }
        if ($MultiMon) { $RDPFile.Add("use multimon:i:1") }else { $RDPFile.Add("use multimon:i:0") }
        if ($FullScreen -or $MultiMon -or !$Height -or !$Width) { $RDPFile.Add("screen mode id:i:2") }else { $RDPFile.Add("screen mode id:i:1") }
        if ($AlwaysPrompt) { $RDPFile.Add("prompt for credentials:i:1") }else { $RDPFile.Add("prompt for credentials:i:0") }
        if ($Gateway) { $RDPFile.Add("gatewayusagemethod:i:2") }else { $RDPFile.Add("gatewayusagemethod:i:4") }
        if ($SeparateGateWayCreds) { 
            $RDPFile.Add("promptcredentialonce:i:0")
            $RDPFile.Add("gatewayprofileusagemethod:i:1")  
        }
        else { 
            $RDPFile.Add("promptcredentialonce:i:1") 
            if ($Gateway) { $RDPFile.Add("gatewayprofileusagemethod:i:0") }
        }
            
        if ($RDPUser) { $RDPFile.Add("username:s:$RDPUser") }

        Write-Host "Creating Shortcut at $_"
        $RDPFile | Out-File $_

        if (!(Test-Path $_ -ErrorAction SilentlyContinue)) {
            Write-Error "Unable to create Shortcut at $_"
            exit 1
        }
    }

    exit 0
}end {
    
    
    
}