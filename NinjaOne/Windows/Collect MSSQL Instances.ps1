#Requires -Version 5.1

<#
.SYNOPSIS
    Gets a list of MSSQL server instances and optionally save the results to a custom field.
.DESCRIPTION
    Gets a list of MSSQL server instances and optionally save the results to a custom field.
    The custom field can be either/both a multi-line or WYSIWYG custom field.

    SQL Server, SQL Server Developer and SQL Express are supported.

    SQL "Local" that are built into an application are not supported as they aren't an SQL Server instance.

    SQL service name that don't start with "MSSQL$" will not get detected.

    PS > Get-Service -Name "MSSQL`$*"
    Status   Name               DisplayName
    ------   ----               -----------
    Running  MSSQL$DB           SQL Server (DB)
    Running  MSSQL$DB01         SQL Server (DB01)
    Running  MSSQL$DB02         SQL Server (DB02)

.EXAMPLE
    (No Parameters)
    ## EXAMPLE OUTPUT WITHOUT PARAMS ##
     Status Name              Instance Path
     ------ ----              -------- ----
    Running SQL Server (DB01) DB01     C:\Program Files\Microsoft SQL Server\MSSQL16.DB01\MSSQL
    Running SQL Server (DB02) DB02     C:\Program Files\Microsoft SQL Server\MSSQL16.DB02\MSSQL

PARAMETER: -CustomFieldName "ReplaceMeWithAnyMultilineCustomField"
    Saves an text table to a multi-line Custom Field with a list of SQL instances.
.EXAMPLE
    -CustomFieldName "ReplaceMeWithAnyMultilineCustomField"
    ## EXAMPLE OUTPUT WITH CustomFieldName ##
     Status Name              Instance Path
     ------ ----              -------- ----
    Running SQL Server (DB01) DB01     C:\Program Files\Microsoft SQL Server\MSSQL16.DB01\MSSQL
    Running SQL Server (DB02) DB02     C:\Program Files\Microsoft SQL Server\MSSQL16.DB02\MSSQL

PARAMETER: -CustomFieldParam "ReplaceMeWithAnyWysiwygCustomField"
    Saves an html table to a Wysiwyg Custom Field with a list of SQL instances.
.EXAMPLE
    -WysiwygCustomFieldName "ReplaceMeWithAnyWysiwygCustomField"
    ## EXAMPLE OUTPUT WITH WysiwygCustomFieldName ##
     Status Name              Instance Path
     ------ ----              -------- ----
    Running SQL Server (DB01) DB01     C:\Program Files\Microsoft SQL Server\MSSQL16.DB01\MSSQL
    Running SQL Server (DB02) DB02     C:\Program Files\Microsoft SQL Server\MSSQL16.DB02\MSSQL
.OUTPUTS
    None
.NOTES
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [String]$CustomFieldName,
    [String]$WysiwygCustomFieldName
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
    if ($env:multilineCustomFieldName -and $env:multilineCustomFieldName -notlike "null") {
        $CustomFieldName = $env:multilineCustomFieldName
    }
    if ($env:WysiwygCustomFieldName -and $env:WysiwygCustomFieldName -notlike "null") {
        $WysiwygCustomFieldName = $env:WysiwygCustomFieldName
    }
}
process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    try {
        $InstanceNames = $(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\" -ErrorAction Stop).InstalledInstances
        $SqlInstances = $InstanceNames | ForEach-Object {
            $SqlPath = $(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$_\Setup" -ErrorAction Stop).SQLPath
            $SqlServices = Get-Service -Name "MSSQL`$$_" -ErrorAction Stop
            $SqlService = $SqlServices | Where-Object { $_.Name -notlike $SqlServices.DependentServices.Name -and $_.Name -notlike "SQLTelemetry*" }
            [PSCustomObject]@{
                Status   = $SqlService.Status
                Service  = $SqlService.DisplayName
                Instance = $_
                Path     = $SqlPath
            }
        }
    }
    catch {
        Write-Host "[Error] $($_.Message)"
        Write-Host "[Info] Likely no MSSQL instance found."
        exit 1
    }

    $SqlInstances | Out-String | Write-Host

    if ($CustomFieldName) {
        Write-Host "Attempting to set Custom Field '$CustomFieldName'."
        Set-NinjaProperty -Name $CustomFieldName -Value ($SqlInstances | Out-String)
        Write-Host "Successfully set Custom Field '$CustomFieldName'!"
    }

    if ($WysiwygCustomFieldName) {
        try {
            Write-Host "Attempting to set Custom Field '$WysiwygCustomFieldName'."
            $htmlReport = New-Object System.Collections.Generic.List[String]
            $htmlReport.Add("<h1>SQL Server Instances</h1>")
            $htmlTable = $SqlInstances | ConvertTo-Html -Fragment 
            $htmlTable = $htmlTable -replace "<tr><td>Running</td>", '<tr class="success"><td>Running</td>'
            $htmlTable = $htmlTable -replace "<tr><td>StartPending</td>", '<tr class="other"><td>StartPending</td>'
            $htmlTable = $htmlTable -replace "<tr><td>ContinuePending</td>", '<tr class="other"><td>ContinuePending</td>'
            $htmlTable = $htmlTable -replace "<tr><td>Paused</td>", '<tr class="other"><td>Paused</td>'
            $htmlTable = $htmlTable -replace "<tr><td>PausePending</td>", '<tr class="other"><td>PausePending</td>'
            $htmlTable = $htmlTable -replace "<tr><td>Stopped</td>", '<tr class="danger"><td>Stopped</td>'
            $htmlTable = $htmlTable -replace "<tr><td>StopPending</td>", '<tr class="danger"><td>StopPending</td>'
            $htmlTable | ForEach-Object { $htmlReport.Add($_) }
            Set-NinjaProperty -Name $WysiwygCustomFieldName -Value ($htmlReport | Out-String)
            Write-Host "Successfully set Custom Field '$WysiwygCustomFieldName'!"
        }
        catch {
            Write-Error $_
            Write-Host "[Error] $($_.Message)"
            exit 1
        }
    }
    exit 0
}
end {
    
    
    
}