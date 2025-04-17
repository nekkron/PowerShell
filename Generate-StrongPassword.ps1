<#
.DESCRIPTION
    This script generates a random and unique password with a default of 20 characters in length

.PARAMETER
    -Length
        This parameter changes the length of the password to any desirable length
    
.EXAMPLE
    The default length is 20 characters
        .\Generate-StrongPassword.ps1
    Length is customizable
        # Generate and display a password with a custom length (e.g., 15)
        $CustomPassword = Generate-StrongPassword -Length 15
        Write-Host "Generated Password (custom length): $CustomPassword"
#>

function Generate-StrongPassword {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Length = 20 # Default value set to 20
    )

    $UpperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $LowerCase = "abcdefghijklmnopqrstuvwxyz"
    $Numbers = "0123456789"
    $Symbols = "!@#$%^&*()_+=-`~[]/\{}|;:'?,.<>"

    $PasswordCharacters = @()

    # Ensure at least one of each required character type by selecting a single random character
    $PasswordCharacters += $UpperCase[(Get-Random -Maximum $UpperCase.Length)]
    $PasswordCharacters += $LowerCase[(Get-Random -Maximum $LowerCase.Length)]
    $PasswordCharacters += $Numbers[(Get-Random -Maximum $Numbers.Length)]
    $PasswordCharacters += $Symbols[(Get-Random -Maximum $Symbols.Length)]

    # Fill the remaining length with random characters from all sets
    for ($i = $PasswordCharacters.Count; $i -lt $Length; $i++) {
        $CharacterType = Get-Random -Maximum 4
        switch ($CharacterType) {
            0 {$PasswordCharacters += $UpperCase[(Get-Random -Maximum $UpperCase.Length)]}
            1 {$PasswordCharacters += $LowerCase[(Get-Random -Maximum $LowerCase.Length)]}
            2 {$PasswordCharacters += $Numbers[(Get-Random -Maximum $Numbers.Length)]}
            3 {$PasswordCharacters += $Symbols[(Get-Random -Maximum $Symbols.Length)]}
        }
    }

    # Shuffle the characters to ensure randomness
    $PasswordCharacters = $PasswordCharacters | Sort-Object {Get-Random}

    return -join $PasswordCharacters
}

# Generate and display the password (default length of 20)
$NewPassword = Generate-StrongPassword
Write-Host "Generated Password: $NewPassword"
