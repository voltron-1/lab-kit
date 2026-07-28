# read4104.ps1 — cross-platform, benign. Parses the shipped, sanitized 4104
# event XML and PRINTS the ScriptBlockText field it recorded — the same
# field a SOC analyst reads first. Nothing here executes that text.
[xml]$xml = Get-Content -Path (Join-Path $PSScriptRoot 'event-4104.xml')
$xml.Event.EventData.Data | Where-Object { $_.Name -eq 'ScriptBlockText' } | ForEach-Object { Write-Output $_.'#text' }
