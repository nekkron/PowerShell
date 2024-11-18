#Requires -Version 5.1

<#
.SYNOPSIS
    Sends an important toast notification to the currently signed in user. Please run as the Current Logged-on User.
.DESCRIPTION
    Sends an important toast notification to the currently signed in user. Please run as 'Current Logged on User'.
    You can also specify the "ApplicationId" to any string.
    The default ApplicationId is your company name found in the NINJA_COMPANY_NAME environment variable, but will fallback to "NinjaOne RMM" if it happens to not be set.

.EXAMPLE
    -Title "My Title Here" -Message "My Message Here"
    Sends the title "My Title Here" and message "My Message Here" as a Toast message/notification to the currently signed in user.
.EXAMPLE
    -Title "My Title Here" -Message "My Message Here" -ApplicationId "MyCompany"
    Sends the title "My Title Here" and message "My Message Here" as a Toast message/notification to the currently signed in user.
        ApplicationId: Creates a registry entry for your toasts called "MyCompany".
.OUTPUTS
    None
.NOTES
    If you want to change the defaults then with in the param block.
    If you want to customize the application name to show your company name,
        then look for $ApplicationId and change the content between the double quotes.

    Minimum OS Architecture Supported: Windows 10 (IoT editions are not supported due to lack of shell)
    Release Notes: Initial Release
#>

[CmdletBinding()]
param
(
    [string]$Title,
    [string]$Message,
    [string]$ApplicationId
)

begin {
    # Set the default ApplicationId if it's not provided. Use the Company Name if available, otherwise use the default.
    $ApplicationId = if ($env:NINJA_COMPANY_NAME) { $env:NINJA_COMPANY_NAME } else { "NinjaOne RMM" }

    Write-Host "[Info] Using ApplicationId: $($ApplicationId -replace '\s+','.')"

    if ($env:title -and $env:title -notlike "null") { $Title = $env:title }
    if ($env:message -and $env:message -notlike "null") { $Message = $env:message }
    if ($env:applicationId -and $env:applicationId -notlike "null") { $ApplicationId = $env:applicationId }

    if ([String]::IsNullOrWhiteSpace($Title)) {
        Write-Host "[Error] A Title is required."
        exit 1
    }
    if ([String]::IsNullOrWhiteSpace($Message)) {
        Write-Host "[Error] A Message is required."
        exit 1
    }

    if ($Title.Length -gt 42) {
        Write-Host "[Warn] The Title is longer than 42 characters. The title will be truncated by the Windows API to 42 characters."
    }
    if ($Message.Length -gt 254) {
        Write-Host "[Warn] The Message is longer than 254 characters. The message might get truncated by the Windows API."
    }

    function Test-IsSystem {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        return $id.Name -like "NT AUTHORITY*" -or $id.IsSystem
    }

    if (Test-IsSystem) {
        Write-Host "[Error] Please run this script as 'Current Logged on User'."
        Exit 1
    }

    function Set-RegKey {
        param (
            $Path,
            $Name,
            $Value,
            [ValidateSet("DWord", "QWord", "String", "ExpandedString", "Binary", "MultiString", "Unknown")]
            $PropertyType = "DWord"
        )
        if (-not $(Test-Path -Path $Path)) {
            # Check if path does not exist and create the path
            New-Item -Path $Path -Force | Out-Null
        }
        if ((Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore)) {
            # Update property and print out what it was changed from and changed to
            $CurrentValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore).$Name
            try {
                Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Host "[Error] Unable to Set registry key for $Name please see below error!"
                Write-Host "$($_.Exception.Message)"
                exit 1
            }
            Write-Host "[Info] $Path\$Name changed from:"
            Write-Host " $CurrentValue to:"
            Write-Host " $($(Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore).$Name)"
        }
        else {
            # Create property with value
            try {
                New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Host "[Error] Unable to Set registry key for $Name please see below error!"
                Write-Host "$($_.Exception.Message)"
                exit 1
            }
            Write-Host "[Info] Set $Path\$Name to:"
            Write-Host " $($(Get-ItemProperty -Path $Path -Name $Name -ErrorAction Ignore).$Name)"
        }
    }

    function Show-Notification {
        [CmdletBinding()]
        Param (
            [string]
            $ApplicationId,
            [string]
            $ToastTitle,
            [string]
            [Parameter(ValueFromPipeline)]
            $ToastText
        )

        # Import all the needed libraries
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
        [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
        [Windows.System.User, Windows.System, ContentType = WindowsRuntime] > $null
        [Windows.System.UserType, Windows.System, ContentType = WindowsRuntime] > $null
        [Windows.System.UserAuthenticationStatus, Windows.System, ContentType = WindowsRuntime] > $null
        [Windows.Storage.ApplicationData, Windows.Storage, ContentType = WindowsRuntime] > $null

        # Make sure that we can use the toast manager, also checks if the service is running and responding
        try {
            $ToastNotifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("$ApplicationId")
        }
        catch {
            Write-Host "$($_.Exception.Message)"
            Write-Host "[Error] Failed to create notification."
        }

        # Create a new toast notification
        $RawXml = [xml] @"
<toast scenario='urgent'>
    <visual>
    <binding template='ToastGeneric'>
        <text hint-maxLines='1'>$ToastTitle</text>
        <text>$ToastText</text>
    </binding>
    </visual>
</toast>
"@

        # Serialized Xml for later consumption
        $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $SerializedXml.LoadXml($RawXml.OuterXml)

        # Setup how are toast will act, such as expiration time
        $Toast = $null
        $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
        $Toast.Tag = "PowerShell"
        $Toast.Group = "PowerShell"
        $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

        # Show our message to the user
        $ToastNotifier.Show($Toast)
    }
}
process {
    # Create an object to store the ApplicationId and DisplayName
    $Application = [PSCustomObject]@{
        DisplayName = $ApplicationId
        # Replace any spaces with a period in the ApplicationId
        AppId       = $($ApplicationId -replace '\s+', '.')
    }
    Write-Host "Display Name: $($Application.DisplayName)"
    Write-Host "Application ID: $($Application.AppId)"

    Set-RegKey -Path "HKCU:\SOFTWARE\Classes\AppUserModelId\$($Application.AppId)" -Name "DisplayName" -Value $Application.DisplayName -PropertyType String
    Set-RegKey -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\$($Application.AppId)" -Name "AllowUrgentNotifications" -Value 1 -PropertyType DWord

    try {
        Write-Host "[Info] Attempting to send message to user..."
        $NotificationParams = @{
            ToastTitle    = $Title
            ToastText     = $Message
            ApplicationId = $Application.AppId
        }
        Show-Notification @NotificationParams -ErrorAction Stop
        Write-Host "[Info] Message sent to user."
    }
    catch {
        Write-Host "[Error] Failed to send message to user."
        Write-Host "$($_.Exception.Message)"
        exit 1
    }
    exit 0
}
end {
    
    
    
}

