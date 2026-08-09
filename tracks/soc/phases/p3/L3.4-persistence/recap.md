Persistence lives in a few known homes: Run keys (Sysmon 13 / 4657), scheduled tasks (4698), services (4697/7045), and cron on Linux.
Match the artifact to the mechanism, then read the payload — a Run value or cron line usually names the command that re-launches the attacker.
The same C2 you saw beacon is often re-fetched by persistence — the WEB01 cron pulls u.sh every 10 minutes, defanged as hxxp://cdn.stonewick[.]example/u.sh.
