# Safe Shadow implementation of Invoke-Expression for demonstration
function Invoke-Expression {
    param([Parameter(Mandatory)][string]$Command)
    Add-Content -Path "$PSScriptRoot/iex.log" -Value "SHADOWED_IEX_LOG: $Command"
    Write-Output "Shadowed execution logged command: $Command"
}
Set-Alias -Name iex -Value Invoke-Expression -Scope Global -Option AllScope -Force
