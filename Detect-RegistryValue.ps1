<#	
	.NOTES
	===========================================================================
	 Created on:   	2024/02/29
	 Created by:   	James Kasparek
	 Filename:     	Detect-RegistryValue.ps1
     URL:           https://github.com/nekkron/PowerShell/
	===========================================================================
	.DESCRIPTION
		Searches if a specified registry Name and Value exists within a specified Path
#>

# Change these variables to meet your detection requirements
$Path = "HKLM:\SYSTEM\CurrentControlSet\Control"
$Name = "DriverVersion"
$Value = "1.2.3"

# Waving the magic wand
$foundMatch = $false
Get-ChildItem -Path $Path -Recurse | ForEach-Object {
    $key = $_
    $valueNames = $key.GetValueNames()
    foreach ($valueName in $valueNames) {
        $valueData = $key.GetValue($valueName)
        if ($valueName -eq $Name -and $valueData -eq $Value) {
            Write-Output "Found a match! '$key' / '$valueName' / '$Value'"
            $foundMatch = $true
        }
    }
}
if ($foundMatch) {
    Write-Output "'$Name' with a value of '$Value' was found within: $Path"
    exit 0
} else {
    Write-Output "'$Name / $Value' was not found anywhere inside '$Path'"
    exit 1
}
