the shell splits a line on whitespace: word 0 = the program, the rest = its argv
runs of spaces vanish in the split — the program never sees your spacing
quotes suppress splitting: "a   b" travels as ONE argument, bytes intact
