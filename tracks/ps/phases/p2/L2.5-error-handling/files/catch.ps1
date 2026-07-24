try {
    Get-Content './nope.txt' -ErrorAction Stop
}
catch {
    'CAUGHT'
}
finally {
    'FINALLY'
}
