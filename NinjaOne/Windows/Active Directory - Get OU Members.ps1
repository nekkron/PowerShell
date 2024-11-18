#Requires -Version 4.0

<#
.SYNOPSIS
    Gets the members of an OU from AD.
.DESCRIPTION
    Gets the members of an OU(Organizational Unit) from AD(Active Directory) and can save the results to a Custom Field.

PARAMETER: -OU "Test"
    A brief explanation of the parameter.
.EXAMPLE
    -OU "Test"

    OU=Test,DC=something,DC=local 
    -----------------------------   
    Test@something.local

PARAMETER: -OU "Test" -CustomField "TestOU"
    A brief explanation of the parameter.
.EXAMPLE
    -OU "Test" -CustomField "TestOU"

    OU=Test,DC=something,DC=local
    ----------------------------- 
    Test@something.local

.OUTPUTS
    None
.NOTES
    Minimum OS Architecture Supported: Windows Server 2012 R2 (Domain Controller's Only)
    Release Notes: Renamed script
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$OU,
    [string]$CustomField
)

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) { 
        Write-Error "RSAT is required to get the membership. Please run this on a domain controller or on a machine with RSAT installed." 
        exit 1
    }
}
process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }

    if ($env:OuName -and $env:OuName -notlike "null") {
        $OU = $env:OuName
    }

    if ($env:CustomField -and $env:CustomField -notlike "null") {
        $CustomField = $env:CustomField
    }

    $Report = New-Object System.Collections.Generic.List[string]

    try {
        $OUPaths = Get-ADOrganizationalUnit -Filter * | Where-Object { $_.DistinguishedName -like "OU=$OU*" } | Select-Object -ExpandProperty DistinguishedName
        $OUPaths | ForEach-Object {
            $Report.Add("`n$_")

            $TitleLength = $_.Length
            $i = 1
            $Title = $Null
            while ($i -le $TitleLength) {
                $Title = "$Title-"
                $i++
            }
            $Report.Add($Title)

            Get-ADUser -Filter * -SearchBase $_ -ErrorAction SilentlyContinue | Select-Object -ExpandProperty UserPrincipalName -ErrorAction SilentlyContinue | ForEach-Object { $Report.Add("$_") }
        }
    }
    catch {
        Write-Error $_
        exit 1
    }

    $Report | Write-Host

    if ($CustomField) {
        Ninja-Property-Set -Name $CustomField -Value $($Report | Out-String)
    }
}
end {
    
    
    
}