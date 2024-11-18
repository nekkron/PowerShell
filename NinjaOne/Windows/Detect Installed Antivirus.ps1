#Requires -Version 4.0

<#
.SYNOPSIS
    This script will attempt to detect the installed antivirus (currently supports 11) and get the age of its definitions, version, and whether or not the antivirus is currently running. It can export the results to one or more custom fields. This script is a best effort and should be treated as such; we do recommend verifying any results.
.DESCRIPTION
    This script will attempt to detect the installed antivirus (currently supports 11) and get the age of its definitions, version, and whether or not the antivirus is currently running. 
    It can export the results to one or more custom fields. 
    This script is a best effort and should be treated as such; we do recommend verifying any results.
    
    AV List: BitDefender,Carbon Black,Crowdstrike,Cylance,ESET,Huntress,MalwareBytes,MDE,SentinelOne,Sophos,Vipre,Webroot

.EXAMPLE
    (No Parameters)
    Desktop Windows Detected, Switching to WMI Method....

    [Alert] The AV definitions are out of date!

    Name             Installed Definitions UpToDate Running Service  Version    
    ----             --------- ----------- -------- ------- -------  -------    
    Sentinel Agent   Yes       2023/05/10      True Yes     Active   21.7.1219  
    Windows Defender Yes       2023/03/31     False No      Inactive 4.18.2302.7

PARAMETER: -ExcludeAV "BitDefender"
    A comma separated list of AVs to exclude.
.EXAMPLE
    -ExcludeAV "BitDefender"

    Name        Installed Version   Definitions UpToDate CurrentlyRunning HasRunningService
    ----        --------- -------   ----------- -------- ---------------- -----------------
    SentinelOne Yes       21.7.1219 2023/04/27      True Yes              Yes

PARAMETER: -ExclusionsFromCustomField "ReplaceWithTextCustomField"
    The name of a text custom field that contains your desired ExcludeAV comma separated list.
    ex. "ExcludedAVs" where you have entered in your desired ExcludeAV list in the "ExcludedAVs" custom field rather than in a parameter.
.EXAMPLE
    -ExclusionsFromCustomField "ExcludeAVs"

    Name        Installed Version   Definitions UpToDate CurrentlyRunning HasRunningService
    ----        --------- -------   ----------- -------- ---------------- -----------------
    SentinelOne Yes       21.7.1219 2023/04/27      True Yes              Yes

PARAMETER: -OutOfDate "7"
    Script will consider the AV to be out of date if the definitions are older than x days.
.EXAMPLE
    -OutOfDate "1"

    Desktop Windows Detected, Switching to WMI Method....

    [Alert] The AV definitions are out of date!

    Name             Installed Definitions UpToDate Running Service  Version    
    ----             --------- ----------- -------- ------- -------  -------    
    Sentinel Agent   Yes       2023/05/10     False Yes     Active   21.7.1219  
    Windows Defender Yes       2023/03/31     False No      Inactive 4.18.2302.7


PARAMETER: -ShowNotFound
    Script will show AV's it checked for but didn't find.
.EXAMPLE
    -ShowNotFound

    Name             Installed Definitions UpToDate Running Service  Version    
    ----             --------- ----------- -------- ------- -------  -------    
    BitDefender      No                       False No      Inactive     
    CarbonBlack      No                       False No      Inactive 
    ...

PARAMETER: -ExportAll "ReplaceWithNameOfAMultiLineCustomField"
    The name of a multiline customfield you'd like to export the resulting table into.
.EXAMPLE
    -ExportAll "ReplaceWithNameOfAMultiLineCustomField"

    Name        Installed Version   Definitions UpToDate CurrentlyRunning HasRunningService
    ----        --------- -------   ----------- -------- ---------------- -----------------
    SentinelOne Yes       21.7.1219 2023/04/27      True Yes              Yes

PARAMETER: -ExportDef "ReplaceWithNameOfAMultiLineCustomField"
    The name of a multiline customfield you'd like to export the definitions column into.

PARAMETER: -ExportDefStatus "ReplaceWithNameOfAMultiLineCustomField"
    The name of a multiline customfield you'd like to export the UpToDate column into.

PARAMETER: -ExportName "ReplaceWithNameOfAMultiLineCustomField"
    The name of a multiline customfield you'd like to export the Name column into.

PARAMETER: -ExportStatus "ReplaceWithNameOfAMultiLineCustomField"
    The name of a multiline customfield you'd like to export the Running column into.

PARAMETER: -ExportVersion "ReplaceWithNameOfAMultiLineCustomField"
    The name of a multiline customfield you'd like to export the Version column into.
.EXAMPLE
    ExportOptions: -ExportAll, -ExportDef, -ExportDefStatus (Whether or not definitions are up to date), 
    -ExportName, -ExportStatus (Whether or not its running), -ExportVersion

    -ExportAll "ReplaceWithNameOfAMultiLineCustomField" -DateFormat "yyyy/MM/dd"

    [Alert] The AV definitions are out of date!

    Name   Installed Definitions UpToDate Running Service Version                  
    ----   --------- ----------- -------- ------- ------- -------                  
    MDE    Yes       2023/03/02     False Yes     Active  4.18.2303.8              
    Sophos Yes       2023/04/26      True Yes     Active  {2022.4.3.1 Legacy,      
                                                      2.4.274.0}               

.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10, Server 2012 R2
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$ExcludeAV,
    [Parameter()]
    [String]$ExclusionsFromCustomField,
    [Parameter()]
    [String]$ExportAll,
    [Parameter()]
    [String]$ExportDef,
    [Parameter()]
    [String]$ExportDefStatus,
    [Parameter()]
    [String]$ExportName,
    [Parameter()]
    [String]$ExportStatus,
    [Parameter()]
    [String]$ExportVersion,
    [Parameter()]
    [String]$OutOfDate = "7",
    [Parameter()]
    [Switch]$ShowNotFound = [System.Convert]::ToBoolean($env:showNotFound)
)
begin {
    Write-Host "Supported AVs: BitDefender, Carbon Black, Crowdstrike, Cylance, ESET, Huntress, MalwareBytes, Windows Defender, SentinelOne, Sophos, Vipre and Webroot."

    # Grabbing the script variables
    if ($env:definitionsAgeLimitInDays -and $env:definitionsAgeLimitInDays -notlike "null") { $OutOfDate = $env:definitionsAgeLimitInDays }
    if ($env:excludeAntivirusProduct -and $env:excludeAntivirusProduct -notlike "null") { $ExcludeAV = $env:excludeAntivirusProduct }
    if ($env:retrieveExclusionFromCustomField -and $env:retrieveExclusionFromCustomField -notlike "null") { $ExclusionsFromCustomField = $env:retrieveExclusionFromCustomField }
    if ($env:allResultsCustomFieldName -and $env:allResultsCustomFieldName -notlike "null") { $ExportAll = $env:allResultsCustomFieldName }
    if ($env:definitionsDateCustomFieldName -and $env:definitionsDateCustomFieldName -notlike "null") { $ExportDef = $env:definitionsDateCustomFieldName }
    if ($env:definitionStatusCustomFieldName -and $env:definitionStatusCustomFieldName -notlike "null" ) { $ExportDefStatus = $env:definitionStatusCustomFieldName }
    if ($env:statusCustomFieldName -and $env:statusCustomFieldName -notlike "null") { $ExportStatus = $env:statusCustomFieldName }
    if ($env:antivirusNameCustomFieldName -and $env:antivirusNameCustomFieldName -notlike "null") { $ExportName = $env:antivirusNameCustomFieldName }
    if ($env:statusCustomFieldName -and $env:statusCustomFieldName -notlike "null") { $ExportStatus = $env:statusCustomFieldName }
    if ($env:antivirusVersionCustomFieldName -and $env:antivirusVersionCustomFieldName -notlike "null") { $ExportVersion = $env:antivirusVersionCustomFieldName }

    # This script should run with administrator or system permissions. 
    # Technically it'll work without these permissions, however some directories would be inaccessible which could lead to false negatives.
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (!(Test-IsElevated)) {
        Write-Host "[Error] Access Denied. Please run with Administrator privileges."
        exit 1
    }

    function Test-IsWorkstation {
        $OS = if ($PSVersionTable.PSVersion.Major -ge 5) {
            Get-CimInstance -Class Win32_OperatingSystem
        }
        else {
            Get-WmiObject -Class Win32_OperatingSystem
        }

        if ($OS.ProductType -eq "1") {
            return $True
        }
    }

    # This will go through the uninstall registry keys and look for the AV. On occasion, we don't want all the information so we have switch options for those cases.
    function Find-UninstallKey {
        [CmdletBinding()]
        param (
            [Parameter(ValueFromPipeline)]
            [String]$DisplayName,
            [Parameter()]
            [Switch]$Version,
            [Parameter()]
            [Switch]$UninstallString,
            [Parameter()]
            [Switch]$InstallPath
        )
        process {
            $UninstallList = New-Object System.Collections.Generic.List[Object]

            $Result = Get-ChildItem HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Get-ItemProperty | 
                Where-Object { $_.DisplayName -like "*$DisplayName*" }

            if ($Result) { $UninstallList.Add($Result) }

            $Result = Get-ChildItem HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Get-ItemProperty | 
                Where-Object { $_.DisplayName -like "*$DisplayName*" }

            if ($Result) { $UninstallList.Add($Result) }

            # Programs don't always have an uninstall string listed here, so to account for that, I made this optional.
            if ($UninstallString) {
                $UninstallList | ForEach-Object { $_ | Select-Object -ExpandProperty UninstallString -ErrorAction SilentlyContinue }
            }

            if ($Version) {
                $UninstallList | ForEach-Object { ($_ | Select-Object -ExpandProperty DisplayVersion -ErrorAction SilentlyContinue) -replace '[^\u0020-\u007E\u00A0-\u00FF]', '' }
            }

            if ($InstallPath) {
                $UninstallList | ForEach-Object { $_ | Select-Object -ExpandProperty InstallLocation -ErrorAction SilentlyContinue }
            }

            if (!$Version -and !$UninstallString -and !$InstallPath) {
                $UninstallList
            }
        }
    }

    # This will find the last write time for a particular file. I made it a function in case I wanted to do something similar as the Uninstall-Key function.
    function Find-Definitions {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline)]
            [String]$Path
        )
        process {
            Get-Item $Path -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object LastWriteTime -Last 1 | Get-Date
        }
    }

    # This will search the typical directories programs are installed in.
    function Find-Executable {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline)]
            [String]$Path,
            [Parameter()]
            [Switch]$Special
        )
        process {
            if (!$Special) {
                if (Test-Path "$env:ProgramFiles\$Path") {
                    "$env:ProgramFiles\$Path"
                }
        
                if (Test-Path "${Env:ProgramFiles(x86)}\$Path") {
                    "${Env:ProgramFiles(x86)}\$Path"
                }
    
                if (Test-Path "$env:ProgramData\$Path") {
                    "$env:ProgramData\$Path"
                }
            }
            else {
                if (Test-Path $Path) {
                    $Path
                }
            }
        }
    }

    # This will check the running processes for our AV.
    function Find-Process {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline)]
            [String]$Name
        )
        process {
            Get-Process | Where-Object { $_.ProcessName -like "*$Name*" } | Select-Object -ExpandProperty Name
        }
    }

    # This was moved outside the function so I don't overload WMI.
    $ServiceList = if ($PSVersionTable.PSVersion.Major -ge 5) {
        Get-CimInstance win32_service
    }
    else {
        Get-WmiObject win32_service
    }
    
    # Looks for a service based on the executable.
    function Find-Service {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline)]
            [String]$Name
        )
        process {
            # Get-Service will display an error everytime it has an issue reading a service. Ignoring them as they're not relevant.
            $ServiceList | Where-Object { $_.State -notlike "Disabled" -and $_.State -notlike "Stopped" } | 
                Where-Object { $_.PathName -Like "*$Name.exe*" }
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
            "Dropdown" {
                # Drop-Down custom fields come in as a comma-separated list of GUIDs; we'll compare these with all the options and return just the option values selected instead of a GUID.
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Options | Where-Object { $_.GUID -eq $NinjaPropertyValue } | Select-Object -ExpandProperty Name
            }
            "MultiSelect" {
                # Multi-Select custom fields come in as a comma-separated list of GUID's we'll compare these with all the options and return just the option values selected instead of a guid.
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = ($NinjaPropertyValue -split ',').trim()
    
                foreach ($Item in $Selection) {
                    $Options | Where-Object { $_.GUID -eq $Item } | Select-Object -ExpandProperty Name
                }
            }
            default {
                # If no type was given or not one that matches the above types just output what we retrieved.
                $NinjaPropertyValue
            }
        }
    }

    # List of AV's and how to detect them.
    $AVList = @(
        [PSCustomObject]@{ Name = "Bitdefender Antivirus"; DisplayName = "Bitdefender Agent", "Bitdefender Endpoint Security Tools"; xmlPath = "$env:ProgramFiles\BitDefender\Endpoint Security\update_statistics.xml"; ExecutablePath = "Bitdefender\Endpoint Security\EPSecurityService.exe", "Bitdefender Agent\ProductAgentService.exe", "Bitdefender\Endpoint Security\EPProtectedService.exe"; ProcessName = "ProductAgentUi", "ProductAgentService", "EPProtectedService", "EPSecurityService" }
        [PSCustomObject]@{ Name = "Carbon Black"; DisplayName = "Carbon Black Cloud Sensor", "Carbon Black App Control Agent"; Definitions = "Confer\scanner\data_0\aevdf.dat"; ExecutablePath = "Confer\RepMgr64.exe", "Confer\RepWSC64.exe", "Confer\repwav.exe"; SpecialExecutablePath = "$env:SystemRoot\CarbonBlack\cb.exe"; ProcessName = "RepMgr64", "RepWSC64", "cb" }
        [PSCustomObject]@{ Name = "Crowdstrike"; DisplayName = "CrowdStrike Windows Sensor", "Falcon Agent"; Definitions = "$env:SystemRoot\system32\drivers\crowdstrike\*.sys"; ExecutablePath = "CrowdStrike\CSFalconService.exe"; ProcessName = "CSFalconService" }
        [PSCustomObject]@{ Name = "Cylance"; DisplayName = "Cylance OPTICS", "Cylance Smart Antivirus", "Cylance PROTECT"; Definitions = "$env:ProgramData\Cylance\Desktop\chp.db"; ExecutablePath = "Cylance\Desktop\CylanceSvc.exe", "Cylance\Optics\CyOptics.exe"; ProcessName = "cylancesvc", "cylancedrv", "CyOptics" }
        [PSCustomObject]@{ Name = "ESET Security"; DisplayName = "ESET Security", "ESET Endpoint Security", "ESET Management Agent", "ESET Server Security"; RegistryDefPath = "HKLM:\SOFTWARE\ESET\ESET Security\CurrentVersion\Info"; RegistryDefName = "ScannerVersion"; ExecutablePath = "ESET\RemoteAdministrator\Agent\ERAAgent.exe", "ESET\ESET Security\ekrn.exe"; ProcessName = "ERAAgent", "ekrn" }
        [PSCustomObject]@{ Name = "Huntress"; DisplayName = "Huntress Agent"; ExecutablePath = "Huntress\HuntressAgent.exe"; ProcessName = "HuntressAgent", "HuntressRio" }
        [PSCustomObject]@{ Name = "MalwareBytes"; DisplayName = "Malwarebytes"; Definitions = "$env:ProgramData\Malwarebytes\MBAMService\scan.mbdb"; ExecutablePath = "Malwarebytes\Anti-Malware\mbam.exe", "Malwarebytes\Anti-Malware\MBAMService.exe"; ProcessName = "MBAMService" }
        [PSCustomObject]@{ Name = "Windows Defender"; ProcessName = "MsMpEng" }
        [PSCustomObject]@{ Name = "Sentinel Agent"; DisplayName = "Sentinel Agent"; Definitions = "$env:ProgramFiles\SentinelOne\Sentinel Agent *\config\DecoyPersistentConfig.json"; ExecutablePath = "SentinelOne\Sentinel Agent *\SentinelAgent.exe"; ProcessName = "SentinelServiceHost", "SentinelStaticEngine", "SentinelStaticEngineScanner", "SentinelUI" }
        [PSCustomObject]@{ Name = "Sophos"; DisplayName = "Sophos Endpoint Agent"; RegistryDefPath = "HKLM:\SOFTWARE\Sophos\Sophos File Scanner\Application\Versions"; RegistryDefName = "VirusDataVersion"; ExecutablePath = "Sophos\Remote Management System\ManagementAgentNT.exe", "Sophos\Sophos Anti-Virus\SavService.exe", "Sophos\Endpoint Defense\SEDService.exe"; ProcessName = "ManagementAgentNT", "SAVService", "SEDService" }
        [PSCustomObject]@{ Name = "Vipre"; DisplayName = "VIPRE Business Agent"; Definitions = "$env:ProgramFiles\VIPRE Business Agent\Definitions\defver.txt"; ExecutablePath = "VIPRE\SBAMSvc.exe"; ProcessName = "SBAMSvc" }
        [PSCustomObject]@{ Name = "Webroot SecureAnywhere"; DisplayName = "Webroot SecureAnywhere"; Definitions = "$env:ProgramData\WRData\WRlog.log"; ExecutablePath = "Webroot\WRSA.exe"; ProcessName = "WRSA" }
    )

    $ExitCode = 0
}
process {

    # Let's see what tools we don't want to alert on.
    $ExcludedAVs = New-Object System.Collections.Generic.List[String]

    if ($ExcludeAV) {
        $ExcludeAV.split(',') | ForEach-Object {
            $ExcludedAVs.Add($_.Trim())
        }
    }

    # For this kind of alert it might be worth it to create a whole custom field of ignorables.
    if ($ExclusionsFromCustomField) {
        try {
            Write-Host "Retrieving exclusions from custom field '$ExclusionsFromCustomField'..."
            $Exclusions = Get-NinjaProperty -Name $ExclusionsFromCustomField
            Write-Host "Successfully retrieved $Exclusions."
        }
        catch {
            Write-Host "[Error] $($_.Message)"
            exit 1
        }
        
        if ($Exclusions) {
            $Exclusions.split(',') | ForEach-Object {
                $ExcludedAVs.Add($_.Trim())
            }
        }
    }

    # WMI Would have better AV coverage and would likely be more accurate. However Windows Server does not have the Security Center
    if (Test-IsWorkstation) {
        Write-Host "Desktop Windows Detected, Checking the Windows Security Center...."
        $AVinfo = if ($PSVersionTable.PSVersion.Major -ge 5) {
            Get-CimInstance -Namespace root/SecurityCenter2 -Class AntivirusProduct
        }
        else {
            Get-WmiObject -Namespace root/SecurityCenter2 -Class AntivirusProduct
        }
    }

    $AVs = New-Object System.Collections.Generic.List[Object]

    # This takes our list and begins searching by the 4 methods in the begin block.
    if ($AVInfo) {
        Write-Warning "Antivirus info received from the Windows Security Center, this may result in duplicate entries in the report due to their naming scheme."
        $AVinfo | ForEach-Object {
            $Executable = ($_.pathToSignedReportingExe -replace '%programfiles%', "$env:ProgramFiles" | Get-Item).BaseName
            $RunningStatus = Find-Process -Name $Executable

            $ConvertToHex = [Convert]::ToString($_.ProductState, 16).PadLeft(6, '0')
            $ProductStateHex = $ConvertToHex.Substring(2, 2)
            $DefinitionsHex = $ConvertToHex.Substring(4, 2)

            $ProductState = switch ($ProductStateHex) {
                "10" { "Active" }
                default { "Inactive" }
            }

            $UpToDateWMI = switch ($DefinitionsHex) {
                "00" { $True }
                default { $False }
            }

            if ($_.displayName -eq "Windows Defender" -and ((Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue).Count -ne 0)) {
                $Version = (Get-MpComputerStatus).AMProductVersion
                $Definitions = (Get-MpComputerStatus).AntivirusSignatureLastUpdated
            }
            else {
                $Definitions = Get-Date $_.timestamp -ErrorAction SilentlyContinue
            }

            $UpToDate = if ($Definitions -and $Definitions -gt (Get-Date).AddDays(-$OutOfDate) -and ($UpToDateWMI -like "True")) {
                $True
            }
            else {
                $False
            }

            if ($_.displayName -ne "Windows Defender") {
                $Version = Find-UninstallKey -Version -DisplayName "$($_.displayName)"
            }

            [PSCustomObject]@{
                Name        = $_.displayName
                Installed   = "Yes"
                Definitions = if ($Definitions) { Get-Date $Definitions -Format "yyyy/MM/dd" }else { $null }
                UpToDate    = $UpToDate
                Running     = if ($RunningStatus) { "Yes" }else { "No" }
                Service     = $ProductState
                Version     = if ($Version) { "$Version" }else { $null }
            } | Where-Object { $ExcludedAVs -notcontains $_.Name } | ForEach-Object { $AVs.Add($_) }
        } 
    }

    $AVList | Where-Object { $AVs.Name -notcontains $_.Name } | ForEach-Object {

        $UninstallKey = if ($_.DisplayName) {
            $_.DisplayName | Find-UninstallKey
        }
        
        $UninstallInfo = if ($_.DisplayName) {
            $_.DisplayName | Find-UninstallKey -Version
        }
        
        $RunningStatus = if ($_.ProcessName) {
            $_.ProcessName | Find-Process
        }

        $ServiceStatus = if ($_.ProcessName) {
            $_.ProcessName | Find-Service
        }

        # AV's don't really have a consistent way to check their definitions (unless it's desktop windows)
        $Definitions = if ($_.Definitions) {
            $_.Definitions | Find-Definitions
        }
        elseif ($_.Name -eq "BitDefender") {
            [xml]$xml = Get-Content $_.xmlPath -ErrorAction SilentlyContinue
            if ($xml) {
                [datetime]$origin = '1970-01-01 00:00:00'
                $ConvertFromUnix = $origin.AddSeconds($xml.UpdateStatistics.Antivirus.Check.updtime)
                Get-Date ($ConvertFromUnix.ToLocalTime()) -ErrorAction SilentlyContinue
            }
        }
        elseif ($_.Name -eq "Sophos") {
            $RegValue = (Get-ItemProperty -Path $_.RegistryDefPath -ErrorAction SilentlyContinue).($_.RegistryDefName)
            if ($RegValue) {
                Get-Date ([datetime]::ParseExact($RegValue.SubString(0, 8), 'yyyyMMdd', $null)) -ErrorAction SilentlyContinue
            }
        }
        elseif ($_.Name -eq "ESET") {
            $RegValue = (Get-ItemProperty -Path $_.RegistryDefPath -ErrorAction SilentlyContinue).($_.RegistryDefName)
            if ($RegValue) {
                $RegValue -match '(\d{8})' | Out-Null
                Get-Date ([datetime]::ParseExact($Matches[0], 'yyyyMMdd', $null)) -ErrorAction SilentlyContinue
            }
        }
        
        $InstallPath = if ($_.ExecutablePath) {
            $_.ExecutablePath | Find-Executable
        }
        elseif ($_.SpecialExecutablePath) {
            $_.SpecialExecutablePath | Find-Executable -Special
        }

        if ($UninstallKey -or $RunningStatus -or $InstallPath -or $ServiceStatus) {
            $Installed = "Yes"
        }
        else {
            $Installed = "No"
        }

        if ($_.Name -eq "Windows Defender" -and ((Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue).Count -ne 0)) {
            $UninstallInfo = (Get-MpComputerStatus).AMProductVersion
            $Definitions = (Get-MpComputerStatus).AntivirusSignatureLastUpdated
        }

        $UpToDate = if ($Definitions -and $Definitions -gt (Get-Date).AddDays(-$OutOfDate)) {
            $True
        }
        else {
            $False
        }

        [PSCustomObject]@{
            Name        = $_.Name
            Installed   = $Installed
            Definitions = if ($Definitions) { Get-Date $Definitions -Format "yyyy/MM/dd" }else { $Null }
            UpToDate    = $UpToDate
            Running     = if ($RunningStatus) { "Yes" }else { "No" }
            Service     = if ($ServiceStatus) { "Active" }else { "Inactive" }
            Version     = $UninstallInfo
        } | Where-Object { $ExcludedAVs -notcontains $_.Name } | ForEach-Object { $AVs.Add($_) }
    }

    $InstalledAVs = $AVs | Where-Object { $_.Installed -eq "Yes" }
    Write-Host ""

    if (!$InstalledAVs) {
        Write-Host "[Alert] It appears there's no installed antivirus? You may want to check the list of AV's this script supports."
        $ExitCode = 1
    }
    
    if ($InstalledAVs | Where-Object { $_.UpToDate -Like "False" }) {
        Write-Host "[Alert] The AV definitions are out of date!"
        $ExitCode = 1
    }

    if ($InstalledAVs | Where-Object { $_.HasRunningService -Like "False" }) {
        Write-Host "[Alert] The AV's service doesn't appear to be running, is the AV Updating or performing maintenance?"
        $ExitCode = 1
    }

    if ($InstalledAVs | Where-Object { $_.CurrentlyRunning -Like "False" }) {
        Write-Host "[Alert] The AV doesn't appear to have a running process, is the AV Updating or performing maintenance?"
        $ExitCode = 1
    }

    # If we found anything in the four checks, we're going to indicate it's installed, but we may also want to save our results to a custom field.
    if ($ShowNotFound) {
        $AVs | Format-Table -AutoSize -Wrap | Out-String | Write-Host
    }
    else {
        if ($InstalledAVs) {
            $InstalledAVs | Format-Table -AutoSize -Wrap | Out-String | Write-Host
        }
    }

    if ($ExportAll) {
        $ExportReport = $InstalledAVs | Format-Table -AutoSize -Wrap | Out-String
        try {
            Write-Host "Attempting to set Custom Field '$ExportAll'."
            Set-NinjaProperty -Name $ExportAll -Value $ExportReport
            Write-Host "Successfully set Custom Field '$ExportAll'!"
        }
        catch {
            Write-Host "[Error] $($_.Message)"
            $ExitCode = 1
        }
    }

    if ($ExportDef) {
        try {
            Write-Host "Attempting to set Custom Field '$ExportDef'."
            $Value = ($InstalledAVs | Select-Object -ExpandProperty Definitions) -join ', '
            Set-NinjaProperty -Name $ExportDef -Value ( $Value | Out-String )
            Write-Host "Successfully set Custom Field '$ExportDef'!"
        }
        catch {
            Write-Host "[Error] $($_.Message)"
            $ExitCode = 1
        }
    }

    if ($ExportDefStatus) {
        try {
            Write-Host "Attempting to set Custom Field '$ExportDefStatus'."
            $Value = ($InstalledAVs | Select-Object -ExpandProperty UpToDate) -join ', '
            Set-NinjaProperty -Name $ExportDefStatus -Value ( $Value | Out-String )
            Write-Host "Successfully set Custom Field '$ExportDefStatus'!"
        }
        catch {
            Write-Host "[Error] $($_.Message)"
            $ExitCode = 1
        }
    }

    if ($ExportName) {
        try {
            Write-Host "Attempting to set Custom Field '$ExportName'."
            $Value = ($InstalledAVs | Select-Object -ExpandProperty Name) -join ', '
            Set-NinjaProperty -Name $ExportName -Value ( $Value | Out-String )
            Write-Host "Successfully set Custom Field '$ExportName'!"
        }
        catch {
            Write-Host "[Error] $($_.Message)"
            $ExitCode = 1
        } 
    }

    if ($ExportStatus) {
        try {
            Write-Host "Attempting to set Custom Field '$ExportStatus'."
            $Value = ($InstalledAVs | Select-Object -ExpandProperty Running) -join ', '
            Set-NinjaProperty -Name $ExportStatus -Value ( $Value | Out-String )
            Write-Host "Successfully set Custom Field '$ExportStatus'!"
        }
        catch {
            Write-Host "[Error] $($_.Message)"
            $ExitCode = 1
        }
    }

    if ($ExportVersion) {
        try {
            Write-Host "Attempting to set Custom Field '$ExportVersion'."
            $Value = (($InstalledAVs | Select-Object -ExpandProperty Version | ForEach-Object { $_.Trim() }) -join ', ')
            Set-NinjaProperty -Name $ExportVersion -Value ($Value | Out-String)
            Write-Host "Successfully set Custom Field '$ExportVersion'!"
        }
        catch {
            Write-Host "[Error] $($_.Message)"
            $ExitCode = 1
        }
    }

    exit $ExitCode
}end {
    
    
    
}
