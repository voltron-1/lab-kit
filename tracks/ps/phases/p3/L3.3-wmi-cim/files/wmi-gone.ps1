if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
    'PRESENT'
}
else {
    'ABSENT-IN-PS7'
}
