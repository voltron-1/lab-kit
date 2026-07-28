# creds-sample.ps1 — READ ONLY, fictional creds only. Audit the credential-
# handling flaws below; this script is never executed by check.sh.

$p = ConvertTo-SecureString 'Sup3rSecret!' -AsPlainText -Force
$cred = New-Object PSCredential('svc_admin', $p)

$key = 'hardcoded-32-byte-key-do-not-use-ever!'
$enc = 'RgB1AGwAbAB5AC0AZgBhAGsAZQA='
$p2 = ConvertTo-SecureString $enc -Key $key

Write-Output $env:AWS_SECRET_ACCESS_KEY
