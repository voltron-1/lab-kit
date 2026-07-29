# hunt.ps1 -- a threat hunt for obfuscated PowerShell, shipped read-only.
# Get-WinEvent reads Windows event logs and does not exist off Windows, so this
# script is teaching material here: it is never executed by the grader. Read it
# for WHICH LOG it reads, WHICH EVENT ID, and WHAT PATTERN it hunts for.

# Get-WinEvent -FilterHashtable is the standard event-query idiom. The filtering
# happens in the event-log service, not in PowerShell, which is why you always
# push LogName and Id into the hashtable rather than piping everything to
# Where-Object -- on a busy host the difference is minutes versus seconds.
Get-WinEvent -FilterHashtable @{
        LogName = 'Microsoft-Windows-PowerShell/Operational'
        Id      = 4104
    } |
    # 4104 carries the DECODED ScriptBlock text, which is the whole reason this
    # hunt works: whatever obfuscation was used on the command line, the script
    # block is logged after PowerShell has parsed it.
    Where-Object { $_.Message -match '-enc|FromBase64String|DownloadString' } | # lint-allow: detection pattern in a defensive hunt, matched against log text, never invoked
    Select-Object TimeCreated, @{ N = 'Script'; E = { $_.Message } }

# What this hunt catches: the encoded-command flag, the base64 decode call, and
# the download cradle -- the tells from phases 4 and 5.
#
# What it does NOT catch, and you should be able to say why: a payload that
# assembles those same keywords at runtime out of fragments never spells any of
# them literally in the ScriptBlock text, so -match finds nothing. That is the
# same gap the Sigma rule in the next lab has.
