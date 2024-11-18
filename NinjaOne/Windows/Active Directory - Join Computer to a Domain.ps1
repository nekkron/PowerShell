#Requires -Version 5.1

<#
.SYNOPSIS
    Joins a computer to a domain.
.DESCRIPTION
    Joins a computer to a domain.
.EXAMPLE
     -DomainName "Domain.com" -UserName "Domain\MyDomainUser" -Password "Somepass1"
    Joins a computer to a "Domain.com" domain and restarts the computer. Don't expect a success result in Ninja as the computer will reboot before the script can return a result.
.EXAMPLE
     -DomainName "Domain.com" -UserName "Domain\MyDomainUser" -Password "Somepass1" -NoRestart
    Joins a computer to a "Domain.com" domain and does not restart the computer.
.EXAMPLE
    PS C:\> Join-Domain.ps1 -DomainName "domain.com" -UserName "Domain\MyDomainUser" -Password "Somepass1" -NoRestart
    Joins a computer to a "Domain.com" domain and does not restart the computer.
.EXAMPLE
     -DomainName "Domain.com" -UserName "Domain\MyDomainUser" -Password "Somepass1" -Server "192.168.0.1"
    Not recommended if the computer this script is running on does not have one of the Domain Controllers set as its DNS server.
    Joins a computer to a "Domain.com" domain, talks to the domain with the IP address of "192.168.0.1", and restarts the computer.
.OUTPUTS
    String[]
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes: Updates outputs with metadata and gets password from secure custom field.
.COMPONENT
    ManageUsers
#>

[CmdletBinding()]
param (
    # Domain Name to join computer to
    [Parameter()]
    [String]$DomainName,
    # Use a Domain UserName to join this computer to a domain, this requires the Password parameter to be used as well
    [Parameter()]
    [String]$UserName,
    # Use a Domain Password to join this computer from a domain
    [Parameter()]
    [String]$Password,
    # Used only when computer can't locate a domain controller via DNS or you wish to connect to a specific DC
    [Parameter()]
    [String]$Server,
    # Do not restart computer after joining to a domain
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
                # In Ninja Date and Date/Time fields are in Unix Epoch time in the UTC timezone the below should convert it into local time as a datetime object.
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
                # Time fields are given as a number of seconds starting from midnight. This will convert it into a datetime object.
                $Seconds = $NinjaPropertyValue
                $UTC = ([timespan]::fromseconds($Seconds)).ToString("hh\:mm\:ss")
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
    if ($env:domainToJoin -and $env:domainToJoin -notlike "null") { $DomainName = $env:domainToJoin }
    if ($env:usernameToJoinDomainWith -and $env:usernameToJoinDomainWith -notlike "null") { 
        $UserName = $env:usernameToJoinDomainWith
        $env:usernameToJoinDomainWith = $env:usernameToJoinDomainWith | ConvertTo-SecureString -AsPlainText -Force 
    }
    # Get password from secure custom field
    if ($env:passwordToJoinDomainWithCustomField -and $env:passwordToJoinDomainWithCustomField -notlike "null") { 
        try {
            $Password = Get-NinjaProperty -Name $env:passwordToJoinDomainWithCustomField
        }
        catch {
            Write-Host "[Error] Failed to get password from secure custom field."
            exit 1
        }
    }
    if ($env:serverName -and $env:serverName -notlike "null") { $Server = $env:serverName }

    if (-not $DomainName) { Write-Host "[Error] Domain Name is required!"; Exit 1 }
    if (-not $UserName) { Write-Host "[Error] A Username and Password is required to join a domain."; Exit 1 }
    if (-not $Password) { Write-Host "[Error] A Username and Password is required to join a domain."; Exit 1 }
    function Join-ComputerToDomainPS2 {
        param (
            [String]
            $DomainName,
            [PSCredential]
            $Credential,
            $Restart,
            $Server
        )
        if ($Credential) {
            # Use supplied Credentials
            if ($Server) {
                Add-Computer -DomainName $DomainName -Credential $Credential -Server $Server -Force -Confirm:$false -PassThru
            }
            else {
                Add-Computer -DomainName $DomainName -Credential $Credential -Force -Confirm:$false -PassThru
            }
        }
        else {
            # No Credentials supplied, use current user
            Add-Computer -DomainName $DomainName -Force -Confirm:$false -PassThru
        }
    }
    Write-Output "[Info] Starting Join Domain"
    
    # Convert username and password into a credential object
    $JoinCred = [PSCredential]::new($UserName, $(ConvertTo-SecureString -String $Password -AsPlainText -Force))
}
    
process {
    Write-Output "[Info] Joining computer($env:COMPUTERNAME) to domain $DomainName"
    $script:JoinResult = $false
    try {
        $JoinResult = if ($NoRestart) {
            # Do not restart after joining
            if ($PSVersionTable.PSVersion.Major -eq 2) {
                if ($Server) {
                    (Join-ComputerToDomainPS2 -DomainName $DomainName -Credential $Credential -Server $Server).HasSucceeded
                }
                else {
                    (Join-ComputerToDomainPS2 -DomainName $DomainName -Credential $Credential).HasSucceeded
                }
            }
            else {
                if ($Server) {
                    (Add-Computer -DomainName $DomainName -Credential $JoinCred -Server $Server -Force -Confirm:$false -PassThru).HasSucceeded
                }
                else {
                    (Add-Computer -DomainName $DomainName -Credential $JoinCred -Force -Confirm:$false -PassThru).HasSucceeded
                }
            }
        }
        else {
            # Restart after joining
            if ($PSVersionTable.PSVersion.Major -eq 2) {
                if ($Server) {
                    (Join-ComputerToDomainPS2 -DomainName $DomainName -Credential $Credential -Server $Server).HasSucceeded
                }
                else {
                    (Join-ComputerToDomainPS2 -DomainName $DomainName -Credential $Credential).HasSucceeded
                }
            }
            else {
                if ($Server) {
                    (Add-Computer -DomainName $DomainName -Credential $JoinCred -Restart -Server $Server -Force -Confirm:$false -PassThru).HasSucceeded
                }
                else {
                    (Add-Computer -DomainName $DomainName -Credential $JoinCred -Restart -Force -Confirm:$false -PassThru).HasSucceeded
                }
            }
        }    
    }
    catch {
        Write-Host "[Error] Failed to Join Domain: $DomainName"
    }

    if ($NoRestart -and $JoinResult) {
        Write-Output "[Info] Joined computer($env:COMPUTERNAME) to Domain: $DomainName and not restarting computer"
    }
    elseif ($JoinResult) {
        Write-Output "[Info] Joined computer($env:COMPUTERNAME) to Domain: $DomainName and restarting computer"
        if ($PSVersionTable.PSVersion.Major -eq 2) {
            shutdown.exe -r -t 60
        }
    }
    else {
        Write-Output "[Error] Failed to Join computer($env:COMPUTERNAME) to Domain: $DomainName"
        # Clean up credentials so that they don't leak outside this script
        $JoinCred = $null
        exit 1
    }
    # Clean up credentials so that they don't leak outside this script
    $JoinCred = $null
    Write-Output "[Info] Completed Join Domain"
}
    
end {
    
    
    
}
