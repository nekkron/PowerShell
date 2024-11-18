#Requires -Version 5.1

<#
.SYNOPSIS
    Creates a VPN using the built-in Windows VPN client, with configuration options from Ninja Documentation or Device Custom Fields.
.DESCRIPTION
    This script will create a VPN using the built-in Windows VPN client. It will not create PPTP or "No Encryption" VPNs. 
    It can pull all the necessary VPN information from a Ninja Document or custom field you specify. 
    You can override the Documentation fields with parameters or only use parameters if you would like.

    For more information on Ninja Documentation: https://ninjarmm.zendesk.com/hc/en-us/articles/360061218431-Documentation

OPTIONAL: Custom Fields - All Fields must be readable by scripts
    # Name # - # Field Type and what values to use for dropdowns. #
    vpnName - text field
    vpnHost - text field
    tunnelType - dropdown field. Acceptable values are L2TP, SSTP, IKEV2, Automatic
    authMethod - multi-select field. Acceptable values are PAP, Chap, MSChapv2, MachineCertificate
    encryptionLevel - dropdown field. Acceptable values are Optional, Required, Maximum
    dnsSuffix - text field
    rememberCreds - Checkbox
    useWinCredentials - Checkbox
    assumeUdpEncapsulation - Checkbox
    splitTunneling - Checkbox
    createVpnShortcut - Checkbox
    shortcutUrl - URL or Text
    shortcutIconDirectory - Text

PARAMETER: -DocumentName "ReplaceWithNameOfyourNinjaDocument"
    Replace the value in quotes with the document you'd like to retireve the vpn parameters from (if any).

PARAMETER: -Name "Contoso VPN"
    The name of the VPN you would like to create

PARAMETER: -Server "replace.me"
    The endpoint/server the VPN will try to establish a connection with.

PARAMETER: -PreSharedKeyField "ReplaceMeWithNameOfSecureCustomField"
    Name of a secure custom field containing your pre-shared key.

PARAMETER: -TunnelType "L2TP"
    The Type of VPN ex. L2TP, SSTP, IKEV2, Automatic

PARAMETER: -AuthMethod "PAP,CHAP"
    The authentication methods supported by the VPN separated by commas.

PARAMETER: -EncryptionLevel "Required"
    The Encryption level used by the VPN.

PARAMETER: -DNSSuffix "contoso.local"
    The DNS Suffix used by the connection.

PARAMETER: -RememberCreds
    Whether or not the VPN should remember the previously used credentials for future connections.

PARAMETER: -UseWinlogonCredential
    Whether or not the VPN should use the Windows logon credentials for authentication.

PARAMETER: -AssumeUDPEncapsulation
    Sets the AssumeUDPEncapsulation registry key which is required by many VPNs
.LINK
    https://learn.microsoft.com/en-us/troubleshoot/windows-server/networking/configure-l2tp-ipsec-server-behind-nat-t-device

PARAMETER: -SplitTunneling
    Enables split tunneling.

PARAMETER: -CreateShortcut
    Creates a desktop shortcut for accessing the VPN.

PARAMETER: -URL
   A URL to an image you'd like to download and use for the shortcut icon. Icon will be stored at -IconDirectory.

PARAMETER: -IconDirectory "C:\ReplaceMe"
    The directory where the shortcut's icon file will be stored.

PRESET PARAMETER: -SkipSleep
    By default the script sleeps for a random interval between 3 and 60 seconds prior to downloading an icon (if the script is given a url). This parameter skips the sleep.

PARAMETER: -Overwrite
    Overwrites an existing VPN with the same name, if present.
.OUTPUTS
    None
.NOTES
    Minimum Supported OS: Windows 10
    Release Notes: Update calculated name
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]$DocumentName,
    [Parameter()]
    [String]$Name,
    [Parameter()]
    [String]$NameField = "vpnName",
    [Parameter()]
    [String]$Server,
    [Parameter()]
    [String]$ServerField = "vpnHost",
    [Parameter()]
    [String]$PreSharedKeyField,
    [Parameter()]
    [String]$TunnelType = "Automatic",
    [Parameter()]
    [String]$TunnelTypeField = "tunnelType",
    [Parameter()]
    [String[]]$AuthMethod,
    [Parameter()]
    [String]$AuthMethodField = "authMethod",
    [Parameter()]
    [String]$EncryptionLevel,
    [Parameter()]
    [String]$EncryptionLevelField = "encryptionLevel",
    [Parameter()]
    [String]$DNSSuffix,
    [Parameter()]
    [String]$DNSSuffixField = "dnsSuffix",
    [Parameter()]
    [Switch]$RememberCreds = [System.Convert]::ToBoolean($env:rememberUserCredentials),
    [Parameter()]
    [String]$RememberCredsField = "rememberCreds",
    [Parameter()]
    [Switch]$UseWinlogonCredential = [System.Convert]::ToBoolean($env:useWindowsCredentials),
    [Parameter()]
    [String]$UseWinlogonCredsField = "useWinCredentials",
    [Parameter()]
    [Switch]$AssumeUDPencapsulation = [System.Convert]::ToBoolean($env:assumeUdpEncapsulation),
    [Parameter()]
    [String]$UDPField = "assumeUdpEncapsulation",
    [Parameter()]
    [Switch]$SplitTunneling = [System.Convert]::ToBoolean($env:splitTunneling),
    [Parameter()]
    [String]$SplitTunnelingField = "splitTunneling",
    [Parameter()]
    [Switch]$CreateShortcut = [System.Convert]::ToBoolean($env:createVpnDesktopShortcut),
    [Parameter()]
    [String]$ShortcutField = "createVpnShortcut",
    [Parameter()]
    [String]$Url,
    [Parameter()]
    [String]$UrlField = "shortcutUrl",
    [Parameter()]
    [String]$IconDirectory,
    [Parameter()]
    [String]$IconDirectoryField = "shortcutIconDirectory",
    [Parameter()]
    [Switch]$Overwrite = [System.Convert]::ToBoolean($env:overwrite),
    [Parameter()]
    [Switch]$SkipSleep
)
begin {
    Add-Type -AssemblyName System.Drawing

    if ([System.Convert]::ToBoolean($env:verboseOutput)) {
        $VerbosePreference = 'Continue'
    }

    # You can replace the line below with $IconBase64 = 'ReplaceThisWithYourBase64EncodedImageEncasedInQuotes', and the script will decode the image and use it for the VPN shortcut.
    $IconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEUAAAD///////////////////8+Uq06AAAABXRSTlMAAECAv9KsvScAAAEsSURBVEjH7ZUxDsIwDEWtFA7ADbqwM8COhLpXtLn/VbDzXduFRpEYEEOzRP15+ontL5VOjUU78DuAiK45P3hLOT+Jzjn3rhXglnlNhDNQpglwyGXdYQED0wQY8DHDAgamMdDx3qdhsVgMoF0YOBYpmYUaQBsZuBVJjmABA9UmBgY5gKtobiDazIB+JC0kGIhWgPJBWkgwEG0N2GUwMMCugIUb4Ap75IxCggEeaWVOUrcaHEKZ1qiRhV4NhtAoa/WF0lMNutjqOCx7QRxWGLeXsBq3ByaUEANj8Vr1IEbOV+iBrjcAJdQB7cG9CqCJy1A/ga4YHKVl20Bo+jbgY6sAPvgK4NGpAuv9G6BxRfORzTKbjQrprA/L01kZt6dzMzAhndtASKcD+//iX4AX3T+7h6Wwmo8AAAAASUVORK5CYII='
    function Test-IsSystem {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
    }

    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function ConvertFrom-Base64 {
        param(
            $Base64,
            $Path
        )
        $bytes = [Convert]::FromBase64String($Base64)

        [IO.File]::WriteAllBytes($Path, $bytes)
    }

    # There are many ways to create icon files. The method below creates a PNG and then creates an ICO file in binary form by creating the header and adding the PNG's binary at the bottom.
    # Once this has been done, we can simply write all the bytes to our new file.
    function ConvertFrom-Image {
        param(
            $ImagePath,
            $Path
        )

        # Grab an instance of the image and a blank bitmap
        $image = [Drawing.Image]::FromFile($ImagePath)

        # If you want transparency, you'll need an Alpha channel in the pixel format
        $bitmap = New-Object System.Drawing.Bitmap (255, 255, [system.drawing.imaging.PixelFormat]::Format32bppArgb)
        $bitmap.SetResolution(255, 255)

        # Create a graphics object which will be used to resize the image to 255px by 255px
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

        # Set some quality settings for the resize operation
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

        # Draw the image onto the bitmap
        $graphics.DrawImage($Image, 0, 0, 255, 255)
        
        # Temporarily save the image as a PNG
        $RandomNumber = Get-Random -Maximum 1000000
        $bitmap.Save("$env:TEMP\image-$RandomNumber.png", [System.Drawing.Imaging.ImageFormat]::Png)
        $png = "$env:TEMP\image-$RandomNumber.png"

        # Begin building the ICO file in binary using the PNG file (ICO files are comprised of PNG(s))
        if ($PSVersionTable.PSVersion.Major -gt 5) {
            $pngBytes = Get-Content -Path $png -AsByteStream
        }
        else {
            $pngBytes = Get-Content -Path $png -Encoding Byte -Raw
        }
        $icoHeader = [byte[]] @(0, 0, 1, 0, 1, 0)
        $imageDataSize = $pngBytes.Length
        $icoDirectory = [byte[]] @(
            255, 255, # icon size
            0, 0, # color count
            0, 0, # reserved
            0, 0, # hotspot x, hotspot y
            ($imageDataSize -band 0xFF),
            (($imageDataSize -shr 8) -band 0xFF),
            (($imageDataSize -shr 16) -band 0xFF),
            (($imageDataSize -shr 24) -band 0xFF),
            22, 0, 0, 0  # offset to image data
        )
        $iconData = $icoHeader + $icoDirectory + $pngBytes

        # Once complete, save the icon file
        if (Test-Path $Path -ErrorAction SilentlyContinue) { Remove-Item $Path -Force }
        [System.IO.File]::WriteAllBytes($Path, $iconData)

        # Close out of everything and remove the temporary file
        if (Test-Path $png -ErrorAction SilentlyContinue) { Remove-Item $png -Force }
        $bitmap.Dispose()
        $image.Dispose()
        $graphics.Dispose()
        [System.GC]::Collect()

        # Refresh the icon cache
        if ([System.Environment]::OSVersion.Version.Major -ge 10) {
            Invoke-Command { ie4uinit.exe -show }
        }
        else {
            Invoke-Command { ie4uinit.exe -ClearIconCache }
        }
    }

    # Utility function for downloading files.
    function Invoke-Download {
        param(
            [Parameter()]
            [String]$URL,
            [Parameter()]
            [String]$Path,
            [Parameter()]
            [int]$Attempts = 3,
            [Parameter()]
            [Switch]$SkipSleep
        )
        Write-Host "URL given, downloading the file..."

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
            # Some cloud services have rate limiting.
            if (-not ($SkipSleep)) {
                $SleepTime = Get-Random -Minimum 3 -Maximum 15
                Write-Host "Waiting for $SleepTime seconds."
                Start-Sleep -Seconds $SleepTime
            }
            if ($i -ne 1) { Write-Host "" }
            Write-Host "Download Attempt $i"

            try {
                # Invoke-WebRequest is preferred because it supports links that redirect, e.g., https://t.ly.
                if ($PSVersionTable.PSVersion.Major -lt 4) {
                    # Downloads the file
                    $WebClient = New-Object System.Net.WebClient
                    $WebClient.DownloadFile($URL, $Path)
                }
                else {
                    # Standard options for Invoke-WebRequest.
                    $WebRequestArgs = @{
                        Uri                = $URL
                        OutFile            = $Path
                        MaximumRedirection = 10
                        UseBasicParsing    = $true
                    }

                    # Downloads the file
                    Invoke-WebRequest @WebRequestArgs
                }

                $File = Test-Path -Path $Path -ErrorAction SilentlyContinue
            }
            catch {
                Write-Warning "An error has occurred while downloading!"
                Write-Warning $_.Exception.Message

                if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
                    Remove-Item $Path -Force -Confirm:$false -ErrorAction SilentlyContinue
                }

                $File = $False
            }

            if ($File) {
                $i = $Attempts
            }
            else {
                Write-Warning "File failed to download."
                Write-Host ""
            }

            $i++
        }

        if (-not (Test-Path $Path)) {
            Write-Warning "Failed to download file!"
        }
        else {
            return $Path
        }
    }

    # Used for creating desktop shortcuts.
    function New-Shortcut {
        [CmdletBinding()]
        param(
            [Parameter()]
            [String]$Arguments,
            [Parameter()]
            [String]$IconPath,
            [Parameter(ValueFromPipeline)]
            [String]$Path,
            [Parameter()]
            [String]$Target,
            [Parameter()]
            [String]$WorkingDir
        )
        process {
            Write-Host "Creating shortcut at $Path"
            $ShellObject = New-Object -ComObject ("WScript.Shell")
            $Shortcut = $ShellObject.CreateShortcut($Path)
            $Shortcut.TargetPath = $Target
            if ($WorkingDir) { $Shortcut.WorkingDirectory = $WorkingDir }
            if ($Arguments) { $ShortCut.Arguments = $Arguments }
            if ($IconPath) { $Shortcut.IconLocation = $IconPath }
            $Shortcut.Save()

            if (-not(Test-Path $Path -ErrorAction Ignore)) {
                Write-Host "[Error] Unable to create shortcut at $Path"
                exit 1
            }
        }
    }

    function Set-HKProperty {
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet('DWord', 'QWord', 'String', 'ExpandedString', 'Binary', 'MultiString', 'Unknown')]
            $PropertyType = 'DWord'
        )
        if (-not $(Test-Path -Path $Path)) {
            # Check if the path does not exist and create the path.
            New-Item -Path $Path -Force | Out-Null
        }
        if ((Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore)) {
            # Update the property and print out what it was changed from and what it was changed to.
            $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore).$Name
            try {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Host "[Error] Unable to Set registry key for $Name; please see below error!"
                Write-Host "$($_.Exception.Message)"
                exit 1
            }
            Write-Host "$Path\$Name changed from $CurrentValue to $($(Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore).$Name)"
        }
        else {
            # Create the property with a value.
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Host "[Error] Unable to Set registry key for $Name please see below error!"
                Write-Host "$($_.Exception.Message)"
                exit 1
            }
            Write-Host "Set $Path\$Name to $($(Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore).$Name)"
        }
    }

    # This function is to make it easier to parse Ninja Custom Fields.
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

        # If we're requested to get the field value from a Ninja document, we'll specify it here.
        $DocumentationParams = @{}
        if ($DocumentName) { $DocumentationParams["DocumentName"] = $DocumentName }

        # These two types require more information to parse.
        $NeedsOptions = "DropDown", "MultiSelect"

        # Grabbing document values requires a slightly different command.
        if ($DocumentName) {
            # Secure fields are only readable when they're a device custom field
            if ($Type -Like "Secure") { throw "$Type is an invalid type! Please check here for valid types. https://ninjarmm.zendesk.com/hc/en-us/articles/16973443979789-Command-Line-Interface-CLI-Supported-Fields-and-Functionality" }

            # We'll redirect the error output to the success stream to make it easier to error out if nothing was found or something else went wrong.
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

        # If we received some sort of error it should have an exception property and we'll exit the function outputing nothing.
        if ($NinjaPropertyValue.Exception) {
            Write-Verbose $NinjaPropertyValue.ToString()
            return $null 
        }
        if ($NinjaPropertyOptions.Exception) {
            Write-Verbose $NinjaPropertyOptions.ToString() 
            return $null 
        }

        # This switch will compare the type given with the quoted string. If it matches, it'll parse it further; otherwise, the default option will be selected.
        switch ($Type) {
            "Checkbox" {
                # Checkboxes come in as a string representing an integer. We'll need to cast that string into an integer and then convert it to a more traditional boolean.
                [System.Convert]::ToBoolean([int]$NinjaPropertyValue)
            }
            "Dropdown" {
                # Drop-down custom fields come in as a comma-separated list of GUIDs; we'll compare these with all the options and return just the option values selected instead of a GUID.
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Options | Where-Object { $_.GUID -eq $NinjaPropertyValue } | Select-Object -ExpandProperty Name
            }
            "MultiSelect" {
                # Multi-Select custom fields come in as a comma-separated list of GUIDs; we'll compare these with all the options and return just the option values selected instead of a GUID.
                $Options = $NinjaPropertyOptions -replace '=', ',' | ConvertFrom-Csv -Header "GUID", "Name"
                $Selection = ($NinjaPropertyValue -split ',') | ForEach-Object { $_.Trim() }

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

    function Get-NinjaProperty-WithError {
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
            "Checkbox" {
                # Checkbox's come in as a string representing an integer. We'll need to cast that string into an integer and then convert it to a more traditional boolean.
                [System.Convert]::ToBoolean([int]$NinjaPropertyValue)
            }
            "Decimal" {
                # In ninja decimals are strings that represent a decimal this will cast it into a double data type.
                [double]$NinjaPropertyValue
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
            default {
                # If no type was given or not one that matches the above types just output what we retrieved.
                $NinjaPropertyValue
            }
        }
    }

    # Pulling the document name from the script form.
    if ($env:ninjaDocumentName -and $env:ninjaDocumentName -notlike "null") { $DocumentName = $env:ninjaDocumentName }

    if ($DocumentName) {
        Write-Host "Retrieving values from Ninja Document '$DocumentName'..."
        $DocumentationParams = @{
            DocumentName = $DocumentName
        }
    }

    if (Test-IsElevated) {
        Write-Host "Checking custom fields for VPN configuration settings ..."

        if ($env:presharedKeyCustomField -and $env:presharedKeyCustomField -notlike "null") { $PreSharedKeyField = $env:presharedKeyCustomField }

        # Grabbing Documentation or Custom Field Values if the parameter wasn't given or is the default value.
        if (-not $AssumeUDPencapsulation) { $AssumeUDPencapsulation = Get-NinjaProperty -Name $UDPField -Type "Checkbox" @DocumentationParams }
        if (-not $Name) { $Name = Get-NinjaProperty -Name $NameField @DocumentationParams }
        if (-not $Server) { $Server = Get-NinjaProperty -Name $ServerField @DocumentationParams }
        if ($PreSharedKeyField) {
            try {
                $PreSharedKey = Get-NinjaProperty-WithError -Name $PreSharedKeyField @DocumentationParams
            }
            catch {
                Write-Host -Object "[Error] Unable to retrieve the PreShared key from '$PreSharedKeyField'."
                Write-Host -Object "[Error] $($_.Exception.Message)"
                $ExitCode = 1
            }
        }
        if (-not $TunnelType -and $TunnelType -eq "Automatic") { 
            $Tunnel = Get-NinjaProperty -Name $TunnelTypeField -Type "Dropdown" @DocumentationParams
            if ($Tunnel) { $TunnelType = $Tunnel } 
        }
        if (-not $AuthMethod) { $AuthMethod = Get-NinjaProperty -Name $AuthMethodField -Type "Multiselect" @DocumentationParams }
        if (-not $EncryptionLevel) { $EncryptionLevel = Get-NinjaProperty -Name $EncryptionLevelField -Type "Dropdown" @DocumentationParams }
        if (-not $DNSSuffix) { $DNSSuffix = Get-NinjaProperty -Name $DNSSuffixField @DocumentationParams }
        if (-not $RememberCreds) { $RememberCreds = Get-NinjaProperty -Name $RememberCredsField -Type "Checkbox" @DocumentationParams }
        if (-not $UseWinlogonCredential) { $UseWinLogonCredential = Get-NinjaProperty -Name $UseWinlogonCredsField -Type "Checkbox" @DocumentationParams }
        if (-not $SplitTunneling) { $SplitTunneling = Get-NinjaProperty -Name $SplitTunnelingField -Type "Checkbox" @DocumentationParams }
        if (-not $CreateShortcut) { $CreateShortcut = Get-NinjaProperty -Name $ShortcutField -Type "Checkbox" @DocumentationParams }
        if (-not $IconDirectory) { $IconDirectory = Get-NinjaProperty -Name $IconDirectoryField @DocumentationParams }
        if (-not $Url) { $Url = Get-NinjaProperty -Name $UrlField @DocumentationParams }
    }
    else {
        Write-Warning "Reading Custom Fields requires local admin privileges."
    }

    # If someone specifies something in the script form, we'll want to overwrite what the documentation says. Makes the script more useful for troubleshooting.
    if ($env:vpnName -and $env:vpnName -notlike "null") { $Name = $env:vpnName }
    if ($env:vpnServerAddress -and $env:vpnServerAddress -notlike "null") { $Server = $env:vpnServerAddress }
    if ($env:vpnTunnelType -and $env:vpnTunnelType -notlike "null") { $TunnelType = $env:vpnTunnelType }
    if ($env:authenticationMethod -and $env:authenticationMethod -notlike "null") { $AuthMethod = $env:authenticationMethod }
    if ($env:encryptionLevel -and $env:encryptionLevel -notlike "null") { $EncryptionLevel = $env:encryptionLevel }
    if ($env:dnsSuffix -and $env:dnsSuffix -notlike "null") { $DNSSuffix = $env:dnsSuffix }
    if ($env:iconPath -and $env:iconPath -notlike "null") { $Icon = $env:iconPath }
    if ($env:iconUrl -and $env:iconUrl -notlike "null") { $Url = $env:iconUrl }
    if ($env:iconDirectory -and $env:iconDirectory -notlike "null") { $IconDirectory = $env:iconDirectory }

    # If an authentication method was given, we'll want to parse that and validate it.
    if ($AuthMethod) {
        $AuthSelections = ($AuthMethod.Split(',')).Trim()

        $AuthSelections | ForEach-Object {
            switch ($_) {
                "PAP" { Write-Verbose "PAP Selected" }
                "Chap" { Write-Verbose "Chap Selected" }
                "MSChapv2" { Write-Verbose "Eap Selected" }
                "MachineCertificate" { Write-Verbose "MachineCertificate" }
                default {
                    Write-Host "[Error] $_ is invalid! The Valid auth types are 'PAP','Chap','MSChapv2' or 'MachineCertificate'."
                    exit 1
                }
            }
        }
    }

    # Validating encryption level. Not supporting "No Encryption". 
    if ($EncryptionLevel) {
        switch ($EncryptionLevel) {
            "Optional" { Write-Verbose "Optional Selected" }
            "Required" { Write-Verbose "Required Selected" }
            "Maximum" { Write-Verbose "Maximum Selected" }
            default {
                Write-Host "[Error] $EncryptionLevel is invalid! The valid encryption levels are 'Optional', 'Required', or 'Maximum'."
            }
        }
    }

    # This will set the tunnel type.
    switch ($TunnelType) {
        "L2TP" { Write-Verbose "L2TP Selected" }
        "SSTP" { Write-Verbose "SSTP Selected" }
        "IKEV2" { Write-Verbose "IKEV2 Selected" }
        "Automatic" { Write-Verbose "Automatic Selected" }
        default { 
            Write-Host "[Error] $TunnelType is invalid! The valid tunnel types are 'L2TP', 'SSTP', 'IKEv2', or 'Automatic'."
            exit 1
        }
    }

    # Error out if the only two mandatory parameters don't exist.
    if (-not $Server -or -not $Name) {
        Write-Host "[Error] Name and Server are required! If using documentation fields or custom fields, double-check that your field exists and is readable by Automations."
        exit 1
    }

    # Icons are minor, so if we're not given the information, we'll continue on without it and just let the technician know. They can always re-run it.
    if (($Url -or $IconDirectory) -and -not $CreateShortcut) {
        Write-Warning "An icon was given, but Create Shortcut was never used? Ignoring icon info..."
        $Url = $null
        $Icon = $null
        $IconDirectory = $null
    }

    # Icons are minor, so if we're not given the information, we'll continue on without it and just let the technician know. They can always re-run it.
    if ($Url -and -not $IconDirectory) {
        Write-Warning "An icon was given, but a place to store it wasn't? Use Icon Directory box to specify a directory to store it. (You may want this directory to be accessible by all users)"
        Write-Warning "Ignoring supplied icon info."
        $Icon = $null
        $Url = $null
    }

    if (!$ExitCode) {
        $ExitCode = 0
    }
}
process {
    # Checking for existing VPNs
    $UserVPNs = Get-VpnConnection -Name $Name -EA Ignore
    $GlobalVPNs = Get-VpnConnection -Name $Name -AllUserConnection -EA Ignore

    # If the overwrite parameter wasn't specified, we'll error out as we won't be able to create the VPN.
    if (($UserVPNs -or $GlobalVPNs) -and -not $Overwrite) {
        Write-Host "[Error] $Name already exists! Use -Overwrite to replace it."
        if ($GlobalVPNs -and -not (Test-IsElevated)) { Write-Host "[Error] $($GlobalVPNs.Name) requires elevation to replace/overwrite." }
        exit 1
    }

    # Removing previous VPNs if overwrite was specified.
    if ($UserVPNs -and $Overwrite) {
        $UserVPNs | Remove-VpnConnection -Force
    }
    
    if ($GlobalVPNs -and $Overwrite) {
        if (Test-IsElevated) {
            $GlobalVPNs | Remove-VpnConnection -AllUserConnection -Force 
        }
        else {
            Write-Host "[Error] $($GlobalVPNs.Name) requires elevation to replace/overwrite."
            exit 1
        }
    }

    # Setting the AssumeUDPEncapsulationContextOnSendRule
    if ($AssumeUDPencapsulation -and (Test-IsElevated)) {
        Write-Warning "AssumeUDPEncapsulation requires a reboot to take effect. This script does NOT reboot the machine."
        Set-HKProperty -Name "AssumeUDPEncapsulationContextOnSendRule" -Path "HKLM:\SYSTEM\CurrentControlSet\Services\PolicyAgent" -Value "2"
    }

    # Building the Add-VPNConnection command based on what information was entered
    $ArgumentList = @{}
    if ($SplitTunneling) { $ArgumentList["SplitTunneling"] = $True }
    if ($Server) { $ArgumentList["ServerAddress"] = $Server }
    if ($Name) { $ArgumentList["Name"] = $Name }
    if ($PreSharedKey) { $ArgumentList["L2TPPsk"] = $PreSharedKey }
    if ($TunnelType) { $ArgumentList["TunnelType"] = $TunnelType }
    if ($AuthMethod) { $ArgumentList["AuthenticationMethod"] = $AuthSelections }
    if ($EncryptionLevel) { $ArgumentList["EncryptionLevel"] = $EncryptionLevel }
    if ($DNSSuffix) { $ArgumentList["DnsSuffix"] = $DNSSuffix }
    if ($RememberCreds) { $ArgumentList["RememberCredential"] = $True }
    if ($UseWinlogonCredential) { $ArgumentList["UseWinLogonCredential"] = $True }

    # If the script wasn't run as system, only the current user should be able to access the VPN.
    if (Test-IsSystem) { $ArgumentList["AllUserConnection"] = $True }
    $ArgumentList["Force"] = $True
    $ArgumentList["Passthru"] = $True

    try {
        Add-VpnConnection @ArgumentList -ErrorAction Stop | Format-Table -Property Name, ServerAddress, TunnelType, EncryptionLevel, AllUserConnection, SplitTunneling | Out-String | Write-Host
    }
    catch {
        Write-Host -Object "[Error] $($_.Exception.Message)"
        $ExitCode = 1
    }

    switch (Test-IsSystem) {
        $True {
            $ShortcutPath = "$env:Public\Desktop\$Name.lnk"
            $RasFile = Join-Path $env:PROGRAMDATA "Microsoft\Network\Connections\Pbk\rasphone.pbk"
        }
        default { 
            $ShortcutPath = "$([Environment]::GetFolderPath("Desktop"))\$Name.lnk"
            $RasFile = Join-Path $env:APPDATA "Microsoft\Network\Connections\Pbk\rasphone.pbk"
        }
    }

    if (-not (Test-Path $RasFile -EA Ignore)) { 
        Write-Host "[Error] Failed to create vpn!"
        exit 1
    }

    # All Windows VPNs get a phonebook entry; we're going to check that the previous Add-VPNConnection was successful by looping through each line in the phonebook.
    $Phonebook = Get-Content -Path $RasFile

    for ($lineNumber = 0; $lineNumber -lt $Phonebook.Length; $lineNumber++) {
        if ($Phonebook[$lineNumber] -eq "[$Name]") {
            $Entry = $lineNumber
            break
        }
    }

    # If the VPN wasn't found, we're going to error out.
    if ($Entry -notmatch "\d") {
        Write-Host "[Error] Failed to create vpn!"
        exit 1
    }

    if ($CreateShortcut) {
        if ($IconDirectory -and -not (Test-Path $IconDirectory -ErrorAction SilentlyContinue)) {
            New-Item -ItemType Directory -Path $IconDirectory | Out-Null
        }

        # If we're given a URL, we'll want to download it.
        if ($Url) {
            $DownloadArguments = @{
                URL  = $Url
                Path = "$IconDirectory\vpnscript-$Name.png"
            }
            if ($SkipSleep) { $DownloadArguments["SkipSleep"] = $True }

            Invoke-Download @DownloadArguments

            if (Test-Path "$IconDirectory\vpnscript-$Name.png" -ErrorAction SilentlyContinue) {
                $Icon = "$IconDirectory\vpnscript-$Name.png"
            }
            else {
                $Icon = $Null
            }
        }
    
        # This will convert the base64 into an image and save it to the temp folder.
        if ($IconBase64 -and $IconDirectory -and -not $Icon -and -not $Url) {
            Write-Verbose "Converting Icon base64 to original image and saving to $IconDirectory..."

            ConvertFrom-Base64 -Base64 $IconBase64 -Path "$IconDirectory\vpnscript-$Name.Png"
            
            if (Test-Path "$IconDirectory\vpnscript-$Name.Png" -ErrorAction SilentlyContinue) {
                $Icon = "$IconDirectory\vpnscript-$Name.Png"
            }
            else {
                $Icon = $Null
            }
        }
    
        if ($Icon) {
            Write-Verbose "Converting image to icon and saving to $IconDirectory\vpnscript-$((Get-FileHash -Path $Icon -Algorithm MD5).Hash).ico ..."

            $NewName = "vpnscript-$((Get-FileHash -Path $Icon -Algorithm MD5).Hash).ico"
            ConvertFrom-Image -ImagePath $Icon -Path "$IconDirectory\$NewName"

            if (Test-Path "$IconDirectory\$NewName" -ErrorAction SilentlyContinue) {
                $Icon = "$IconDirectory\$NewName"
            }
            else {
                $Icon = $Null
            }
        }
    }

    if ($CreateShortcut) {
        $ShortcutArgs = @{
            Path       = $ShortcutPath
            Target     = "rasphone.exe"
            Arguments  = "-d `"$Name`""
            WorkingDir = "$env:SystemRoot\System32"
        }
        if ($Icon) { $ShortcutArgs["IconPath"] = $Icon } 

        New-Shortcut @ShortcutArgs
    }

    exit $ExitCode
}
end {
    
    
    
}
