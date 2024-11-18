<#
.SYNOPSIS
    Set Power and Sleep Settings. It can adjust just the plugged in or battery settings if requested.
    Please Note not all devices support all options.
.DESCRIPTION
    Please Note not all devices support all options.
    Options: ScreenTimeout, HibernateTimeout, SleepTimeout, Disk Timeout, PowerPlan, Lid Action, Wake Timers, USB Suspend, Critical Action
    Low Action, Power Button Action, Critical Level, Low Level, Reserve Level, Critical Notification, and Low Notification.
.EXAMPLE
    (No Parameters)
    
    By default The Script doesn't do anything without some parameters.
.LINK 
    https://learn.microsoft.com/en-us/windows/win32/power/power-policy-settings

PARAMETER: -ScreenTimeout "60"
    Replace 60 with any time in seconds to set the screen timeout. (0 for disabled)

PARAMETER: -HibernateTimeout "28800"
    Replace 28800 with any time in seconds. (0 for disabled)

PARAMETER: -SleepTimeout "14400"
    Replace 14400 with any time in seconds. (0 for disabled)

PARAMETER: -DiskTimeout "0"
    Replace 0 with your desired time in seconds. (0 for disabled)

PARAMETER: -PowerPlan "High Performance"
    Replace "High Performance" with your desired power plan. Keep in mind that most newer computers no longer have seperate power plans.

PARAMETER: -LidAction "Nothing"
    Replace Nothing with one of these three available options. Sleep, Shutdown, Nothing.
    Will be skipped for non-laptops and this script cannot verify if the action was successfully set.

PARAMETER: -AllowWakeTimers
    Allows the ability for software to wake the computer from sleep at a later date.

PARAMETER: -DisableWakeTimers
    Disables the ability for software to wake the computer from sleep at a later date.

PARAMETER: -EnableUSBSuspend
    Allows the OS to suspend USB devices to conserve power.

PARAMETER: -DisableUSBSuspend
    Disable's the OS's ability to suspend USB devices to conserve power.

PARAMETER: -CriticalAction "Hibernate"
    Replace Hibernate with your desired action for when the machine is at a "Critical" batter level.
    Valid Options: Hibernate, Sleep, Shutdown, Nothing

PARAMETER: -LowAction "Hibernate"
    Replace Hibernate with your desired action for when the machine is at a "Low" battery level.
    Valid Options: Hibernate, Sleep, Shutdown, Nothing.

PARAMETER: -CriticalLevel "7"
    Replace 7 with your desired battery percent level to be considered critical (without the % symbol).

PARAMETER: -LowLevel "10"
    Replace 10 with your desired battery percent level to be considered low (without the % symbol).

PARAMETER: -LowNotify
    Allows the notification that comes in when the battery hits "low" levels.

PARAMETER: -AC
    Only applies your chosen battery settings to the "Plugged In" section of a power plan.

PARAMETER: -DC
    Only applies your chosen battery settings to the "Battery" section of a power plan.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 7, Windows Server 2008
    General notes
    Version: Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$ScreenTimeout,
    [Parameter()]
    [String]$HibernateTimeout,
    [Parameter()]
    [String]$SleepTimeout,
    [Parameter()]
    [String]$DiskTimeout,
    [Parameter()]
    [String]$PowerPlan,
    [Parameter()]
    [String]$LidAction,
    [Parameter()]
    [Switch]$AllowWakeTimers,
    [Parameter()]
    [Switch]$DisableWakeTimers,
    [Parameter()]
    [Switch]$EnableUSBSuspend,
    [Parameter()]
    [Switch]$DisableUSBSuspend,
    [Parameter()]
    [String]$CriticalAction,
    [Parameter()]
    [String]$LowAction,
    [Parameter()]
    [String]$CriticalLevel,
    [Parameter()]
    [String]$LowLevel,
    [Parameter()]
    [Switch]$LowNotify,
    [Parameter()]
    [Switch]$LowNoNotify,
    [Parameter()]
    [Switch]$AC,
    [Parameter()]
    [Switch]$DC
)

begin {
    # Grab Script Variables if present
    if ($env:powerSourceSetting -and $env:powerSourceSetting -notlike "null") {
        switch ($env:powerSourceSetting) {
            "Plugged In" { $AC = $True }
            "On Battery" { $DC = $True }
            default {}
        }
    }
    if ($env:screenTimeoutInMinutes -and $env:screenTimeoutInMinutes -notlike "null") { $ScreenTimeout = $env:screenTimeoutInMinutes }
    if ($env:hibernateTimeoutInMinutes -and $env:hibernateTimeoutInMinutes -notlike "null") { $HibernateTimeout = $env:hibernateTimeoutInMinutes }
    if ($env:sleepTimeoutInMinutes -and $env:sleepTimeoutInMinutes -notlike "null") { $SleepTimeout = $env:sleepTimeoutInMinutes }
    if ($env:diskTimeoutInMinutes -and $env:diskTimeoutInMinutes -notlike "null") { $DiskTimeout = $env:diskTimeoutInMinutes }
    if ($env:powerPlan -and $env:powerPlan -notlike "null") { $PowerPlan = $env:powerPlan }
    if ($env:lidAction -and $env:lidAction -notlike "null") { $LidAction = $env:lidAction }
    if ($env:wakeTimers -and $env:wakeTimers -notlike "null") {
        switch ($env:wakeTimers) {
            "Enable" { $AllowWakeTimers = $True }
            "Disable" { $DisableWakeTimers = $True }
        }
    }
    if ($env:usbSuspend -and $env:usbSuspend -notlike "null") {
        switch ($env:usbSuspend) {
            "Enable" { $EnableUSBSuspend = $True }
            "Disable" { $DisableUSBSuspend = $True }
        }
    }
    if ($env:criticalBatteryAction -and $env:criticalBatteryAction -notlike "null") { $CriticalAction = $env:criticalBatteryAction }
    if ($env:lowBatteryAction -and $env:lowBatteryAction -notlike "null") { $LowAction = $env:lowBatteryAction }
    if ($env:criticalBatteryLevel -and $env:criticalBatteryLevel -notlike "null") { $CriticalLevel = $env:criticalBatteryLevel }
    if ($env:lowBatteryLevel -and $env:lowBatteryLevel -notlike "null") { $LowLevel = $env:lowBatteryLevel }
    if ($env:lowNotification -and $env:lowNotification -notlike "null") {
        switch ($env:lowNotification) {
            "Enable" { $LowNotify = $True }
            "Disable" { $LowNoNotify = $True }
        }
    }

    if ($ScreenTimeout) { [int]$ScreenTimeoutValue = [int]$ScreenTimeout * 60 }
    if ($HibernateTimeout) { [int]$HibernateTimeoutValue = [int]$HibernateTimeout * 60 }
    if ($SleepTimeout) { [int]$SleepTimeoutValue = [int]$SleepTimeout * 60 }
    if ($DiskTimeout) { [int]$DiskTimeoutValue = [int]$DiskTimeout * 60 }
    if ($CriticalLevel) { [int]$CriticalLevelValue = [int]$CriticalLevel }
    if ($LowLevel) { [int]$LowLevelValue = [int]$LowLevel }

    # Elevation Test
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (
        -not $ScreenTimeout -and -not $HibernateTimeout -and -not $SleepTimeout -and -not $DiskTimeout -and -not $PowerPlan -and
        -not $LidAction -and -not $AllowWakeTimers -and -not $DisableWakeTimers -and -not $EnableUSBSuspend -and
        -not $DisableUSBSuspend -and -not $CriticalAction -and -not $LowAction -and -not $CriticalLevel -and
        -not $LowLevel -and -not $LowNotify -and -not $LowNoNotify
    ) {
        Write-Error -Message '[Error] No action given!'
        exit 1
    }
    
    # Check for battery and whether or not the device is a laptop
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $BatteryCheck = @(Get-WmiObject -Class Win32_Battery).Count -gt 0
        $LaptopCheck = Get-WmiObject -Class win32_systemenclosure | Where-Object { $_.chassistypes -eq 9 -or $_.chassistypes -eq 10 -or $_.chassistypes -eq 14 }
    }
    else {
        $BatteryCheck = @(Get-CimInstance -Class Win32_Battery).Count -gt 0
        $LaptopCheck = Get-CimInstance -Class win32_systemenclosure | Where-Object { $_.chassistypes -eq 9 -or $_.chassistypes -eq 10 -or $_.chassistypes -eq 14 }
    }
    
    # Function to test if policy was set correctly
    function Test-PowerValue {
        [CmdletBinding()]
        param(
            [Parameter()]
            [String]$GUID,
            [Parameter()]
            [String]$Index,
            [Parameter()]
            [int]$Value,
            [Parameter()]
            [String]$Setting
        )

        # LidAction shows no information so we'll issue a warning and then exit the test function.
        if ($GUID -eq "SUB_BUTTONS" -and $Index -eq "5ca83367-6e45-459f-a27b-476b1d01c936") {
            Write-Warning "Unable to verify LidAction via script."
            break
        }

        # Values are stored in hex so we'll need to convert it.
        $Hex = "0x" + '{0:X8}' -f $Value

        $PowerQuery = powercfg.exe /QUERY SCHEME_CURRENT $GUID | Out-String
        $RelevantSetting = $PowerQuery -split "Power Setting GUID:" | Where-Object { $_ -like "*$Index*" }
        if (-not ($RelevantSetting)) {
            Write-Warning "Unable to verify setting for $GUID $Index. This option may not exist for this machine."
            break
        }

        # Depending on how the script was ran we'll need to verify in different ways (ex. its on a laptop or only AC was specified)
        if ($AC -or -not $BatteryCheck) {
            $ACQuery = $RelevantSetting -split '\s{2}' | Where-Object { $_ -eq "Current AC Power Setting Index: $Hex" }

            # Actual check code is really similar though (only difference is AC vs DC).
            if (-not $ACQuery) {
                Write-Warning "AC Value of $Hex Not Found for $GUID $Index. You may want to verify the results."
                break
            }
        }
        elseif ($DC) {
            $BatteryQuery = $RelevantSetting -split '\s{2}' | Where-Object { $_ -eq "Current DC Power Setting Index: $Hex" }

            if (-not $BatteryQuery) {
                Write-Warning "DC Value of $Hex Not Found for $GUID $Index. You may want to verify the results."
                break
            }
        }
        else {
            $BatteryQuery = $RelevantSetting -split '\s{2}' | Where-Object { $_ -eq "Current DC Power Setting Index: $Hex" }
            if (-not $BatteryQuery) {
                Write-Warning "DC Value of $Hex Not Found for $GUID $Index. You may want to verify the results."
                break
            }

            $ACQuery = $RelevantSetting -split '\s{2}' | Where-Object { $_ -eq "Current AC Power Setting Index: $Hex" }
            if (-not $ACQuery) {
                Write-Warning "AC Value of $Hex Not Found for $GUID $Index. You may want to verify the results."
                break
            }
        }

        Write-Host "Successfully set power setting for $Setting!"
    }
    function Set-PowerAction {
        [CmdletBinding()]
        param(
            [Parameter()]
            [ValidateSet("Nothing", "Sleep", "Hibernate", "ShutDown")]
            [String]$Action,
            [Parameter()]
            [String]$GUID,
            [Parameter()]
            [String]$Index,
            [Parameter()]
            [String]$Setting
        )
        try {
            switch ($Action) {
                "Nothing" {
                    if ($AC -or -not $BatteryCheck) {
                        powercfg.exe /SETACVALUEINDEX SCHEME_CURRENT $GUID $Index 0
                    }
                    elseif ($DC) {
                        powercfg.exe /SETDCVALUEINDEX SCHEME_CURRENT $GUID $Index 0
                    }
                    else {
                        powercfg.exe /SETACVALUEINDEX SCHEME_CURRENT $GUID $Index 0
                        powercfg.exe /SETDCVALUEINDEX SCHEME_CURRENT $GUID $Index 0
                    }
    
                    Test-PowerValue $GUID $Index 0 -Setting $Setting
                }
                "Sleep" {
                    if ($AC -or -not $BatteryCheck) {
                        powercfg.exe /SETACVALUEINDEX SCHEME_CURRENT $GUID $Index 1
                    }
                    elseif ($DC) {
                        powercfg.exe /SETDCVALUEINDEX SCHEME_CURRENT $GUID $Index 1
                    }
                    else {
                        powercfg.exe /SETACVALUEINDEX SCHEME_CURRENT $GUID $Index 1
                        powercfg.exe /SETDCVALUEINDEX SCHEME_CURRENT $GUID $Index 1
                    }
    
                    Test-PowerValue $GUID $Index 1 -Setting $Setting
                }
                "Hibernate" {
                    if ($AC -or -not $BatteryCheck) {
                        powercfg.exe /SETACVALUEINDEX SCHEME_CURRENT $GUID $Index 2
                    }
                    elseif ($DC) {
                        powercfg.exe /SETDCVALUEINDEX SCHEME_CURRENT $GUID $Index 2
                    }
                    else {
                        powercfg.exe /SETACVALUEINDEX SCHEME_CURRENT $GUID $Index 2
                        powercfg.exe /SETDCVALUEINDEX SCHEME_CURRENT $GUID $Index 2
                    }
    
                    Test-PowerValue $GUID $Index 2 -Setting $Setting
                }
                "Shutdown" {
                    if ($AC -or -not $BatteryCheck) {
                        powercfg.exe /SETACVALUEINDEX SCHEME_CURRENT $GUID $Index 3
                    }
                    elseif ($DC) {
                        powercfg.exe /SETDCVALUEINDEX SCHEME_CURRENT $GUID $Index 3
                    }
                    else {
                        powercfg.exe /SETACVALUEINDEX SCHEME_CURRENT $GUID $Index 3
                        powercfg.exe /SETDCVALUEINDEX SCHEME_CURRENT $GUID $Index 3
                    }
    
                    Test-PowerValue $GUID $Index 3 -Setting $Setting
                }
                default {
                    throw "$Action is not a valid action for $Setting, valid actions are Shutdown, Hibernate, Sleep and Nothing."
                }
            }
        }
        catch {
            Write-Warning $_.Exception.Message
            Write-Warning "Failed to set power setting for $Setting"
        }
    }

    # The actual code required to set these values is very similar.
    function Set-PowerValue {
        [CmdletBinding()]
        param(
            [Parameter()]
            [String]$Value,
            [Parameter()]
            [String]$GUID,
            [Parameter()]
            [String]$Index,
            [Parameter()]
            [String]$Setting
        )

        try {
            if ($AC -or -not $BatteryCheck) {
                powercfg.exe /SETACVALUEINDEX SCHEME_CURRENT $GUID $Index $Value
            }
            elseif ($DC) {
                powercfg.exe /SETDCVALUEINDEX SCHEME_CURRENT $GUID $Index $Value
            }
            else {
                powercfg.exe /SETACVALUEINDEX SCHEME_CURRENT $GUID $Index $Value
                powercfg.exe /SETDCVALUEINDEX SCHEME_CURRENT $GUID $Index $Value
            }

            Test-PowerValue $GUID $Index $Value -Setting $Setting
        }
        catch {
            Write-Warning $_.Exception.Message
            Write-Warning "Failed to set power setting for $Setting"
        }
    }

    # Before changing the power plan we should check if it exists and whether or not it is in use.
    function Get-PowerPlan {
        [CmdletBinding()]
        param(
            [Parameter()]
            [Switch]$Active,
            [Parameter()]
            [String]$Name
        )
        if ($Active) {
            $PowerPlan = powercfg.exe /getactivescheme
            $PowerPlan = ($PowerPlan -replace "Power Scheme GUID:" -split "(?=\S{8}-\S{4}-\S{4}-\S{17})" -split '\(' -replace '\)') | Where-Object { $_ -ne " " }
            $PowerPlan = @(
                [PSCustomObject]@{
                    Name = $($PowerPlan | Where-Object { $_ -notmatch "\S{8}-\S{4}-\S{4}-\S{17}" })
                    GUID = $($PowerPlan | Where-Object { $_ -match "\S{8}-\S{4}-\S{4}-\S{17}" })
                }
            )
        }
        else {
            $PowerPlan = powercfg.exe /L
            $PowerPlan = $PowerPlan -replace '\s{2,}', ',' -replace ' \*', ',True' -replace "Existing Power Schemes \(\* Active\)", "GUID,Name,Active" -replace "-{2,}" -replace "Power Scheme GUID: " -replace '\(' -replace '\)' | Where-Object { $_ } | ConvertFrom-Csv
        }

        if ($Name) {
            $PowerPlan | Where-Object { $_.Name -like $Name }
        }
        else {
            $PowerPlan
        }
    }
}
process {
    # If not elevated, exit the script.
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    # If a power plan was specified, let the user know that this might not actually be a changeable option (depending on computer age).
    if ($PowerPlan) {
        Write-Warning "Devices with modern standby might only have `"Balanced`" as an option."
        Write-Warning "Link: https://learn.microsoft.com/en-us/windows/win32/power/power-policy-settings"

        $TargetPlan = Get-PowerPlan -Name $PowerPlan
        # If totally not available we're going to exit as all these settings are tied to the active power plan. 
        # If we're not able to set it we'll want to give an opportunity to correct the error.
        if ($null -eq $TargetPlan) {
            Write-Error "Your targeted Power Plan is not available."
            exit 1
        }

        if ($TargetPlan.Active -ne $True) {
            powercfg.exe /setactive $TargetPlan.GUID
        }

        $CurrentPlan = Get-PowerPlan -Active
        if ($CurrentPlan.GUID -notlike "*$($TargetPlan.GUID)*") {
            Write-Error "Failed to change power plan!"
            exit 1
        }
        else {
            Write-Host "Successfully set Power Plan!"
        }
    }

    # We're going to run through all the various options and if requested we'll adjust them.
    if ($ScreenTimeout) { Set-PowerValue -GUID "SUB_VIDEO" -Index "3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e" -Value $ScreenTimeoutValue -Setting "Screen Timeout" }
    if ($HibernateTimeout) { 
        Write-Warning "Hibernate timeout is not supported by all devices and may be ignored by the System." 
        Set-PowerValue -GUID "SUB_SLEEP" -Index "9d7815a6-7ee4-497e-8888-515a05f02364" -Value $HibernateTimeoutValue -Setting "Hibernate Timeout"
    }
    if ($SleepTimeout) { Set-PowerValue -GUID "SUB_SLEEP" -Index "29f6c1db-86da-48c5-9fdb-f2b67b1f44da" -Value $SleepTimeoutValue -Setting "Sleep Timeout" }
    if ($DiskTimeout) { 
        Write-Warning "An HDD is required for this setting to display (has no effect on SSDs)."
        Set-PowerValue -GUID "SUB_DISK" -Index "6738e2c4-e8a5-4a42-b16a-e040e769756e" -Value $DiskTimeoutValue -Setting "Disk Timeout"
    }
    if ($DisableUSBSuspend) { Set-PowerValue -GUID "2a737441-1930-4402-8d77-b2bebba308a3" -Index "48e6b7a6-50f5-4782-a5d4-53bb8f07e226" -Value 0 -Setting "Disable USB Auto-Suspend" }
    if ($EnableUSBSuspend) { Set-PowerValue -GUID "2a737441-1930-4402-8d77-b2bebba308a3" -Index "48e6b7a6-50f5-4782-a5d4-53bb8f07e226" -Value 1 -Setting "Enable USB Auto-Suspend" }
    if ($AllowWakeTimers) { Set-PowerValue -GUID "SUB_SLEEP" -Index "bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d" -Value 1 -Setting "Allow Wake Timers" }
    if ($DisableWakeTimers) { Set-PowerValue -GUID "SUB_SLEEP" -Index "bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d" -Value 0 -Setting "Disable Wake Timers" }
    # Lid Action has slightly different options than Set-PowerAction.
    if ($LidAction -and $LaptopCheck) { 
        switch ($LidAction) {
            "Nothing" { Set-PowerValue -GUID "SUB_BUTTONS" -Index "5ca83367-6e45-459f-a27b-476b1d01c936" -Value 0 -Setting "Lid Action" }
            "Sleep" { Set-PowerValue -GUID "SUB_BUTTONS" -Index "5ca83367-6e45-459f-a27b-476b1d01c936" -Value 1 -Setting "Lid Action" }
            "Shutdown" { Set-PowerValue -GUID "SUB_BUTTONS" -Index "5ca83367-6e45-459f-a27b-476b1d01c936" -Value 3 -Setting "Lid Action" }
            default {
                Write-Error "Invalid PowerButton Option. Only Sleep, Nothing and Shutdown are allowed!"
                exit 1
            }
        } 
    }
    if ($CriticalAction) { 
        Set-PowerAction -GUID "SUB_BATTERY" -Index "637ea02f-bbcb-4015-8e2c-a1c7b9c0b546" -Action $CriticalAction -Setting "Critical Battery Action"
    }
    if ($LowAction) { 
        Set-PowerAction -GUID "SUB_BATTERY" -Index "d8742dcb-3e6a-4b3c-b3fe-374623cdcf06" -Action $LowAction -Setting "Low Battery Action"
    }
    if ($CriticalLevel) { Set-PowerValue -GUID "SUB_BATTERY" -Index "9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469" -Value $CriticalLevelValue -Setting "Critical Battery Level" }
    if ($LowLevel) { Set-PowerValue -GUID "SUB_BATTERY" -Index "8183ba9a-e910-48da-8769-14ae6dc1170a" -Value $LowLevelValue -Setting "Low Battery Level" }
    if ($LowNoNotify) { Set-PowerValue -GUID "SUB_BATTERY" -Index "bcded951-187b-4d05-bccc-f7e51960c258" -Value 0 -Setting "Disable Low Battery Notification" }
    if ($LowNotify) { Set-PowerValue -GUID "SUB_BATTERY" -Index "bcded951-187b-4d05-bccc-f7e51960c258" -Value 1 -Setting "Enable Low Battery Notification" }
}
end {
    
    
    
}
