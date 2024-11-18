#Requires -Version 5.1

<#
.SYNOPSIS
    Gets the hardware ID and saves it to a custom field.
.DESCRIPTION
    Gets the hardware ID and saves it to a custom field.
    Setup:
        Create a Multi-line Custom Field, as the hardware ID is 4000 characters long.
.EXAMPLE
     -CustomField "autopilothwid"
    Uses the custom field named "autopilothwid" and saves the 4000 character long id to it.
.EXAMPLE
    PS C:\> Get-HardwareId.ps1 -CustomField "autopilothwid"
    Uses the custom field named "autopilothwid" and saves the 4000 character long id to it.
.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2019
    Release Notes: Renamed script and added Script Variable support
#>

[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $CustomField = "hardwareid"
)

begin {

    if ($env:customFieldName -and $env:customFieldName -notlike "null") { $CustomField = $env:customFieldName }
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    function Test-StringEmpty {
        param([string]$Text)
        # Returns true if string is empty, null, or whitespace
        process { [string]::IsNullOrEmpty($Text) -or [string]::IsNullOrWhiteSpace($Text) }
    }
}
process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    try {
        $DeviceDetail = Get-CimInstance -Namespace "root/cimv2/mdm/dmmap" -Class "MDM_DevDetail_Ext01" -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" -ErrorAction Stop
    }
    catch {
        if ($_.Exception.Message -like "Invalid class") {
            Write-Error -Message "root/cimv2/mdm/dmmap: MDM_DevDetail_Ext01 WMI class does not exist on system."
        }
        else {
            Write-Error $_
        }
        exit 1
    }

    if (
        $DeviceDetail -and
        $DeviceDetail.DeviceHardwareData -and
        -not $(Test-StringEmpty -Text $DeviceDetail.DeviceHardwareData)
    ) {
        Ninja-Property-Set -Name $CustomField -Value $DeviceDetail.DeviceHardwareData
        Write-Host "HardwareID: $($DeviceDetail.DeviceHardwareData)"
    }
    else {
        Write-Error "Unable to retrieve device details or DeviceHardwareData does not exist."
        exit 1
    }
    
}
end {
    
    
    
}
