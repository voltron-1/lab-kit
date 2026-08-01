# ai-1.ps1 -- READ ONLY, fictional teaching sample. Audit the flaws below;
# this script is never executed by check.sh.
function Get-Update {
    iex (Invoke-RestMethod hxxp://update.fake-vendor[.]test/latest.ps1)  # lint-allow: fictional flawed-AI sample, never executed by check.sh
}
