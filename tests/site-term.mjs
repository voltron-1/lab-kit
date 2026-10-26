// tests/site-term.mjs <data.json> — differential test of the page's simulated
// terminal (docs/site/src/term/*.js) against the real tools:
//   1. every fenced bash block in every lab.md runs in real bash and in the
//      simulated shell on the same files; stdout and written files must match
//   2. a corpus of extra commands (grep/sed/awk/jq/sort/cut/tr/wc/...) on real
//      evidence, stdout and exit status compared
//   3. lab walkthroughs: the lab's own commands, run in the page terminal,
//      must satisfy the grader's checks on tool-output files (toolcheck.txt, ...)
// Real-tool comparisons are skipped, with a note, for tools the host lacks.
import { createRequire } from 'node:module';
import { readFileSync, readdirSync, mkdtempSync, writeFileSync, mkdirSync, symlinkSync, rmSync, existsSync, statSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const src = join(here, '..', 'docs', 'site', 'src');
const termCode = readdirSync(join(src, 'term')).filter((f) => f.endsWith('.js')).sort()
  .map((f) => readFileSync(join(src, 'term', f), 'utf8')).join('\n');
const mod = { exports: {} };
new Function('module', 'exports', termCode)(mod, mod.exports);
const T = mod.exports;
const { Grader } = require(join(src, 'app.js'));
const data = JSON.parse(readFileSync(process.argv[2], 'utf8'));

const have = (cmd) => spawnSync('sh', ['-c', `command -v ${cmd}`]).status === 0;
const tools = ['jq', 'tshark', 'rg', 'awk', 'sed', 'grep', 'column', 'python3'].filter((t) => !have(t));
if (tools.length) console.log('note: real tools missing, those comparisons are skipped: ' + tools.join(' '));

let failed = 0;
let compared = 0;
function bad(msg) { failed++; console.log('FAIL ' + msg); }

const trackRoot = join(here, '..', 'tracks', 'soc', 'phases');

function makeEmu(lab) {
  const texts = {};
  lab.graded_files.forEach((g) => { texts[g.name] = g.prefill; });
  const vfs = T.vfsFromLab(lab, { get: (n) => texts[n] || '', set: (n, t) => { texts[n] = t; } });
  return { sh: T.createShell({ vfs }), vfs, texts };
}
function makeReal(lab) {
  const dir = mkdtempSync(join(tmpdir(), 'term-real-'));
  const files = join(trackRoot, lab.phase, lab.dir, 'files');
  if (existsSync(files)) spawnSync('cp', ['-R', files + '/.', dir]);
  symlinkSync('.', join(dir, 'files'));
  return dir;
}
function runReal(dir, script) {
  const r = spawnSync('bash', ['--noprofile', '--norc', '-c', script], { cwd: dir, encoding: 'utf8', env: { PATH: process.env.PATH, LC_ALL: 'C.UTF-8', HOME: dir } });
  return { out: r.stdout, err: r.stderr, status: r.status };
}
function runEmu(emu, script) {
  const r = emu.sh.run(script);
  return { out: r.chunks.filter((c) => !c.e).map((c) => c.t).join(''), err: r.chunks.filter((c) => c.e).map((c) => c.t).join(''), status: r.status };
}
function realFiles(dir) {
  const out = {};
  const walk = (d, pre) => {
    for (const n of readdirSync(d)) {
      if (n === 'files' && pre === '') continue;
      const p = join(d, n);
      const rel = pre ? pre + '/' + n : n;
      if (statSync(p).isDirectory()) walk(p, rel);
      else { const b = readFileSync(p); if (!b.includes(0)) out[rel] = b.toString('utf8'); }
    }
  };
  walk(dir, '');
  return out;
}
function syncToReal(dir, emu) {
  for (const f of emu.vfs.allFiles()) {
    const e = emu.vfs.entry(f);
    if (e.bytes) continue;
    const p = join(dir, f);
    mkdirSync(dirname(p), { recursive: true });
    writeFileSync(p, emu.vfs.readText(f));
  }
}
function compareFiles(label, lab, dir, emu) {
  const real = realFiles(dir);
  const mine = {};
  for (const f of emu.vfs.allFiles()) {
    const t = emu.vfs.readText(f);
    if (t !== null && !emu.vfs.entry(f).bytes) mine[f] = t;
  }
  const prefilled = {};
  lab.graded_files.forEach((g) => { prefilled[g.name] = g.prefill; });
  for (const k of new Set([...Object.keys(real), ...Object.keys(mine)])) {
    if (real[k] === undefined && mine[k] === prefilled[k] && prefilled[k] !== undefined) continue;
    if (real[k] !== mine[k]) {
      bad(`${label}: file ${k} differs\n   real: ${JSON.stringify(real[k])?.slice(0, 160)}\n   mine: ${JSON.stringify(mine[k])?.slice(0, 160)}`);
    }
  }
}

/* ---- 1. lab.md bash blocks ---- */
function bashBlocks(md) {
  const blocks = [];
  let cur = null;
  for (const line of md.split('\n')) {
    const f = /^\s*```(\w*)/.exec(line);
    if (f) {
      if (cur === null) cur = { lang: f[1], lines: [] };
      else { if (cur.lang === 'bash') blocks.push(cur.lines.map((l) => l.replace(/^ {1,3}/, '')).join('\n')); cur = null; }
      continue;
    }
    if (cur) cur.lines.push(line);
  }
  return blocks;
}
const SKIP_BLOCK = /\bsudo\b|\blab\b|^cd |\bapt(-get)?\b|--version| -v\b|dig -v/m;
for (const lab of data.labs) {
  const blocks = bashBlocks(lab.lab_md);
  if (!blocks.length) continue;
  const emu = makeEmu(lab);
  const dir = makeReal(lab);
  blocks.forEach((b, i) => {
    const label = `${lab.id} block ${i + 1}`;
    const realTool = /\b(jq|tshark|rg|python3|column)\b/.exec(b);
    if (realTool && tools.includes(realTool[1])) return;
    if (SKIP_BLOCK.test(b)) { runEmu(emu, b); syncToReal(dir, emu); return; }
    const r = runReal(dir, b);
    const m = runEmu(emu, b);
    compared++;
    // tty-only formatting differences: the page terminal is a tty, bash here is not
    if (r.out !== m.out && !(/\brg\b|^ls\b/m.test(b))) {
      bad(`${label}: stdout differs for:\n   ${b.split('\n').join('\n   ')}\n   real: ${JSON.stringify(r.out).slice(0, 300)}\n   mine: ${JSON.stringify(m.out).slice(0, 300)}\n   mine err: ${m.err.slice(0, 200)}`);
    }
    compareFiles(label, lab, dir, emu);
  });
  rmSync(dir, { recursive: true, force: true });
}

/* ---- 2. corpus ---- */
const corpus = {
  'L2.1': ['head -7 conn.log', 'column -t conn.log', 'cut -f1,3,5 conn.log | head -5', "sort -t$'\\t' -k3 conn.log | head -4", 'wc -l conn.log', 'wc conn.log',
    "grep -v '^#' conn.log | wc -l", "awk -F'\\t' '!/^#/{c[$12]++} END{for(k in c) print k, c[k]}' conn.log | sort", 'tail -n +9 conn.log | head -3', 'tail -3 conn.log',
    'grep -c REJ conn.log', 'grep -n REJ conn.log', "grep -i s0 conn.log | cut -f5 | sort -u", "sed -n '2,4p' conn.log", "sed 's/\\t/,/g' conn.log | head -3",
    "tr '\\t' ',' < conn.log | head -2", 'head -3 conn-state-legend.md', "grep -E '^(S0|REJ)' conn-state-legend.md", 'grep -w S0 conn-state-legend.md', 'wc -w conn-state-legend.md',
    'nl conn-state-legend.md | head -3', 'sort -r conn-state-legend.md | head -3', "grep -o 'S[0-9]' conn-state-legend.md | sort | uniq -c", 'grep -c "" conn.log', 'grep -m1 REJ conn.log | cut -f2',
    "awk -F'\\t' 'NR>8{n++} END{print n}' conn.log", 'cat conn-state-legend.md | tr a-z A-Z | head -2', 'cat -n conn-state-legend.md | head -2',
    "sort -u -k5,5 -t$'\\t' conn.log | head -3", "awk -F'\\t' '{print NF}' conn.log | uniq -c", 'grep -e REJ -e S0 conn.log | wc -l', 'grep -A1 REJ conn.log | head -4', "grep -B1 REJ conn.log | head -4", 'grep -v -e "^#" conn.log | sort -k1,1n | head -2'],
  'L4.1': ['jq . alert.json', "jq -r '.entities.host' alert.json", 'jq -c . events.jsonl', "jq -r '.id' events.jsonl", "jq -r '[.id,.event_code]|@tsv' events.jsonl", "jq -s 'length' events.jsonl",
    "jq -s 'map(select(.event_code==1))|length' events.jsonl", "jq -c 'keys' events.jsonl | sort -u", 'column -s, -t asset-inventory.csv', 'cut -d, -f1,2 asset-inventory.csv', 'sort -t, -k2 asset-inventory.csv',
    "jq -r '.rule_id, .severity' alert.json", "jq '.evidence_event_ids | length' alert.json", "jq -r '.evidence_event_ids[]' alert.json | sort -r", 'grep -c . events.jsonl', "grep powershell events.jsonl | jq -r .guid",
    "jq 'to_entries|map(.key)' alert.json -c", "jq -r 'to_entries[]|\"\\(.key)=\\(.value)\"' alert.json | head -4", "jq -S -c . alert.json", "jq --arg x CM 'select(.id|startswith($x))|.id' events.jsonl -r | head -2",
    "awk -F, 'NR>1{print $2}' asset-inventory.csv | sort | uniq -c | sort -rn", "awk -F, '$3==\"low\"' asset-inventory.csv", 'tail -n 2 asset-inventory.csv', "sed '1d' asset-inventory.csv | wc -l", "sed -E 's/(WKS)-([A-Z]+)/\\2:\\1/' asset-inventory.csv | head -2",
    "jq -e '.severity==\"critical\"' alert.json", "jq '.nope.deeper' alert.json", "jq -r '.entities|keys[]' alert.json", "tr -d ',' < asset-inventory.csv | head -2", 'wc -c alert.json', 'sha256sum alert.json | cut -c1-16'],
  'L4.2': ["jq '.last_analysis_stats.malicious' enrichment/vt-ip-203.0.113.66.json", "jq -r '.resolutions[].domain' enrichment/pdns-203.0.113.66.json", 'cat enrichment/whois-stonewick.txt | head -4', "grep -i 'creation' enrichment/whois-stonewick.txt",
    "jq -r 'keys[]' enrichment/vt-hash.json | head -3", 'ls enrichment | cat', 'find enrichment -name "*.json" | sort', 'wc -l enrichment/*.json', 'grep -l malicious enrichment/*.json', "jq -c '.last_analysis_stats' enrichment/vt-ip-203.0.113.66.json"],
  'L3.1': ['wc -l security.json', "jq -r '.event.code' security.json | sort | uniq -c", "jq -r 'select(.event.code==4625)|.user.name' security.json | sort -u", "jq -c 'select(.source.ip!=null)|.source.ip' security.json | sort -u | head -2",
    "grep -c 4625 security.json", "jq -r '.winlog.logon.type' security.json | sort -n | uniq -c", "jq -s 'group_by(.user.name)|map({u:.[0].user.name,n:length})' security.json -c", "jq -s 'map(.host.name)|unique' security.json -c"],
  'L2.2': ["grep -v '^#' dns.log | cut -f3 | sort | uniq -c | sort -rn | head -3", "awk -F'\\t' '!/^#/{print length($8)}' dns.log | sort -n | tail -2", "grep -c tun dns.log", "awk -F'\\t' '!/^#/ && $8 ~ /tun/ {n++} END{print n+0}' dns.log", "grep -v '^#' dns.log | head -2 | cut -f1,8", 'head -8 dns.log | tail -3 | cut -c1-30'],
  'L1.2': ["grep j.walsh raw-syslog.txt", "jq -r '.\"@timestamp\"' ecs.jsonl | head -3", "sort -t, -k2 events-map.csv | head -3", "jq . windows-raw.json | head -8", 'wc -l raw-syslog.txt ecs.jsonl', "cut -d' ' -f1-3 raw-syslog.txt | head -3", "awk '{print $5}' raw-syslog.txt | sort | uniq -c | sort -rn | head -3"],
  'L0.1': ["jq -r '.user.name' sample-event.json", "tshark -n -r fixtures.pcap -T fields -e dns.qry.name | sort -u", "rg --no-ignore 'escalation-marker' notes/ | cat", "rg -n escalation notes/triage-notes.txt | cat", "grep 'Creation Date' whois-stonewick.txt", "tshark -r fixtures.pcap -Y 'dns.flags.response==1' -T fields -e dns.qry.name -e dns.a",
    "tshark -r fixtures.pcap | head -3", "tshark -r fixtures.pcap -Y 'dns.qry.name contains \"www\"' | cat", "tshark -r fixtures.pcap -c 2 -T fields -e frame.number -e ip.src -e ip.dst", "tshark -r fixtures.pcap -Y 'ip.addr==192.0.2.44' -T fields -e frame.number"],
  'L2.4': ["tshark -r capture.pcap -Y 'dns.flags.response==0' -T fields -e dns.qry.name | sort -u", "tshark -r capture.pcap -Y 'dns.flags.response==1' -T fields -e dns.a | sort -u", "tshark -r capture.pcap -Y http.request -T fields -e http.request.method -e http.host -e http.request.uri",
    "tshark -r capture.pcap -Y http.request -T fields -e http.user_agent", "tshark -r capture.pcap -Y 'http.response' -T fields -e http.response.code", "tshark -r capture.pcap -z follow,tcp,ascii,0 -q", "tshark -r capture.pcap | head -4", "tshark -r capture.pcap -Y 'tcp.flags.syn==1' -T fields -e frame.number -e tcp.srcport -e tcp.dstport",
    "tshark -r capture.pcap -Y 'tcp.stream==0 && http' -T fields -e frame.number", "tshark -r capture.pcap -Y 'http.host contains \"stonewick\"' | cat", "tshark -r capture.pcap -T fields -e frame.number -e _ws.col.Protocol | head -3"],
  'L2.7': ["tshark -r capture.pcap -Y 'tls.handshake.extensions_server_name' -T fields -e tls.handshake.extensions_server_name", "tshark -r capture.pcap -T fields -e frame.number -e ip.src -e ip.dst | head -4", "tshark -r capture.pcap -Y 'dns' -T fields -e dns.qry.name -e dns.a"],
  'L6.3': ['wc -l auth.log', "grep -c Failed auth.log", "grep 'Failed password' auth.log | awk '{print $11}' | sort | uniq -c | sort -rn | head -3", "grep -o '[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}\\.[0-9]\\{1,3\\}' auth.log | sort -u | head -3", "jq -c 'keys' security.json | head -2", "cut -d' ' -f1-2 auth.log | head -2"],
  'L5.3': ['sha256sum invoice_2026-03.docm', 'sha256sum files/invoice_2026-03.docm | cut -d" " -f1', 'wc -c invoice_2026-03.docm photo.jpg receipt.pdf.exe', 'cat safe-handling.md | head -3', 'base64 safe-handling.md | head -2', 'base64 safe-handling.md | base64 -d | head -2'],
  'L7.6': ['find queue -type f | sort', 'ls queue | cat', "jq -c '.[0]' queue/alerts.json", 'jq length queue/alerts.json', 'cat shift-brief.md | head -3', 'grep -rn -i verdict queue incident phish | wc -l', 'grep -rl alert queue incident | sort', 'find . -name "*.json" | sort | head -3'],
  'L1.1': ['ls telemetry | cat', "head -c 120 telemetry/e-auth.log", "wc -l telemetry/*", "grep -h 'Failed' telemetry/e-auth.log | wc -l", "jq -c 'keys' telemetry/f-entra-signin.json | head -2", 'for f in telemetry/a-zeek-conn.log; do wc -l $f; done'],
  'L0.2': ['grep -E "CM-0311-0107|CM-0311-0111" events.jsonl | wc -l', "jq '.rule' alert-sample.json", "jq -r '.evidence.event_ids[]' alert-sample.json", 'cat README-evidence.md | head -3'],
};
const shellExtras = [
  ['echo hello world', 'echo hello world'], ['echo -n a; echo b', 'echo -n a; echo b'], ['printf "%s-%d\\n" a 3', 'printf "%s-%d\\n" a 3'],
  ['var', 'x=5; echo $x ${x} "${x}y" $((x*2)) ${y:-dflt}'], ['sub', 'echo $(echo inner | tr a-z A-Z)'], ['and-or', 'false || echo yes; true && echo ok; false && echo no'],
  ['redir', 'echo a > t.txt; echo b >> t.txt; cat t.txt; wc -l < t.txt'], ['group', '{ echo 1; echo 2; } | wc -l'], ['glob', 'ls *.md 2>/dev/null | cat'], ['quotes', "echo 'a b'  \"c   d\" e\\ f"],
  ['stderr', 'ls nope 2>&1 | head -1 | cut -c1-20'], ['status', 'grep zzzz /dev/null; echo $?'], ['neg', '! false && echo neg'], ['tilde', 'cd ~ && pwd | tail -c 2 | wc -c'], ['seq', 'seq 1 3 | tr "\\n" " "'],
  ['ansi', "echo $'a\\tb' | cut -f2"], ['pipe-sort', 'printf "b\\na\\nc\\nb\\n" | sort | uniq -c'], ['sort-n', 'printf "10\\n9\\n100\\n" | sort -n'], ['sort-r', 'printf "b\\na\\nc\\n" | sort -r | head -2'],
  ['tr-sq', 'echo "aa  bb" | tr -s " "'], ['cut-c', 'echo abcdef | cut -c2-4'], ['wc-multi', 'printf "a b\\nc\\n" | wc'], ['head-neg', 'seq 1 5 | head -n -2'], ['tail-plus', 'seq 1 5 | tail -n +3'],
  ['uniq-d', 'printf "a\\na\\nb\\n" | uniq -d'], ['grep-ctx', 'seq 1 9 | grep -C1 5'], ['grep-only', 'echo "a1b22" | grep -o "[0-9]*"'], ['sed-g', 'echo aaa | sed "s/a/b/2g"'], ['xargs', 'echo a b c | xargs echo x'],
];

let cases = 0;
for (const [id, cmds] of Object.entries(corpus)) {
  const lab = data.labs.find((l) => l.id === id);
  if (!lab) { bad(`corpus lab ${id} missing from data`); continue; }
  const emu = makeEmu(lab);
  const dir = makeReal(lab);
  for (const c of cmds) {
    const realTool = /\b(jq|tshark|rg|python3|column)\b/.exec(c);
    if (realTool && tools.includes(realTool[1])) continue;
    const r = runReal(dir, c);
    const m = runEmu(emu, c);
    cases++;
    if (r.out !== m.out || r.status !== m.status) {
      bad(`${id}: ${c}\n   real(rc=${r.status}): ${JSON.stringify(r.out).slice(0, 260)}\n   mine(rc=${m.status}): ${JSON.stringify(m.out).slice(0, 260)}\n   mine err: ${m.err.slice(0, 200)}`);
    }
  }
  rmSync(dir, { recursive: true, force: true });
}
{
  const lab = data.labs.find((l) => l.id === 'L2.1');
  const emu = makeEmu(lab);
  const dir = makeReal(lab);
  for (const [name, c] of shellExtras) {
    const r = runReal(dir, c);
    const m = runEmu(emu, c);
    cases++;
    if (r.out !== m.out) bad(`shell ${name}: ${c}\n   real: ${JSON.stringify(r.out)}\n   mine: ${JSON.stringify(m.out)}\n   mine err: ${m.err.slice(0, 200)}`);
  }
  rmSync(dir, { recursive: true, force: true });
}

/* ---- 3. walkthroughs: lab commands in the page terminal satisfy tool-output checks ---- */
let walked = 0;
for (const lab of data.labs) {
  const toolFiles = lab.graded_files.filter((g) => g.tool_output).map((g) => g.name);
  if (!toolFiles.length) continue;
  const emu = makeEmu(lab);
  bashBlocks(lab.lab_md).forEach((b) => {
    if (/\bsudo\b|\blab\b|^cd |\bapt(-get)?\b/m.test(b)) return;
    const r = runEmu(emu, b);
    if (/not found|internal error|not available/.test(r.err)) bad(`${lab.id}: terminal could not run a lab step:\n   ${b}\n   ${r.err.slice(0, 200)}`);
  });
  const res = Grader.run(lab, emu.texts);
  lab.assertions.forEach((a, i) => {
    if (a.path && toolFiles.includes(a.path) && !res.results[i].ok) bad(`${lab.id}: after the lab's own commands, check fails: ${res.results[i].msg}`);
    if (a.fn === 'cmd_ok' && !res.results[i].ok) bad(`${lab.id}: ${res.results[i].msg}`);
  });
  walked++;
}

console.log(`site-term: ${compared} lab blocks + ${cases} corpus commands compared, ${walked} walkthroughs`);
if (failed) { console.error(`site-term: ${failed} failure(s)`); process.exit(1); }
console.log('site-term: simulated terminal matches the real tools');
