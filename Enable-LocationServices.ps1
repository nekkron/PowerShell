# Enable Location Services in Windows 10
# https://msendpointmgr.com/2020/05/20/automatically-set-time-zone-for-devices-provisioned-using-windows-autopilot/
#
# This is verified functional in 1909 & 2004. This is not guaranteed to work in 20H2 or higher. 

function Enable-LocationServices {
    $LocationConsentKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"
    Write-LogEntry -Value "Checking registry key presence: $($LocationConsentKey)" -Severity 1
    if (-not(Test-Path -Path $LocationConsentKey)) {
        Write-LogEntry -Value "Presence of '$($LocationConsentKey)' key was not detected, attempting to create it" -Severity 1
        New-Item -Path $LocationConsentKey -Force | Out-Null
    }
    
    $LocationConsentValue = Get-ItemPropertyValue -Path $LocationConsentKey -Name "Value"
    Write-LogEntry -Value "Checking registry value 'Value' configuration in key: $($LocationConsentKey)" -Severity 1
    if ($LocationConsentValue -notlike "Allow") {
        Write-LogEntry -Value "Registry value 'Value' configuration mismatch detected, setting value to: Allow" -Severity 1
        Set-ItemProperty -Path $LocationConsentKey -Name "Value" -Type "String" -Value "Allow" -Force
    }
    
    $SensorPermissionStateRegValue = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
    $SensorPermissionStateValue = Get-ItemPropertyValue -Path $SensorPermissionStateRegValue -Name "SensorPermissionState"
    Write-LogEntry -Value "Checking registry value 'SensorPermissionState' configuration in key: $($SensorPermissionStateRegValue)" -Severity 1
    if ($SensorPermissionStateValue -ne 1) {
        Write-LogEntry -Value "Registry value 'SensorPermissionState' configuration mismatch detected, setting value to: 1" -Severity 1
        Set-ItemProperty -Path $SensorPermissionStateRegValue -Name "SensorPermissionState" -Type "DWord" -Value 1 -Force
    }
    
    $LocationServiceStatusRegValue = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
    $LocationServiceStatusValue = Get-ItemPropertyValue -Path $LocationServiceStatusRegValue -Name "Status"
    Write-LogEntry -Value "Checking registry value 'Status' configuration in key: $($LocationServiceStatusRegValue)" -Severity 1
    if ($LocationServiceStatusValue -ne 1) {
        Write-LogEntry -Value "Registry value 'Status' configuration mismatch detected, setting value to: 1" -Severity 1
        Set-ItemProperty -Path $LocationServiceStatusRegValue -Name "Status" -Type "DWord" -Value 1 -Force
    }

    $LocationService = Get-Service -Name "lfsvc"
    Write-LogEntry -Value "Checking location service 'lfsvc' for status: Running" -Severity 1
    if ($LocationService.Status -notlike "Running") {
        Write-LogEntry -Value "Location service is not running, attempting to start service" -Severity 1
        Start-Service -Name "lfsvc"
    }
}
