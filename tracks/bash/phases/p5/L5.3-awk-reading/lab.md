## BRIEF
Three `awk` one-liners over `alerts.csv` — a running count per severity, a
filtered projection, and a header inspection. `awk` looks like magic
mostly because it hides how ordinary it is: split each line into fields,
run an action when a pattern matches, keep a running total in a variable.
Predict each command's output **before** running it — the check can't
tell whether you predicted first, you're only cheating your own reps.

## GUIDED STEPS

1. Look at the data — do not run any `awk` command yet:

       cat alerts.csv

   ```
   timestamp,severity,host
   2026-07-18T10:00:00Z,high,host-a.test
   2026-07-18T10:05:00Z,low,host-b.test
   2026-07-18T10:07:00Z,high,host-a.test
   2026-07-18T10:09:00Z,medium,host-c.test
   2026-07-18T10:11:00Z,high,host-b.test
   2026-07-18T10:15:00Z,low,host-a.test
   ```

   3 columns: `timestamp`, `severity`, `host`. 6 data rows plus a header.

2. Read these three commands and predict their output before running any
   of them:

       awk -F',' 'NR>1 {count[$2]++} END {for (s in count) print s, count[s]}' alerts.csv | sort
       awk -F',' '$2=="high" {print $1, $3}' alerts.csv
       awk -F',' 'NR==1 {print NF, "fields:", $0}' alerts.csv

   Command 1 skips the header (`NR>1`), tallies a `count[]` array keyed by
   the severity field (`$2`), and prints every key/value pair once at
   `END` — piped through `sort` because `awk`'s array iteration order is
   unspecified. Command 2 keeps only rows where `$2` equals `"high"` and
   prints the timestamp and host columns. Command 3 fires only on line 1
   (`NR==1`) and prints `NF` (how many fields that line split into) plus
   the whole line.

3. Write your predictions to `predictions.txt` before running anything:

       predict1_line1=<severity count line 1>
       predict1_line2=<severity count line 2>
       predict1_line3=<severity count line 3>
       predict2_line1=<first high row: timestamp host>
       predict2_line2=<second high row: timestamp host>
       predict2_line3=<third high row: timestamp host>
       predict3=<NF> fields: <header line>

4. Now run all three for real and compare:

       awk -F',' 'NR>1 {count[$2]++} END {for (s in count) print s, count[s]}' alerts.csv | sort
       awk -F',' '$2=="high" {print $1, $3}' alerts.csv
       awk -F',' 'NR==1 {print NF, "fields:", $0}' alerts.csv

   captured output:

       ```
       $ awk -F',' 'NR>1 {count[$2]++} END {for (s in count) print s, count[s]}' alerts.csv | sort
       high 3
       low 2
       medium 1

       $ awk -F',' '$2=="high" {print $1, $3}' alerts.csv
       2026-07-18T10:00:00Z host-a.test
       2026-07-18T10:07:00Z host-a.test
       2026-07-18T10:11:00Z host-b.test

       $ awk -F',' 'NR==1 {print NF, "fields:", $0}' alerts.csv
       3 fields: timestamp,severity,host
       ```

5. Update `predictions.txt` to match what you actually observed:

       predict1_line1=high 3
       predict1_line2=low 2
       predict1_line3=medium 1
       predict2_line1=2026-07-18T10:00:00Z host-a.test
       predict2_line2=2026-07-18T10:07:00Z host-a.test
       predict2_line3=2026-07-18T10:11:00Z host-b.test
       predict3=3 fields: timestamp,severity,host

6. `lab check bash L5.3`
