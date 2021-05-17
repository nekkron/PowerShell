# Update the mtxagent.ini file to have the CertAuth=bcm & CertTrusted=bcm lines 
# https://stackoverflow.com/questions/15662799/powershell-function-to-replace-or-add-lines-in-text-files

# Set variables
Set-

function setConfig ($file, $key, $value ) {
    $content = Get-Content $file
    if ( $content -match "^$key\s*=" ) {
        $content -replace "^$key\s*=.*", "$key = $value" |
        Set-Content $file
    } else {
        Add-Content $file "$key = $value"
    }
}

setConfig "divider.conf" "Logentrytimeout" "180"