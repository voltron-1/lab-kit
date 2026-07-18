curl | bash executes whatever the server sends, unread, right now — trusting the URL means trusting every future version of that file and anyone who can sit on the network path
audit red flags: a chained remote script piped into sh, unexplained sudo, a plain-HTTP download that gets executed, writes to a shell rc file (persistence), and anything shipping env or tokens off-box (exfiltration)
the safe pattern is fetch to a file, read it end to end, pin a version, then decide to run it — never pipe a URL straight into a shell
