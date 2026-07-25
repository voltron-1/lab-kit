#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Quick','Full')]
    [string]$Mode,

    [int]$TopN = 5
)

Import-Module Microsoft.PowerShell.Management

function Get-HealthTag {
    param([double]$WorkingSetMB)
    if     ($WorkingSetMB -gt 500) { 'CRITICAL' }
    elseif ($WorkingSetMB -gt 100) { 'WARN' }
    else                           { 'OK' }
}

$report = foreach ($p in Get-Process | Sort-Object WS -Descending | Select-Object -First $TopN) {
    $mb  = [math]::Round($p.WS / 1MB, 1)
    [pscustomobject]@{
        Name = $p.ProcessName
        MB   = $mb
        Tag  = (Get-HealthTag -WorkingSetMB $mb)
    }
}

switch ($Mode) {
    'Quick' { $report | Select-Object Name, Tag }
    'Full'  { $report | Format-Table -AutoSize }
    default { throw "unknown mode: $Mode" }
}

try {
    $report | ConvertTo-Json | Out-File './health.log'
}
catch {
    Write-Warning "log write failed: $($_.Exception.Message)"
}

$critical = @($report | Where-Object { $_.Tag -eq 'CRITICAL' })
if ($critical.Count -gt 0) {
    "escalate: $($critical.Count) critical process(es)"
}
else {
    'all clear'
}
