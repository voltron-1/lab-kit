switch -Regex -File "$PSScriptRoot/events.log" {
    'FAILED' { "HIT:$_" }
}
