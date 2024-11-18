#Requires -Version 5.1

<#
.SYNOPSIS
    Exports the specified event logs to a specified location in a compressed zip file.
.DESCRIPTION
    Exports the specified event logs to a specified location in a compressed zip file.
    The event logs can be exported from a specific date range.

PARAMETER: -EventLogs "System,Security" -BackupDestination "C:\Temp\EventLogs\"
    Exports the specified event logs to a specified location in a compressed zip file.
.EXAMPLE
    -EventLogs "System,Security" -BackupDestination "C:\Temp\EventLogs\"
    ## EXAMPLE OUTPUT WITH EventLogs ##
    [Info] Today is 2023-04-17
    [Info] EventLogs are System,Security
    [Info] Backup Destination is C:\Temp\EventLogs\
    [Info] Start Date is null
    [Info] End Date is null
    [Info] Exporting Event Logs...
    [Info] Exported Event Logs to C:\Temp\EventLogs\System.evtx
    [Info] Exported Event Logs to C:\Temp\EventLogs\Security.evtx
    [Info] Successfully exported Event Logs!
    [Info] Compressing Event Logs...
    [Info] Compressed Event Logs to C:\Temp\EventLogs\Backup-System-Security-2023-04-17.zip
    [Info] Successfully compressed Event Logs!
    [Info] Removing Temporary Event Logs...
    [Info] Removed Temporary Event Logs!

PARAMETER: -EventLogs "System,Security" -BackupDestination "C:\Temp\EventLogs\" -StartDate "2023-04-15" -EndDate "2023-04-15"
    Exports the specified event logs to a specified location in a compressed zip file.
    The event logs can be exported from a specific date range.
.EXAMPLE
    -EventLogs "System,Security" -BackupDestination "C:\Temp\EventLogs\" -StartDate "2023-04-15" -EndDate "2023-04-15"
    ## EXAMPLE OUTPUT WITH StartDate and EndDate ##
    [Info] Today is 2023-04-17
    [Info] EventLogs are System,Security
    [Info] Backup Destination is C:\Temp\EventLogs\
    [Info] Start Date is 2023-04-15
    [Info] End Date is 2023-04-16
    [Info] Exporting Event Logs...
    [Info] Exported Event Logs to C:\Temp\EventLogs\System.evtx
    [Info] Exported Event Logs to C:\Temp\EventLogs\Security.evtx
    [Info] Successfully exported Event Logs!
    [Info] Compressing Event Logs...
    [Info] Compressed Event Logs to C:\Temp\EventLogs\Backup-System-Security-2023-04-17.zip
    [Info] Successfully compressed Event Logs!
    [Info] Removing Temporary Event Logs...
    [Info] Removed Temporary Event Logs!
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [String]$EventLogs,
    [String]$BackupDestination,
    [DateTime]$StartDate,
    [DateTime]$EndDate
)

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}
process {
    if (-not (Test-IsElevated)) {
        Write-Host "[Error] Access Denied. Please run with Administrator privileges."
        exit 1
    }
    if ($env:eventLogs -and $env:eventLogs -notlike "null") {
        $EventLogs = $env:eventLogs
    }
    
    $EventLogNames = $EventLogs -split "," | ForEach-Object { $_.Trim() }
    if ($env:backupDestination -and $env:backupDestination -notlike "null") {
        $BackupDestination = $env:backupDestination
    }
    if ($env:startDate -and $env:startDate -notlike "null") {
        $StartDate = $env:startDate
    }
    if ($env:endDate -and $env:endDate -notlike "null") {
        $EndDate = $env:endDate
    }

    # Validate StartDate and EndDate
    if ($StartDate) {
        try {
            $StartDate = Get-Date -Date $StartDate -ErrorAction Stop
        }
        catch {
            Write-Host "[Error] The specified start date is not a valid date."
            exit 1
        }
    }
    if ($EndDate) {
        try {
            $EndDate = Get-Date -Date $EndDate -ErrorAction Stop
        }
        catch {
            Write-Host "[Error] The specified end date is not a valid date."
            exit 1
        }
    }
    # Validate BackupDestination is a valid path to a folder
    if ($(Test-Path -Path $BackupDestination -PathType Container -ErrorAction SilentlyContinue)) {
        $BackupDestination = Get-Item -Path $BackupDestination
    }
    else {
        try {
            $BackupDestination = New-Item -Path $BackupDestination -ItemType Directory -ErrorAction Stop
        }
        catch {
            Write-Host "[Error] The specified backup destination is not a valid path to a folder."
            exit 1
        }
    }

    Write-Host "[Info] Today is $(Get-Date -Format yyyy-MM-dd-HH-mm)"

    # Validate EventLogs are valid event logs
    if (
        $(
            wevtutil.exe el | ForEach-Object {
                if ($EventLogNames -and $($EventLogNames -contains $_ -or $EventLogNames -like $_)) { $_ }
            }
        ).Count -eq 0
    ) {
        Write-Host "[Error] No Event Logs matching: $EventLogNames"
    }

    Write-Host "[Info] EventLogs are $EventLogNames"
    if ($EventLogNames -and $EventLogNames.Count -gt 0) {
        Write-Host "[Info] Backup Destination is $BackupDestination"

        # If the start date is specified, check if it's a valid date
        if ($StartDate) {
            try {
                $StartDate = $(Get-Date -Date $StartDate).ToUniversalTime()
            }
            catch {
                Write-Host "[Error] The specified start date is not a valid date."
                exit 1
            }
            Write-Host "[Info] Start Date is $(Get-Date -Date $StartDate -Format yyyy-MM-dd-HH-mm)"
        }
        else {
            Write-Host "[Info] Start Date is null"
        }
        if ($EndDate) {
            try {
                $EndDate = $(Get-Date -Date $EndDate).ToUniversalTime()
            }
            catch {
                Write-Host "[Error] The specified end date is not a valid date."
                exit 1
            }
            Write-Host "[Info] End Date is $(Get-Date -Date $EndDate -Format yyyy-MM-dd-HH-mm)"
        }
        else {
            Write-Host "[Info] End Date is null"
        }

        # Check if the start date after the end date
        if ($StartDate -and $EndDate -and $StartDate -gt $EndDate) {
            # Flip the dates if the start date is after the end date
            $OldEndDate = $EndDate
            $OldStartDate = $StartDate
            $EndDate = $OldStartDate
            $StartDate = $OldEndDate
            Write-Host "[Info] Start Date is after the end date. Flipping dates."
        }

        Write-Host "[Info] Exporting Event Logs..."
        foreach ($EventLog in $EventLogNames) {
            $EventLogPath = $(Join-Path -Path $BackupDestination -ChildPath "$EventLog.evtx")
            try {
                if ($StartDate -and $EndDate) {
                    wevtutil.exe epl "$EventLog" "$EventLogPath" /ow:true /query:"*[System[TimeCreated[@SystemTime>='$(Get-Date -Date $StartDate -UFormat "%Y-%m-%dT%H:%M:%S")' and @SystemTime<='$(Get-Date -Date $EndDate -UFormat "%Y-%m-%dT%H:%M:%S")']]]" 2>$null
                }
                elseif ($StartDate) {
                    wevtutil.exe epl "$EventLog" "$EventLogPath" /ow:true /query:"*[System[TimeCreated[@SystemTime>='$(Get-Date -Date $StartDate -UFormat "%Y-%m-%dT%H:%M:%S")']]]" 2>$null
                }
                elseif ($EndDate) {
                    wevtutil.exe epl "$EventLog" "$EventLogPath" /ow:true /query:"*[System[TimeCreated[@SystemTime<='$(Get-Date -Date $EndDate -UFormat "%Y-%m-%dT%H:%M:%S")']]]" 2>$null
                }
                else {
                    wevtutil.exe epl "$EventLog" "$EventLogPath" /ow:true /query:"*[System[TimeCreated[@SystemTime>='1970-01-01T00:00:00']]]" 2>$null
                }
                if ($(Test-Path -Path $EventLogPath -ErrorAction SilentlyContinue)) {
                    # Get the number of events in the log
                    $EventCount = $(Get-WinEvent -Path $EventLogPath -ErrorAction SilentlyContinue).Count
                    if ($EventCount -and $EventCount -gt 0) {
                        Write-Host "[Info] Found $EventCount events from $EventLog"
                    }
                    else {
                        Write-Host "[Warn] No events found in $EventLog"
                        continue
                    }
                    Write-Host "[Info] Exported Event Logs to $EventLogPath"
                }
                else {
                    throw
                }
            }
            catch {
                Write-Host "[Error] Failed to export event logs $EventLog"
                continue
            }
        }

        Write-Host "[Info] Compressing Event Logs..."

        # Get the event log paths that where created
        $JoinedPaths = foreach ($EventLog in $EventLogNames) {
            # Join the Backup Destination and the Event Log Name
            $JoinedPath = Join-Path -Path $BackupDestination -ChildPath "$EventLog.evtx" -ErrorAction SilentlyContinue
            if ($(Test-Path -Path $JoinedPath -ErrorAction SilentlyContinue)) {
                # Get the saved event log path
                Get-Item -Path $JoinedPath -ErrorAction SilentlyContinue
            }
        }
        $JoinedPaths = $JoinedPaths | Where-Object { $(Test-Path -Path $_ -ErrorAction SilentlyContinue) }

        try {
            # Create a destination path to save the compressed file to
            # <Folder>Backup-<EventLogName-EventLogName>-<Date>.zip
            $Destination = Join-Path -Path $($BackupDestination) -ChildPath $(
                @(
                    "Backup-",
                    $($EventLogNames -join '-'),
                    "-",
                    $(Get-Date -Format yyyy-MM-dd-HH-mm),
                    ".zip"
                ) -join ''
            )

            $CompressArchiveSplat = @{
                Path            = $JoinedPaths
                DestinationPath = $Destination
                Update          = $true
            }

            # # If the destination path already exists, update the archive instead of creating a new one
            # if ($(Test-Path -Path $Destination -ErrorAction SilentlyContinue)) {
            #     $CompressArchiveSplat.Add("Update", $true)
            # }

            # Compress the Event Logs
            $CompressError = $true
            $ErrorCount = 0
            $SecondsToSleep = 1
            $TimeOut = 120
            while ($CompressError) {
                try {
                    $CompressError = $false
                    Compress-Archive @CompressArchiveSplat -ErrorAction Stop
                    break
                }
                catch {
                    $CompressError = $true
                }

                if ($CompressError) {
                    if ($ErrorCount -gt $TimeOut) {
                        Write-Host "[Warn] Skipping compression... Timed out."
                    }
                    if ($ErrorCount -eq 0) {
                        Write-Host "[Info] Waiting for wevtutil.exe to close file."
                    }
                    Start-Sleep -Seconds $SecondsToSleep
                }
                $ErrorCount++
            }
            if ($CompressError) {
                Write-Host "[Error] Failed to Compress Event Logs."
            }
            else {
                Write-Host "[Info] Compressed Event Logs to $($Destination)"
            }
        }
        catch {
            Write-Host "[Error] Failed to compress event logs."
        }

        if ($(Test-Path -Path $Destination -ErrorAction SilentlyContinue)) {
            Write-Host "[Info] Removing Temporary Event Logs..."
            foreach ($EventLogPath in $JoinedPaths) {
                try {
                    Remove-Item -Path $EventLogPath -Force -ErrorAction SilentlyContinue
                    Write-Host "[Info] Removed Temporary Event Logs: $EventLogPath"
                }
                catch {}
            }
        }
        else {
            Write-Host "[Info] Renaming Event Logs..."
            foreach ($EventLogPath in $JoinedPaths) {
                if ($(Test-Path -Path $EventLogPath -ErrorAction SilentlyContinue)) {
                    try {
                        $NewPath = Rename-Item -Path $EventLogPath -NewName "$($EventLogPath.BaseName)-$(Get-Date -Format yyyy-MM-dd-HH-mm).evtx" -PassThru -ErrorAction Stop
                        Write-Host "[Info] Event Logs saved to: $NewPath"
                    }
                    catch {
                        Write-Host "[Info] Event Logs saved to: $EventLogPath"
                    }
                }
                else {
                    Write-Host "[Info] Event Logs saved to: $EventLogPath"
                }
            }
        }
    }
    else {
        Write-Host "[Error] No Event Logs were specified."
        exit 1
    }
}
end {
    
    
    
}