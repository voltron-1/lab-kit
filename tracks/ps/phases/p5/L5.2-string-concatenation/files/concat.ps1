# concat.ps1 -- reassembles three keywords split across string-literal pieces (the same
# technique real obfuscated launchers use to dodge naive plain-string scanners) and PRINTS
# each result. String concatenation, -join, and [char] codes are all safe, generic
# PowerShell -- reassembling and reading a keyword is never the same as running it.
$byPlus = "i"+"e"+"x"
$byJoin = ('D','o','w','n','l','o','a','d') -join ''
$byCharCode = [char]105 + [char]101 + [char]120

Write-Output "concatenation (+):  $byPlus"
Write-Output "array -join:        $byJoin"
Write-Output "char codes:         $byCharCode"
