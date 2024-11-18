#Requires -Version 5.1

<#
.SYNOPSIS
    This will disable the selected administrator tools depending on your selection (Defaults to all). Can be given a comma separated list of users to exclude from this action.
.DESCRIPTION
    This will disable the selected administrator tools. The options are "All", the command prompt, the control panel, the microsoft management console,
    the registry editor, the run command window and task manager. You can give it a comma separated list of items if you want to disable some but not all.
    Exit 1 is usually an indicator of bad input but can also mean editing the registry is blocked.
.EXAMPLE
    PS C:\> .\Disable-LocalAdminTools.ps1 -Tools "MMC,Cmd,TaskMgr,RegistryEditor"
    Disabling MMC...
    Set Registry::HKEY_USERS\DefaultProfile\Software\Policies\Microsoft\MMCRestrictToPermittedSnapins to...
    Disabling Cmd...
    Set Registry::HKEY_USERS\DefaultProfile\Software\Policies\Microsoft\WindowsDisableCMD to...
    Disabling TaskMgr...
    Set Registry::HKEY_USERS\DefaultProfile\Software\Microsoft\Windows\CurrentVersion\Policies\SystemDisableTaskMgr to...
    Disabling RegistryEditor...
    Set Registry::HKEY_USERS\DefaultProfile\Software\Microsoft\Windows\CurrentVersion\Policies\SystemDisableRegistryTools to...
.OUTPUTS
    None
.NOTES
    Minimum Supported OS: Windows 10, Windows Server 2016+
    Release Notes: Renamed script and added Script Variable support
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$Tools = "All",
    [Parameter()]
    [String]$ExcludedUsers
)

begin {
    
    if ($env:excludeUsers -and $env:excludeUsers -notlike "null") { $ExcludedUsers = $env:excludeUsers }
    
    # Lets double check that this script is being run appropriately
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Test-IsSystem {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
    }

    if (!(Test-IsElevated) -and !(Test-IsSystem)) {
        Write-Error -Message "[Error] Access Denied. Please run with Administrator privileges."
        exit 1
    }

    # Setting up some functions to be used later.
    function Set-HKProperty {
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet('DWord', 'QWord', 'String', 'ExpandedString', 'Binary', 'MultiString', 'Unknown')]
            $PropertyType = 'DWord'
        )
        if (-not $(Test-Path -Path $Path)) {
            # Check if path does not exist and create the path
            New-Item -Path $Path -Force | Out-Null
        }
        if ((Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore)) {
            # Update property and print out what it was changed from and changed to
            $CurrentValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore
            try {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Error "[Error] Unable to Set registry key for $Name please see below error!"
                Write-Error $_
                exit 1
            }
            Write-Host "$Path\$Name changed from $CurrentValue to $(Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore)"
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
            Write-Host "Set $Path$Name to $(Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore)"
        }
    }

    # This will get all the registry path's for all actual users (not system or network service account but actual users.)
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

        # User account SID's follow a particular patter depending on if they're azure AD or a Domain account or a local "workgroup" account.
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
                @{Name = "UserName"; Expression = { "$($_.ProfileImagePath | Split-Path -Leaf)" } }
        }

        # There are some situations where grabbing the .Default user's info is needed.
        switch ($IncludeDefault) {
            $True {
                $DefaultProfile = "" | Select-Object UserName, SID, UserHive
                $DefaultProfile.UserName = "Default"
                $DefaultProfile.SID = "DefaultProfile"
                $DefaultProfile.Userhive = "$env:SystemDrive\Users\Default\NTUSER.DAT"

                # It was easier to write-output twice than combine the two objects.
                $DefaultProfile | Where-Object { $ExcludedUsers -notcontains $_.UserName } | Write-Output
            }
        }

        $UserProfiles | Where-Object { $ExcludedUsers -notcontains $_.UserName } | Write-Output
    }

    function Set-Tool {
        [CmdletBinding()]
        param(
            [Parameter()]
            [ValidateSet("All", "Cmd", "ControlPanel", "theControlPanel", "MMC", "RegistryEditor", "theRegistryEditor", "Run", "TaskMgr", "taskManager")]
            [string]$Tool,
            [string]$key
        )
        process {
            # Each option has a different registry key to change. Since this function only supports 1 item at a time I can check which option and set the regkey individually.
            Write-Host "Disabling $Tool..."
            switch ($Tool) {
                "Cmd" { Set-HKProperty -Path $key\Software\Policies\Microsoft\Windows\System -Name DisableCMD -Value 1 }
                "ControlPanel" { Set-HKProperty -Path $key\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name NoControlPanel -Value 1 }
                "theControlPanel" { Set-HKProperty -Path $key\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name NoControlPanel -Value 1 }
                "MMC" { Set-HKProperty -Path $key\Software\Policies\Microsoft\MMC -Name RestrictToPermittedSnapins -Value 1 }
                "RegistryEditor" { Set-HKProperty -Path $key\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name DisableRegistryTools -Value 1 }
                "theRegistryEditor" { Set-HKProperty -Path $key\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name DisableRegistryTools -Value 1 }
                "Run" { Set-HKProperty -Path $key\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name NoRun -Value 1 }
                "TaskMgr" { Set-HKProperty -Path $key\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name DisableTaskMgr -Value 1 }
                "taskManager" { Set-HKProperty -Path $key\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name DisableTaskMgr -Value 1 }
                "All" {
                    Set-HKProperty -Path $key\Software\Policies\Microsoft\Windows\System -Name DisableCMD -Value 1
                    Set-HKProperty -Path $key\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name NoControlPanel -Value 1
                    Set-HKProperty -Path $key\Software\Policies\Microsoft\MMC -Name RestrictToPermittedSnapins -Value 1
                    Set-HKProperty -Path $key\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name DisableRegistryTools -Value 1
                    Set-HKProperty -Path $key\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer -Name NoRun -Value 1
                    Set-HKProperty -Path $key\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name DisableTaskMgr -Value 1
                }
            }
        }
    }
}
process {

    # Get each user profile SID and Path to the profile. If there are any exclusions we'll have to take them into account.
    if ($ExcludedUsers) {
        $ToBeExcluded = New-Object System.Collections.Generic.List[string]
        $ExcludedUsers.split(",").trim() | ForEach-Object { if ($_) { $ToBeExcluded.Add($_) } }
        Write-Warning "The Following Users will not have your selected tools disabled. $ToBeExcluded"
        $UserProfiles = Get-UserHives -IncludeDefault -ExcludedUsers $ToBeExcluded
    }
    else {
        $UserProfiles = Get-UserHives -IncludeDefault
    }

    # Loop through each profile on the machine
    Foreach ($UserProfile in $UserProfiles) {
        # Load each user's registry hive if not already loaded. Backticked "UserProfile.UserHive" so that it accounts for spaces in the username.
        If (($ProfileWasLoaded = Test-Path Registry::HKEY_USERS\$($UserProfile.SID)) -eq $false) {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe LOAD HKU\$($UserProfile.SID) `"$($UserProfile.UserHive)`"" -Wait -WindowStyle Hidden
        }
        # The path is different for each individual user. This is the base path.
        $key = "Registry::HKEY_USERS\$($UserProfile.SID)"

        # List of checkbox items
        $CheckboxItems = "cmd", "theControlPanel", "mmc", "theRegistryEditor", "run", "taskManager"
        # Checkboxes come in as environmental variables. This'll grab the ones that were selected (if any)
        $EnvItems = Get-ChildItem env:* | Where-Object { $CheckboxItems -contains $_.Name -and $_.Value -notlike "false" }

        # This will grab the tool selections from the parameter field. Since it comes in as a string we'll have to split it up.
        $Tool = $Tools.split(",").trim()

        # If the checkbox for all was selected I can just run the function once instead of running it repeatedly for the same thing.
        if ($env:allTools -and $env:allTools -notlike "false") {
            Set-Tool -Tool "All" -Key $key
        }
        elseif ($EnvItems) {
            # If checkboxes were used we should just use those.
            $EnvItems | ForEach-Object { Set-Tool -Tool $_.Name -Key $key }
        }
        else {
            $Tool | ForEach-Object { Set-Tool -Tool $_ -Key $key }
        }

        # Unload NTuser.dat for user's we loaded previously.
        If ($ProfileWasLoaded -eq $false) {
            [gc]::Collect()
            Start-Sleep -Seconds 1
            Start-Process -FilePath "cmd.exe" -ArgumentList "/C reg.exe UNLOAD HKU\$($UserProfile.SID)" -Wait -WindowStyle Hidden | Out-Null
        }
    }
    
}
end {
    
    
    
}   
