# creds-sample.ps1 — READ ONLY, fictional creds only. Audit the credential-
# handling flaws below; this script is never executed by check.sh.

$p = ConvertTo-SecureString 'Sup3rSecret!' -AsPlainText -Force
$cred = New-Object PSCredential('svc_admin', $p)

[byte[]]$key = 1..32
$enc = '76492d1116743f0423413b16050a5345MgB8AEUAagBOAFAASgBOAGgAZgBWAFIANABxAFgAbAA4ADkAdgBQAFMAcQB1AFEAPQA9AHwAZAAxAGUAZQA4AGEAMAA4ADYAMgBiADQAOQBhAGMANwAwAGQAZAA2AGEANgBlAGYANgBkAGMAOQBkADQANwBiADQAMQA2ADgAYgA1ADMANwBiADMANwBkADcAZgAxADIAOABmAGYAYgA1AGMAMwAwADYAZABhAGEAMABjADAAZgA='
$p2 = ConvertTo-SecureString $enc -Key $key

Write-Output $env:LABKIT_DEMO_SECRET
