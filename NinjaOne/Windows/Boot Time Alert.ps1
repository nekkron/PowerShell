#Requires -Version 5.1

<#
.SYNOPSIS
    Gets the Last BIOS time from the startup section of task manager and alerts if it exceeds a threshold you specify.
.DESCRIPTION
    Gets the Last BIOS time from the startup section of task manager and alerts if it exceeds a threshold you specify.
    Can save the result to a custom field.

.EXAMPLE
    (No Parameters)
    ## EXAMPLE OUTPUT WITHOUT PARAMS ##
    Last BIOS Time: 14.6s

PARAMETER: -BootCustomField "BootTime"
    Saves the boot time to this Text Custom Field.
.EXAMPLE
    -BootCustomField "BootTime"
    ## EXAMPLE OUTPUT WITH BootCustomField ##
    Last BIOS Time: 14.6s

PARAMETER: -Seconds 20
    Sets the threshold for when the boot time is greater than this number.
    In this case the boot time is over the threshold.
.EXAMPLE
    -Seconds 20
    ## EXAMPLE OUTPUT WITH Seconds ##
    Last BIOS Time: 14.6s
    [Error] Boot time exceeded threshold of 20s by 5.41s. Boot time: 14.6s

PARAMETER: -Seconds 10
    Sets the threshold for when the boot time is greater than this number.
    In this case the boot time is under the threshold.
.EXAMPLE
    -Seconds 10
    ## EXAMPLE OUTPUT WITH Seconds ##
    Last BIOS Time: 14.6s
    [Info] Boot time under threshold of 10s by 4.59s. Boot time: 14.6s

.OUTPUTS
    String
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    $Seconds,
    [String]$BootCustomField
)

begin {
    if ($env:bootCustomField -and $env:bootCustomField -notlike "null") {
        $BootCustomField = $env:bootCustomField
    }
    if ($env:bootTimeThreshold -and $env:bootTimeThreshold -notlike "null") {
        # Remove any non digits
        [double]$Seconds = $env:bootTimeThreshold -replace '[^0-9.]+'
    }
    function Set-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [String]$Name,
            [Parameter()]
            [String]$Type,
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            $Value,
            [Parameter()]
            [String]$DocumentName
        )
    
        $Characters = $Value | Measure-Object -Character | Select-Object -ExpandProperty Characters
        if ($Characters -ge 10000) {
            throw [System.ArgumentOutOfRangeException]::New("Character limit exceeded, value is greater than 10,000 characters.")
        }
        
        # If we're requested to set the field value for a Ninja document we'll specify it here.
        $DocumentationParams = @{}
        if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }
        
        # This is a list of valid fields that can be set. If no type is given, it will be assumed that the input doesn't need to be changed.
        $ValidFields = "Attachment", "Checkbox", "Date", "Date or Date Time", "Decimal", "Dropdown", "Email", "Integer", "IP Address", "MultiLine", "MultiSelect", "Phone", "Secure", "Text", "Time", "URL", "WYSIWYG"
        if ($Type -and $ValidFields -notcontains $Type) { Write-Warning "$Type is an invalid type! Please check here for valid types. https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality" }
        
        # The field below requires additional information to be set
        $NeedsOptions = "Dropdown"
        if ($DocumentName) {
            if ($NeedsOptions -contains $Type) {
                # We'll redirect the error output to the success stream to make it easier to error out if nothing was found or something else went wrong.
                $NinjaPropertyOptions = Ninja-Property-Docs-Options -AttributeName $Name @DocumentationParams 2>&1
            }
        }
        else {
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Options -Name $Name 2>&1
            }
        }
        
        # If an error is received it will have an exception property, the function will exit with that error information.
        if ($NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }
        
        # The below type's require values not typically given in order to be set. The below code will convert whatever we're given into a format ninjarmm-cli supports.
        switch ($Type) {
            "Checkbox" {
                # While it's highly likely we were given a value like "True" or a boolean datatype it's better to be safe than sorry.
                $NinjaValue = [System.Convert]::ToBoolean($Value)
            }
            "Date or Date Time" {
                # Ninjarmm-cli expects the GUID of the option to be selected. Therefore, the given value will be matched with a GUID.
                $Date = (Get-Date $Value).ToUniversalTime()
                $TimeSpan = New-TimeSpan (Get-Date "1970-01-01 00:00:00") $Date
                $NinjaValue = $TimeSpan.TotalSeconds
            }
            "Dropdown" {
                # Ninjarmm-cli is expecting the guid of the option we're trying to select. So we'll match up the value we were given with a guid.
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = $Options | Where-Object { $_.Name -eq $Value } | Select-Object -ExpandProperty GUID
        
                if (-not $Selection) {
                    throw [System.ArgumentOutOfRangeException]::New("Value is not present in dropdown")
                }
        
                $NinjaValue = $Selection
            }
            default {
                # All the other types shouldn't require additional work on the input.
                $NinjaValue = $Value
            }
        }
        
        # We'll need to set the field differently depending on if its a field in a Ninja Document or not.
        if ($DocumentName) {
            $CustomField = Ninja-Property-Docs-Set -AttributeName $Name -AttributeValue $NinjaValue @DocumentationParams 2>&1
        }
        else {
            $CustomField = Ninja-Property-Set -Name $Name -Value $NinjaValue 2>&1
        }
        
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }
}
process {
    $Ticks = try {
        # Get boot time from performance event logs
        $PerfTicks = Get-WinEvent -FilterHashtable @{LogName = "Microsoft-Windows-Diagnostics-Performance/Operational"; Id = 100 } -MaxEvents 1 -ErrorAction SilentlyContinue | ForEach-Object {
            # Convert the event to XML and grab the Event node
            $eventXml = ([xml]$_.ToXml()).Event
            # Output boot time in ms
            [int64]($eventXml.EventData.Data | Where-Object { $_.Name -eq 'BootTime' }).InnerXml
        }
        # Get the boot POST time from the firmware, when available
        $FirmwareTicks = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "FwPOSTTime" -ErrorAction SilentlyContinue
        # Get the boot POST time from Windows, used as fall back
        $OsTicks = Get-ItemPropertyValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "POSTTime" -ErrorAction SilentlyContinue
        # Use most likely to be accurate to least accurate
        if ($FirmwareTicks -gt 0) {
            $FirmwareTicks
        }
        elseif ($OsTicks -gt 0) {
            $OsTicks
        }
        elseif ($PerfTicks -and $PerfTicks -gt 0) {
            $PerfTicks
        }
        else {
            # Fall back to reading System event logs
            $StartOfBoot = Get-WinEvent -FilterHashtable @{LogName = 'System'; Id = 12 } -MaxEvents 1 | Select-Object -ExpandProperty TimeCreated
            $LastUpTime = Get-WmiObject Win32_OperatingSystem -ErrorAction Stop | Select-Object @{Label = 'LastBootUpTime'; Expression = { $_.ConvertToDateTime($_.LastBootUpTime) } } | Select-Object -ExpandProperty LastBootUpTime
            New-TimeSpan -Start $LastUpTime -End $StartOfBoot -ErrorAction Stop | Select-Object -ExpandProperty TotalMilliseconds
        }
    }
    catch {
        Write-Host "[Error] Failed to get Last BIOS Time from registry."
        exit 2
    }

    $TimeSpan = [TimeSpan]::FromMilliseconds($Ticks)

    $BootTime = if ($TimeSpan.Days -gt 0) {
        "$($TimeSpan.Days)d, $($TimeSpan.Hours)h, $($TimeSpan.Minutes)m, $($TimeSpan.Seconds + [Math]::Round($TimeSpan.Milliseconds / 1000, 1))s"
    }
    elseif ($TimeSpan.Hours -gt 0) {
        "$($TimeSpan.Hours)h, $($TimeSpan.Minutes)m, $($TimeSpan.Seconds + [Math]::Round($TimeSpan.Milliseconds / 1000, 1))s"
    }
    elseif ($TimeSpan.Minutes -gt 0) {
        "$($TimeSpan.Minutes)m, $($TimeSpan.Seconds + [Math]::Round($TimeSpan.Milliseconds / 1000, 1))s"
    }
    elseif ($TimeSpan.Seconds -gt 0) {
        "$($TimeSpan.Seconds + [Math]::Round($TimeSpan.Milliseconds / 1000, 1))s"
    }
    else {
        # Fail safe output
        "$($TimeSpan.Days)d, $($TimeSpan.Hours)h, $($TimeSpan.Minutes)m, $($TimeSpan.Seconds + [Math]::Round($TimeSpan.Milliseconds / 1000, 1))s"
    }

    Write-Host "Last BIOS Time: $BootTime"

    if ($BootCustomField) {
        Set-NinjaProperty -Name $BootCustomField -Type Text -Value $BootTime
    }

    if ($Seconds -gt 0) {
        if ($TimeSpan.TotalSeconds -gt $Seconds) {
            Write-Host "[Error] Boot time exceeded threshold of $($Seconds)s by $($TimeSpan.TotalSeconds - $Seconds)s. Boot time: $BootTime"
            exit 1
        }
        Write-Host "[Info] Boot time under threshold of $($Seconds)s by $($Seconds - $TimeSpan.TotalSeconds)s. Boot time: $BootTime"
    }
    exit 0
}
end {
    
    
    
}