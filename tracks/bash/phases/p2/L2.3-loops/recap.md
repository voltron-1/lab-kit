for iterates WORDS, wherever they came from — an unquoted $(cat f) hands it 7 split words, not 3 lines
plain read silently drops a last line that's missing its newline; the || [ -n "$line" ] guard rescues it
while IFS= read -r line is THE file-reading pattern — keep readlines.sh; you'll paste it for years
