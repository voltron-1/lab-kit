# fmt.ps1 -- the -f format operator substitutes args into {index} placeholders. Reordering
# the indices scrambles a keyword's letters in the source while the runtime result is fully
# reassembled. This script only evaluates the format expressions and PRINTS the results --
# it never invokes what they spell.
$byIndex = "{0}{2}{1}" -f 'I','x','E'
$byIndex2 = "{1}{0}" -f 'ex','i'

Write-Output "reordered 3-arg format: $byIndex"
Write-Output "reordered 2-arg format: $byIndex2"
