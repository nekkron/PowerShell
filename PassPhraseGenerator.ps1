$numberofpasswords = Read-Host 'How many passwords do you need?'
$howmanypasswrods = 1..$numberofpasswords

$rand = new-object System.Random
$MyPword = $null
$word1 = $null
$word2 = $null
$conjunction = "the","my","we","our","and","but","+","when","while","as"
$punctuation = '~', '!', '@', '#', '$', '%', '^', '&', '(', ')', '-', '.', '+', '=', '}', '{', '\', '/', '|', ';', ',', ':', '<', '>', '?', '"', '*'
<#Change file location path based on where dict.csv saved location path#>
$words = import-csv 'C:\Users\...'

$howmanypasswrods | ForEach-Object {
"------------------------------------------------"
$_

$word1 = ($words[$rand.Next(0,$words.Count)]).Word
$con = ($conjunction[$rand.Next(0,$conjunction.Count)])
$punct = ($punctuation[$rand.Next(0,$punctuation.Count)])
$word2 = ($words[$rand.Next(0,$words.Count)]).Word
$MyPword = $word1 + " " + $con + " " + $word2 + $punct
$MyPword

}

