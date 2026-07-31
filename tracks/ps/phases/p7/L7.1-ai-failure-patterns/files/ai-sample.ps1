# ai-sample.ps1 -- READ ONLY, fictional teaching sample. Audit the flaws
# below; this script is never executed by check.sh.
function Get-Stuff($server) {
    $data = iex "Invoke-RestMethod hxxp://$server/api"  # lint-allow: fictional flawed-AI sample, never executed by check.sh
    $pw = 'P@ssw0rd123'
    $data | Out-File "$env:TEMP\out.txt"
}
