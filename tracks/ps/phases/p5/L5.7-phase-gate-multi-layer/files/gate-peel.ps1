# gate-peel.ps1 -- the phase gate sample, three layers deep:
#   layer 1  base64/UTF-16LE   (L5.1)
#   layer 2  character reversal (L5.4)
#   layer 3  an unresolved format-operator expression (L5.3)
# Each layer is undone and PRINTED. Layer 3 is resolved as DATA: this script runs
# its own format expression to compute the replacement text, then swaps that text
# into the string. Nothing from the sample is ever executed -- not a fragment of it.
# Resolve the sample next to this script rather than against the current directory,
# so the probe reads the same file wherever it is run from.
$blobPath = Join-Path $PSScriptRoot 'gate-blob.txt'
$blob = (Get-Content -Raw -LiteralPath $blobPath).Trim()

try {
    $layer1 = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($blob))
} catch {
    Write-Output "gate-blob.txt no longer looks like base64 -- restore the shipped sample."
    exit 1
}
$layer2 = -join $layer1[-1..-$layer1.Length]

# The sample leaves this expression unresolved so a scanner never sees the keyword.
# Resolve it the same way the sample would have: same indices, same arguments --
# evaluated here on our own literals, never on anything the sample supplies.
$fmtText  = '("{0}{2}{1}" -f ''I'',''x'',''E'')'
$fmtValue = '{0}{2}{1}' -f 'I', 'x', 'E'
$layer3   = $layer2.Replace($fmtText, $fmtValue)

Write-Output "layer 1 -- base64 decoded, still reversed:   $layer1"
Write-Output "layer 2 -- reversed back, format unresolved: $layer2"
Write-Output "layer 3 -- format resolved, full plaintext:  $layer3"
