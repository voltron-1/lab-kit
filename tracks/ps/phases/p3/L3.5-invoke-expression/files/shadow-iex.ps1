# Safe Shadow implementation of Invoke-Expression for demonstration # lint-allow: shadows the real cmdlet with a logger below, never evaluates
function Invoke-Expression {  # lint-allow: redefinition is the logger, not the real cmdlet
    param([Parameter(Mandatory)][string]$Command)
    Add-Content -Path "$PSScriptRoot/iex.log" -Value "SHADOWED_IEX_LOG: $Command"  # lint-allow: logs the string, never evaluates it
    Write-Output "Shadowed execution logged command: $Command"
}
Set-Alias -Name iex -Value Invoke-Expression -Scope Global -Option AllScope -Force  # lint-allow: aliases the safe logger above, not the real cmdlet
