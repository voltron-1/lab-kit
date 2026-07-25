function Get-HealthTag {
    param([double]$WorkingSetMB)
    if     ($WorkingSetMB -gt 500) { 'CRITICAL' }
    elseif ($WorkingSetMB -gt 100) { 'WARN' }
    else                           { 'OK' }
}

Get-HealthTag -WorkingSetMB 600
Get-HealthTag -WorkingSetMB 250
Get-HealthTag -WorkingSetMB 50
