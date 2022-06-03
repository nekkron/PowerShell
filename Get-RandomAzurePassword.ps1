# https://github.com/JasonRBeer/PublicPowerShellScripts/blob/master/Get-RandomAzurePassword.ps1
function Get-RandomAzurePassword{
    # Requirements for Azure passwords https://docs.microsoft.com/en-us/azure/active-directory/authentication/concept-sspr-policy
    # This is setup to use the following: A-Z a-z 0-9 !"#$%&'()*+,-./:;=?@[\]^_`{|}~
    $UpperCaseLetters = [char[]]([char]65..[char]90)
    $LowerCaseLetters = [char[]]([char]97..[char]122)
    $Numbers = [char[]]([char]48..[char]57)
    $Symbols = [char[]]([char]33..[char]47) + [char[]]([char]58..[char]59) + [char]61 + [char[]]([char]63..[char]64) + [char[]]([char]91..[char]96) + [char[]]([char]123..[char]126)
    $AllPossibleChars = $UpperCaseLetters + $LowerCaseLetters + $Numbers + $Symbols
    $PasswordLength = 256 #This is the max password length at this time

    #Add a capital, lowercase, number, and symbol to meet complexity requirements. Add to $RandomPassword.
    $RandomPassword = $UpperCaseLetters[(Get-Random -Minimum 0 -Maximum (($UpperCaseLetters.count)-1))]
    $RandomPassword += $LowerCaseLetters[(Get-Random -Minimum 0 -Maximum (($LowerCaseLetters.count)-1))]
    $RandomPassword += $Numbers[(Get-Random -Minimum 0 -Maximum (($Numbers.count)-1))]
    $RandomPassword += $Symbols[(Get-Random -Minimum 0 -Maximum (($Symbols.count)-1))]

    #Add additional random characters until you reach $PasswordLength
    Do{
        #Add a random character to the password
        $RandomPassword += $AllPossibleChars[(Get-Random -Minimum 0 -Maximum (($AllPossibleChars.count)-1))]

        #Measure the Password length
        $PasswordMeasure = $RandomPassword | Measure-Object -Character
        $RandomPasswordLength = $PasswordMeasure.Characters
    } while ($RandomPasswordLength -ne $PasswordLength)

    #Randomly sort the characters currently in $RandomPassword (so the first 4 chars aren't always Upper-Lower-Number-Symbol)
    $RandomPassword = ($RandomPassword -split '' | Sort-Object {Get-Random}) -join ''

    return $RandomPassword
}
