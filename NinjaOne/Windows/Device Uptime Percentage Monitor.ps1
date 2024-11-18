#Requires -Version 4.0

<#
.SYNOPSIS
    Get the Uptime percentage of a Windows device and show a list of boot events.
.DESCRIPTION
    Get the Uptime percentage of a Windows device and show a list of boot events.

    Unexpected Shutdowns can skew results slightly.

    Duration in results is in days.
.Example
    (No Parameters)

    WARNING: No time frame specified. Checking uptime percentage for the last 30 days
    Creating uptime entries based on event logs...
    Uptime entries created!
    WARNING: Estimating unexpected shutdown times. This will not be 100% accurate.

    Oldest uptime record: 06/29/2023 22:24:01

    Filtering uptime records to your time frame...
    Calculating uptime during time frame...

    ### Time Frame ###
    Start Date: 12/26/2023 19:39:38
    End Date: 01/25/2024 19:39:38

    ### Statistics ###
    Percentage Online: 3.93%
    Total Time Frame: 30d
    Total Uptime: 1d 4h 19m 14s

    ### Uptime Entries ###

    BootType     BootTime             ShutdownTime Duration     
    --------     --------             ------------ --------     
    Current Boot 1/24/2024 3:20:23 PM              1d 4h 19m 14s
.EXAMPLE
    -Days 30

    WARNING: No time frame specified. Checking uptime percentage for the last 30 days
    Creating uptime entries based on event logs...
    Uptime entries created!
    WARNING: Estimating unexpected shutdown times. This will not be 100% accurate.

    Oldest uptime record: 06/29/2023 22:24:01

    Filtering uptime records to your time frame...
    Calculating uptime during time frame...

    ### Time Frame ###
    Start Date: 12/26/2023 19:39:38
    End Date: 01/25/2024 19:39:38

    ### Statistics ###
    Percentage Online: 3.93%
    Total Time Frame: 30d
    Total Uptime: 1d 4h 19m 14s

    ### Uptime Entries ###

    BootType     BootTime             ShutdownTime Duration     
    --------     --------             ------------ --------     
    Current Boot 1/24/2024 3:20:23 PM              1d 4h 19m 14s
.EXAMPLE
    -StartDay "2023-07-01T00:00:00.000-07:00" -EndDay "2023-07-31T00:00:00.000-07:00"

    Creating uptime entries based on event logs...
    Uptime entries created!
    WARNING: Estimating unexpected shutdown times. This will not be 100% accurate.

    Oldest uptime record: 06/29/2023 22:24:01

    Filtering uptime records to your time frame...
    Calculating uptime during time frame...

    ### Time Frame ###
    Start Date: 07/01/2023 00:00:00
    End Date: 07/31/2023 00:00:00

    ### Statistics ###
    Percentage Online: 89%
    Total Time Frame: 30d
    Total Uptime: 26d 16h 49m 17s

    ### Uptime Entries ###

    BootType            BootTime              ShutdownTime           Duration       
    --------            --------              ------------           --------       
    Normal              7/26/2023 12:16:34 PM 12/21/2023 11:24:17 AM 147d 23h 7m 42s
    Normal              7/26/2023 11:52:47 AM 7/26/2023 12:16:26 PM  23m 39s        
    Normal              7/26/2023 11:22:46 AM 7/26/2023 11:52:40 AM  29m 53s        
    Normal              7/26/2023 10:55:08 AM 7/26/2023 11:22:38 AM  27m 29s        
    Unexpected Shutdown 7/26/2023 10:42:45 AM 7/26/2023 10:53:16 AM  10m 30s        
    Normal              7/24/2023 11:09:01 AM 7/24/2023 11:35:43 AM  26m 42s        
    Normal              7/24/2023 10:45:38 AM 7/24/2023 11:08:53 AM  23m 15s        
    Normal              7/24/2023 9:50:52 AM  7/24/2023 9:58:47 AM   7m 54s         
    Normal              7/24/2023 8:08:34 AM  7/24/2023 8:10:16 AM   1m 41s         
    Normal              7/20/2023 5:26:15 PM  7/24/2023 8:08:26 AM   3d 14h 42m 11s 
    Normal              7/20/2023 5:21:09 PM  7/20/2023 5:26:08 PM   4m 59s         
    Normal              7/20/2023 4:08:28 PM  7/20/2023 5:21:02 PM   1h 12m 33s     
    Unexpected Shutdown 6/29/2023 10:41:23 PM 7/19/2023 10:35:01 AM  19d 11h 53m 38s

PARAMETER: -Days "replaceMeWithANumber"
    Gets the uptime for the past X days.

PARAMETER: -StartDay "2023-07-01T00:00:00.000-07:00"
    Gets the uptime starting from the specified day.

PARAMETER: -EndDay "2023-07-31T00:00:00.000-07:00"
    Gets the uptime ending on the specified day.

PARAMETER: -WysiwygCustomField "The name of your selected custom field."
    Outputs the results to a WYSIWYG custom field.

PARAMETER: -PercentageCustomField "The name of a text custom field"
    Outputs the results to a text custom field.

PARAMETER: -EstimateUnexpectedShutdown
    Tells the script to estimate the shutdown time and date using the last known eventlog for that range.
.OUTPUTS
    PSObject
.NOTES
    Minimum OS Architecture Supported: Windows 8, Windows Server 2012
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [int]$Days,
    [Parameter()]
    $StartDay,
    [Parameter()]
    $EndDay,
    [Parameter()]
    [string]$WysiwygCustomField,
    [Parameter()]
    [String]$PercentageCustomField,
    [Parameter()]
    [Switch]$EstimateUnexpectedShutdown = [System.Convert]::ToBoolean($env:estimateUnexpectedShutdownTime)
)

begin {
    if ($env:uptimeForThePastXDays -and $env:uptimeForThePastXDays -notlike "null") { $Days = $env:uptimeForThePastXDays }
    if ($env:startDay -and $env:startDay -notlike "null") { $StartDay = $env:startDay }
    if ($env:endDay -and $env:endDay -notlike "null") { $EndDay = $env:endDay }
    if ($env:wysiwygCustomFieldName -and $env:wysiwygCustomFieldName -notlike "null") { $WysiwygCustomField = $env:wysiwygCustomFieldName }
    if ($env:percentageCustomFieldName -and $env:percentageCustomFieldName -notlike "null") { $PercentageCustomField = $env:percentageCustomFieldName }

    if ($StartDay -and $EndDay) {
        $StartDay = Get-Date -Date $StartDay
        $EndDay = Get-Date -Date $EndDay
    }

    if ($Days -and ($StartDay -or $EndDay)) { Write-Host "[Error] You cannot use 'The Past X Days' and 'Start Day' or 'End Day' at the same time"; exit 1 }
    if (-not $Days -and -not $StartDay -and -not $EndDay) { Write-Warning "No time frame specified. Checking uptime percentage for the last 30 days"; $Days = 30 }
    if (($StartDay -and -not $EndDay) -or ($EndDay -and -not $StartDay)) { Write-Host "[Error] Start Day must be used with End Day."; exit 1 }
    if ($StartDay -and $StartDay -ge $EndDay) { Write-Host "[Error] Start Day must be before End Day"; exit 1 }

    if ($Days) {
        $StartDay = (Get-Date).AddDays(-$Days)
        $EndDay = Get-Date
    }

    function ConvertFrom-TimeSpan {
        [CmdletBinding()]
        [OutputType([string[]])]
        param(
            [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
            [TimeSpan[]]$TimeSpan
        )
        process {
            $Days = if ($($_.Days)) { "$($_.Days)d" }else { "" }
            $Hours = if ($($_.Hours)) { "$($_.Hours)h" }else { "" }
            $Minutes = if ($($_.Minutes)) { "$($_.Minutes)m" }else { "" }
            $Seconds = if ($($_.Seconds)) { "$($_.Seconds)s" }else { "" }
            "$($(@($Days, $Hours, $Minutes, $Seconds) | Select-Object -Unique) -join ' ')".Trim()
        }
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
    $ExitCode = 0
}
process {
    if (
        $PSCmdlet.ParameterSetName -like "StartEndDays" -and $StartDay -ge $EndDay -or
        $($StartDay -and $EndDay -and $StartDay -ge $EndDay)
    ) {
        Write-Error "StartDay must be less than EndDay."
        exit 1
    }
    
    # Gathers all the event logs pertaining to startup and shutdowns
    $eventFilter = @{
        LogName      = 'System'
        ProviderName = @('Microsoft-Windows-Kernel-General', 'Microsoft-Windows-Eventlog')
        ID           = 12, 13, 6008
    }
    $Events = Get-WinEvent -FilterHashtable $eventFilter

    $BootEntries = New-Object System.Collections.Generic.List[object]
    $i = 0
    $BootTime = $null
    $ShutdownTime = $null

    Write-Host "Creating uptime entries based on event logs..."
    $Events | ForEach-Object {
        # If this is the first event it is for our current boot
        if ($i -eq 0) {
            $BootEntries.Add(
                [PSCustomObject]@{
                    BootType     = "Current Boot"
                    BootTime     = $_.TimeCreated
                    ShutdownTime = $null
                    Duration     = if ((((Get-Date) - $EndDay).TotalDays -lt 1)) { New-TimeSpan -Start $_.TimeCreated -End $EndDay }else { (New-TimeSpan -Start $_.TimeCreated -End $(Get-Date)) }
                }
            )
            $i++
            return
        }

        # Check to see if the next event is either an Unexpected Shutdown or a Startup Entry
        if ($_.Id -eq 13 -and ($Events[$($i + 1)].Id -eq 12 -or $Events[$($i + 1)].Id -eq 6008)) {
            $ShutdownTime = $_.TimeCreated
            $BootTime = $Events[$($i + 1)].TimeCreated
        }

        # Check to see if the previous entry was something other than shutdown and the next event is a shutdown event.
        if ($_.Id -eq 12 -and ($Events[$($i - 1)].Id -ne 13) -and ($Events[$($i + 1)].Id -eq 13)) {
            # There's no end record for unexpected shutdowns so we'll need to record that
            $BootEntries.Add(
                [PSCustomObject]@{
                    BootType     = "Unexpected Shutdown"
                    BootTime     = $_.TimeCreated
                    ShutdownTime = $null
                    Duration     = $null
                }
            )
        }

        # If there are no special cases record the information
        if ($BootTime -and $ShutdownTime) {
            $BootEntries.Add(
                [PSCustomObject]@{
                    BootType     = "Normal"
                    BootTime     = $BootTime
                    ShutdownTime = $ShutdownTime
                    Duration     = (New-TimeSpan -Start $BootTime -End $ShutdownTime)
                }
            )
            $BootTime = $null
            $ShutdownTime = $null
        }

        $i++
    }

    Write-Host "Uptime entries created!"

    # Warn about unexpected shutdown's effect on the report
    if ($BootEntries.BootType -contains "Unexpected Shutdown" -and -not $EstimateUnexpectedShutdown) {
        Write-Warning "There are unexpected shutdowns in your boot history (may or may not be within your timeframe)." 
        Write-Warning "Unexpected shutdowns do NOT have a shutdown time and will be excluded from all calculations."
    }
    elseif ($BootEntries.BootType -contains "Unexpected Shutdown") {
        # If requested to estimate the shutdown time. Estimate it based on the last event log prior to the next bootup.
        Write-Warning "Estimating unexpected shutdown times. This will not be 100% accurate."
        $entry = 0
        $BootEntries | ForEach-Object {
            if ($_.BootType -ne "Unexpected Shutdown") {
                $entry++
                return
            }

            $EventFilter = @{
                LogName   = "*"
                StartTime = $_.BootTime
                EndTime   = $BootEntries[$($entry - 1)].BootTime
            }

            # We only want one event to minimize impact on performance
            $LastEvent = Get-WinEvent -FilterHashtable $EventFilter -MaxEvents 1
            $_.ShutdownTime = $LastEvent.TimeCreated
            $_.Duration = (New-TimeSpan -Start $_.BootTime -End $LastEvent.TimeCreated)
            $entry++
        }
    }

    Write-Host "`nOldest uptime record: $($BootEntries | Select-Object -ExpandProperty BootTime -Last 1)`n"

    # We now have all the information needed to decide what uptime records should be output.
    Write-Host "Filtering uptime records to your time frame..."
    $ReportableBootEntries = New-Object System.Collections.Generic.List[object]
    $BootEntries | ForEach-Object {
        if ($_.Duration) {
            $_.Duration = $_.Duration | ConvertFrom-TimeSpan
        }

        if ( $_.ShutdownTime -and $_.ShutdownTime -le $EndDay -and $_.ShutdownTime -ge $StartDay) {
            $ReportableBootEntries.Add($_)
            return
        }

        if ( $_.BootType -eq "Current Boot" -and $_.BootTime -le $StartDay -and $_.BootTime -le $EndDay ) {
            $ReportableBootEntries.Add($_)
            return
        }

        if ( $_.BootTime -and $_.BootTime -ge $StartDay -and $_.BootTime -le $EndDay) {
            $ReportableBootEntries.Add($_)
            return
        }
    }

    # Now let's use our information to calculate the total amount of time the system has been online in the time range.
    Write-Host "Calculating uptime during time frame..."
    $ReportableBootEntries | ForEach-Object {
        # If the current boot is in the time range we'll need to use the End Date as the ending time frame.
        if ($_.BootType -eq "Current Boot" -and $_.BootTime -gt $StartDay) {
            $TotalTimeOnline = $TotalTimeOnline + (New-TimeSpan -Start $_.BootTime -End $EndDay)
            return
        }
        elseif ($_.BootType -eq "Current Boot") {
            # If the boot time is older than the start date we'll use the start date.
            $TotalTimeOnline = $TotalTimeOnline + (New-TimeSpan -Start $StartDay -End $EndDay)
            return
        }

        # If we're missing the information required to make these calculations we should skip it.
        if (-not $_.BootTime -or -not $_.ShutdownTime) {
            return
        }

        # If the uptime entry is in our time range we can add it straight in.
        if ($_.BootTime -ge $StartDay -and $_.ShutdownTime -le $EndDay) {
            $TotalTimeOnline = $TotalTimeOnline + (New-TimeSpan -Start $_.BootTime -End $_.ShutdownTime)
            return
        }

        # If the uptime entry starts to early then we need to use the start day as the starting point.
        if ($_.BootTime -le $StartDay -and $_.ShutdownTime -le $EndDay) {
            $TotalTimeOnline = $TotalTimeOnline + (New-TimeSpan -Start $StartDay -End $_.ShutdownTime)
            return
        }

        # If the uptime entry goes too long than we need to use the end date as a reference.
        if ($_.ShutdownTime -ge $EndDay -and $_.BootTime -ge $StartDay) {
            $TotalTimeOnline = $TotalTimeOnline + (New-TimeSpan -Start $_.BootTime -End $EndDay)
            return
        }

        # If the uptime entry is both before the start day and after the end day we'll use both the start and end day.
        if ($_.ShutdownTime -ge $EndDay -and $_.BootTime -le $StartDay) {
            $TotalTimeOnline = $TotalTimeOnline + (New-TimeSpan -Start $StartDay -End $EndDay)
            return
        }
    }

    # We're now ready to output our results to the activity log
    Write-Host ""

    $TotalTimeFrame = (New-TimeSpan -Start $StartDay -End $EndDay)
    Write-Host "### Time Frame ###"
    Write-Host "Start Date: $StartDay"
    Write-Host "End Date: $EndDay`n"

    # For the percentage we'll take the total number of seconds it was online for and divide it by the total number of seconds possible
    $Percentage = $([math]::Round(($TotalTimeOnline.TotalSeconds / $TotalTimeFrame.TotalSeconds * 100), 2))
    Write-Host "### Statistics ###"
    Write-Host "Percentage Online: $Percentage%"
    Write-Host "Total Time Frame: $($TotalTimeFrame | ConvertFrom-TimeSpan)"
    if ($TotalTimeOnline) {
        $HumanFriendlyTotalUptime = $($TotalTimeOnline | ConvertFrom-Timespan)
    }
    else {
        $HumanFriendlyTotalUptime = "0d 0h 0m 0s"
    }
    Write-Host "Total Uptime: $HumanFriendlyTotalUptime"

    # Let's output our table as well
    Write-Host "`n### Uptime Entries ###"
    $ReportableBootEntries | Format-Table -AutoSize | Out-String | Write-Host

    if ($PercentageCustomField) {
        try {
            Write-Host "Attempting to set Custom Field '$PercentageCustomField'."
            Set-NinjaProperty -Name $PercentageCustomField -Value "$Percentage%"
            Write-Host "Successfully set Custom Field '$PercentageCustomField'!"
        }
        catch {
            Write-Host "[Error] $($_.Message)"
            $ExitCode = 1
        }
    }

    if ($WysiwygCustomField) {
        try {
            Write-Host "Attempting to set Custom Field '$WysiwygCustomField'."
            $htmlReport = New-Object System.Collections.Generic.List[String]
            $htmlReport.Add(@"
<h1>Uptime Statistics</h1>
<ul class="unstyled"><strong>Percentage Online:</strong> $Percentage%</ul>
<ul class="unstyled"><strong>Uptime (In Range):</strong> $HumanFriendlyTotalUptime</ul>
<ul class="unstyled"><strong>Range:</strong> $($StartDay.ToShortDateString()) - $($EndDay.ToShortDateString())</ul>
"@)
            $htmlTable = $ReportableBootEntries | ConvertTo-Html -Fragment 
            $htmlTable = $htmlTable -replace "<tr><td>Current Boot</td>", '<tr class="success"><td>Current Boot</td>'
            $htmlTable = $htmlTable -replace "<tr><td>Normal</td>", '<tr class="other"><td>Normal</td>'
            $htmlTable = $htmlTable -replace "<tr><td>Unexpected Shutdown</td>", '<tr class="danger"><td>Unexpected Shutdown</td>'
            $htmlTable | ForEach-Object { $htmlReport.Add($_) }
            Set-NinjaProperty -Name $WysiwygCustomField -Value ($htmlReport | Out-String)
            Write-Host "Successfully set Custom Field '$WysiwygCustomField'!"
        }
        catch {
            Write-Host "[Error] $($_.Message)"
            $ExitCode = 1
        }
    }

    exit $ExitCode
}
end {
    
    
    
}

