# rev.ps1 -- $s[-1..-$s.Length] -join '' walks a string backwards, character by character.
# A reversed literal hides a keyword from forward string scans; reversing it again recovers
# the original. This script only reverses and PRINTS -- it never invokes what it spells.
$s1 = 'xei'
$s2 = 'gnirtSdaolnwoD'
$r1 = -join $s1[-1..-$s1.Length]
$r2 = -join $s2[-1..-$s2.Length]

Write-Output "reversed keyword 1: $r1"
Write-Output "reversed keyword 2: $r2"
