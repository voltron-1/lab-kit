$results = @($null, $null, $null)
if ($results -eq $null) { "arr -eq null: TRUE (misleading! `$results` is a populated 3-element array, not null)" } else { "arr -eq null: false" }
if ($null -eq $results) { "null -eq arr: true" } else { "null -eq arr: FALSE (correct)" }
