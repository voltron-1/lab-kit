$m = Import-PowerShellDataFile "$PSScriptRoot/AdminTools.psd1"
$m.FunctionsToExport
$m.ModuleVersion
