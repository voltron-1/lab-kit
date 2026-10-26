// tests/site-smoke.mjs [page.html] — drives docs/site/soc.html in headless
// Chromium: home, L4.1 end to end, persistence, export/reset/import, hints,
// 375 px layout, zero console errors. Uses the pre-installed playwright.
// SITE_EXPORT_OUT=<path> keeps the exported progress.json for further checks.
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { mkdtempSync, readFileSync, copyFileSync } from 'node:fs';
import { tmpdir } from 'node:os';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const here = dirname(fileURLToPath(import.meta.url));
const page_path = resolve(process.argv[2] || join(here, '..', 'docs', 'site', 'soc.html'));
const url = 'file://' + page_path;
const PROGRESS = 'labkit.soc.progress.v1';

let failed = 0;
function ok(cond, msg) {
  console.log((cond ? '  ok   ' : '  FAIL ') + msg);
  if (!cond) failed++;
}

const browser = await chromium.launch();
const ctx = await browser.newContext({ viewport: { width: 1000, height: 900 }, acceptDownloads: true });
const page = await ctx.newPage();
const errors = [];
page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text()); });
page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
page.on('dialog', (d) => d.accept());

// 1. fresh home
await page.goto(url);
ok((await page.locator('.lab-row').count()) === 52, '52 lab rows');
ok((await page.locator('.mark-frontier').count()) === 1, 'exactly one ▶');
ok((await page.locator('.lab-row[data-id="L0.1"] .mark-frontier').count()) === 1, 'L0.1 is the ▶');
ok((await page.locator('.lab-row.locked').count()) === 51, '51 locked rows, none are links');
ok((await page.locator('a.lab-row').count()) === 1, 'only the frontier row is a link');

// 1b. L0.1: each workspace file shows the step that makes it, and Run fills it via the terminal
await page.goto(url + '#/lab/L0.1');
await page.waitForSelector('#workspace');
ok(/Your task: Produce 4 files: jq_out\.txt.*Start at step 3/.test(await page.locator('#task').innerText()), 'L0.1: task line names the 4 files and says to start at step 3');
ok((await page.locator('li.fold details:not([open])').count()) === 2, 'L0.1: install and cd steps are folded, not shown as tasks');
ok((await page.locator('#workspace .directions').count()) === 4, 'L0.1: all 4 workspace files carry directions');
ok(/jq -r '\.user\.name'/.test(await page.locator('.ws-file[data-file="jq_out.txt"] .directions').innerText()), 'jq_out.txt directions show the jq command');
await page.locator('.ws-file[data-file="jq_out.txt"] [data-run]').first().click();
ok((await page.locator('#ws-jq_out_txt').inputValue()).trim() === 'm.reyes', 'Run on the jq step writes m.reyes into jq_out.txt');
ok((await page.locator('.ws-file[data-file="jq_out.txt"] .run-out').count()) === 1, 'Run shows its output under the command');
for (const f of ['tshark_out.txt', 'rg_out.txt', 'toolcheck.txt']) {
  await page.locator(`.ws-file[data-file="${f}"] [data-run]`).first().click();
}
ok(/coppermine\.example/.test(await page.locator('#ws-tshark_out_txt').inputValue()), 'tshark step fills tshark_out.txt from the pcap');
ok(/CM-TOOLBELT-7C42/.test(await page.locator('#ws-rg_out_txt').inputValue()), 'rg step fills rg_out.txt');
ok(/TShark/.test(await page.locator('#ws-toolcheck_txt').inputValue()), 'version step fills toolcheck.txt');
await page.fill('.term-in', 'ls notes | wc -l; grep -c escalation notes/triage-notes.txt');
await page.press('.term-in', 'Enter');
ok(/^\s*1\s*\n?\s*1\s*$/m.test((await page.locator('.term-log').innerText()).slice(-60)) || /1\n1/.test(await page.locator('.term-log').innerText()), 'terminal runs pipes');
await page.fill('.term-in', 'lab check soc L0.1');
await page.press('.term-in', 'Enter');
ok(/checks 14\/14/.test(await page.locator('.term-log').innerText()), 'lab check in the terminal grades 14/14');
ok((await page.locator('#results .res.ok').count()) === 14, 'lab check in the terminal also fills the Check panel');
await page.fill('.term-in', 'echo "unterminated');
await page.press('.term-in', 'Enter');
ok((await page.locator('.term-in').inputValue()).includes('\n'), 'Enter inside an open quote continues on a new line');
await page.fill('.term-in', '');

// 2. force L0.1..L3.7 passed
const ids = await page.evaluate(() => JSON.parse(document.getElementById('lab-data').textContent).labs.map((l) => l.id));
const upto = ids.indexOf('L4.1');
const labs = {};
ids.slice(0, upto).forEach((id) => {
  labs['soc/' + id] = { status: 'passed', skipped: false, attempts: 1, hints_used: 0,
    started_at: '2026-01-01T00:00:00Z', first_passed_at: '2026-01-01T00:00:00Z', last_attempt_at: '2026-01-01T00:00:00Z' };
});
await page.evaluate(([k, l]) => localStorage.setItem(k, JSON.stringify(
  { version: 1, created_at: 'a', updated_at: 'a', labs: l, events: [] })), [PROGRESS, labs]);
await page.goto(url + '#/lab/L4.1');
await page.reload();

ok((await page.locator('.tab').allTextContents()).join(',') === 'alert.json,asset-inventory.csv,events.jsonl', 'L4.1 evidence tabs');
ok((await page.locator('#workspace textarea').count()) === 1, 'one workspace textarea');
const prefill = await page.locator('#workspace textarea').inputValue();
ok((prefill.match(/^q\d=/gm) || []).length === 5, 'textarea prefilled with 5 q lines');

// hints reveal one at a time
for (let i = 1; i <= 3; i++) {
  await page.click('#btn-hint');
  ok((await page.locator('#hints .hint').count()) === i, `hint ${i} revealed (${i} visible)`);
}
ok(await page.locator('#btn-hint').isDisabled(), 'hint button disabled after the last hint');

// evidence filter + csv table
await page.click('.tab:has-text("events.jsonl")');
const total = await page.locator('#evidence .ln').count();
await page.fill('#evidence input[type=text]', 'powershell');
const filtered = await page.locator('#evidence .ln').count();
ok(filtered > 0 && filtered < total, 'filter hides non-matching lines');
await page.click('.tab:has-text("asset-inventory.csv")');
await page.locator('#evidence label:has-text("table") input').check();
ok((await page.locator('#evidence table tr').count()) > 1, 'csv table view');

// failing check first, then fix
await page.click('#btn-check');
ok((await page.locator('#results .res.bad').count()) > 0 && (await page.locator('#quiz-form').count()) === 0, 'template as-is fails and shows no quiz');
await page.fill('#workspace textarea', 'q1=CM-R-0159 # rule\nq2=cm-0311-0201\nq3=n\nq4=1\nq5=tp\n');
await page.keyboard.press('Tab'); // leave the textarea so shortcuts work
await page.evaluate(() => document.activeElement && document.activeElement.blur());
await page.keyboard.press('c');
ok((await page.locator('#results .res.ok').count()) === 8, '8 passes');
const fs = page.locator('#quiz-form fieldset');
ok((await fs.count()) === 3, 'quiz has 3 questions');
for (let i = 0; i < 3; i++) await fs.nth(i).locator('input[value=b]').check();
await page.click('#btn-quiz');
ok(/3\/3/.test(await page.locator('#quiz-verdict').textContent()), 'quiz 3/3');
ok((await page.locator('.banner.passed .recap li').count()) === 3, '✓ banner with 3 recap lines');

await page.reload();
ok((await page.locator('.banner.passed').count()) === 1, '✓ persists after reload');
await page.goto(url + '#/');
ok((await page.locator('.lab-row[data-id="L4.1"] .mark-passed').count()) === 1, 'home shows ✓ on L4.1');
ok((await page.locator('.lab-row[data-id="L4.2"] .mark-frontier').count()) === 1, 'L4.2 is the ▶ after reload');

// 3. export, reset, import
const [dl] = await Promise.all([page.waitForEvent('download'), page.click('#btn-export')]);
const tmp = mkdtempSync(join(tmpdir(), 'site-smoke-'));
const exported = join(tmp, 'progress.json');
await dl.saveAs(exported);
const doc = JSON.parse(readFileSync(exported, 'utf8'));
ok(doc.version === 1 && typeof doc.labs === 'object' && Array.isArray(doc.events), 'export has the .progress.json v1 shape');
ok(doc.labs['soc/L4.1'] && doc.labs['soc/L4.1'].status === 'passed' && doc.labs['soc/L4.1'].hints_used === 3, 'export records L4.1 passed with 3 hints');
const ev = doc.events.find((e) => e.id === 'L4.1');
ok(ev && ev.type === 'pass' && ev.track === 'soc' && ev.recap.length === 3 && typeof ev.seq === 'number', 'pass event carries seq, track and recap');
if (process.env.SITE_EXPORT_OUT) copyFileSync(exported, process.env.SITE_EXPORT_OUT);

await page.click('#btn-reset');
ok((await page.locator('.lab-row[data-id="L0.1"] .mark-frontier').count()) === 1, 'reset returns to L0.1 as the ▶');
await page.setInputFiles('#file-import', exported);
await page.waitForSelector('.lab-row[data-id="L4.1"] .mark-passed');
ok(true, 'import restores ✓ on L4.1');
await page.evaluate(() => { document.getElementById('file-import').value = ''; });

// bad import is rejected, store untouched
const bad = join(tmp, 'bad.json');
(await import('node:fs')).writeFileSync(bad, '{"version":2}');
await page.setInputFiles('#file-import', bad);
await page.waitForFunction(() => /Import failed/.test(document.getElementById('toast').textContent));
ok((await page.locator('.lab-row[data-id="L4.1"] .mark-passed').count()) === 1, 'bad import leaves progress alone');

// 4. locked lab deep link
await page.goto(url + '#/lab/L7.7');
ok((await page.locator('text=is locked').count()) === 1, 'locked lab shows the locked notice');

// 5. skip moves the frontier
await page.goto(url + '#/lab/L4.2');
await page.click('#btn-skip');
await page.goto(url + '#/');
ok((await page.locator('.lab-row[data-id="L4.2"] .mark-skipped').count()) === 1, 'skip marks ⏭');
ok((await page.locator('.lab-row[data-id="L4.3"] .mark-frontier').count()) === 1, 'frontier moves past the skipped lab');

// 6. phone width + dark mode
await page.setViewportSize({ width: 375, height: 800 });
for (const hash of ['#/', '#/lab/L4.1', '#/lab/L2.4']) {
  await page.goto(url + hash);
  const over = await page.evaluate(() => document.documentElement.scrollWidth - window.innerWidth);
  ok(over <= 0, `no horizontal overflow at 375px on ${hash}`);
}
await page.emulateMedia({ colorScheme: 'dark' });
await page.goto(url + '#/lab/L4.1');
const bg = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);
ok(bg === 'rgb(20, 23, 27)', 'dark colour scheme applies dark background');
if (process.env.SITE_SHOT_DIR) {
  await page.screenshot({ path: join(process.env.SITE_SHOT_DIR, 'mobile-dark-lab.png'), fullPage: false });
}
await page.click('#btn-theme');
const bg2 = await page.evaluate(() => getComputedStyle(document.body).backgroundColor);
ok(bg2 !== bg, 'theme toggle flips the theme');

ok(errors.length === 0, 'zero console errors' + (errors.length ? ': ' + errors.join(' | ') : ''));
await browser.close();
if (failed) { console.error(`site-smoke: ${failed} check(s) failed`); process.exit(1); }
console.log('site-smoke: all checks passed');
