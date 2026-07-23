switch -Regex ('4104') {
    '^\d+$' { 'DIGITS' }
    '41'    { 'HAS41' }
    default { 'NO-MATCH' }
}
