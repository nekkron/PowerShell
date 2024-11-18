#Requires -Version 2.0

<#
.SYNOPSIS
    Removes the computer from the domain.
.DESCRIPTION
    Removes the computer from the domain.
.EXAMPLE
     -UserName "MyDomainUser" -Password "Somepass1"
    Removes the computer from the domain and restarts the computer.
.EXAMPLE
     -UserName "MyDomainUser" -Password "Somepass1" -NoRestart
    Removes the computer from the domain and does not restart the computer.
.EXAMPLE
    PS C:\> Leave-Domain.ps1 -UserName "MyDomainUser" -Password "Somepass1" -NoRestart
    Removes the computer from the domain and does not restart the computer.
.OUTPUTS
    String[]
.NOTES
    Minimum OS Architecture Supported: Windows 7, Windows Server 2012
    Release Notes: Gets passwords from secure custom fields
.COMPONENT
    ManageUsers
#>

[CmdletBinding()]
param (
    # Use a Domain UserName to remove this computer to a domain, this requires the Password parameter to be used as well
    [Parameter()]
    [String]
    $UserName,
    # Use a Domain Password to remove a computer from a domain
    [Parameter()]
    $Password,
    # Do not restart computer after leaving to a domain
    [Parameter()]
    [Switch]$NoRestart = [System.Convert]::ToBoolean($env:noRestart)
)

begin {
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
            if ($Type -Like "Secure") { throw [System.ArgumentOutOfRangeException]::New("$Type is an invalid type! Please check here for valid types. https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality") }
    
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
    
        if (-not $NinjaPropertyValue) {
            throw [System.NullReferenceException]::New("The Custom Field '$Name' is empty!")
        }
    
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
                # In Ninja Date and Date/Time fields are in Unix Epoch time in the UTC timezone the below should convert it into local time as a DateTime object.
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
                # Casts the Ninja provided string into an integer.
                [int]$NinjaPropertyValue
            }
            "MultiSelect" {
                # Multi-Select custom fields come in as a comma-separated list of GUIDs we'll compare these with all the options and return just the option values selected instead of a guid.
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
                # Time fields are given as a number of seconds starting from midnight. This will convert it into a DateTime object.
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

    # Check if custom fields are used for the username and password
    if ($env:domainUsername -and $env:domainUsername -notlike "null") { 
        $UserName = $env:domainUsername 
    }

    if ($env:domainPasswordWithCustomField -and $env:domainPasswordWithCustomField -notlike "null") { 
        try {
            $Password = Get-NinjaProperty -Name $env:domainPasswordWithCustomField
            if ([string]::IsNullOrWhiteSpace($Password)) {
                Write-Host "[Warn] The Domain Password With Custom Field '$env:domainPasswordWithCustomField' is empty!"
                throw
            }
        }
        catch {
            Write-Host "[Error] Failed to get password from secure custom field."
            exit 1
        }
    }


    # Check if usernames and passwords where provided
    if (-not ($UserName) -or -not ($Password) ) { Write-Error "A domain username and password is required."; Exit 1 }

    Write-Output "Starting Leave Domain"

    # Converts username and password into a credential object
    $LeaveCred = [PSCredential]::new($UserName, $(ConvertTo-SecureString -String $Password -AsPlainText -Force))

}

process {
    Write-Output "Removing computer($env:COMPUTERNAME) from domain"
    $script:LeaveResult = $false
    try {
        $LeaveResult = if ($NoRestart) {
            (Remove-Computer -UnjoinDomainCredential $LeaveCred -PassThru -Force -Confirm:$false).HasSucceeded
            # Do not restart after leaving
        }
        else {
            # Restart after leaving
            (Remove-Computer -UnjoinDomainCredential $LeaveCred -PassThru -Force -Restart -Confirm:$false).HasSucceeded
        }
    }
    catch {
        Write-Error "Failed to Leave Domain"
    }
    if ($LeaveResult) {
        if ($NoRestart) {
            Write-Output "Removed computer($env:COMPUTERNAME) from domain and not restarting computer"
        }
        else {
            Write-Output "Removed computer($env:COMPUTERNAME) from domain and restarting computer"
        }
    }
    else {
        Write-Output "Failed to remove computer($env:COMPUTERNAME) from domain"
        # Clean up credentials so that they don't leak outside this script
        $LeaveCred = $null
        exit 1
    }

    # Clean up credentials so that they don't leak outside this script
    $LeaveCred = $null
    Write-Output "Completed Leave Domain"
}
    
end {
    
    
    
}



