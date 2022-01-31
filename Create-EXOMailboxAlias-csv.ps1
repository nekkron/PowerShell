# https://docs.microsoft.com/en-us/powershell/module/exchange/set-mailbox?view=exchange-ps#example-7
$Alias  = import-csv c:/usr/alias.csv

foreach($Data in $Alias){
    if((Get-Mailbox $data.Name -ErrorAction 'SilentlyContinue') -eq $null){
        Write-Host -BackgroundColor Red -ForegroundColor White -Object "Mailbox does not exist! Create mailbox before adding aliases!"
    }
    Set-Mailbox $data.Name -EmailAddresses @{Add=$data.Alias}
}
