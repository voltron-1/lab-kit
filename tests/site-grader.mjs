// tests/site-grader.mjs <data.json> [--emit <lab-id> <dir>] — replays every lab's recorded assertions
// through the page's own grader (docs/site/src/app.js) against answers
// synthesised from the assertions themselves, then runs each quiz with its
// decoded answer key. Exits 1 and names every lab that does not pass.
// With --emit, writes that lab's synthesized answer files into <dir> instead
// (tests/site.sh feeds them to the real ./bin/lab check).
import { createRequire } from 'node:module';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const require = createRequire(import.meta.url);
const { Grader, Quiz } = require(join(here, '..', 'docs', 'site', 'src', 'app.js'));
const data = JSON.parse(readFileSync(process.argv[2], 'utf8'));

// A literal that satisfies a plain ERE (anchors, one alternation, [0-9] classes, x*).
// The model-*.md files are style examples, not answer keys, so REPORT labs are
// synthesised from their heading and literal assertions like every other lab.
function literalFor(p) {
  let s = p.replace(/^\^/, '').replace(/\$$/, '');
  s = s.replace(/\(([^()|]*)(\|[^()]*)?\)/g, '$1');
  s = s.replace(/\[0-9\]\{(\d+)\}/g, (m, n) => '1'.repeat(+n)).replace(/\[0-9\]/g, '1');
  s = s.replace(/[^\\]\*/g, '').replace(/\\([.\[\]()|*+?{}^$\\])/g, '$1');
  return s;
}

function synthesize(lab) {
  const norm = new Map(lab.norms.map((n) => [n.target, n.source]));
  const lines = new Map();
  for (const a of lab.assertions) {
    if (!a.path || !['contains_fixed', 'contains', 'contains_i'].includes(a.fn)) continue;
    const file = norm.get(a.path) || a.path;
    if (lab.files.some((f) => f.name === file)) continue;
    if (!lines.has(file)) lines.set(file, []);
    lines.get(file).push(a.fn === 'contains_fixed' ? a.arg : literalFor(a.arg));
  }
  const texts = {};
  for (const g of lab.graded_files) {
    texts[g.name] = (lines.get(g.name) || []).join('\n') + '\n';
  }
  return texts;
}

if (process.argv[3] === '--emit') {
  const lab = data.labs.find((l) => l.id === process.argv[4]);
  if (!lab) { console.error('no such lab: ' + process.argv[4]); process.exit(2); }
  const outDir = process.argv[5];
  mkdirSync(outDir, { recursive: true });
  const texts = synthesize(lab);
  for (const [name, text] of Object.entries(texts)) writeFileSync(join(outDir, name), text);
  process.exit(0);
}

const failures = [];
let checked = 0;
for (const lab of data.labs) {
  if (lab.ungradable) continue;
  const texts = synthesize(lab);
  let res = Grader.run(lab, texts);
  checked++;
  if (!res.pass) {
    failures.push(`${lab.id}: ` + res.results.filter((r) => !r.ok).map((r) => r.msg).join(' | '));
  }
  // an empty workspace must NOT pass any lab that has non-tool-only checks
  const blank = {};
  lab.graded_files.forEach((g) => { blank[g.name] = ''; });
  const empty = Grader.run(lab, blank);
  if (empty.pass && lab.assertions.some((a) => a.fn !== 'cmd_ok')) {
    failures.push(`${lab.id}: passes with an empty workspace`);
  }
  // quiz: decoded key passes, a blank reply fails
  const key = lab.quiz.map((q) => Buffer.from(q.answer_b64, 'base64').toString('utf8'));
  if (Quiz.grade(lab.quiz, key).correct !== lab.quiz.length) failures.push(`${lab.id}: quiz key does not pass`);
  if (Quiz.grade(lab.quiz, lab.quiz.map(() => '')).correct !== 0) failures.push(`${lab.id}: blank quiz reply passes`);
  for (const q of lab.quiz) {
    for (const alt of q.accept_b64 || []) {
      const t = Buffer.from(alt, 'base64').toString('utf8');
      if (!Quiz.gradeOne(q, t)) failures.push(`${lab.id}: accepted alternative "${t}" rejected`);
    }
  }
  for (const q of lab.recall || []) {
    const b64 = q.answer_b64 || (q.accept_b64 || [])[0];
    const t = Buffer.from(b64, 'base64').toString('utf8');
    if (!Quiz.gradeOne(q, t)) failures.push(`${lab.id}: recall key rejected`);
  }
}
if (failures.length) {
  console.error('site-grader: FAIL');
  failures.forEach((f) => console.error('  ' + f));
  process.exit(1);
}
console.log(`site-grader: ${checked} labs graded, all pass with synthesized answers`);
