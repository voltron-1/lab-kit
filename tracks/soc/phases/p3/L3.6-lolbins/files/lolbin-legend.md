# Common LOLBins & Abuse Tells
- powershell.exe: -enc / -w hidden / -nop -> abuse (T1059.001)
- certutil.exe: -urlcache -split -f -> abuse (T1105)
- curl / wget piped to bash: curl ... | bash -> abuse (T1059.004)
- Signed scripts / cert verification -> benign
