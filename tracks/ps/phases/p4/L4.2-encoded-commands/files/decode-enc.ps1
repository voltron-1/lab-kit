# decode-enc.ps1 — cross-platform, benign. Decodes a base64/UTF-16LE blob,
# the exact encoding the encoded-command launch flag always uses, and
# PRINTS the decoded text. This is the real, safe half of the skill: it
# reveals what the blob says, and never executes it.
$encoded = 'VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAnAGIAZQBuAGkAZwBuACcA'
$decoded = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($encoded))
Write-Output $decoded
