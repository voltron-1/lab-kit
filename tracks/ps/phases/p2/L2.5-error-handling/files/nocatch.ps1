$ErrorActionPreference = 'Continue'
try {
    Get-Content './nope.txt'
}
catch {
    'CAUGHT'
}
'REACHED-END'
