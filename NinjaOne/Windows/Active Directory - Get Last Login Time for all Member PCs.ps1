#Requires -Version 5.1

<#
.SYNOPSIS
    Gets the last login time for all computers in Active Directory.
.DESCRIPTION
    Gets the last login time for all computers in Active Directory.
    The last login time is retrieved from the LastLogonTimeStamp property of the computer object.
    If the user name cannot be retrieved from an offline computer, the script will return Unknown.
    If the computer name cannot be retrieved, the script will return Unknown.

.EXAMPLE
    (No Parameters)
    ## EXAMPLE OUTPUT WITHOUT PARAMS ##

PARAMETER: -WysiwygCustomField "myWysiwygCustomField"
    Saves results to a WYSIWYG Custom Field.
.EXAMPLE
    -WysiwygCustomField "myWysiwygCustomField"
    ## EXAMPLE OUTPUT WITH WysiwygCustomField ##
    [Info] Found 10 computers.
    [Info] Attempting to set Custom Field 'myWysiwygCustomField'.
    [Info] Successfully set Custom Field 'myWysiwygCustomField'!

PARAMETER: -QueryForLastUserLogon "true"
    When checked, the script will query for the last user logon time for each computer.
    Note that this will take longer to run and will try to connect to each computer in the domain.
.EXAMPLE
    -QueryForLastUserLogon "true"
    ## EXAMPLE OUTPUT WITH QueryForLastUserLogon ##
    [Warn] Remote computer WIN-1234567891 is not available.
    [Info] Found 2 computers.

    Computer                  Last Logon Date   Last Login in Days   User
    --------                  ---------------   ------------------   ----
    WIN-1234567891            2024-04-01 12:00   0                   Unknown
    WIN-1234567890            2024-04-01 12:00   0                   Fred
    WIN-9876543210            2023-04-01 12:00   32                  Bob

.NOTES
    Minimum OS Architecture Supported: Windows Server 2016
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$WysiwygCustomField,
    [Parameter()]
    [Switch]$QueryForLastUserLogon
)

begin {
    # CIM timeout
    $CIMTimeout = 10

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
        Write-Host -Object "[Error] Access Denied. Please run with Administrator privileges."
        exit 1
    }

    # Get Script Variables and override parameters with them
    if ($env:wysiwygCustomField -and $env:wysiwygCustomField -notlike "null") {
        $WysiwygCustomField = $env:wysiwygCustomField
    }
    if ($env:queryForLastUserLogon -and $env:queryForLastUserLogon -notlike "null") {
        if ($env:queryForLastUserLogon -eq "true") {
            $QueryForLastUserLogon = $true
        }
        else {
            $QueryForLastUserLogon = $false
        }
    }

    # Check that Active Directory module is available
    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Write-Host "[Error] Active Directory module is not available. Please install it and try again."
        exit 1
    }

    # Get the computer system from the CIM
    $ComputerSystem = $(Get-CimInstance -ClassName Win32_ComputerSystem)

    # Check if this script is running on a domain joined computer
    if ($ComputerSystem.PartOfDomain -eq $false) {
        Write-Host "[Error] This script must be run on a domain joined computer."
        exit 1
    }

    # Check if this script is running on a domain controller
    switch ($ComputerSystem.DomainRole) {
        0 { Write-Host "[Info] Running script on a Standalone Workstation." }
        1 { Write-Host "[Info] Running script on a Member Workstation." }
        2 { Write-Host "[Info] Running script on a Standalone Server." }
        3 { Write-Host "[Info] Running script on a Member Server." }
        4 { Write-Host "[Info] Running script on a Backup Domain Controller." }
        5 { Write-Host "[Info] Running script on a Primary Domain Controller." }
    }

    # Get the SearchBase for the domain
    $Domain = "DC=$($ComputerSystem.Domain -split "\." -join ",DC=")"

    # Get Computers from Active Directory
    try {
        $Computers = Get-ADComputer -Filter { (Enabled -eq $true) } -Properties Name, LastLogonTimeStamp -SearchBase "$Domain" -ErrorAction Stop
    }
    catch {
        Write-Host "[Error] Failed to get computers. Make sure this is running on a domain controller."
        exit 1
    }

    $IsFirstError = $true

    $LastLogonInfo = foreach ($Computer in $Computers) {
        try {
            # Get the LastLogonTimeStamp for the computer from Active Directory
            $PCInfo = Get-ADComputer -Identity $Computer.Name -Properties LastLogonTimeStamp -ErrorAction Stop | Select-Object -Property @(
                @{Name = "Computer"; Expression = { $_.Name } },
                @{Name = "LastLogon"; Expression = { [DateTime]::FromFileTime($_.LastLogonTimeStamp) } }
            )
        }
        catch {
            # This should only happen if the script is not running as the system user on a domain controller or not as a domain admin
            Write-Debug "[Debug] $($_.Exception.Message)"
            Write-Host "[Warn] Failed to get details for $($Computer.Name) from Active Directory. Skipping."
            continue
        }
        try {
            if ($QueryForLastUserLogon) {
                # Get the User Principal Name from the computer
                $LastUserLogonInfo = Get-CimInstance -ClassName Win32_UserProfile -ComputerName $Computer.name -OperationTimeoutSec $CIMTimeout -ErrorAction Stop | Where-Object { $_.LocalPath -like "*Users*" } | Sort-Object -Property LastUseTime | Select-Object -Last 1
                $SecIdentifier = New-Object System.Security.Principal.SecurityIdentifier($LastUserLogonInfo.SID) -ErrorAction Stop
                $UserName = $SecIdentifier.Translate([System.Security.Principal.NTAccount])
            }
        }
        catch {
            if ($null -eq $UserName) {
                if ($IsFirstError) {
                    # Only show on the first error
                    Write-Debug "[Debug] $($_.Exception.Message)"
                    Write-Host "[Error] Failed to connect to 1 or more computers via Get-CimInstance."
                    $IsFirstError = $false
                }
                Write-Host "[Warn] Remote computer $($Computer.Name) is not available or could not be queried."
            }
        }

        if ($null -eq $UserName) {
            $UserName = [PSCustomObject]@{
                value = "Unknown"
            }
        }
        if ($null -eq $PCInfo.LastLogon) {
            $PCInfo = [PSCustomObject]@{
                Computer  = $Computer.Name
                LastLogon = "Unknown"
            }
            Write-Host "[Warn] Failed to get LastLogonTimeStamp for $($Computer.Name)."
        }

        # Get the number of days since the last login
        $LastLoginDays = try {
            0 - $(Get-Date -Date $PCInfo.LastLogon).Subtract($(Get-Date)).Days
        }
        catch {
            # Return unknown if the date is invalid or does not exist
            "Unknown"
        }

        # Output the results
        if ($QueryForLastUserLogon) {
            [PSCustomObject]@{
                'Computer'           = $PCInfo.Computer
                'Last Logon Date'    = $PCInfo.LastLogon
                'Last Login in Days' = $LastLoginDays
                'User'               = $UserName.value
            }
        }
        else {
            [PSCustomObject]@{
                'Computer'           = $PCInfo.Computer
                'Last Logon Date'    = $PCInfo.LastLogon
                'Last Login in Days' = $LastLoginDays
            }
        }

        $PCInfo = $null
        $LastUserLogonInfo = $null
        $SecIdentifier = $null
        $UserName = $null
    }

    # Output the number of computers found
    if ($LastLogonInfo -and $LastLogonInfo.Count -gt 0) {
        Write-Host "[Info] Found $($LastLogonInfo.Count) computers."
    }
    else {
        Write-Host "[Error] No computers were found."
        $ExitCode = 1
    }

    function Write-LastLoginInfo {
        param ()
        $LastLogonInfo | Format-Table -AutoSize | Out-String -Width 4000 | Write-Host
    }

    # Save the results to a custom field
    if ($WysiwygCustomField) {
        $LastLoginOkayDays = 30
        $LastLoginTooOldDays = 90
        # Convert the array to an HTML table
        $HtmlTable = $LastLogonInfo | ConvertTo-Html -Fragment
        # Set the color of the rows based on the last logon time
        $HtmlTable = $HtmlTable -split [Environment]::NewLine | ForEach-Object {
            if ($_ -match "<td>(?'LastLoginDays'\d+)<\/td>") {
                # Get the last login days from the HTML table
                [int]$LastLoginDays = $Matches.LastLoginDays
                if ($LastLoginDays -lt $LastLoginTooOldDays -and $LastLoginDays -ge $LastLoginOkayDays) {
                    # warning = 31 days to 89 days
                    $_ -replace "<tr><td>", '<tr class="warning"><td>'
                }
                elseif ($LastLoginDays -ge $LastLoginTooOldDays) {
                    # danger = 90 days or more
                    $_ -replace "<tr><td>", '<tr class="danger"><td>'
                }
                else {
                    # success = 30 days or less
                    $_ -replace "<tr><td>", '<tr class="success"><td>'
                }
            }
            else {
                $_
            }
        }
        # Set the width of the table to 10% to reduce the width of the table to its minimum possible width
        $HtmlTable = $HtmlTable -replace "<table>", "<table style='white-space:nowrap;'>"
        try {
            Write-Host "[Info] Attempting to set Custom Field '$WysiwygCustomField'."
            Set-NinjaProperty -Name $WysiwygCustomField -Value $($HtmlTable | Out-String)
            Write-Host "[Info] Successfully set Custom Field '$WysiwygCustomField'!"
        }
        catch {
            Write-Host "[Error] Failed to set Custom Field '$WysiwygCustomField'."
            Write-LastLoginInfo
            $ExitCode = 1
        }
    }
    else {
        Write-LastLoginInfo
    }

    exit $ExitCode
}
end {
    
    
    
}