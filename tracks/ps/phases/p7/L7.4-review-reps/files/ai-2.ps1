# ai-2.ps1 -- READ ONLY, fictional teaching sample. Audit the flaws below;
# this script is never executed by check.sh.
function Connect-Service {
    $pw = ConvertTo-SecureString 'Sup3rSecret!' -AsPlainText -Force
    $cred = New-Object PSCredential('svc_account', $pw)
    Invoke-Command -ComputerName $env:COMPUTERNAME -Credential $cred -ScriptBlock { Get-Process }
}
