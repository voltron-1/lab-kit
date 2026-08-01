# candidate.ps1 -- READ ONLY, sample for PSScriptAnalyzer practice. Never
# executed by check.sh; run it yourself with PSScriptAnalyzer installed.
function Show-Status {
    $items = gci $env:TEMP
    Write-Host "Found $($items.Count) items"
}
