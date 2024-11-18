#Requires -Version 5.1

<#
.SYNOPSIS
    Generates a report for the number of active users in active directory that have logged in the specified time frame.
.DESCRIPTION
    Generates a report for the number of active users in active directory that have logged in the specified time frame.

.EXAMPLE
    (No Parameters)
    
    Number of active users: 2
    Total users (including active and inactive): 5
    Percent Active: 40%

    SamAccountName UserPrincipalName   mail           LastLogonDate      
    -------------- -----------------   ----           -------------      
    kbohlander     kbohlander@test.lan                6/5/2023 8:58:20 AM
    tuser          tuser@test.lan      tuser@test.com 6/6/2023 8:30:23 AM

PARAMETER: -NumberOfDays "ReplaceWithAnumber"
    How long ago in days to report on.
.EXAMPLE
    -NumberOfDays "1" (If today was 6/7/2023)
    
    Number of active users: 2
    Total users (including active and inactive): 5
    Percent Active: 40%

    SamAccountName UserPrincipalName   mail           LastLogonDate      
    -------------- -----------------   ----           -------------      
    tuser          tuser@test.lan      tuser@test.com 6/6/2023 8:30:23 AM

PARAMETER: -ExcludeDisabledUsers
    Excludes the user from the report if they're currently disabled.

PARAMETER: -CustomFieldName "ReplaceMeWithAnyMultilineCustomField"
    Name of a multiline custom field to save the results to.
.EXAMPLE
    -CustomFieldName "ReplaceMeWithAnyMultilineCustomField"
    
    Number of active users: 2
    Total users (including active and inactive): 5
    Percent Active: 40%

    SamAccountName UserPrincipalName   mail           LastLogonDate      
    -------------- -----------------   ----           -------------      
    kbohlander     kbohlander@test.lan                6/5/2023 8:58:20 AM
    tuser          tuser@test.lan      tuser@test.com 6/6/2023 8:30:23 AM
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes: Renamed script and added Script Variable support
#>

[CmdletBinding()]
param (
    [Parameter()]
    [int]$NumberOfDays = 30,
    [Parameter()]
    [String]$CustomFieldName,
    [Parameter()]
    [Switch]$ExcludeDisabledUsers = [System.Convert]::ToBoolean($env:excludeDisabledUsersFromReport)
)

begin {
    # Tests for administrative rights which is required to get the last logon date.
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    # Tests if the device the script is running on is a dmona controller.
    function Test-IsDomainController {
        return $(Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -eq 2
    }

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

    # Todays date
    $Today = Get-Date

    if ($env:numberOfDaysToReportOn -and $env:numberOfDaysToReportOn -notlike "null") { $NumberOfDays = $env:numberOfDaysToReportOn }
    if ($env:customFieldName -and $env:customFieldName -notlike "null") { $CustomFieldName = $env:customFieldName }
}
process {
    # Erroring out when ran without administrator rights
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    # Erroring out when ran on a non-domain controller
    if (-not (Test-IsDomainController)) {
        Write-Error -Message "The script needs to be run on a domain controller!"
        exit 1
    }

    # If disabled users are to be excluded we're going to fetch different properties and Filter out disabled users
    if ($ExcludeDisabledUsers) {
        $Users = Get-ADUser -Filter * -Properties SamAccountName, UserPrincipalName, mail, LastLogonDate, Enabled | 
            Where-Object { $_.Enabled -eq $True }
        $ActiveUsers = Get-ADUser -Filter { LastLogonDate -ge 0 } -Properties SamAccountName, UserPrincipalName, mail, LastLogonDate, Enabled |
            Where-Object { (New-TimeSpan $_.LastLogonDate $Today).Days -le $NumberOfDays -and $_.Enabled -eq $True } |
            Select-Object SamAccountName, UserPrincipalName, mail, LastLogonDate
    }
    else {
        $Users = Get-ADUser -Filter * -Properties SamAccountName, UserPrincipalName, mail, LastLogonDate
        $ActiveUsers = Get-ADUser -Filter { LastLogonDate -ge 0 } -Properties SamAccountName, UserPrincipalName, mail, LastLogonDate |
            Where-Object { (New-TimeSpan $_.LastLogonDate $Today).Days -le $NumberOfDays } |
            Select-Object SamAccountName, UserPrincipalName, mail, LastLogonDate
    }

    # Creating a generic list to start assembling the report
    $Report = New-Object System.Collections.Generic.List[string]

    # Actual report assembly each section will be print on its own line
    $Report.Add("Active users: $(($ActiveUsers | Measure-Object).Count)")
    $Report.Add("Total users: $(($Users | Measure-Object).Count)")
    $Report.Add("Percent Active: $(if((($Users | Measure-Object).Count) -gt 0){[Math]::Round(($ActiveUsers | Measure-Object).Count / (($Users | Measure-Object).Count) * 100, 2)}else{0})%")

    # Set's up table to use in the report
    $Report.Add($($ActiveUsers | Format-Table | Out-String))

    if ($ActiveUsers) {
        # Exports report to activity log
        $Report | Write-Host

        if ($CustomFieldName) {
            # Saves report to custom field.
            try {
                Set-NinjaProperty -Name $CustomFieldName -Value ($Report | Out-String)
            }
            catch {
                # If we ran into some sort of error we'll output it here.
                Write-Error -Message $_.ToString() -Category InvalidOperation -Exception (New-Object System.Exception)
                exit 1
            }
        }
    }
    else {
        Write-Error "[Error] No active users found!"
        exit 1
    }
}
end {
    
    
    
}
