<#
.SYNOPSIS
    Gets the Organizational Units (OUs) that this device is a member of in Active Directory or Azure AD.
.DESCRIPTION
    Gets the Organizational Units (OUs) that this device is a member of in Active Directory or Azure AD.
.EXAMPLE
    -CustomFieldName "ReplaceMeWithAnyMultilineCustomField"
    
    Attempting to set Custom Field 'ReplaceMeWithAnyMultilineCustomField'.
    Successfully set Custom Field 'ReplaceMeWithAnyMultilineCustomField'!

    Organizational Units Found:
    OU=Domain Controllers,OU=Computers,DC=test,DC=lan
    OU=Servers,OU=Computers,DC=test,DC=lan

PARAMETER: -CustomFieldName "ReplaceMeWithAnyMultilineCustomField"
    Name of a multiline custom field to save the results to.
.EXAMPLE
    -CustomFieldName "ReplaceMeWithAnyMultilineCustomField"
    
    Attempting to set Custom Field 'ReplaceMeWithAnyMultilineCustomField'.
    Successfully set Custom Field 'ReplaceMeWithAnyMultilineCustomField'!

    Organizational Units Found:
    OU=Domain Controllers,OU=Computers,DC=test,DC=lan
    OU=Servers,OU=Computers,DC=test,DC=lan
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$CustomFieldName
)

begin {
    # If using script form variables, replace command line parameters with the form variables.
    if ($env:customFieldName -and $env:customFieldName -notlike "null") { $CustomFieldName = $env:customFieldName }

    # Function to check if the script is running with elevated (administrator) privileges
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function Test-IsDomainJoined {
        # Check the PowerShell version to determine the appropriate cmdlet to use
        if ($PSVersionTable.PSVersion.Major -lt 5) {
            return $(Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain
        }
        else {
            return $(Get-CimInstance -Class Win32_ComputerSystem).PartOfDomain
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
        
        # Measure the number of characters in the provided value
        $Characters = $Value | Out-String | Measure-Object -Character | Select-Object -ExpandProperty Characters
    
        # Throw an error if the value exceeds the character limit of 200,000 characters
        if ($Characters -ge 200000) {
            throw "Character limit exceeded: the value is greater than or equal to 200,000 characters."
        }
        
        # Initialize a hashtable for additional documentation parameters
        $DocumentationParams = @{}
    
        # If a document name is provided, add it to the documentation parameters
        if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }
        
        # Define a list of valid field types
        $ValidFields = "Attachment", "Checkbox", "Date", "Date or Date Time", "Decimal", "Dropdown", "Email", "Integer", "IP Address", "MultiLine", "MultiSelect", "Phone", "Secure", "Text", "Time", "URL", "WYSIWYG"
    
        # Warn the user if the provided type is not valid
        if ($Type -and $ValidFields -notcontains $Type) { Write-Warning "$Type is an invalid type. Please check here for valid types: https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality" }
        
        # Define types that require options to be retrieved
        $NeedsOptions = "Dropdown"
    
        # If the property is being set in a document or field and the type needs options, retrieve them
        if ($DocumentName) {
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Docs-Options -AttributeName $Name @DocumentationParams 2>&1
            }
        }
        else {
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Options -Name $Name 2>&1
            }
        }
        
        # Throw an error if there was an issue retrieving the property options
        if ($NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }
            
        # Process the property value based on its type
        switch ($Type) {
            "Checkbox" {
                # Convert the value to a boolean for Checkbox type
                $NinjaValue = [System.Convert]::ToBoolean($Value)
            }
            "Date or Date Time" {
                # Convert the value to a Unix timestamp for Date or Date Time type
                $Date = (Get-Date $Value).ToUniversalTime()
                $TimeSpan = New-TimeSpan (Get-Date "1970-01-01 00:00:00") $Date
                $NinjaValue = $TimeSpan.TotalSeconds
            }
            "Dropdown" {
                # Convert the dropdown value to its corresponding GUID
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = $Options | Where-Object { $_.Name -eq $Value } | Select-Object -ExpandProperty GUID
            
                # Throw an error if the value is not present in the dropdown options
                if (!($Selection)) {
                    throw [System.ArgumentOutOfRangeException]::New("Value is not present in dropdown options.")
                }
            
                $NinjaValue = $Selection
            }
            default {
                # For other types, use the value as is
                $NinjaValue = $Value
            }
        }
            
        # Set the property value in the document if a document name is provided
        if ($DocumentName) {
            $CustomField = Ninja-Property-Docs-Set -AttributeName $Name -AttributeValue $NinjaValue @DocumentationParams 2>&1
        }
        else {
            # Otherwise, set the standard property value
            $CustomField = $NinjaValue | Ninja-Property-Set-Piped -Name $Name 2>&1
        }
            
        # Throw an error if setting the property failed
        if ($CustomField.Exception) {
            throw $CustomField
        }
    }
}
process {
    # Check if the script is running with elevated (administrator) privileges
    if (!(Test-IsElevated)) {
        Write-Host "[Error] Access Denied. Please run with Administrator privileges."
        exit 1
    }

    $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine'
    $DistinguishedName = Get-ItemProperty -Path $regPath -Name 'Distinguished-Name' -ErrorAction SilentlyContinue

    $OrganizationalUnit = if ($DistinguishedName -and $DistinguishedName.'Distinguished-Name') {
        $OU = $DistinguishedName.'Distinguished-Name' -replace '^CN=.*?,', ''
        Write-Output $OU
    }
    else {
        Write-Host "[Warn] Failed to retrieve Organizational Unit from Group Policy State."
    }

    $OrganizationalUnit = if (Test-ComputerSecureChannel -ErrorAction SilentlyContinue) {
        "$OrganizationalUnit"
    }
    else {
        "(Cached) $OrganizationalUnit"
    }

    if ($OrganizationalUnit) {
        Write-Host "[Info] The OU for $env:COMPUTERNAME is: $OrganizationalUnit"
    }
    else {
        Write-Host "[Error] Failed to retrieve Organizational Units."
        exit 1
    }


    # If custom field name is provided, set the custom field with the list of OUs
    if ($CustomFieldName) {
        try {
            Write-Host "[Info] Attempting to set Custom Field '$CustomFieldName'."
            if ((Test-IsDomainJoined)) {
                Set-NinjaProperty -Name $CustomFieldName -Value $($OrganizationalUnit | Out-String)
            }
            else {
                Set-NinjaProperty -Name $CustomFieldName -Value "Workgroup"
            }
            Write-Host "[Info] Successfully set Custom Field '$CustomFieldName'!"
        }
        catch {
            Write-Host "[Error] $($_.Exception.Message)"
            exit 1
        }
    }

    exit 0
}
end {
    
    
    
}