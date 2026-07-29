# collector.ps1 -- EXCERPT of an incident-response triage collector, shipped read-only.
# This is teaching material: it is never executed by the grader, and several of the
# cmdlets below only exist on Windows. Read it for WHAT EVIDENCE IT GATHERS.
#
# The shape of every IR collector is the same: decide what evidence matters, gather
# each category, and serialize the lot to something an analyst or a SIEM can parse.

# --- section 1: running processes -------------------------------------------
# Cross-platform. Answers "what is executing right now", and Path is what lets you
# spot a binary running from a user-writable directory.
$processes = Get-Process | Select-Object Name, Id, Path

# --- section 2: autostart entries (persistence) ------------------------------
# Windows-only (CIM). Answers "what will execute again after a reboot" -- which is
# where persistence lives. An encoded launcher in a Run key is the classic finding.
$autostart = Get-CimInstance Win32_StartupCommand |
    Select-Object Name, Command, Location

# --- section 3: logon events -------------------------------------------------
# Windows-only. 4624 is a successful logon. LogonType matters as much as the event:
# type 3 is a network logon, type 10 is RDP.
# The two fields you actually triage on are not top-level properties -- they live in
# the event's Properties array, so the collector projects them out with calculated
# properties. That is why the report shows LogonType and Account rather than a wall
# of Message text.
$logons = Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4624 } |
    Select-Object TimeCreated, Id,
        @{ N = 'LogonType'; E = { $_.Properties[8].Value } },
        @{ N = 'Account';   E = { $_.Properties[5].Value } }

# --- section 4: recently written files in temp --------------------------------
# Answers "what was dropped". Size and write time are what make a staging directory
# obvious once you sort by them.
$tempFiles = Get-ChildItem $env:TEMP -Recurse -File -ErrorAction SilentlyContinue |
    Select-Object FullName, Length, LastWriteTime

# --- serialize ----------------------------------------------------------------
# One structured report, not four piles of console text. JSON so an analyst can
# diff two collections, and a SIEM can ingest it without a parser being written.
[pscustomobject]@{
    collected = (Get-Date).ToString('o')
    host      = $env:COMPUTERNAME
    sections  = [pscustomobject]@{
        processes = $processes
        autostart = $autostart
        logons    = $logons
        tempFiles = $tempFiles
    }
} | ConvertTo-Json -Depth 6 | Out-File -Encoding utf8 report.json
