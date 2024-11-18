#Requires -Version 5.1

<#
.SYNOPSIS
    This will get the current status of AD Replication and alert if it's abnormal, as well as provide some diagnostic info.
.DESCRIPTION
    This will get the current status of AD Replication and alert if it's abnormal, as well as provide some diagnostic info.

.EXAMPLE 
    (No Parameters)

    WARNING: Replication has failed 100 or more times. See Diagnostic Info for more details
 
    ### Diagnostic Info ###

    Repadmin: running command /showrepl against full DC localhost
    Default-First-Site-Name\SRV19-TEST
    DSA Options: IS_GC 
    Site Options: (none)
    DSA object GUID: ffe29454-2a68-4ba8-a877-d5a49b382d16
    DSA invocationID: ffe29454-2a68-4ba8-a877-d5a49b382d16

PARAMETER: -ErrorCount "99999999999999"
    The number of errors until AD Replication is considered unhealthy.
.EXAMPLE
    -ErrorCount "99999999999999"

    AD Replication appears to be healthy. Please check below to confirm.

    Destination DSA Last Success Time   Failures Naming Context                           
    --------------- -----------------   -------- --------------                           
    SRV19-TEST      2023-04-17 17:12:45 179      DC=test,DC=lan                           
    SRV19-TEST      2023-04-17 16:51:45 21       CN=Configuration,DC=test,DC=lan          
    SRV19-TEST      2023-04-17 16:51:45 21       CN=Schema,CN=Configuration,DC=test,DC=lan
    SRV19-TEST      2023-04-17 17:06:18 22       DC=DomainDnsZones,DC=test,DC=lan         
    SRV19-TEST      2023-04-17 17:06:15 22       DC=ForestDnsZones,DC=test,DC=lan 

PARAMETER: -EventLogStart "48"
    Time in hours to search through event logs for possible issues.
.EXAMPLE
    -EventLogStart "48"

    DsBindWithCred to localhost failed with status 5
    WARNING: Directory Service Log Event ID 1864 shows failure to replicate in > 1 week
 

    TimeCreated           Id LogName           Level Message                                                    
    -----------           -- -------           ----- -------                                                    
    7/2/2028 8:34:33 AM 1864 Directory Service Error This is the replication status for the following directo...
    7/2/2028 8:34:33 AM 1864 Directory Service Error This is the replication status for the following directo...

PARAMETER: -ErrorCustomField "ReplaceMeWithAnyIntegerCustomField"
    Name of an integer custom field that contains your desired ErrorCount threshold.
    ex. "AllowedADerrors" where you have entered in your desired ErrorCount limit in the "AllowedADerrors" custom field rather than in a parameter.
PARAMETER: -EventLogCustomField "ReplaceMeWithAnyIntegerCustomField"
    Name of an integer custom field that contains your desired EventLogStart threshold.
    ex. "ADeventsAgeLimit" where you have entered in your desired EventLogStart limit in the "ADeventsAgeLimit" custom field rather than in a parameter.
.EXAMPLE
    -ErrorCustomField "ReplaceMeWithAnyIntegerCustomField" -EventLogCustomField "ReplaceMeWithAnyIntegerCustomField"
    
    DsBindWithCred to localhost failed with status 5
    WARNING: Directory Service Log Event ID 1864 shows failure to replicate in > 1 week

    TimeCreated           Id LogName           Level Message                                                    
    -----------           -- -------           ----- -------                                                    
    7/2/2028 8:34:33 AM 1864 Directory Service Error This is the replication status for the following directo...
    7/2/2028 8:34:33 AM 1864 Directory Service Error This is the replication status for the following directo...

PARAMETER:  -ExportCSV "ReplaceMeWithAnyMultiLineCustomField"
    Name of a multi-line customfield you'd like to export the results to (in csv format).
.EXAMPLE
    -ExportCSV "ReplaceMeWithAnyMultiLineCustomField"
    
    DsBindWithCred to localhost failed with status 5
    WARNING: Directory Service Log Event ID 1864 shows failure to replicate in > 1 week

    TimeCreated           Id LogName           Level Message                                                    
    -----------           -- -------           ----- -------                                                    
    7/2/2028 8:34:33 AM 1864 Directory Service Error This is the replication status for the following directo...
    7/2/2028 8:34:33 AM 1864 Directory Service Error This is the replication status for the following directo...
    
PARAMETER: -ExportTXT "ReplaceMeWithAnyMultiLineCustomField"
    Name of a multiline customfield you'd like to export the results to.
.EXAMPLE
    -ExportTXT "ReplaceMeWithAnyMultiLineCustomField"

    DsBindWithCred to localhost failed with status 5
    WARNING: Directory Service Log Event ID 1864 shows failure to replicate in > 1 week
 

    TimeCreated           Id LogName           Level Message                                                    
    -----------           -- -------           ----- -------                                                    
    7/2/2028 8:34:33 AM 1864 Directory Service Error This is the replication status for the following directo...
    7/2/2028 8:34:33 AM 1864 Directory Service Error This is the replication status for the following directo...
.OUTPUTS
    
.NOTES
    Minimum OS Architecture Supported: Server 2016+
    Release Notes: Renamed script and added Script Variable support
#>

[CmdletBinding()]
param (
    [Parameter()]
    [int]$EventLogStart = "24",
    [Parameter()]
    [int]$ErrorCount = "100",
    [Parameter()]
    [String]$EventLogCustomField,
    [Parameter()]
    [String]$ErrorCustomField,
    [Parameter()]
    [String]$ExportCSV,
    [Parameter()]
    [String]$ExportTXT
)
begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    function Test-IsSystem {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
    }

    function Test-IsDomainController {
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem

        if ($OS.ProductType -eq "2") {
            return $true
        }
    }

    if (!(Test-IsElevated) -and !(Test-IsSystem)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    if (!(Test-IsDomainController)) {
        Write-Error "This is not a domain controller. Please run this script on a DC."
        exit 1
    }

    # If script variables are used grab that and replace the static ones.
    if ($env:hoursBackToSearchEventLog -and $env:hoursBackToSearchEventLog -notlike "null") { $EventLogStart = $env:hoursBackToSearchEventLog }
    if ($env:errorCountToAlertOn -and $env:errorCountToAlertOn -notlike "null") { $ErrorCount = $env:errorCountToAlertOn }
    if ($env:retrieveHoursBackFromCustomFieldNamed -and $env:retrieveHoursBackFromCustomFieldNamed -notlike "null") { $EventLogCustomField = $env:retrieveHoursBackFromCustomFieldNamed }
    if ($env:retrieveErrorCountFromCustomFieldNamed -and $env:retrieveErrorCountFromCustomFieldNamed -notlike "null") { $ErrorCustomField = $env:retrieveErrorCountFromCustomFieldNamed }
    if ($env:exportCsvResultsToThisCustomField -and $env:exportCsvResultsToThisCustomField -notlike "null") { $ExportCSV = $env:exportCsvResultsToThisCustomField }
    if ($env:exportTextResultsToThisCustomField -and $env:exportTextResultsToThisCustomField -notlike "null") { $ExportTXT = $env:exportTextResultsToThisCustomField }

    # This function is to make it easier to set Ninja Custom Fields.
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

        # If we're requested to set the field value for a Ninja document we'll specify it here.
        $DocumentationParams = @{}
        if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }

        # This is a list of valid fields we can set. If no type is given we'll assume the input doesn't have to be changed in any way.
        $ValidFields = "Attachment", "Checkbox", "Date", "Date or Date Time", "Decimal", "Dropdown", "Email", "Integer", "IP Address", "MultiLine", "MultiSelect", "Phone", "Secure", "Text", "Time", "URL"
        if ($Type -and $ValidFields -notcontains $Type) { Write-Warning "$Type is an invalid type! Please check here for valid types. https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality" }

        # The below field requires additional information in order to set
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

        # If we received some sort of error it should have an exception property and we'll exit the function with that error information.
        if ($NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }

        # The below type's require values not typically given in order to be set. The below code will convert whatever we're given into a format ninjarmm-cli supports.
        switch ($Type) {
            "Checkbox" {
                # While it's highly likely we were given a value like "True" or a boolean datatype it's better to be safe than sorry.
                $NinjaValue = [System.Convert]::ToBoolean($Value)
            }
            "Date or Date Time" {
                # Ninjarmm-cli is expecting the time to be representing as a Unix Epoch string. So we'll convert what we were given into that format.
                $Date = (Get-Date $Value).ToUniversalTime()
                $TimeSpan = New-TimeSpan (Get-Date "1970-01-01 00:00:00") $Date
                $NinjaValue = $TimeSpan.TotalSeconds
            }
            "Dropdown" {
                # Ninjarmm-cli is expecting the guid of the option we're trying to select. So we'll match up the value we were given with a guid.
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = $Options | Where-Object { $_.Name -eq $Value } | Select-Object -ExpandProperty GUID

                if (-not $Selection) {
                    throw "Value is not present in dropdown"
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

    # Shortened Version from "Example - Get Ninja Property"
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
            "Integer" {
                # Cast's the Ninja provided string into an integer.
                if (-not $NinjaPropertyValue) {
                    throw "CustomField $Name is empty!"
                }
                [int]$NinjaPropertyValue
            }
            default {
                # If no type was given or not one that matches the above types just output what we retrieved.
                $NinjaPropertyValue
            }
        }
    }

    $ExitCode = 0
}process {

    # Grabbing the information from custom fields (if any)
    if ($ErrorCustomField) {
        try {
            $FieldCount = Get-NinjaProperty -Name $ErrorCustomField -Type "Integer"
            if ($FieldCount) { $ErrorCount = $FieldCount }
        }
        catch {
            Write-Error -Message $_.ToString() -Category InvalidOperation -Exception (New-Object System.Exception)
            exit 1
        }
    } 
    if ($EventLogCustomField) {
        try {
            $FieldStart = Get-NinjaProperty -Name $EventLogCustomField -Type "Integer"
            if ($FieldStart) { $EventLogStart = $FieldStart } 
        }
        catch {
            Write-Error -Message $_.ToString() -Category InvalidOperation -Exception (New-Object System.Exception)
            exit 1
        }
    }

    $represult = (repadmin.exe /showrepl /csv | ConvertFrom-Csv)

    if ($ExportCSV) {
        try {
            Set-NinjaProperty -Name $ExportCSV -Value (repadmin.exe /showrepl /csv)
        }
        catch {
            Write-Error -Message $_.ToString() -Category InvalidOperation -Exception (New-Object System.Exception)
            $ExitCode = 1
        }
    }

    if ($ExportTXT) {
        $String = $represult | Format-Table -Property "Destination DSA", "Last Success Time", "Last Failure Status", "Number of Failures", "Naming Context" | Out-String
        try {
            Set-NinjaProperty -Name $ExportTXT -Value $String
        }
        catch {
            Write-Error -Message $_.ToString() -Category InvalidOperation -Exception (New-Object System.Exception)
            $ExitCode = 1
        }
    }

    if ($represult."Number of Failures" -ge $ErrorCount) {
        Write-Warning "Replication has failed $ErrorCount or more times. See Diagnostic Info for more details"

        # The Table version is a bit more to the point but the description gives you more of an idea of what's going wrong than in the non-table version.
        Write-Host '### Diagnostic Info ###'
        repadmin.exe /showrepl /errorsonly
        $represult | Format-Table -Property "Destination DSA", "Last Success Time", @{Name = "Failures"; Expression = { $_."Number of Failures" } }, "Naming Context" | Out-String | Write-Host
        
        Exit 1
    }
    else {
        Write-Host "No errors found in repadmin /showrepl /csv"
    }

    # Check Event Log for replication failure
    $Date = (Get-Date).AddHours(-$EventLogStart)

    $Events = Get-WinEvent -FilterHashtable @{LogName = "Directory Service"; Id = 1864; StartTime = $Date } -ErrorAction SilentlyContinue | 
        Where-Object { ($_.Message -replace "`r`n", " ") -match "More than a week: [1-9]+.*" }

    if ($Events) {
        Write-Warning "Directory Service Log Event ID 1864 shows failure to replicate in > 1 week"
        $Events | Format-Table -Property TimeCreated, Id, LogName, @{Name = "Level"; Expression = { $_.LevelDisplayName } }, Message -AutoSize | Out-String | Write-Host

        Exit 1
    }
    else {
        Write-Host "No bad event viewer events found since $Date."
    }

    # Check if Sysvol is present
    $sysvol = (Get-CimInstance Win32_Share) | Where-Object { $_.name -eq "SYSVOL" }
    if (!($sysvol.Path)) {
        Write-Warning "SYSVOL is Missing!"
        Get-CimInstance Win32_Share | Out-String | Write-Host
        
        Exit 1
    }
    else {
        Write-Host "SYSVOL appears to be present."
    }

    Write-Host "AD Replication appears to be healthy. Please check script output and other sources to confirm."
    $Report = $represult | Format-Table -Property "Destination DSA", "Last Success Time", @{Name = "Failures"; Expression = { $_."Number of Failures" } }, "Naming Context" | Out-String
    
    if ($Report) {
        $Report | Write-Host
    }

    exit $ExitCode

}end {
    
    
    
}
