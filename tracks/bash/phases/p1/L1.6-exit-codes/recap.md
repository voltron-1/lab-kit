every command leaves a one-byte verdict in $? — 0 means success, nonzero means some flavor of failure
EVERY command overwrites $? — including the echo you just used to look at it
if consumes the exit code, not the output; scripts are commands too — exit 1 is pulse.sh reporting upward
