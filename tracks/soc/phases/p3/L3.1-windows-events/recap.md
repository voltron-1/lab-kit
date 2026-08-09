A handful of Windows Security codes carry most of triage: 4624 logon success, 4625 failure, 4688 process creation, 4720 account created, 4732 group add.
winlog.logon.type is the qualifier — 2 interactive, 3 network, 5 service, 10 RDP — and type 3 from an external IP is how a spray success looks.
4720 then 4732 is the account-created-then-elevated story; read the group, not just the name.
