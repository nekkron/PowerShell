#Requires -Version 5.1

<#
.SYNOPSIS
    Gets computers that have been inactive for a specified number of days.
.DESCRIPTION
    Gets computers that have been inactive for a specified number of days.
    The number of days to consider a computer inactive can be specified as a parameter or saved to a custom field.

PARAMETER: -InactiveDays 30
    The number of days to consider a computer inactive. Computers that have been inactive for this number of days will be included in the report.
.EXAMPLE
    -InactiveDays 30
    ## EXAMPLE OUTPUT WITH InactiveDays ##
    [Info] Searching for computers that are inactive for 30 days or more.
    [Info] Found 11 inactive computers.

PARAMETER: -InactiveDays 30 -WysiwygCustomField "ReplaceMeWithAnyWysiwygCustomField"
    The number of days to consider a computer inactive. Computers that have been inactive for this number of days will be included in the report.
.EXAMPLE
    -InactiveDays 30 -WysiwygCustomField "ReplaceMeWithAnyWysiwygCustomField"
    ## EXAMPLE OUTPUT WITH WysiwygCustomField ##
    [Info] Searching for computers that are inactive for 30 days or more.
    [Info] Found 11 inactive computers.
    [Info] Attempting to set Custom Field 'Inactive Computers'.
    [Info] Successfully set Custom Field 'Inactive Computers'!

.NOTES
    Minimum OS Architecture Supported: Windows Server 2016
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    $InactiveDays,
    [Parameter()]
    [String]$WysiwygCustomField
)

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
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
        
        # The below types require values not typically given in order to be set. The below code will convert whatever we're given into a format ninjarmm-cli supports.
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
    if (-not (Test-IsElevated)) {
        Write-Host "[Error] Access Denied. Please run with Administrator privileges."
        exit 1
    }

    # Get Script Variables and override parameters with them
    if ($env:inactiveDays -and $env:inactiveDays -notlike "null") {
        $InactiveDays = $env:inactiveDays
    }
    if ($env:wysiwygCustomField -and $env:wysiwygCustomField -notlike "null") {
        $WysiwygCustomField = $env:wysiwygCustomField
    }

    # Parameter Requirements
    if ([string]::IsNullOrWhiteSpace($InactiveDays)) {
        Write-Host "[Error] Inactive Days is required."
        exit 1
    }
    elseif ([int]::TryParse($InactiveDays, [ref]$null) -eq $false) {
        Write-Host "[Error] Inactive Days must be a number."
        exit 1
    }

    # Check that Active Directory module is available
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Host "[Error] Active Directory module is not available. Please install it and try again."
        exit 1
    }

    try {
        # Get the date in the past $InactiveDays days
        $InactiveDate = (Get-Date).AddDays(-$InactiveDays)
        # Get the SearchBase for the domain
        $Domain = "DC=$(
            $(Get-CimInstance Win32_ComputerSystem).Domain -split "\." -join ",DC="
        )"
        Write-Host "[Info] Searching for computers that are inactive for $InactiveDays days or more."

        # For Splatting parameters into Get-ADComputer
        $GetComputerSplat = @{
            Property   = "Name", "LastLogonTimeStamp", "OperatingSystem"
            # LastLogonTimeStamp is converted to a DateTime object from the Get-ADComputer cmdlet
            Filter     = { (Enabled -eq "true") -and (LastLogonTimeStamp -le $InactiveDate) }
            SearchBase = $Domain
        }

        # Get inactive computers that are not active in the past $InactiveDays days
        $InactiveComputers = Get-ADComputer @GetComputerSplat | Select-Object "Name", @{
            # Format the LastLogonTimeStamp property to a human-readable date
            Name       = "LastLogon"
            Expression = {
                if ($_.LastLogonTimeStamp -gt 0) {
                    # Convert LastLogonTimeStamp to a datetime
                    $lastLogon = [DateTime]::FromFileTime($_.LastLogonTimeStamp)
                    # Format the datetime
                    $lastLogonFormatted = $lastLogon.ToString("MM/dd/yyyy hh:mm:ss tt")
                    return $lastLogonFormatted
                }
                else {
                    return "01/01/1601 00:00:00 AM"
                }
            }
        }, "OperatingSystem"

        if ($InactiveComputers -and $InactiveComputers.Count -gt 0) {
            Write-Host "[Info] Found $($InactiveComputers.Count) inactive computers."
        }
        else {
            Write-Host "[Info] No inactive computers were found."
        }
    }
    catch {
        Write-Host "[Error] Failed to get inactive computers. Please try again."
        exit 1
    }

    # Save the results to a custom field
    if ($WysiwygCustomField) {
        try {
            Write-Host "[Info] Attempting to set Custom Field '$WysiwygCustomField'."
            Set-NinjaProperty -Name $WysiwygCustomField -Value $($InactiveComputers | ConvertTo-Html -Fragment | Out-String)
            Write-Host "[Info] Successfully set Custom Field '$WysiwygCustomField'!"
        }
        catch {
            Write-Host "[Error] Failed to set Custom Field '$WysiwygCustomField'."
            $ExitCode = 1
        }
    }

    $InactiveComputers | Format-Table -AutoSize | Out-String -Width 4000 | Write-Host

    exit $ExitCode
}
end {
    
    
    
}