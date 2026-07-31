# ai-3.ps1 -- READ ONLY, fictional teaching sample. Audit the flaws below;
# this script is never executed by check.sh.
function Remove-OldLog($name) {
    Remove-Item -Path "$env:TEMP\logs\$name" -Force
}
