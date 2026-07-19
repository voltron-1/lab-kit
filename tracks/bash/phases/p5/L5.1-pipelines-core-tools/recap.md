A pipeline is a chain of single-purpose filters — each stage reads stdin, transforms it, and writes stdout to the next; read it top to bottom, one transformation at a time.
uniq -c only collapses ADJACENT duplicate lines, which is why sort almost always comes right before it — unsorted input makes uniq silently undercount.
grep filters rows, cut extracts columns, sort orders, uniq -c counts, a second sort -rn ranks — that shape covers most "what's happening the most" log questions.
