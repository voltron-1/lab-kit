function Get-SuspiciousProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(ValueFromPipeline)]
        [int]$MinWorkingSetMB = 100,

        [ValidateSet('Stop','Continue','Ignore')]
        [string]$OnFound = 'Continue'
    )
    process {
        Get-Process -Name $Name |
            Where-Object { $_.WS -gt ($MinWorkingSetMB * 1MB) }
    }
}
