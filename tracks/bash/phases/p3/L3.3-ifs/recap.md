IFS is the shell's cutting guide: it decides where unquoted $var and $(cmd) break into separate words — default is space/tab/newline
change IFS and the same line parses differently: IFS=':' reads /etc/passwd fields; IFS='' turns splitting off entirely
a script that splits untrusted data while trusting an inherited IFS can be re-steered — set IFS explicitly, and quote what must stay whole
