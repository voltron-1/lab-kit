Get-Process -Name pwsh | Select-Object -First 1 Name, @{Name='MB';Expression={[math]::Round($_.WS/1MB,1)}} | Format-Table -AutoSize | Out-String -Width 200
