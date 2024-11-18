#Requires -Version 5.1

<#
.SYNOPSIS
    Deploy a wifi profile to all users on a given device.
.DESCRIPTION
    Deploy a wifi profile to all users on a given device.
.EXAMPLE
    -SSID "cookiemonster" -PreSharedKeyCustomField "WifiPass"

    Retrieving preshared key from secure custom field 'WifiPassword'.
    Successfully retrieved preshared key.
    Creating XML for Wi-Fi profile 'cookiemonster'.
    Saving XML to C:\Windows\Temp\wi-fi.251d970a-299d-48a2-a256-341542983464.xml
    Importing Wi-Fi profile 'cookiemonster' from XML.
    ExitCode: 0
    Profile 'cookiemonster' is added on interface Wi-Fi.
    Removing xml.

PARAMETER: -SSID "ReplaceMeWithYourWi-FiName"
    Specify the Wi-Fi SSID/name.

PARAMETER: -AuthType "WPA3SAE"
    Select either WPA2 authentication or WPA3..

PARAMETER: -PreSharedKeyCustomField "ReplaceMeWithASecureCustomField"
    Specify the name of a secure custom field that contains the preshared key.

PARAMETER: -Overwrite
    If the profile already exists overwrite it.

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes: Initial Release
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$SSID,
    [Parameter()]
    [String]$AuthType = "WPA2PSK",
    [Parameter()]
    [String]$PreSharedKeyCustomField,
    [Parameter()]
    [Switch]$Overwrite = [System.Convert]::ToBoolean($env:overwrite)
)

begin {
    # If script form variables are used replace the command line parameters.
    if ($env:ssid -and $env:ssid -notlike "null") { $SSID = $env:ssid }
    if ($env:authenticationType -and $env:authenticationType -notlike "null") { $AuthType = $env:authenticationType }
    if ($env:nameOfASecureCustomFieldContainingPresharedKey -and $env:nameOfASecureCustomFieldContainingPresharedKey -notlike "null") { $PreSharedKeyCustomField = $env:nameOfASecureCustomFieldContainingPresharedKey }

    # If no Wi-Fi interfaces exist or the wireless service is not running, display an error message indicating that they are required.
    try {
        $WifiAdapters = Get-NetAdapter -ErrorAction Stop | Where-Object { $_.PhysicalMediaType -match '802\.11' }
        if (!$WifiAdapters) {
            Write-Host -Object "[Error] No Wi-Fi network interfaces exist on the system."
            exit 1
        }

        $WlanService = Get-Service -Name 'wlansvc' -ErrorAction Stop | Where-Object { $_.Status -eq 'Running' }
        if (!$WlanService) {
            Write-Host -Object "[Error] The service 'wlansvc' is not running. The service 'wlansvc' is required to add the Wi-Fi network."
            exit 1
        }
    }
    catch {
        Write-Host -Object "[Error] Unable to verify if a Wi-Fi network interface exists and that the 'wlansvc' service is running."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        exit 1
    }

    # If $SSID is provided, trim any leading or trailing whitespace from the SSID
    if ($SSID) {
        $SSID = $SSID.Trim()
    }

    # If $SSID is not provided or is empty after trimming, display an error message indicating the SSID is required
    if (!$SSID) {
        Write-Host -Object "[Error] The Wi-Fi SSID/name is required to add Wi-Fi profile to the device."
        exit 1
    }

    # If $AuthType is provided, trim any leading or trailing whitespace from the authentication type
    if ($AuthType) {
        $AuthType = $AuthType.Trim()
    }

    # If $AuthType is not provided or is empty after trimming, display an error message indicating the authentication type is required
    if (!$AuthType) {
        Write-Host -Object "[Error] No authentication type given. The authentication type is required."
        exit 1
    }

    # If $PreSharedKeyCustomField is provided, trim any leading or trailing whitespace from the preshared key custom field
    if ($PreSharedKeyCustomField) {
        $PreSharedKeyCustomField = $PreSharedKeyCustomField.Trim()
    }

    # If $PreSharedKeyCustomField is not provided or is empty after trimming, display an error message indicating the preshared key custom field is required
    if (!$PreSharedKeyCustomField) {
        Write-Host -Object "[Error] You must provide the name of a secure custom field that contains the preshared key."
        exit 1
    }

    # Measure the length of the SSID and store it in $SSIDCharcterLength
    $SSIDCharacterLength = $SSID | Measure-Object -Character | Select-Object -ExpandProperty Characters
    # If the SSID length is greater than 32 characters, display an error message indicating the SSID length constraint
    if ($SSIDCharacterLength -gt 32) {
        Write-Host -Object "[Error] The SSID '$SSID' is greater than 32 characters. SSIDs must be less than or equal to 32 characters."
        exit 1
    }

    # Define valid authentication types
    $ValidAuthTypes = "WPA2PSK", "WPA3SAE"
    # If the provided authentication type is not valid, display an error message indicating the valid authentication types
    if ($ValidAuthTypes -notcontains $AuthType) {
        Write-Host -Object "[Error] The authentication type '$AuthType' is invalid. The only valid authentication types are 'WPA2PSK' and 'WPA3SAE'."
        exit 1
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
        
        # Initialize a hashtable for documentation parameters
        $DocumentationParams = @{}
        if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }
        
        # Define types that need options
        $NeedsOptions = "DropDown", "MultiSelect"
        
        if ($DocumentName) {
            # Check for invalid type 'Secure'
            if ($Type -Like "Secure") { throw [System.ArgumentOutOfRangeException]::New("$Type is an invalid type! Please check here for valid types. https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality") }
        
            # Retrieve the property value from Ninja Document
            Write-Host "Retrieving value from Ninja Document..."
            $NinjaPropertyValue = Ninja-Property-Docs-Get -AttributeName $Name @DocumentationParams 2>&1
        
            # Retrieve property options if needed
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Docs-Options -AttributeName $Name @DocumentationParams 2>&1
            }
        }
        else {
            # Retrieve the property value directly
            $NinjaPropertyValue = Ninja-Property-Get -Name $Name 2>&1
        
            # Retrieve property options if needed
            if ($NeedsOptions -contains $Type) {
                $NinjaPropertyOptions = Ninja-Property-Options -Name $Name 2>&1
            }
        }
        
        # Throw exceptions if errors occur during retrieval
        if ($NinjaPropertyValue.Exception) { throw $NinjaPropertyValue }
        if ($NinjaPropertyOptions.Exception) { throw $NinjaPropertyOptions }
        
        # Throw an exception if the property value is empty
        if (-not $NinjaPropertyValue) {
            throw [System.NullReferenceException]::New("The Custom Field '$Name' is empty!")
        }
        
        # Process the property value based on its type
        switch ($Type) {
            "Attachment" {
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Checkbox" {
                [System.Convert]::ToBoolean([int]$NinjaPropertyValue)
            }
            "Date or Date Time" {
                $UnixTimeStamp = $NinjaPropertyValue
                $UTC = (Get-Date "1970-01-01 00:00:00").AddSeconds($UnixTimeStamp)
                $TimeZone = [TimeZoneInfo]::Local
                [TimeZoneInfo]::ConvertTimeFromUtc($UTC, $TimeZone)
            }
            "Decimal" {
                [double]$NinjaPropertyValue
            }
            "Device Dropdown" {
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Device MultiSelect" {
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Dropdown" {
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Options | Where-Object { $_.GUID -eq $NinjaPropertyValue } | Select-Object -ExpandProperty Name
            }
            "Integer" {
                [int]$NinjaPropertyValue
            }
            "MultiSelect" {
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = ($NinjaPropertyValue -split ',').trim()
        
                foreach ($Item in $Selection) {
                    $Options | Where-Object { $_.GUID -eq $Item } | Select-Object -ExpandProperty Name
                }
            }
            "Organization Dropdown" {
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Organization Location Dropdown" {
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Organization Location MultiSelect" {
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Organization MultiSelect" {
                $NinjaPropertyValue | ConvertFrom-Json
            }
            "Time" {
                $Seconds = $NinjaPropertyValue
                $UTC = ([timespan]::fromseconds($Seconds)).ToString("hh\:mm\:ss")
                $TimeZone = [TimeZoneInfo]::Local
                $ConvertedTime = [TimeZoneInfo]::ConvertTimeFromUtc($UTC, $TimeZone)
        
                Get-Date $ConvertedTime -DisplayHint Time
            }
            default {
                $NinjaPropertyValue
            }
        }
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (!$ExitCode) {
        $ExitCode = 0
    }
}
process {
    # If the script is not running with elevated privileges, display an error and exit
    if (!(Test-IsElevated)) {
        Write-Host -Object "[Error] Access Denied. Please run with Administrator privileges."
        exit 1
    }

    try {
        Write-Host -Object "Retrieving preshared key from secure custom field '$PreSharedKeyCustomField'."

        # Attempt to get the custom field value
        $PreSharedKey = Get-NinjaProperty -Name $PreSharedKeyCustomField -ErrorAction Stop

        Write-Host -Object "Successfully retrieved preshared key."
    }
    catch {
        # If an error occurs, display the error message and exit
        Write-Host -Object "[Error] $($_.Exception.Message)"
        exit 1
    }

    # If $PreSharedKey is not retrieved or is empty, display an error and exit
    if (!$PreSharedKey) {
        Write-Host -Object "Failed to retrieve preshared key."
        exit 1
    }
    else {
        # Measure the length of the preshared key and store it in $PreSharedKeyCharacters
        $PreSharedKeyCharacters = $PreSharedKey | Measure-Object -Character | Select-Object -ExpandProperty Characters

        # If the preshared key length is less than 8 or greater than 63 characters, display an error and exit
        if ($PreSharedKeyCharacters -lt 8 -or $PreSharedKeyCharacters -gt 63) {
            Write-Host -Object "[Error] The preshared key needs to be at least 8 characters and less than 64 characters."
            exit 1
        }
    }

    # Define the paths for standard error and output logs
    $StandardErrorPath = "$env:TEMP\wi-fi.prof.$(New-Guid).err.log"
    $StandardOutputPath = "$env:TEMP\wi-fi.prof.$(New-Guid).out.log"

    # Define the arguments for the netsh command to show existing Wi-Fi profiles
    $ExistingProfilesArguments = @(
        "wlan"
        "show"
        "profiles"
    )
    
    # Define the arguments for starting the netsh process
    $ExistingProfilesProcessArguments = @{
        Wait                   = $True
        PassThru               = $True
        NoNewWindow            = $True
        ArgumentList           = $ExistingProfilesArguments
        RedirectStandardError  = $StandardErrorPath
        RedirectStandardOutput = $StandardOutputPath
        FilePath               = "$env:SystemRoot\System32\netsh.exe"
    }

    # Attempt to start the netsh process to show existing Wi-Fi profiles
    try {
        Write-Host -Object "Checking for existing Wi-Fi profiles"
        $ExistingProfilesProcess = Start-Process @ExistingProfilesProcessArguments -ErrorAction Stop
    }
    catch {
        # If an error occurs while starting netsh, display an error message and exit
        Write-Host -Object "[Error] Unable to check for existing Wi-Fi profiles."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        exit 1
    }

    # Display the exit code of the netsh process
    Write-Host -Object "ExitCode: $($ExistingProfilesProcess.ExitCode)"

    # If the exit code indicates failure, display an error message
    if ($ExistingProfilesProcess.ExitCode -ne 0) {
        Write-Host -Object "[Error] Exit code does not indicate success. Failed to check for existing Wi-Fi profiles."
        $ExitCode = 1
    }

    # If the standard error log file exists, read its content
    if (Test-Path -Path $StandardErrorPath -ErrorAction SilentlyContinue) {
        $ExistingProfilesErrors = Get-Content -Path $StandardErrorPath -ErrorAction SilentlyContinue
        Remove-Item -Path $StandardErrorPath -Force -ErrorAction SilentlyContinue
    }

    # If there are any errors in the standard error log, display them
    if ($ExistingProfilesErrors) {
        Write-Host -Object "[Error] An error has occurred when executing netsh."

        $ExistingProfilesErrors | ForEach-Object {
            Write-Host -Object "[Error] $_"
        }

        $ExitCode = 1
    }

    # If the standard output log file exists, read and display its content
    if (Test-Path -Path $StandardOutputPath -ErrorAction SilentlyContinue) {
        $ExistingProfilesOutput = Get-Content -Path $StandardOutputPath -ErrorAction SilentlyContinue
        Remove-Item -Path $StandardOutputPath -Force -ErrorAction SilentlyContinue
    }

    if($ExistingProfilesOutput){
        # Prepare a CSV list to store the profile data
        $CSVData = New-Object System.Collections.Generic.List[string]
        $CSVData.Add("ProfileType,ProfileName")

        # Process the output to format it as CSV
        $ExistingProfilesOutput | Where-Object { $_ -match ':' -and $_ -notmatch 'Profiles on interface' } | ForEach-Object {
            $CSVData.Add(
                ($_ -replace "\s+:\s+",",").Trim()
            )
        }

        # Convert the CSV data to objects
        $ExistingProfiles = $CSVData | ConvertFrom-CSV

        # Check if the specified SSID is already present
        $ProfileToOverwrite = $ExistingProfiles | Where-Object { $_.ProfileName -like $SSID }

        # If the profile is found and overwrite is requested, indicate that it will be overwritten
        if($ProfileToOverwrite -and $Overwrite){
            Write-Host -Object "Wi-Fi network profile '$SSID' was detected. Overwriting as requested."
        }

        # If the profile is found and overwrite is not requested, display an error and list existing profiles
        if($ProfileToOverwrite -and !$Overwrite){
            $ExistingProfiles | Format-Table | Out-String | Write-Host
            Write-Host -Object "[Error] Wi-Fi network profile '$SSID' is already deployed to this machine. Please select the 'Overwrite' checkbox to overwrite it."
            exit 1
        }
    }

    Write-Host -Object "Creating XML for Wi-Fi profile '$SSID'."

    # Define the XML template for the Wi-Fi profile
    [XML]$ProfileXML = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name></name>
	<SSIDConfig>
		<SSID>
			<hex></hex>
			<name></name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>auto</connectionMode>
	<MSM>
		<security>
			<authEncryption>
				<authentication></authentication>
				<encryption>AES</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
			<sharedKey>
				<keyType>passPhrase</keyType>
				<protected>false</protected>
				<keyMaterial></keyMaterial>
			</sharedKey>
		</security>
	</MSM>
	<MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
		<enableRandomization>false</enableRandomization>
		<randomizationSeed></randomizationSeed>
	</MacRandomization>
</WLANProfile>
"@
    # Create a namespace manager and add namespaces
    $namespaceManager = New-Object System.Xml.XmlNamespaceManager($ProfileXML.NameTable)
    $namespaceManager.AddNamespace("ns", "http://www.microsoft.com/networking/WLAN/profile/v1")
    $namespaceManager.AddNamespace("m", "http://www.microsoft.com/networking/WLAN/profile/v3")

    # Set the WLAN name in the XML profile
    $WLANNameXML = $ProfileXML.SelectSingleNode("/ns:WLANProfile/ns:name", $namespaceManager)
    $WLANNameXML.InnerText = $SSID

    # Convert SSID to hexadecimal and set it in the XML profile
    $SSIDhex = [System.Text.Encoding]::UTF8.GetBytes($SSID) | ForEach-Object { 
        [System.String]::Format("{0:X2}", $_) 
    }
    $SSIDHexXML = $ProfileXML.SelectSingleNode("/ns:WLANProfile/ns:SSIDConfig/ns:SSID/ns:hex", $namespaceManager)
    $SSIDHexXml.InnerText = $($SSIDhex -join '')

    # Set the SSID name in the XML profile
    $SSIDNameXML = $ProfileXML.SelectSingleNode("/ns:WLANProfile/ns:SSIDConfig/ns:SSID/ns:name", $namespaceManager)
    $SSIDNameXML.InnerText = $SSID

    # Set the authentication type in the XML profile
    $AuthenticationXML = $ProfileXML.SelectSingleNode("/ns:WLANProfile/ns:MSM/ns:security/ns:authEncryption/ns:authentication", $namespaceManager)
    $AuthenticationXML.InnerText = $AuthType

    # Set the preshared key in the XML profile
    $keyMaterialXML = $ProfileXML.SelectSingleNode("/ns:WLANProfile/ns:MSM/ns:security/ns:sharedKey/ns:keyMaterial", $namespaceManager)
    $keyMaterialXML.InnerText = $PreSharedKey

    try {
        # Generate a random 32-bit unsigned integer for the randomization seed
        $Random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $SeedBytes = New-Object byte[] 4
        $Random.GetBytes($seedBytes)
        $randomizationSeed = [BitConverter]::ToUInt32($seedBytes, 0)
    }
    catch {
        # If an error occurs while creating the randomization seed, display an error message and exit
        Write-Host -Object "[Error] Failed to create randomization seed."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        exit 1
    }

    # Set the randomization seed in the XML profile
    $randomizationXML = $ProfileXML.SelectSingleNode("/ns:WLANProfile/m:MacRandomization/m:randomizationSeed", $namespaceManager)
    $randomizationXML.InnerText = $randomizationSeed

    # Define the path to save the XML profile
    $ProfilePath = "$env:TEMP\wi-fi.$(New-Guid).xml"
    Write-Host -Object "Saving XML to $ProfilePath"
    $ProfileXML.Save($ProfilePath)

    # Define the arguments for the netsh command
    $NetshArguments = @(
        "wlan"
        "add"
        "profile"
        "filename=`"$ProfilePath`""
        "user=all"
    )

    # Define the paths for standard error and output logs
    $StandardErrorPath = "$env:TEMP\wi-fi.$(New-Guid).err.log"
    $StandardOutputPath = "$env:TEMP\wi-fi.$(New-Guid).out.log"

    # Define the arguments for starting the netsh process
    $NetShProcessArguments = @{
        Wait                   = $True
        PassThru               = $True
        NoNewWindow            = $True
        ArgumentList           = $NetshArguments
        RedirectStandardError  = $StandardErrorPath
        RedirectStandardOutput = $StandardOutputPath
        FilePath               = "$env:SystemRoot\System32\netsh.exe"
    }

    # Attempt to start the netsh process to add the Wi-Fi profile
    try {
        Write-Host -Object "Importing Wi-Fi profile '$SSID' from XML."
        $NetshProcess = Start-Process @NetShProcessArguments -ErrorAction Stop
    }
    catch {
        # If an error occurs while starting netsh, display an error message and exit
        Write-Host -Object "[Error] Failed to start netsh."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        exit 1
    }

    # Display the exit code of the netsh process
    Write-Host -Object "ExitCode: $($NetshProcess.ExitCode)"

    # If the exit code indicates failure, display an error message
    if ($NetshProcess.ExitCode -ne 0) {
        Write-Host -Object "[Error] Exit code does not indicate success. Failed to add Wi-Fi profile."
        $ExitCode = 1
    }

    # If the standard error log file exists, read its content
    if (Test-Path -Path $StandardErrorPath -ErrorAction SilentlyContinue) {
        $NetshErrors = Get-Content -Path $StandardErrorPath -ErrorAction SilentlyContinue
        Remove-Item -Path $StandardErrorPath -Force -ErrorAction SilentlyContinue
    }

    # If there are any errors in the standard error log, display them
    if ($NetshErrors) {
        Write-Host -Object "[Error] An error has occurred when executing netsh."

        $NetshErrors | ForEach-Object {
            Write-Host -Object "[Error] $_"
        }

        $ExitCode = 1
    }

    # If the standard output log file exists, read and display its content
    if (Test-Path -Path $StandardOutputPath -ErrorAction SilentlyContinue) {
        $NetshOutput = Get-Content -Path $StandardOutputPath -ErrorAction SilentlyContinue
        Write-Host -Object $NetshOutput
        Remove-Item -Path $StandardOutputPath -Force -ErrorAction SilentlyContinue
    }

    # Attempt to remove the XML profile and log files
    try {
        Write-Host -Object "Removing xml."
        Remove-Item -Path $ProfilePath -Force
    }
    catch {
        # If an error occurs while removing files, display an error message and set the exit code to 1
        Write-Host -Object "[Error] Failed to remove XML or log files."
        Write-Host -Object "[Error] $($_.Exception.Message)"
        $ExitCode = 1
    }

    exit $ExitCode
}
end {
    
    
    
}