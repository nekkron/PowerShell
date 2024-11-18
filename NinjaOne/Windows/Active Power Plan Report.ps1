#Requires -Version 5.1

<#
.SYNOPSIS
    Reports the active power plan and active power settings. Outputs to activity log and customfield "activePowerPlan" and "activePowerSettings" by default.
.DESCRIPTION
    Reports the active power plan and active power settings. Outputs to activity log and customfield "activePowerPlan" and "activePowerSettings" by default.
.EXAMPLE
    (No Parameters)

    Active Power Plan: Balanced 

    ### Current Power Settings For Balanced ### 

    Name                          When Plugged In                 When On Battery                  Units  
    ----                          ---------------                 ---------------                  -----  
    Allow hybrid sleep            Off                             Off                              N/A    
    Allow wake timers             Important Wake Timers Only      Disable                          N/A    
    Critical battery action       Do nothing                      Do nothing                       N/A    
    Critical battery level        5                               5                                %      
    Critical battery notification On                              On                               N/A    
    Dimmed display brightness     50                              50                               %      
    Display brightness            100                             40                               %      
    Enable adaptive brightness    Off                             Off                              N/A    
    Hibernate after               10800                           10800                            Seconds
    JavaScript Timer Frequency    Maximum Performance             Maximum Power Savings            N/A    
    Link State Power Management   Maximum power savings           Maximum power savings            N/A    
    Low battery action            Do nothing                      Do nothing                       N/A    
    Low battery level             10                              10                               %      
    Low battery notification      On                              On                               N/A    
    Maximum processor state       100                             100                              %      
    Minimum processor state       5                               5                                %      
    Power Saving Mode             Maximum Performance             Medium Power Saving              N/A    
    Reserve battery level         7                               7                                %      
    Sleep after                   1800                            900                              Seconds
    Slide show                    Available                       Paused                           N/A    
    Start menu power button       Sleep                           Sleep                            N/A    
    System cooling policy         Active                          Passive                          N/A    
    Turn off display after        600                             300                              Seconds
    Turn off hard disk after      1200                            600                              Seconds
    USB selective suspend setting Enabled                         Enabled                          N/A    
    Video playback quality bias   Video playback performance bias Video playback power-saving bias N/A    
    When playing video            Optimize video quality          Balanced                         N/A    
    When sharing media            Prevent idling to sleep         Allow the computer to sleep      N/A    

PARAMETER: -PowerPlanCustomFieldName "ReplaceMeWithAnyMultilineCustomField"
    Replace the quoted text with any custom field name you'd like the script to write the active power plan to.
PARAMETER: -PowerSettingsCustomFieldName "ReplaceMeWithAnyTextCustomField"
    Replace the quoted text with any custom field name you'd like the script to write the active power settings to.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes: Renamed script and added Script Variable support
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$PowerPlanCustomFieldName = "activePowerPlan",
    [Parameter()]
    [String]$PowerSettingsCustomFieldName = "activePowerSettings"
)

begin {

    # If Script forms are used replace parameters with their value.
    if ($env:powerPlanCustomFieldName -and $env:powerPlanCustomFieldName -notlike "null" ) { $PowerPlanCustomFieldName = $env:powerPlanCustomFieldName }
    if ($env:powerSettingsCustomFieldName -and $env:powerSettingsCustomFieldName -notlike "null") { $PowerSettingsCustomFieldName = $env:powerSettingsCustomFieldName }

    # Script will fail if not elevated (some setting values are hidden to non-admins)
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    # Get's the active power plan
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
            $PowerPlan = ($PowerPlan -replace "Power Scheme GUID:" -split "(?=\S{8}-\S{4}-\S{4}-\S{4}-\S{12})" -split '\(' -replace '\)') | Where-Object { $_ -ne " " }
            $PowerPlan = @(
                [PSCustomObject]@{
                    Name = $($PowerPlan | Where-Object { $_ -notmatch "\S{8}-\S{4}-\S{4}-\S{4}-\S{12}" })
                    GUID = $($PowerPlan | Where-Object { $_ -match "\S{8}-\S{4}-\S{4}-\S{4}-\S{12}" })
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

    # Gets all the powersettings for the current plan
    function Get-PowerSettings {
        [CmdletBinding()]
        param()
        process {

            # Grabs all the powersetting subroups first as that's require info to grab the actual setting values
            $PowerSubgroups = powercfg.exe /Q | Select-String "Subgroup GUID:"
            $PowerSubgroups = ($PowerSubgroups -replace "Subgroup GUID:" -replace '\(' -replace '\)').trim() | ForEach-Object { 
                @(
                    [PSCustomObject]@{
                        SubName = $($_ -split "\s{2,}" | Where-Object { $_ -notmatch "(\S{8}-\S{4}-\S{4}-\S{4}-\S{12})" })
                        SubGUID = $($_ -split "\s{2,}" | Where-Object { $_ -match "(\S{8}-\S{4}-\S{4}-\S{4}-\S{12})" })
                    }
                )
            }

            # From each subgroup we'll get a list of every power setting
            $PowerSettings = ForEach ($Subgroup in $PowerSubgroups) {
                $Settings = powercfg.exe /Q SCHEME_CURRENT $Subgroup.SubGUID | Select-String "Power Setting GUID:"
                ($Settings -replace "Power Setting GUID:" -replace '\(' -replace '\)').trim() | ForEach-Object {
                    @(
                        [PSCustomObject]@{
                            Name    = $($_ -split "\s{2,}" | Where-Object { $_ -notmatch "(\S{8}-\S{4}-\S{4}-\S{4}-\S{12})" })
                            GUID    = $($_ -split "\s{2,}" | Where-Object { $_ -match "(\S{8}-\S{4}-\S{4}-\S{4}-\S{12})" })
                            SubName = $Subgroup.SubName
                            SubGUID = $Subgroup.SubGUID
                        }
                    )
                }
            }

            # Finally we'll parse out the actual power setting values based on the previously retrieved subgroup guid and setting guid
            ForEach ($PowerSetting in $PowerSettings) {
                # Windows has a different value/setting for both plugged in (AC) and battery (DC) 
                $ACValue = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String "Current AC Power Setting Index:" 
                $ACValue = ($ACValue -replace "Current AC Power Setting Index:" -replace '\(' -replace '\)').trim()

                $DCValue = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String "Current DC Power Setting Index:"
                $DCValue = ($DCValue -replace "Current DC Power Setting Index:" -replace '\(' -replace '\)').trim()

                # The values are always in hex so we'll need to convert them into integers to make them easier to understand
                $ACValue = [int32]$ACValue
                $DCValue = [int32]$DCValue
                
                # Some settings correspond to an action rather than a certain percentage level or a number of seconds. These cases always have 
                # the pharse "Possible Setting Friendly Name"
                $FriendlyName = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String "Possible Setting Friendly Name:"
                if ($FriendlyName) {
                    # Since the friendly name, index and current value are stored seperately we'll have to parse them out individually
                    $Indexs = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String "Possible Setting Index:"
                    $Indexs = $Indexs | ForEach-Object { ($_ -replace "Possible Setting Index:").trim() }

                    $FriendlyNames = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String "Possible Setting Friendly Name:"
                    $FriendlyNames = $FriendlyNames | ForEach-Object { ($_ -replace "Possible Setting Friendly Name:").trim() }

                    # Once parsed the FriendlyNames and their index's should be the same number and one is always followed by the other.
                    # So to combine them we just need to loop through them in order, this'll give us a more Powershell friendly object
                    $FriendlyOptions = For ($i = 0; $i -lt $FriendlyNames.Count; $i++) {
                        [PSCustomObject]@{
                            Name  = $FriendlyNames[$i]
                            Index = $Indexs[$i]
                        }
                    }

                    # Now that we have the object figuring out which action is active and what it does is a piece of cake. 
                    # Though we'll have to convert the index to an integer to make everything match up easy.
                    $ACValue = $FriendlyOptions | Where-Object { [int32]$_.Index -eq $ACValue } | Select-Object Name -ExpandProperty Name
                    $DCValue = $FriendlyOptions | Where-Object { [int32]$_.Index -eq $DCValue } | Select-Object Name -ExpandProperty Name

                    # There's no units to accompany these actions
                    $Units = "N/A"
                }
                else {
                    # Everything else is either a percent or a number of seconds we'll save that for later
                    $Units = powercfg.exe /Q SCHEME_CURRENT $PowerSetting.SubGUID $PowerSetting.GUID | Select-String "Possible Settings units:"
                    $Units = ($Units -replace "Possible Settings units:" -replace '\(' -replace '\)').trim()
                }

                # Lastly we format our findings into a nice firendly PowerShell Object
                [PSCustomObject]@{
                    Name              = $PowerSetting.Name
                    GUID              = $PowerSetting.GUID
                    "When Plugged In" = $ACValue
                    "When On Battery" = $DCValue
                    Units             = $Units
                    SubName           = $PowerSetting.SubName
                    SubGUID           = $PowerSetting.SubGUID
                }
            }
        }
    }
}
process {
    # If not elevated exit the script.
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    # Retrieve's the Active Power Plan to be used for the report
    $ActivePowerPlan = Get-PowerPlan -Active | Select-Object Name -ExpandProperty Name

    # If somehow we came up empty we should error out
    if (-not $ActivePowerPlan) {
        Write-Error "[Error] Unable to retrieve power plan!"
        exit 1
    }

    # Retrieve's the current settings and formats them into a nice table. Organized by name for easy viewing.
    $CurrentPowerSettings = Get-PowerSettings | Sort-Object Name | Format-Table -Property Name, 'When Plugged In', 'When On Battery', Units -AutoSize | Out-String
    if (-not $CurrentPowerSettings) {
        Write-Error "[Error] Unable to retrieve power settings!"
        exit 1
    }

    # Constructing the actual report
    $Report = New-Object System.Collections.Generic.List[string]
    $Report.Add("Active Power Plan: $ActivePowerPlan")
    $Report.Add("`n`n### Current Power Settings For $ActivePowerPlan ###")
    $Report.Add("`n$CurrentPowerSettings")

    # Write to the activity log
    Write-Host $Report

    # Save our findings to a custom field
    if ($PowerPlanCustomFieldName) {
        Ninja-Property-Set -Name $PowerPlanCustomFieldName -Value $ActivePowerPlan
    }

    if ($PowerSettingsCustomFieldName) {
        Ninja-Property-Set -Name $PowerSettingsCustomFieldName -Value $CurrentPowerSettings
    }
}
end {
    
    
    
}
