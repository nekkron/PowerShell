#Requires -Version 2.0

<#
.SYNOPSIS
    Alert on drive(s) that fall below a specified % or size. Distinguishes between System and Data drives.
.DESCRIPTION
    Alert on drive(s) that fall below a specified % or size. Distinguishes between System and Data drives.
    The system drive is the drive(s) that are used to boot the OS.
.EXAMPLE
     -SystemDriveMinFreePercent 10 -SystemDriveMinFreeBytes 10GB -DataDriveMinFreePercent 20 -DataDriveMinFreeBytes 20GB
    This checks all Drives for at least 10% free or 10GB free for the System Drive and 20% free or 20GB free for all other drives.
.EXAMPLE
    -ExcludeDrivesByName "NoMonitor"
    Will exclude drives that contain the text "NoMonitor" in the volume name.
.EXAMPLE
     -ExcludeDrives "C,Z"
     -ExcludeDrives "CZ"
    This checks all Drives, except for C: and Z:.
.EXAMPLE
     -SystemDriveMinFreePercentCustomField "SystemDriveMinFreePercent" -SystemDriveMinFreeBytes "SystemDriveMinFreeBytes" -DataDriveMinFreePercent "DataDriveMinFreePercent" -DataDriveMinFreeBytes "DataDriveMinFreeBytes"
    Use this if you wish to to custom fields to specify the values from roles or globally.
    This will pull the values from custom fields that would have otherwise been used from parameters.
.EXAMPLE
     -ExcludeDrivesByNameCustomField "NoMonitor" -SystemDriveMinFreePercentCustomField "SystemDriveMinFreePercent" -SystemDriveMinFreeBytes "SystemDriveMinFreeBytes" -DataDriveMinFreePercent "DataDriveMinFreePercent" -DataDriveMinFreeBytes "DataDriveMinFreeBytes"
    This checks all Drives, except where a drive name/label contains the text "NoMonitor".
    Use this if you wish to to custom fields to specify the values from roles or globally.
    This will pull the values from custom fields that would have otherwise been used from parameters.
.EXAMPLE
     No Parameters Specified
    This checks all Drives with the defaults:
        SystemDriveMinFreePercent   10%
        SystemDriveMinFreeBytes     10GB
        DataDriveMinFreePercent 20%
        DataDriveMinFreeBytes   20GB
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 8, Windows Server 2012 R2
    Release Notes: Updated Calculated Name
#>

[CmdletBinding()]
param (
    [Parameter()]
    $SystemDriveMinFreePercent,
    $SystemDriveMinFreeBytes,
    $DataDriveMinFreePercent,
    $DataDriveMinFreeBytes,
    [String] $ExcludeDrives,
    [String] $ExcludeDrivesCustomField, # If set, get value from a custom field with this name.
    [String] $ExcludeDrivesByName,
    [String] $ExcludeDrivesByNameCustomField, # If set, get value from a custom field with this name.
    [String] $SystemDriveMinFreePercentCustomField, # If set, get value from a custom field with this name.
    [String] $SystemDriveMinFreeBytesCustomField, # If set, get value from a custom field with this name.
    [String] $DataDriveMinFreePercentCustomField, # If set, get value from a custom field with this name.
    [String] $DataDriveMinFreeBytesCustomField # If set, get value from a custom field with this name.
)

begin {
    if ($env:getSystemDriveMinimumSizeInPercentFromCustomField -and $env:getSystemDriveMinimumSizeInPercentFromCustomField -notlike "null") {
        $SystemDriveMinFreePercentCustomField = $env:getSystemDriveMinimumSizeInPercentFromCustomField
    }
    if ($env:getSystemDriveMinimumSizeInBytesFromCustomField -and $env:getSystemDriveMinimumSizeInBytesFromCustomField -notlike "null") {
        $SystemDriveMinFreeBytesCustomField = $env:getSystemDriveMinimumSizeInBytesFromCustomField
    }
    if ($env:getDataDriveMinimumSizeInPercentFromCustomField -and $env:getDataDriveMinimumSizeInPercentFromCustomField -notlike "null") {
        $DataDriveMinFreePercentCustomField = $env:getDataDriveMinimumSizeInPercentFromCustomField
    }
    if ($env:getDataDriveMinimumSizeInBytesFromCustomField -and $env:getDataDriveMinimumSizeInBytesFromCustomField -notlike "null") {
        $DataDriveMinFreeBytesCustomField = $env:getDataDriveMinimumSizeInBytesFromCustomField
    }
    if ($env:systemDriveMinimumSizeInPercent -and $env:systemDriveMinimumSizeInPercent -notlike "null") {
        $SystemDriveMinFreePercent = $env:systemDriveMinimumSizeInPercent
    }
    if ($env:systemDriveMinimumSizeInBytes -and $env:systemDriveMinimumSizeInBytes -notlike "null") {
        $SystemDriveMinFreeBytes = $env:systemDriveMinimumSizeInBytes
    }
    if ($env:dataDriveMinimumSizeInPercent -and $env:dataDriveMinimumSizeInPercent -notlike "null") {
        $DataDriveMinFreePercent = $env:dataDriveMinimumSizeInPercent
    }
    if ($env:dataDriveMinimumSizeInBytes -and $env:dataDriveMinimumSizeInBytes -notlike "null") {
        $DataDriveMinFreeBytes = $env:dataDriveMinimumSizeInBytes
    }
    if ($env:excludeDrives -and $env:excludeDrives -notlike 'null') {
        $ExcludeDrives = $env:excludeDrives
    }
    if ($env:excludeDrivesByName -and $env:excludeDrivesByName -notlike 'null') {
        $ExcludeDrivesByName = $env:excludeDrivesByName
    }
    if ($env:excludeDrivesCustomField -and $env:excludeDrivesCustomField -notlike 'null') {
        $ExcludeDrivesCustomField = $env:excludeDrivesCustomField
    }
    if ($env:excludeDrivesByNameCustomField -and $env:excludeDrivesByNameCustomField -notlike 'null') {
        $ExcludeDrivesByNameCustomField = $env:excludeDrivesByNameCustomField
    }
    function Get-NinjaProperty {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            [String]$Name,
            [Parameter()]
            [String]$Type,
            [Parameter()]
            [String]$DocumentName
        )
    
        if ($PSVersionTable.PSVersion.Major -lt 3) {
            throw "PowerShell 3.0 or higher is required to retrieve data from custom fields. https://ninjarmm.zendesk.com/hc/en-us/articles/4405408656013"
        }
    
        # If we're requested to get the field value from a Ninja document we'll specify it here.
        $DocumentationParams = @{}
        if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }
    
        # These two types require more information to parse.
        $NeedsOptions = "DropDown", "MultiSelect"
    
        # Grabbing document values requires a slightly different command.
        if ($DocumentName) {
            # Secure fields are only readable when they're a device custom field
            if ($Type -Like "Secure") { throw "$Type is an invalid type! Please check here for valid types. https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality" }
    
            # We'll redirect the error output to the success stream to make it easier to error out if nothing was found or something else went wrong.
            Write-Host "Retrieving value from Ninja Document..."
            $NinjaPropertyValue = Ninja-Property-Docs-Get -AttributeName $Name @DocumentationParams 2>&1
    
            # Certain fields require more information to parse.
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Docs-Options -AttributeName $Name @DocumentationParams 2>&1
            }
        }
        else {
            # We'll redirect error output to the success stream to make it easier to error out if nothing was found or something else went wrong.
            $NinjaPropertyValue = Ninja-Property-Get -Name $Name 2>&1
    
            # Certain fields require more information to parse.
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Options -Name $Name 2>&1
            }
        }
    
        # If we received some sort of error it should have an exception property and we'll exit the function with that error information.
        if ($NinjaPropertyValue.Exception) { throw $NinjaPropertyValue }
        if ($NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }
    
        # This switch will compare the type given with the quoted string. If it matches, it'll parse it further; otherwise, the default option will be selected.
        switch ($Type) {
            "Attachment" {
                # Attachments come in a JSON format this will convert it into a PowerShell Object.
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Checkbox" {
                # Checkbox's come in as a string representing an integer. We'll need to cast that string into an integer and then convert it to a more traditional boolean.
                [System.Convert]::ToBoolean([int]$NinjaPropertyValue)
            }
            "Date or Date Time" {
                # In Ninja Date and Date/Time fields are in Unix Epoch time in the UTC timezone the below should convert it into local time as a date time object.
                $UnixTimeStamp = $NinjaPropertyValue
                $UTC = (Get-Date "1970-01-01 00:00:00").AddSeconds($UnixTimeStamp)
                $TimeZone = [TimeZoneInfo]::Local
                [TimeZoneInfo]::ConvertTimeFromUtc($UTC, $TimeZone)
            }
            "Decimal" {
                # In ninja decimals are strings that represent a decimal this will cast it into a double data type.
                [double]$NinjaPropertyValue
            }
            "Device Dropdown" {
                # Device Drop-Downs Fields come in a JSON format this will convert it into a PowerShell Object.
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Device MultiSelect" {
                # Device Multi-Select Fields come in a JSON format this will convert it into a PowerShell Object.
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Dropdown" {
                # Drop-Down custom fields come in as a comma-separated list of GUIDs; we'll compare these with all the options and return just the option values selected instead of a GUID.
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Options | Where-Object { $_.GUID -eq $NinjaPropertyValue } | Select-Object -ExpandProperty Name
            }
            "Integer" {
                # Cast's the Ninja provided string into an integer.
                [int]$NinjaPropertyValue
            }
            "MultiSelect" {
                # Multi-Select custom fields come in as a comma-separated list of GUID's we'll compare these with all the options and return just the option values selected instead of a guid.
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = ($NinjaPropertyValue -split ',').trim()
    
                foreach ($Item in $Selection) {
                    $Options | Where-Object { $_.GUID -eq $Item } | Select-Object -ExpandProperty Name
                }
            }
            "Organization Dropdown" {
                # Turns the Ninja provided JSON into a PowerShell Object.
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Organization Location Dropdown" {
                # Turns the Ninja provided JSON into a PowerShell Object.
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Organization Location MultiSelect" {
                # Turns the Ninja provided JSON into a PowerShell Object.
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Organization MultiSelect" {
                # Turns the Ninja provided JSON into a PowerShell Object.
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Time" {
                # Time fields are given as a number of seconds starting from midnight. This will convert it into a date time object.
                $Seconds = $NinjaPropertyValue
                $UTC = ([TimeSpan]::FromSeconds($Seconds)).ToString("hh\:mm\:ss")
                $TimeZone = [TimeZoneInfo]::Local
                $ConvertedTime = [TimeZoneInfo]::ConvertTimeFromUtc($UTC, $TimeZone)
    
                Get-Date $ConvertedTime -DisplayHint Time
            }
            default {
                # If no type was given or not one that matches the above types just output what we retrieved.
                $NinjaPropertyValue
            }
        }
    }
    function Get-Size {
        param (
            [string]$String
        )
        switch -wildcard ($String) {
            '*PB' { [int64]$($String -replace '[^\d+]+') * 1PB; break }
            '*TB' { [int64]$($String -replace '[^\d+]+') * 1TB; break }
            '*GB' { [int64]$($String -replace '[^\d+]+') * 1GB; break }
            '*MB' { [int64]$($String -replace '[^\d+]+') * 1MB; break }
            '*KB' { [int64]$($String -replace '[^\d+]+') * 1KB; break }
            '*B' { [int64]$($String -replace '[^\d+]+') * 1; break }
            '*Bytes' { [int64]$($String -replace '[^\d+]+') * 1; break }
            Default { [int64]$($String -replace '[^\d+]+') * 1 }
        }
    }
    function Get-FriendlySize {
        param($Bytes)
        # Converts Bytes to the highest matching unit
        $Sizes = 'Bytes,KB,MB,GB,TB,PB,EB,ZB' -split ','
        for ($i = 0; ($Bytes -ge 1kb) -and ($i -lt $Sizes.Count); $i++) { $Bytes /= 1kb }
        $N = 2
        if ($i -eq 0) { $N = 0 }
        if ($Bytes) { "$([System.Math]::Round($Bytes,$N)) $($Sizes[$i])" }else { "0 B" }
    }
}
process {
    if (
        $null -eq $SystemDriveMinFreePercent -and
        $null -eq $SystemDriveMinFreeBytes -and
        $null -eq $DataDriveMinFreePercent -and
        $null -eq $DataDriveMinFreeBytes -and
        $null -eq $SystemDriveMinFreePercentCustomField -and
        $null -eq $SystemDriveMinFreeBytesCustomField -and
        $null -eq $DataDriveMinFreePercentCustomField -and
        $null -eq $DataDriveMinFreeBytesCustomField
    ) {
        Write-Host "[Error] Missing a threshold option."
        Write-Host "Set one of the following:"
        Write-Host " System Drive Minimum Size in Percent"
        Write-Host " System Drive Minimum Size in Bytes"
        Write-Host " Data Drive Minimum Size in Percent"
        Write-Host " Data Drive Minimum Size in Bytes"
        Write-Host " System Drive Minimum Size in Percent Custom Field"
        Write-Host " System Drive Minimum Size in Bytes Custom Field"
        Write-Host " Data Drive Minimum Size in Percent Custom Field"
        Write-Host " Data Drive Minimum Size in Bytes Custom Field"
        
        exit 1
    }
    # Get values from custom field
    if ($SystemDriveMinFreePercentCustomField) {
        # Store in temp variable
        try {
            $SystemDriveMinFreePercent = Get-NinjaProperty -Name $SystemDriveMinFreePercentCustomField
            if ([String]::IsNullOrWhiteSpace($SystemDriveMinFreePercent)) {
                Write-Host "[Error] Custom Field is empty."
                throw
            }
        }
        catch {
            Write-Host "[Error] Could not get Custom Field ($SystemDriveMinFreePercentCustomField)."
            exit 1
        }
    }
    if ($SystemDriveMinFreeBytesCustomField) {
        # Store in temp variable
        try {
            $SystemDriveMinFreeBytes = Get-NinjaProperty -Name $SystemDriveMinFreeBytesCustomField
            if ([String]::IsNullOrWhiteSpace($SystemDriveMinFreeBytes)) {
                Write-Host "[Error] Custom Field is empty."
                throw
            }
        }
        catch {
            Write-Host "[Error] Could not get Custom Field ($SystemDriveMinFreeBytesCustomField)."
            exit 1
        }
    }
    if ($DataDriveMinFreePercentCustomField) {
        # Store in temp variable
        try {
            $DataDriveMinFreePercent = "$(Get-NinjaProperty -Name $DataDriveMinFreePercentCustomField)" -replace '%'
            if ([String]::IsNullOrWhiteSpace($DataDriveMinFreePercent)) {
                Write-Host "[Error] Custom Field is empty."
                throw
            }
        }
        catch {
            Write-Host "[Error] Could not get Custom Field ($DataDriveMinFreePercentCustomField)."
            exit 1
        }
    }
    if ($DataDriveMinFreeBytesCustomField) {
        # Store in temp variable
        try {
            $DataDriveMinFreeBytes = "$(Get-NinjaProperty -Name $DataDriveMinFreeBytesCustomField)" -replace '%'
            if ([String]::IsNullOrWhiteSpace($DataDriveMinFreeBytes)) {
                Write-Host "[Error] Custom Field is empty."
                throw
            }
        }
        catch {
            Write-Host "[Error] Could not get Custom Field ($DataDriveMinFreeBytesCustomField)."
            exit 1
        }
    }
    # Remove % from string
    $SystemDriveMinFreePercent = "$SystemDriveMinFreePercent" -replace '%'
    $DataDriveMinFreePercent = "$DataDriveMinFreePercent" -replace '%'
    # Check that Parameters or Script Variables are valid
    if (
        ($env:systemDriveMinimumSizeInBytes -and $(Get-Size -String $env:systemDriveMinimumSizeInBytes) -notmatch '\d+') -or
        ($env:dataDriveMinimumSizeInBytes -and $(Get-Size -String $env:dataDriveMinimumSizeInBytes) -notmatch '\d+') -or
        ($SystemDriveMinFreeBytes -and $(Get-Size -String $SystemDriveMinFreeBytes) -notmatch '\d+') -or
        ($DataDriveMinFreeBytes -and $(Get-Size -String $DataDriveMinFreeBytes) -notmatch '\d+')
    ) {
        Write-Host "[Error] One of the Minimum Size in Bytes parameters is not formatted correctly."
        exit 1
    }
    # Check that Parameters or Script Variables are valid
    if (
        ($env:systemDriveMinimumSizeInPercent -and $env:systemDriveMinimumSizeInPercent -notmatch '\d+|\d+%') -or
        ($env:dataDriveMinimumSizeInPercent -and $env:dataDriveMinimumSizeInPercent -notmatch '\d+|\d+%') -or
        ($SystemDriveMinFreePercent -and $SystemDriveMinFreePercent -notmatch '\d+') -or
        ($DataDriveMinFreePercent -and $DataDriveMinFreePercent -notmatch '\d+')
    ) {
        Write-Host "[Error] One of the Minimum Size in Percent parameters is not formatted correctly."
        exit 1
    }
    # Convert SystemDriveMinFreeBytes to an int64
    [int64]$SystemDriveMinFreeBytes = if ($SystemDriveMinFreeBytes -is [string]) {
        Get-Size -String $SystemDriveMinFreeBytes
    }
    elseif ($SystemDriveMinFreeBytes -is [int] -or $SystemDriveMinFreeBytes -is [long] -or $SystemDriveMinFreeBytes -is [float] -or $SystemDriveMinFreeBytes -is [double]) {
        $SystemDriveMinFreeBytes
    }
    else {
        0
    }
    # Convert DataDriveMinFreeBytes to an int64
    [int64]$DataDriveMinFreeBytes = if ($DataDriveMinFreeBytes -is [string]) {
        Get-Size -String $DataDriveMinFreeBytes
    }
    elseif ($DataDriveMinFreeBytes -is [int] -or $DataDriveMinFreeBytes -is [long] -or $DataDriveMinFreeBytes -is [float] -or $DataDriveMinFreeBytes -is [double]) {
        $DataDriveMinFreeBytes
    }
    else {
        0
    }

    if ($ExcludeDrivesCustomField) {
        try {
            $ExcludeDrives = Get-NinjaProperty -Name $ExcludeDrivesCustomField
            if ([String]::IsNullOrWhiteSpace($ExcludeDrives)) {
                Write-Host "[Error] Custom Field is empty."
                throw
            }
        }
        catch {
            Write-Host "[Error] Could not get Custom Field ($ExcludeDrivesCustomField)."
            exit 1
        }
    }
    if ($ExcludeDrivesByNameCustomField) {
        try {
            $ExcludeDrivesByName = Get-NinjaProperty -Name $ExcludeDrivesByNameCustomField
            if ([String]::IsNullOrWhiteSpace($ExcludeDrivesByName)) {
                Write-Host "[Error] Custom Field is empty."
                throw
            }
        }
        catch {
            Write-Host "[Error] Could not get Custom Field ($ExcludeDrivesByNameCustomField)."
            exit 1
        }
    }

    # Split strings and clean up the results
    # Replace comma and split by individual characters
    $ExcludeDrives = $ExcludeDrives -replace ',' -split '' | Sort-Object -Unique | Select-Object -Skip 1 | ForEach-Object { "$_".Trim() }
    # Split by comma and trim spaces from around the strings
    $ExcludeDrivesByName = $ExcludeDrivesByName -split ',' | ForEach-Object { "$_".Trim() }

    # Find System drive running Windows
    $SystemRoot = $(Get-Item -Path $env:SystemRoot | Split-Path -Parent) -replace ':\\'
    # Get Drives that have data
    $Drives = Get-PSDrive | Where-Object { $_.Used -and $_.Free }
    # Exclude drives based on drive letter
    if ($ExcludeDrives) {
        $Drives = $Drives | Where-Object {
            $ExcludeDrives -notlike "*$($_.Name)*"
        }
    }
    # Exclude drives based on drive label
    if ($ExcludeDrivesByName) {
        $Drives = $Drives | Where-Object {
            $_.Description -notin $ExcludeDrivesByName
        }
    }
    # Exit if no drives found
    if ($Drives.Count -eq 0) {
        Write-Host "No drives found."
        exit 0
    }
    $SystemDrive = $Drives | Where-Object { $_.Name -like $SystemRoot }
    $DataDrives = $Drives | Where-Object { $_.Name -notlike $SystemRoot -and $SystemDrive.Name -notlike $_.Name -and $_.Used }

    $Results = $(
        $SystemDrive | ForEach-Object {
            $Drive = $_
            Write-Host "[Info] ($($Drive.Name)) currently has $(Get-FriendlySize -Bytes $Drive.Free) free at $([System.Math]::Round($Drive.Free / $($Drive.Free+$Drive.Used) * 100,0))%."
            if (
                $(Get-Size -String $SystemDriveMinFreeBytes) -gt 0 -and 
                $Drive.Free -lt $(Get-Size -String $SystemDriveMinFreeBytes)
            ) {
                Write-Output "[Warn] $Type ($($Drive.Name)) free space is under $(Get-FriendlySize -Bytes $(Get-Size -String $SystemDriveMinFreeBytes)) threshold."
            }

            if (
                $SystemDriveMinFreePercent -gt 0 -and 
                $($Drive.Free + $Drive.Used) -and $($Drive.Free / $($Drive.Free + $Drive.Used) * 100) -lt $SystemDriveMinFreePercent
            ) {
                Write-Output "[Warn] $Type ($($Drive.Name)) free space is under $($SystemDriveMinFreePercent)% threshold."
            }
        }
        $DataDrives | ForEach-Object {
            $Drive = $_
            Write-Host "[Info] ($($Drive.Name)) currently has $(Get-FriendlySize -Bytes $Drive.Free) free at $([System.Math]::Round($Drive.Free / $($Drive.Free+$Drive.Used) * 100,0))%."
            if (
                $DataDriveMinFreeBytes -gt 0 -and 
                $Drive.Free -lt $DataDriveMinFreeBytes
            ) {
                Write-Output "[Warn] $Type ($($Drive.Name)) free space is under $(Get-FriendlySize -Bytes $DataDriveMinFreeBytes) threshold."
            }

            if (
                $DataDriveMinFreePercent -gt 0 -and 
                $($Drive.Free + $Drive.Used) -and $($Drive.Free / $($Drive.Free + $Drive.Used) * 100) -lt $DataDriveMinFreePercent
            ) {
                Write-Output "[Warn] $Type ($($Drive.Name)) free space is under $($DataDriveMinFreePercent)% threshold."
            }
        }
    )

    if ($Results) {
        $Results | Out-String | Write-Host
    }
    else {
        Write-Output "[Info] No drives found with low free space."
    }
    exit 0
}
end {
    
    
    
}
