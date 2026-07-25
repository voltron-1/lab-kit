if ((Get-Command Invoke-Command).Parameters.ContainsKey('ComputerName')) {
    'HAS-COMPUTERNAME'
}
else {
    'NO'
}
