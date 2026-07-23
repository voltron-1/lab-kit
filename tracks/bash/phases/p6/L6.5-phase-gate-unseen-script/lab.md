## BRIEF
This is the Phase 6 Phase Gate: a solo tour of a production cron wrapper (`files/feed-refresh.sh`).
You have not seen this script before. Read it cold from top to bottom — including the header comments, which detail the `/etc/cron.d/` schedule and environment constraints.
Nothing in this kit executes `files/feed-refresh.sh`. Audit the script and record your answers in `answers.txt`.

## GUIDED STEPS

1. **Audit `files/feed-refresh.sh` cold**:
   - Read the header comments, cron schedule, environment setup, single-instance locking (`flock`), staleness monitoring, download validation (`jq`), and atomic deployment mechanics.

2. **Verify ShellCheck status**:
   ```bash
   shellcheck -x -S style files/feed-refresh.sh
   ```
   *(Expected output: clean, 0 findings)*

3. **Write `answers.txt`** containing eight `key=value` lines using the exact allowed vocabulary:
   - `schedule=4`
   - `lock=flock`
   - `lockexit=0`
   - `pinpath=cron`
   - `tmphome=atomic`
   - `mustpass=jq`
   - `failmode=kept`
   - `warnwho=monitoring`

4. **Check your work**:
   ```bash
   lab check bash L6.5
   ```
