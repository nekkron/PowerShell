## WORK IN PROGRESS

# If AD user title contains "exemployee" or "ex employee" then change attribute msExchHideEmailFromGAL to TRUE

# Import AD Module
Import-Module ActiveDirectory

# Find users with "exemployee" or "ex employee" in the job title
$Users = Get-ADUser -Filter { Description -like '*' } -SearchBase 'OU=Users,OU=spot,DC=domain,DC=tld' -Properties title

foreach( $User in $Users ){
    try{
        Set-ADObject -Identity $Users -Replace @{msExchHideFromAddressLists="$True"} -ErrorAction Stop -ErrorVariable 'ErrorMessage' # msExchHideFromAddressLists

        Write-Verbose "Successfully hid email from GAL for $($User.Name)" -Verbose
        }
    catch{
        Write-Warning "Failed to hide email from GAL for $($User.Name)"
        Write-Warning "UserName: $($User.SamAccountName)`tDescription: $($User.Description)"
        Write-Warning "Error Message:`n$ErrorMessage"
        }
    }t {Set-ADObject -Identity $_.DistinguishedName ` -Replace @{personaltitle=$($_.description)}}
