<#
.SYNOPSIS
    Downloads a file from a provided URL to a specified path. The script can compare file hashes and automatically remove a failed download. For URLs requiring basic authentication, provide a username and password.

.DESCRIPTION
    This script downloads a file from a given URL to a designated path. 
    It offers the capability to compare file hashes and automatically delete a download if it fails. 
    If the URL mandates basic authentication, you must input a username and password.

.EXAMPLE
    -Url "https://www.google.com/" -FilePath "C:\temp\index.html"
    This command downloads the index.html page from google.com to C:\temp\index.html.

.EXAMPLE
    -Url "https://www.nirsoft.net/utils/advancedrun.zip" -FilePath "C:\temp\advancedrun.zip" -Hash "b2c65aa6e71b0f154c5f3a8b884582779d716ff2c03d6cdca9e157f0fe397c9c" -Algorithm SHA256
    This command downloads the advancedrun.zip file from nirsoft.net to C:\temp\advancedrun.zip and validates that the SHA256 hash matches.

.EXAMPLE
    -Url "https://www.nirsoft.net/utils/advancedrun.zip" -FilePath "C:\temp\advancedrun.zip" -Hash "b2c65aa6e71b0f154c5f3a8b884582779d716ff2c03d6cdca9e157f0fe397c9c" -AutoRemove
    This command downloads the advancedrun.zip file from nirsoft.net to C:\temp\advancedrun.zip and checks that the SHA256 hash matches. If there's a mismatch, the file is deleted. If the Algorithm parameter isn't specified, it defaults to SHA256.

.OUTPUTS
    None

.NOTES
    Minimum OS Architecture Supported: Windows 7, Windows Server 2008 R2
    Release Notes: 
    - Renamed script and added Script Variable support.
    - The script now creates a download directory if it doesn't exist.
    - Added redirect support (not available on Windows 7 or Server 2008).
    - Implemented multiple download attempts and delays before retries.
    - Hash verification is now compatible with older OS versions.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$URL,
    [Parameter()]
    [string]$FilePath,
    [Parameter()]
    [string]$Hash,
    [Parameter()][ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MD5")]
    [string]$Algorithm = "SHA256",
    [Parameter()]
    [switch]$AutoRemove = [System.Convert]::ToBoolean($env:cleanupFailedDownloads),
    [Parameter()]
    [string]$UserName,
    [Parameter()]
    $Password,
    [Parameter()]
    [int]$Attempts = 3,
    [Parameter()]
    [Switch]$SkipSleep = [System.Convert]::ToBoolean($env:skipSleep),
    [Parameter()]
    [Switch]$Overwrite = [System.Convert]::ToBoolean($env:overwrite)
)
# Helper functions and input validation
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
    # If Dynamic Script Variables are used replace the parameters
    if ($env:linkToFile -and $env:linkToFile -notlike "null") { $Url = $env:linkToFile }
    if ($env:destinationFilePath -and $env:destinationFilePath -notlike "null") { $FilePath = $env:destinationFilePath }
    if ($env:verificationHash -and $env:verificationHash -notlike "null") { $Hash = $env:verificationHash }
    if ($env:hashAlgorithm -and $env:hashAlgorithm -notlike "null") { $Algorithm = $env:hashAlgorithm }
    if ($env:usernameForDownload -and $env:usernameForDownload -notlike "null") { $UserName = $env:usernameForDownload }
    # Get password from secure custom field
    if ($env:passwordForDownloadWithCustomField -and $env:passwordForDownloadWithCustomField -notlike "null") { 
        try {
            $Password = Get-NinjaProperty -Name $env:passwordForDownloadWithCustomField
        }
        catch {
            Write-Host "[Error] Failed to get password from secure custom field."
            exit 1
        }
    }
    if ($env:downloadAttempts -and $env:downloadAttempts -notlike "null") { $Attempts = $env:downloadAttempts }

    # URL and FilePath are the only mandatory parameters
    if (-not ($Url)) { Write-Error "A URL is required for this script."; Exit 1 }
    if (-not ($FilePath)) { Write-Error "A File Path is required for this script."; Exit 1 }

    # In case 'https://' is omitted from the URL.
    if ($Url -notmatch "^http(s)?://") {
        Write-Warning "http(s):// is required to download the file. Adding https:// to your input...."
        $Url = "https://$Url"
        Write-Warning "New Url $Url."
    }

    # Basic authentication requires both a username and a password.
    if ((-not ($UserName) -and $Password) -or ($Username -and -not ($Password))) {
        Write-Error "Username and Password must be used together!"
        Exit 1
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (-not (Test-IsElevated)) {
        Write-Warning "You're currently running this script without local admin privileges. If the script fails ensure $env:USERNAME has permission to create a file at $(Split-Path $FilePath)."
    }

    # If the directory doesn't exist we'll need to create it
    if ($FilePath -and -not (Test-Path -Path (Split-Path $FilePath) -ErrorAction SilentlyContinue)) {
        New-Item -ItemType Directory -Path (Split-Path $FilePath) -ErrorAction Stop | Out-Null
    }

    # For PowerShell 2.0 and 3.0 compatibility we're going to need to create a Get-FileHash function
    if ($PSVersionTable.PSVersion.Major -lt 4) {
        function Get-FileHash {
            param (
                [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                [string[]]$Path,
                [Parameter(Mandatory = $false)]
                [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MD5")]
                [string]$Algorithm = "SHA256"
            )
            $Path | ForEach-Object {
                # Only hash files that exist
                $CurrentPath = $_
                if ($(Test-Path -Path $CurrentPath -ErrorAction SilentlyContinue)) {
                
                    $HashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
                    $Hash = [System.BitConverter]::ToString($hashAlgorithm.ComputeHash([System.IO.File]::ReadAllBytes($CurrentPath)))
                    @{
                        Algorithm = $Algorithm
                        Path      = $Path
                        Hash      = $Hash.Replace('-', '')
                    }
                }
            }
        }
    }

    # This function returns 'true' or 'false' based on whether the hash matches the file given, and provides console output.
    function Test-Hash {
        param (
            [Parameter()]
            [String]$File,
            [Parameter()]
            [String]$Algorithm,
            [Parameter()]
            [String]$Hash
        )

        try {
            Write-Host "Computing hash using $Algorithm"
            $ComputedHash = $(Get-FileHash -Path $File -Algorithm $Algorithm).Hash
            Write-Host "Computed hash for $File is $ComputedHash"
            if ($ComputedHash -like $Hash) {
                Write-Host "$File hash matched!"
                return $True
            }
            else {
                $RelevantFile = $File | Split-Path -Leaf
                throw "Hash Mismatch for file $RelevantFile."
            }
        }
        catch {
            Write-Warning $_.Exception.Message
            Write-Warning "Computed hash was: $ComputedHash"
            Write-Warning "Expected hash was: $Hash"
            return $False
        }
        
    }

    # Utility function for downloading.
    function Invoke-Download {
        param(
            [Parameter()]
            [String]$URL,
            [Parameter()]
            [String]$Path,
            [Parameter()]
            [int]$Attempts,
            [Parameter()]
            [String]$Username,
            [Parameter()]
            $Password,
            [Parameter()]
            [String]$Algorithm,
            [Parameter()]
            [String]$Hash,
            [Parameter()]
            [Switch]$SkipSleep,
            [Parameter()]
            [Switch]$AutoRemove
        )
        Write-Host "URL given, Downloading the file..."

        $SupportedTLSversions = [enum]::GetValues('Net.SecurityProtocolType')
        if ( ($SupportedTLSversions -contains 'Tls13') -and ($SupportedTLSversions -contains 'Tls12') ) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol::Tls13 -bor [System.Net.SecurityProtocolType]::Tls12
        }
        elseif ( $SupportedTLSversions -contains 'Tls12' ) {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        }
        else {
            # Not everything requires TLS 1.2, but we'll try anyways.
            Write-Warning "TLS 1.2 and or TLS 1.3 isn't supported on this system. This download may fail!"
            if ($PSVersionTable.PSVersion.Major -lt 3) {
                Write-Warning "PowerShell 2 / .NET 2.0 doesn't support TLS 1.2."
            }
        }

        $i = 1
        While ($i -le $Attempts) {
            # Some cloud services have rate-limiting
            if (-not ($SkipSleep)) {
                $SleepTime = Get-Random -Minimum 3 -Maximum 30
                Write-Host "Waiting for $SleepTime seconds."
                Start-Sleep -Seconds $SleepTime
            }
            if ($i -ne 1) { Write-Host "" }
            Write-Host "Download Attempt $i"

            try {
                # Invoke-WebRequest is preferred just due to it supports links that redirect e.g. https://t.ly
                if ($PSVersionTable.PSVersion.Major -lt 4) {
                    $WebClient = New-Object System.Net.WebClient
                    if ($Username -and $Password) {
                        # In my testing Net.NetworkCredential is expecting the password in plain text
                        $WebClient.Credentials = New-Object System.Net.NetworkCredential($UserName, $Password)
                    }

                    # Downloads the file
                    $WebClient.DownloadFile($URL, $Path)
                }
                else {
                    # Standard options
                    $WebRequestArgs = @{
                        Uri                = $URL
                        OutFile            = $Path
                        MaximumRedirection = 10
                        UseBasicParsing    = $true
                    }
                    if ($Username -and $Password) {
                        # We should convert this to a secure string as soon as we're able.
                        if (-not ($Password -is [System.Security.SecureString])) {
                            $Password = $Password | ConvertTo-SecureString -AsPlainText -Force
                        }
                        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $Password
                        $WebRequestArgs["Credential"] = $Credentials
                    }

                    # Downloads the file
                    Invoke-WebRequest @WebRequestArgs
                }

                $File = Test-Path -Path $Path -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "An error has occurred while downloading!"
                Write-Warning $_.Exception.Message
            }

            if ($File) {
                # Now that we have the file we might need to validate it.
                if ($Hash -and -not (Test-Hash -File $Path -Algorithm $Algorithm -Hash $Hash)) {
                    $FailedHash = $True
                    # If validation failed do we need to remove the file?
                    if ($AutoRemove) {
                        Write-Host ""
                        Write-Host "Removing failed download."

                        Remove-Item $Path -Force -Confirm:$false -ErrorAction SilentlyContinue
                        Write-Host "Removed failed download."
                    }
                }
                else {
                    $FailedHash = $False
                    $i = $Attempts
                }
            }
            else {
                Write-Warning "File failed to download."
                Write-Host ""
            }

            $i++
        }

        if (-not (Test-Path $Path) -or ($FailedHash)) {
            Write-Error "Failed to download file!"
            Exit 1
        }
        else {
            return $Path
        }
    }
}
process {

    # The following arguments are always present
    $DownloadArgs = @{
        Url      = $URL
        Path     = $FilePath
        Attempts = $Attempts
    }

    # Optional arguments derived from the provided parameters
    if ($UserName) { $DownloadArgs["UserName"] = $UserName }
    if ($Password) { $DownloadArgs["Password"] = $Password }
    if ($Algorithm) { $DownloadArgs["Algorithm"] = $Algorithm }
    if ($Hash) { $DownloadArgs["Hash"] = $Hash }
    if ($SkipSleep) { $DownloadArgs["SkipSleep"] = $True }
    if ($AutoRemove) { $DownloadArgs["AutoRemove"] = $True }

    # If we're not supposed to overwrite the file we should check the hash to see if that's irrelevant
    if (-not ($Overwrite) -and $Hash -and (Test-Path $FilePath -ErrorAction SilentlyContinue)) {
        Write-Warning "Existing file found and Overwrite was not specified. Verifying hash...."
        if (-not (Test-Hash -Hash $Hash -Algorithm $Algorithm -File $FilePath)) {
            Write-Error "Hash does not match"
            Exit 1
        }
        else {
            Write-Host "Successfully downloaded file to $FilePath"
            Exit 0
        }
    }
    
    # If we're allowed to overwrite the file we should check the hash to see if that's irrelevant
    if ($Overwrite -and $Hash -and (Test-Path $FilePath -ErrorAction SilentlyContinue)) {
        Write-Host "Existing file found. Checking to see if hashes match..."
        if (Test-Hash -Hash $Hash -Algorithm $Algorithm -File $FilePath) {
            Write-Host "File is identical to what would be downloaded. Skipping download and considering it a success!"
            Write-Host "Successfully downloaded file to $FilePath"
            Exit 0
        }
    }

    # If we're not supposed to overwrite the file, and we don't have a hash to validate, we'll error out.
    if (-not ($Overwrite) -and (Test-Path $FilePath -ErrorAction SilentlyContinue)) {
        Write-Error "Existing file found and Overwrite was not specified."
        Exit 1
        
    }

    # Downloads the file
    $Download = Invoke-Download @DownloadArgs

    # The function returns the file path upon success. It will handle errors and exit independently if unsuccessful.
    if ($Download) {
        Write-Host ""
        Write-Host "Successfully downloaded file to $Download"
        Exit 0
    }
   
}
end {
    
    
    
}
