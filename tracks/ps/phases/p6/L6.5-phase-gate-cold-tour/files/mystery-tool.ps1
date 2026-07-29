# Shipped read-only for the phase gate. It is deliberately not labelled with what
# it does -- working that out is the exercise.
#
# Do not run this. Read it. Pass 2 walks a Windows path that does not resolve off
# Windows, but pass 1 is cross-platform and would hash every running process image
# on whatever machine you are sitting at. On a corporate Windows host the shipped
# scan root would mean reading every byte of every user profile, which is both slow
# and indistinguishable from something an EDR should page someone about.

$ListPath = Join-Path $PSScriptRoot 'reference-list.txt'
$ScanRoot = 'C:\Lab\NoSuchRoot'   # sentinel: set this deliberately before any real use

$known = Get-Content -LiteralPath $ListPath |
    Where-Object { $_ -and -not $_.TrimStart().StartsWith('#') } |
    ForEach-Object { $_.Trim().ToUpperInvariant() }

$fromProcesses = Get-Process |
    Where-Object { $_.Path } |
    ForEach-Object {
        $digest = (Get-FileHash -LiteralPath $_.Path -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        if ($digest -and $known -contains $digest.ToUpperInvariant()) {
            [pscustomobject]@{
                Source = 'running process'
                Name   = $_.Name
                Id     = $_.Id
                Path   = $_.Path
                Sha256 = $digest
            }
        }
    }

$fromDisk = Get-ChildItem -LiteralPath $ScanRoot -Recurse -File -ErrorAction SilentlyContinue |
    Get-FileHash -Algorithm SHA256 -ErrorAction SilentlyContinue |
    Where-Object { $known -contains $_.Hash.ToUpperInvariant() } |
    ForEach-Object {
        [pscustomobject]@{
            Source = 'file on disk'
            Name   = Split-Path -Path $_.Path -Leaf
            Id     = $null
            Path   = $_.Path
            Sha256 = $_.Hash
        }
    }

@($fromProcesses) + @($fromDisk) |
    Sort-Object Source, Path |
    Format-Table Source, Name, Id, Path -AutoSize
