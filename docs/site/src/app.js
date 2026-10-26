/* SOC Analyst Lab — generated single-page player. Vanilla JS, no dependencies.
 * Sections: md · grader · quiz · state · ui helpers · views · boot.
 * The grader replays the assertions harness/checklib-record.sh captured from
 * each lab's check.sh; the quiz mirrors lib/quiz.sh; the progress store
 * mirrors lib/state.sh (same .progress.json v1 document). */
(function () {
  'use strict';

  var TRACK_ID = 'soc';
  var PROGRESS_KEY = 'labkit.soc.progress.v1';
  var THEME_KEY = 'labkit.soc.theme';
  var DRAFT_KEY = 'labkit.soc.drafts.v1';

  /* ================= md: tiny markdown renderer ================= */
  var Md = (function () {
    function esc(s) {
      return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    function inline(s) {
      var codes = [];
      s = s.replace(/`([^`]+)`/g, function (m, c) {
        codes.push(c);
        return '\u0000' + (codes.length - 1) + '\u0000';
      });
      s = esc(s);
      s = s.replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g,
        '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>');
      s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
      s = s.replace(/(^|[^*\w])\*([^*\s][^*]*?)\*(?!\w)/g, '$1<em>$2</em>');
      s = s.replace(/\u0000(\d+)\u0000/g, function (m, i) {
        return '<code>' + esc(codes[+i]) + '</code>';
      });
      return s;
    }

    function indentOf(l) {
      return /^ */.exec(l)[0].length;
    }

    var foldFn = null;
    var LIST_RE = /^(\s*)([-*+]|\d+[.)])(\s+)(.*)$/;
    var FENCE_RE = /^(\s*)(```+|~~~+)\s*([\w-]*)\s*$/;
    var HEAD_RE = /^(#{1,6})\s+(.*?)\s*#*\s*$/;
    var HR_RE = /^\s*(-{3,}|\*{3,})\s*$/;

    function blocks(lines) {
      var out = [];
      var i = 0;
      while (i < lines.length) {
        var line = lines[i];
        var m;
        if (/^\s*$/.test(line)) { i++; continue; }

        if ((m = FENCE_RE.exec(line))) {
          var ind = m[1].length;
          var fch = m[2].charAt(0);
          var body = [];
          i++;
          while (i < lines.length) {
            var t = lines[i].trim();
            if (t.length >= 3 && t.split(fch).join('') === '') { break; }
            body.push(lines[i].slice(Math.min(ind, indentOf(lines[i]))));
            i++;
          }
          i++;
          out.push({ t: 'code', lang: m[3], text: body.join('\n') });
          continue;
        }

        if ((m = HEAD_RE.exec(line))) {
          out.push({ t: 'h', level: m[1].length, text: m[2] });
          i++;
          continue;
        }

        if (HR_RE.test(line)) { out.push({ t: 'hr' }); i++; continue; }

        if ((m = LIST_RE.exec(line))) {
          var base = m[1].length;
          var ordered = /\d/.test(m[2]);
          var start = ordered ? parseInt(m[2], 10) : 1;
          var items = [];
          while (i < lines.length) {
            var lm = LIST_RE.exec(lines[i]);
            if (!lm || lm[1].length !== base || /\d/.test(lm[2]) !== ordered) { break; }
            var width = base + lm[2].length + lm[3].length;
            var item = [lm[4]];
            i++;
            while (i < lines.length) {
              var l = lines[i];
              if (/^\s*$/.test(l)) {
                var j = i;
                while (j < lines.length && /^\s*$/.test(lines[j])) { j++; }
                if (j < lines.length && indentOf(lines[j]) > base) { item.push(''); i++; continue; }
                break;
              }
              if (indentOf(l) > base) {
                item.push(l.slice(Math.min(width, indentOf(l))));
                i++;
                continue;
              }
              break;
            }
            items.push(item);
            var k = i;
            while (k < lines.length && /^\s*$/.test(lines[k])) { k++; }
            if (k > i && k < lines.length) {
              var nm = LIST_RE.exec(lines[k]);
              if (nm && nm[1].length === base && /\d/.test(nm[2]) === ordered) { i = k; } else { break; }
            }
          }
          out.push({ t: 'list', ordered: ordered, start: start, items: items });
          continue;
        }

        var para = [line];
        i++;
        while (i < lines.length && !/^\s*$/.test(lines[i]) && !FENCE_RE.test(lines[i]) &&
               !HEAD_RE.test(lines[i]) && !LIST_RE.test(lines[i]) && !HR_RE.test(lines[i])) {
          para.push(lines[i]);
          i++;
        }
        out.push({ t: 'p', text: para.join(' ') });
      }
      return out;
    }

    function html(bs) {
      return bs.map(function (b) {
        switch (b.t) {
          case 'h': return '<h' + b.level + '>' + inline(b.text) + '</h' + b.level + '>';
          case 'hr': return '<hr>';
          case 'p': return '<p>' + inline(b.text) + '</p>';
          case 'code':
            return '<div class="code"><button type="button" class="copy" data-copy>copy</button>' +
              (/^(bash|sh|shell|console)$/.test(b.lang || '') ? '<button type="button" class="run" data-run>run</button>' : '') +
              '<pre><code>' + esc(b.text) + '</code></pre></div>';
          case 'list':
            return '<' + (b.ordered ? 'ol' + (b.start !== 1 ? ' start="' + b.start + '"' : '') : 'ul') + '>' +
              b.items.map(function (it) {
                var inner = blocks(it);
                var h = html(inner);
                if (inner.length === 1 && inner[0].t === 'p') { h = inline(inner[0].text); }
                var label = foldFn ? foldFn(it.join('\n')) : null;
                if (label) {
                  return '<li class="fold"><details><summary>' + esc(label) + '</summary>' + h + '</details></li>';
                }
                return '<li>' + h + '</li>';
              }).join('') +
              '</' + (b.ordered ? 'ol' : 'ul') + '>';
          default: return '';
        }
      }).join('\n');
    }

    // opts.fold(itemSource) -> label | null: list items to render collapsed.
    function render(src, opts) {
      foldFn = opts && opts.fold ? opts.fold : null;
      try { return html(blocks(String(src).replace(/\r\n?/g, '\n').split('\n'))); } finally { foldFn = null; }
    }

    // Split a lab.md into [{title, body}] on "## " headings.
    function sections(src) {
      var secs = [];
      var cur = null;
      String(src).replace(/\r\n?/g, '\n').split('\n').forEach(function (line) {
        var m = /^##\s+(.*?)\s*$/.exec(line);
        if (m) { cur = { title: m[1], lines: [] }; secs.push(cur); } else if (cur) { cur.lines.push(line); }
      });
      return secs.map(function (s) { return { title: s.title, body: s.lines.join('\n') }; });
    }

    // Top-level list items of a section body, each as markdown source (the numbered steps).
    function steps(src) {
      var out = [];
      blocks(String(src).replace(/\r\n?/g, '\n').split('\n')).forEach(function (b) {
        if (b.t === 'list') { b.items.forEach(function (it) { out.push(it.join('\n')); }); }
      });
      return out;
    }

    return { render: render, sections: sections, steps: steps, esc: esc };
  })();

  /* ================= grader: mirrors harness/checklib.sh ================= */
  var Grader = (function () {
    function lc(s) { return s.replace(/[A-Z]/g, function (c) { return c.toLowerCase(); }); }

    // The lab's `tr | sed | tr` normaliser, line by line.
    function normalize(text, n) {
      var lines = String(text).split('\n').map(function (l) {
        l = lc(l);
        if (n.comment) { l = l.replace(/#.*$/, ''); }
        l = l.replace(/\r/g, '');
        if (n.nows) { l = l.replace(/[ \t]/g, ''); }
        if (n.trim) { l = l.replace(/[ \t\v\f\r]+$/, ''); }
        return l;
      });
      if (n.sort_csv) {
        var key = n.sort_csv;
        var parts = [];
        String(text).split('\n').forEach(function (l) {
          if (l.indexOf(key + '=') === 0) {
            Array.prototype.push.apply(parts, lc(l.slice(key.length + 1)).replace(/\r/g, '').split(','));
          }
        });
        var sorted = parts.sort().join(',');
        var re = new RegExp('^' + key + '=');
        lines = lines.map(function (l) { return re.test(l) ? key + '=' + sorted : l; });
      }
      return lines.join('\n');
    }

    function buildVfs(lab, texts) {
      var vfs = {};
      lab.files.forEach(function (f) { vfs[f.name] = typeof f.text === 'string' ? f.text : ''; });
      lab.graded_files.forEach(function (g) {
        var t = texts[g.name];
        if (typeof t === 'string' && t.trim() !== '') { vfs[g.name] = t; }
      });
      lab.norms.forEach(function (n) {
        var src = vfs[n.source];
        vfs[n.target] = typeof src === 'string' ? normalize(src, n) : '';
      });
      return vfs;
    }

    function lineMatch(text, re) {
      return text.split('\n').some(function (l) { return re.test(l); });
    }

    function evalOne(a, vfs) {
      var has = Object.prototype.hasOwnProperty.call(vfs, a.path);
      var text = has ? vfs[a.path] : null;
      var hint = a.hint || '';
      var re;
      switch (a.fn) {
        case 'exists':
          return has ? ok(a.path + ' exists') : bad(a.path + ' missing', hint);
        case 'contains':
        case 'contains_i':
          if (!has) { return bad(a.path + ' missing', hint); }
          try { re = new RegExp(a.arg, a.fn === 'contains_i' ? 'i' : ''); } catch (e) {
            return bad(a.path + ' does not match: ' + a.arg, hint);
          }
          return lineMatch(text, re)
            ? ok(a.path + ' matches: ' + a.arg)
            : bad(a.path + ' does not match: ' + a.arg, hint);
        case 'contains_fixed':
          if (!has) { return bad(a.path + ' missing', hint); }
          return text.indexOf(a.arg) !== -1
            ? ok(a.path + ' contains: ' + a.arg)
            : bad(a.path + ' does not contain: ' + a.arg, hint);
        case 'not_contains':
          if (!has) { return ok(a.path + ' absent (vacuously does not contain: ' + a.arg + ')'); }
          try { re = new RegExp(a.arg); } catch (e) { return ok(a.path + ' does not match: ' + a.arg); }
          return lineMatch(text, re)
            ? bad(a.path + ' unexpectedly matches: ' + a.arg, hint)
            : ok(a.path + ' does not match: ' + a.arg);
        case 'cmd_ok':
          return { ok: true, msg: a.desc, terminal: true, hint: a.hint || '' };
        default:
          return bad('unsupported check: ' + a.fn, '');
      }
    }
    function ok(msg) { return { ok: true, msg: msg, hint: '' }; }
    function bad(msg, hint) { return { ok: false, msg: msg, hint: hint }; }

    function run(lab, texts) {
      var vfs = buildVfs(lab, texts);
      var results = lab.assertions.map(function (a) { return evalOne(a, vfs); });
      var passed = results.filter(function (r) { return r.ok; }).length;
      return { pass: passed === results.length, results: results, passed: passed, total: results.length };
    }

    return { normalize: normalize, run: run };
  })();

  /* ================= quiz: mirrors lib/quiz.sh ================= */
  var Quiz = (function () {
    function normalize(s) {
      return String(s).toLowerCase().replace(/\s+/g, ' ').replace(/^ /, '').replace(/ $/, '');
    }
    function decode(b64) {
      var bin = atob(b64);
      var bytes = new Uint8Array(bin.length);
      for (var i = 0; i < bin.length; i++) { bytes[i] = bin.charCodeAt(i); }
      return new TextDecoder().decode(bytes);
    }
    function gradeOne(q, reply) {
      reply = reply == null ? '' : String(reply);
      // A few recall questions carry only accept_b64; lib/quiz.sh then decodes
      // the literal "null" into bytes no learner reply can equal.
      var expect = q.answer_b64 ? decode(q.answer_b64) : null;
      var norm;
      if (q.type === 'choice') {
        return expect !== null && normalize(reply).charAt(0) === expect;
      }
      var cs = q.case_sensitive === true;
      norm = cs ? reply : normalize(reply);
      if (expect !== null && !cs) { expect = normalize(expect); }
      if (expect !== null && norm === expect) { return true; }
      return (q.accept_b64 || []).some(function (b) {
        var alt = decode(b);
        if (!cs) { alt = normalize(alt); }
        return norm === alt;
      });
    }
    function grade(questions, replies) {
      var missed = [];
      var correct = 0;
      questions.forEach(function (q, i) {
        if (gradeOne(q, replies[i])) { correct++; } else { missed.push(i + 1); }
      });
      return { correct: correct, total: questions.length, missed: missed };
    }
    return { normalize: normalize, gradeOne: gradeOne, grade: grade };
  })();

  /* ================= state: mirrors lib/state.sh ================= */
  function nowUtc() { return new Date().toISOString().replace(/\.\d{3}Z$/, 'Z'); }
  function recDefault() {
    return { status: null, skipped: false, attempts: 0, hints_used: 0,
             started_at: null, first_passed_at: null, last_attempt_at: null };
  }
  function stateDefault() {
    var n = nowUtc();
    return { version: 1, created_at: n, updated_at: n, labs: {}, events: [] };
  }
  function stateValid(d) {
    return !!d && d.version === 1 && !!d.labs && typeof d.labs === 'object' &&
      !Array.isArray(d.labs) && Array.isArray(d.events);
  }

  function makeState(storage) {
    var doc = null;
    function load() {
      try {
        var raw = storage.getItem(PROGRESS_KEY);
        if (raw) {
          var d = JSON.parse(raw);
          if (stateValid(d)) { return d; }
        }
      } catch (e) { /* fall through to a fresh document */ }
      return stateDefault();
    }
    function save() {
      doc.updated_at = nowUtc();
      try { storage.setItem(PROGRESS_KEY, JSON.stringify(doc)); } catch (e) { /* in-memory only */ }
    }
    function key(id) { return TRACK_ID + '/' + id; }
    function ensure() { if (!doc) { doc = load(); } return doc; }
    function rec(id) {
      var r = ensure().labs[key(id)];
      return Object.assign(recDefault(), r || {});
    }
    function upsert(id, fn) {
      ensure();
      var r = Object.assign(recDefault(), doc.labs[key(id)] || {});
      fn(r);
      doc.labs[key(id)] = r;
      save();
    }
    return {
      doc: function () { return ensure(); },
      rec: rec,
      replace: function (d) { doc = d; save(); },
      reset: function () { doc = stateDefault(); save(); },
      start: function (id) {
        upsert(id, function (r) {
          r.status = r.status === 'passed' ? 'passed' : 'in_progress';
          r.started_at = r.started_at || nowUtc();
        });
      },
      attempt: function (id) {
        upsert(id, function (r) { r.attempts += 1; r.last_attempt_at = nowUtc(); });
      },
      pass: function (id, recap) {
        var at = nowUtc();
        upsert(id, function (r) {
          r.status = 'passed';
          r.first_passed_at = r.first_passed_at || at;
        });
        var last = doc.events.length ? doc.events[doc.events.length - 1] : null;
        doc.events.push({ seq: (last && last.seq ? last.seq : 0) + 1, type: 'pass',
                          track: TRACK_ID, id: id, at: at, recap: recap });
        save();
      },
      hint: function (id, total) {
        upsert(id, function (r) { r.hints_used = Math.min((r.hints_used || 0) + 1, total); });
      },
      skip: function (id) {
        upsert(id, function (r) { r.skipped = true; });
      }
    };
  }

  /* Pure helpers over a lab list + store. */
  function frontierIndex(labs, state) {
    for (var i = 0; i < labs.length; i++) {
      var r = state.rec(labs[i].id);
      if (r.status !== 'passed' && r.skipped !== true) { return i; }
    }
    return -1;
  }
  function accessible(labs, state, idx) {
    var f = frontierIndex(labs, state);
    if (f === -1 || idx <= f) { return true; }
    var r = state.rec(labs[idx].id);
    return r.status === 'passed' || r.skipped === true;
  }

  /* Node (tests): export the pure pieces and stop; nothing below touches the DOM at load. */
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = { Md: Md, Grader: Grader, Quiz: Quiz, makeState: makeState,
                       frontierIndex: frontierIndex, accessible: accessible, stateValid: stateValid };
    return;
  }

  /* ================= ui helpers ================= */
  function h(tag, attrs) {
    var el = document.createElement(tag);
    if (attrs) {
      Object.keys(attrs).forEach(function (k) {
        var v = attrs[k];
        if (v === null || v === undefined || v === false) { return; }
        if (k.slice(0, 2) === 'on' && typeof v === 'function') { el.addEventListener(k.slice(2), v); }
        else if (k === 'class') { el.className = v; }
        else if (k === 'text') { el.textContent = v; }
        else if (k === 'html') { el.innerHTML = v; }
        else if (v === true) { el.setAttribute(k, ''); }
        else { el.setAttribute(k, v); }
      });
    }
    for (var i = 2; i < arguments.length; i++) { appendKid(el, arguments[i]); }
    return el;
  }
  function appendKid(el, kid) {
    if (kid === null || kid === undefined || kid === false) { return; }
    if (Array.isArray(kid)) { kid.forEach(function (k) { appendKid(el, k); }); return; }
    el.appendChild(typeof kid === 'string' || typeof kid === 'number' ? document.createTextNode(String(kid)) : kid);
  }

  var toastTimer = null;
  function toast(msg) {
    var t = document.getElementById('toast');
    t.textContent = msg;
    t.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { t.hidden = true; }, 3500);
  }

  function lsGet(k) { try { return window.localStorage.getItem(k); } catch (e) { return null; } }
  function lsSet(k, v) { try { window.localStorage.setItem(k, v); } catch (e) { /* ignore */ } }

  function copyText(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(text).catch(function () { legacyCopy(text); });
    }
    legacyCopy(text);
    return Promise.resolve();
  }
  function legacyCopy(text) {
    var ta = h('textarea', { 'aria-hidden': 'true' });
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand('copy'); } catch (e) { /* ignore */ }
    document.body.removeChild(ta);
  }

  function hexDump(b64, cap) {
    var bin = atob(b64);
    var n = Math.min(bin.length, cap);
    var lines = [];
    for (var off = 0; off < n; off += 16) {
      var hex = [];
      var asc = '';
      for (var j = 0; j < 16; j++) {
        if (off + j < n) {
          var c = bin.charCodeAt(off + j);
          hex.push((c < 16 ? '0' : '') + c.toString(16));
          asc += c >= 32 && c < 127 ? String.fromCharCode(c) : '.';
        } else { hex.push('  '); }
      }
      lines.push(('00000000' + off.toString(16)).slice(-8) + '  ' + hex.slice(0, 8).join(' ') + '  ' +
                 hex.slice(8).join(' ') + '  |' + asc + '|');
    }
    if (bin.length > n) { lines.push('… ' + (bin.length - n) + ' more bytes not shown'); }
    return lines.join('\n');
  }

  function parseCsv(text) {
    var rows = [];
    var row = [];
    var cell = '';
    var inq = false;
    for (var i = 0; i < text.length; i++) {
      var c = text.charAt(i);
      if (inq) {
        if (c === '"') {
          if (text.charAt(i + 1) === '"') { cell += '"'; i++; } else { inq = false; }
        } else { cell += c; }
      } else if (c === '"') { inq = true; }
      else if (c === ',') { row.push(cell); cell = ''; }
      else if (c === '\n') { row.push(cell); rows.push(row); row = []; cell = ''; }
      else if (c !== '\r') { cell += c; }
    }
    if (cell !== '' || row.length) { row.push(cell); rows.push(row); }
    return rows;
  }

  /* ================= app ================= */
  var DATA = JSON.parse(document.getElementById('lab-data').textContent);
  var LABS = DATA.labs;
  var BY_ID = {};
  LABS.forEach(function (l, i) { BY_ID[l.id] = i; });
  var storage = (function () { try { return window.localStorage; } catch (e) { return null; } })() ||
    { getItem: function () { return null; }, setItem: function () {} };
  var State = makeState(storage);

  var view = null;
  var current = null; // handlers for the open lab view: {check, hint, next, filter}

  function glyph(idx) {
    var r = State.rec(LABS[idx].id);
    if (r.skipped) { return { ch: '⏭', cls: 'mark-skipped', label: 'skipped' }; }
    if (r.status === 'passed') { return { ch: '✓', cls: 'mark-passed', label: 'passed' }; }
    if (idx === frontierIndex(LABS, State)) { return { ch: '▶', cls: 'mark-frontier', label: 'next up' }; }
    return { ch: '○', cls: 'mark-todo', label: 'locked' };
  }

  function badges(lab) {
    return [
      h('span', { class: 'badge type' }, lab.meta.type),
      lab.meta.gate ? h('span', { class: 'badge gate' }, 'gate') : null,
      h('span', { class: 'badge' }, lab.meta.est_minutes + ' min')
    ];
  }

  /* ---------- home ---------- */
  function homeView() {
    current = null;
    var fi = frontierIndex(LABS, State);
    var passed = LABS.filter(function (l) { return State.rec(l.id).status === 'passed'; }).length;
    var minutes = LABS.reduce(function (a, l) { return a + l.meta.est_minutes; }, 0);
    var root = h('div', null);

    var resume = fi === -1
      ? h('p', { class: 'banner passed' }, '✓ Track complete. Every lab is passed or skipped.')
      : h('a', { class: 'btn primary', id: 'btn-resume', href: '#/lab/' + LABS[fi].id },
          (passed || State.rec(LABS[fi].id).status ? 'Resume ' : 'Start ') + LABS[fi].id + ' — ' + LABS[fi].meta.title);
    root.appendChild(h('div', { class: 'summary' },
      h('div', { class: 'totals' }, passed + ' / ' + LABS.length + ' labs passed · about ' +
        (minutes / 60).toFixed(1) + ' hours of content'),
      h('div', { class: 'bar', 'aria-hidden': 'true' }, h('span', { style: 'width:' + Math.round(100 * passed / LABS.length) + '%' }))));
    root.appendChild(h('div', { class: 'summary' }, resume));

    var filter = h('input', { type: 'search', id: 'home-filter', placeholder: 'Filter labs (press /)', 'aria-label': 'Filter labs' });
    root.appendChild(h('div', { class: 'filter-row' }, filter));

    var phases = Object.keys(DATA.track.phases);
    var sections = [];
    phases.forEach(function (p) {
      var idxs = [];
      LABS.forEach(function (l, i) { if (l.phase === p) { idxs.push(i); } });
      if (!idxs.length) { return; }
      var pPassed = idxs.filter(function (i) { return State.rec(LABS[i].id).status === 'passed'; }).length;
      var pMin = idxs.reduce(function (a, i) { return a + LABS[i].meta.est_minutes; }, 0);
      var rows = h('div', { class: 'rows' });
      idxs.forEach(function (i) {
        var lab = LABS[i];
        var g = glyph(i);
        var open = accessible(LABS, State, i);
        var row = h(open ? 'a' : 'div', {
          class: 'lab-row' + (open ? '' : ' locked'),
          href: open ? '#/lab/' + lab.id : null,
          'data-id': lab.id,
          'data-search': (lab.id + ' ' + lab.meta.title + ' ' + lab.meta.type).toLowerCase()
        },
          h('span', { class: 'mark ' + g.cls, 'aria-label': g.label, title: g.label }, g.ch),
          h('span', { class: 'id' }, lab.id),
          h('span', { class: 'title' }, lab.meta.title),
          h('span', { class: 'badges' }, badges(lab)));
        rows.appendChild(row);
      });
      var sec = h('section', { class: 'phase', 'data-phase': p },
        h('div', { class: 'phase-head' },
          h('h2', null, p.toUpperCase().replace('P', 'Phase ') + ' — ' + DATA.track.phases[p]),
          h('span', { class: 'muted' }, pPassed + ' / ' + idxs.length + ' passed · ' + pMin + ' min')),
        rows);
      sections.push(sec);
      root.appendChild(sec);
    });

    filter.addEventListener('input', function () {
      var q = filter.value.trim().toLowerCase();
      sections.forEach(function (sec) {
        var any = false;
        Array.prototype.forEach.call(sec.querySelectorAll('.lab-row'), function (row) {
          var show = !q || row.getAttribute('data-search').indexOf(q) !== -1;
          row.hidden = !show;
          if (show) { any = true; }
        });
        sec.hidden = !any;
      });
    });
    view.appendChild(root);
    current = { filter: function () { filter.focus(); } };
  }

  /* ---------- evidence ---------- */
  function evidencePanel(lab, ui) {
    var panel = h('section', { class: 'panel evidence', id: 'evidence' }, h('h2', null, 'Evidence'));
    if (!lab.files.length) {
      panel.appendChild(h('p', { class: 'muted' }, 'This lab ships no evidence files.'));
      return panel;
    }
    var tabs = h('div', { class: 'tabs', role: 'tablist' });
    var body = h('div', { class: 'tabbody' });
    var buttons = lab.files.map(function (f, i) {
      return h('button', { type: 'button', role: 'tab', class: 'tab', onclick: function () { select(i); } }, f.name);
    });
    buttons.forEach(function (b) { tabs.appendChild(b); });
    panel.appendChild(tabs);
    panel.appendChild(body);

    function select(i) {
      buttons.forEach(function (b, j) { b.setAttribute('aria-selected', j === i ? 'true' : 'false'); });
      body.textContent = '';
      body.appendChild(filePanel(lab.files[i], ui));
    }
    select(0);
    return panel;
  }

  function filePanel(f, ui) {
    var wrap = h('div', { class: 'file' });
    var meta = h('dl', { class: 'meta' },
      h('dt', null, 'size'), h('dd', null, f.size + ' bytes'));
    if (f.kind !== 'text') {
      meta.appendChild(h('dt', null, 'magic'));
      meta.appendChild(h('dd', null, f.magic));
      meta.appendChild(h('dt', null, 'sha256'));
      meta.appendChild(h('dd', null, f.sha256));
      wrap.appendChild(meta);
      if (f.kind === 'pcap') {
        wrap.appendChild(h('p', { class: 'muted' }, 'Decoded text view of the capture:'));
        wrap.appendChild(textViewer(f.rendered || '', f.name + '.txt', ui, {}));
      } else {
        wrap.appendChild(h('p', { class: 'muted' }, 'Binary file. Hex dump:'));
        wrap.appendChild(h('div', { class: 'viewer' }, h('pre', { class: 'hex' }, hexDump(f.b64, 4096))));
      }
      return wrap;
    }
    wrap.appendChild(meta);
    wrap.appendChild(textViewer(f.text, f.name, ui, { pretty: /\.jsonl?$/i.test(f.name), table: /\.csv$/i.test(f.name) }));
    return wrap;
  }

  function textViewer(text, name, ui, opts) {
    var st = { pretty: false, table: false, q: '' };
    var input = h('input', { type: 'text', placeholder: 'filter lines (press /)', 'aria-label': 'Filter lines' });
    var toolbar = h('div', { class: 'toolbar' }, input);
    var viewer = h('div', { class: 'viewer' });
    var count = h('span', { class: 'muted' });
    if (opts.pretty) {
      var cb = h('input', { type: 'checkbox' });
      cb.addEventListener('change', function () { st.pretty = cb.checked; draw(); });
      toolbar.appendChild(h('label', null, cb, ' pretty'));
    }
    if (opts.table) {
      var tb = h('input', { type: 'checkbox' });
      tb.addEventListener('change', function () { st.table = tb.checked; draw(); });
      toolbar.appendChild(h('label', null, tb, ' table'));
    }
    toolbar.appendChild(count);
    input.addEventListener('input', function () { st.q = input.value.toLowerCase(); draw(); });
    ui.filter = function () { input.focus(); };

    function shown() {
      var t = text;
      if (st.pretty) {
        if (/\.jsonl$/i.test(name)) {
          t = t.split('\n').filter(function (l) { return l.trim() !== ''; }).map(function (l) {
            try { return JSON.stringify(JSON.parse(l), null, 2); } catch (e) { return l; }
          }).join('\n\n');
        } else {
          try { t = JSON.stringify(JSON.parse(t), null, 2); } catch (e) { /* keep raw */ }
        }
      }
      return t;
    }

    function draw() {
      viewer.textContent = '';
      if (st.table) {
        var rows = parseCsv(text);
        var head = rows.shift() || [];
        var tbl = h('table', null, h('thead', null, h('tr', null, head.map(function (c) { return h('th', null, c); }))));
        var tbody = h('tbody');
        var shownRows = 0;
        rows.forEach(function (r) {
          if (st.q && r.join(' ').toLowerCase().indexOf(st.q) === -1) { return; }
          shownRows++;
          tbody.appendChild(h('tr', null, r.map(function (c) { return h('td', null, c); })));
        });
        tbl.appendChild(tbody);
        viewer.appendChild(tbl);
        count.textContent = shownRows + ' / ' + rows.length + ' rows';
        return;
      }
      var lines = shown().split('\n');
      var frag = document.createDocumentFragment();
      var shownN = 0;
      var CAP = 3000;
      lines.forEach(function (l, i) {
        if (st.q && l.toLowerCase().indexOf(st.q) === -1) { return; }
        shownN++;
        if (shownN > CAP) { return; }
        frag.appendChild(h('div', { class: 'ln' }, h('span', { class: 'n' }, String(i + 1)), h('span', { class: 't' }, l)));
      });
      var pre = h('pre', null);
      pre.appendChild(frag);
      viewer.appendChild(pre);
      count.textContent = shownN + ' / ' + lines.length + ' lines' + (shownN > CAP ? ' (first ' + CAP + ' shown)' : '');
    }
    draw();
    return h('div', null, toolbar, viewer);
  }

  /* ---------- recall (non-gating warm-up) ---------- */
  function recallPanel(lab) {
    var qs = lab.recall;
    var det = h('details', { class: 'panel', id: 'recall' },
      h('summary', null, 'Warm-up recall (' + qs.length + ' questions, never gates the lab)'));
    var form = h('form', { 'aria-label': 'Recall warm-up' });
    var inputs = qs.map(function (q, i) { return questionField(q, i, 'R'); });
    inputs.forEach(function (x) { form.appendChild(x.el); });
    var out = h('div', null);
    form.appendChild(h('div', { class: 'actions' }, h('button', { type: 'submit' }, 'Submit warm-up')));
    form.addEventListener('submit', function (ev) {
      ev.preventDefault();
      var res = Quiz.grade(qs, inputs.map(function (x) { return x.value(); }));
      var need = Math.floor((qs.length * 4 + 4) / 5);
      out.textContent = '';
      var pass = qs.length > 0 && res.correct >= need;
      out.appendChild(h('p', { class: 'verdict ' + (pass ? 'ok' : 'bad') },
        'recall: ' + res.correct + '/' + res.total + (pass ? ' — pass' : ' (missed ' + res.missed.map(function (n) { return 'R' + n; }).join(',') + ')')));
      res.missed.forEach(function (n) {
        var src = qs[n - 1].source;
        if (!src) { return; }
        var idx = BY_ID[src];
        var link = idx !== undefined && accessible(LABS, State, idx)
          ? h('a', { href: '#/lab/' + src }, src) : h('span', null, src);
        out.appendChild(h('p', null, 'review: ', link));
      });
    });
    det.appendChild(form);
    det.appendChild(out);
    return det;
  }

  var uid = 0;
  function questionField(q, i, prefix) {
    var label = prefix + (i + 1);
    var fs = h('fieldset', { class: 'q' }, h('legend', null, label + '. ' + q.prompt));
    var getter;
    if (q.type === 'choice') {
      var group = prefix + i + '_' + (uid++);
      Object.keys(q.options).sort().forEach(function (k) {
        fs.appendChild(h('label', null,
          h('input', { type: 'radio', name: group, value: k }),
          ' ' + k + ') ' + q.options[k]));
      });
      getter = function () {
        var c = fs.querySelector('input[type=radio]:checked');
        return c ? c.value : '';
      };
    } else {
      var inp = h('input', { type: 'text', autocomplete: 'off', 'aria-label': label + ' answer' });
      fs.appendChild(inp);
      getter = function () { return inp.value; };
    }
    return { el: fs, value: getter };
  }

  /* ---------- terminal ---------- */
  function termPanel(lab, texts, areas, hooks) {
    var vfs = window.LabTerm.vfsFromLab(lab, {
      get: function (n) { return texts[n] || ''; },
      set: function (n, t) {
        texts[n] = t;
        if (areas[n]) { areas[n].value = t; areas[n].rows = Math.max(4, Math.min(18, t.split('\n').length + 1)); }
        writeDraft(lab.id, n, t);
      }
    });
    var sh = window.LabTerm.createShell({ vfs: vfs, hooks: hooks });
    var log = h('pre', { class: 'term-log', tabindex: '0', 'aria-label': 'Terminal output' });
    var promptEl = h('span', { class: 'term-prompt' });
    var input = h('textarea', { class: 'term-in', rows: '1', spellcheck: 'false', autocomplete: 'off', autocapitalize: 'off', autocorrect: 'off', 'aria-label': 'Terminal input' });
    var hist = [];
    var hpos = 0;
    var draft = '';
    var lastTab = '';

    function promptText() { return 'analyst@soc:' + (sh.cwd ? '~/' + sh.cwd : '~') + '$ '; }
    function syncPrompt() { promptEl.textContent = promptText(); }
    function grow() { input.rows = Math.min(8, input.value.split('\n').length); }
    function append(text, cls) {
      if (!text) { return; }
      var span = h('span', { class: cls || null }, text);
      log.appendChild(span);
      if (log.textContent.length > 300000) {
        while (log.firstChild && log.textContent.length > 200000) { log.removeChild(log.firstChild); }
      }
      log.scrollTop = log.scrollHeight;
    }
    function exec(cmd) {
      append(promptText(), 'term-prompt');
      append(cmd + '\n', 'term-cmd');
      var r = sh.run(cmd);
      if (r.clear) { log.textContent = ''; }
      var text = '';
      r.chunks.forEach(function (c) { append(c.t, c.e ? 'term-err' : null); text += c.t; });
      syncPrompt();
      return { text: text, status: r.status };
    }
    function submit() {
      var val = input.value;
      input.value = '';
      grow();
      if (val.trim() !== '') { hist.push(val); }
      hpos = hist.length;
      draft = '';
      exec(val);
    }
    input.addEventListener('keydown', function (ev) {
      if (ev.key === 'Enter' && !ev.shiftKey) {
        ev.preventDefault();
        if (window.LabTerm.incomplete(input.value)) { input.value += '\n'; grow(); return; }
        submit();
        return;
      }
      if (ev.key === 'Enter' && ev.shiftKey) { setTimeout(grow, 0); return; }
      if (ev.key === 'ArrowUp' && input.value.indexOf('\n') === -1) {
        if (hpos > 0) { if (hpos === hist.length) { draft = input.value; } hpos--; input.value = hist[hpos]; ev.preventDefault(); }
        return;
      }
      if (ev.key === 'ArrowDown' && input.value.indexOf('\n') === -1) {
        if (hpos < hist.length) { hpos++; input.value = hpos === hist.length ? draft : hist[hpos]; ev.preventDefault(); }
        return;
      }
      if (ev.key === 'Tab' && !ev.shiftKey) {
        ev.preventDefault();
        var pre = input.value.slice(0, input.selectionStart);
        var rest = input.value.slice(input.selectionStart);
        var c = sh.complete(pre);
        if (!c.matches.length) { return; }
        var common = c.matches[0];
        c.matches.forEach(function (m) { while (m.indexOf(common) !== 0) { common = common.slice(0, -1); } });
        if (common.length > c.word.length) {
          input.value = c.before + common + (c.matches.length === 1 && common.slice(-1) !== '/' ? ' ' : '') + rest;
        } else if (lastTab === pre) {
          append(promptText(), 'term-prompt'); append(pre + '\n', 'term-cmd'); append(c.matches.join('  ') + '\n');
        }
        lastTab = pre;
        return;
      }
      lastTab = '';
      if (ev.ctrlKey && (ev.key === 'l' || ev.key === 'L')) { ev.preventDefault(); log.textContent = ''; return; }
      if (ev.ctrlKey && (ev.key === 'c' || ev.key === 'C') && input.selectionStart === input.selectionEnd) {
        ev.preventDefault();
        append(promptText() + input.value + '^C\n', 'term-cmd');
        input.value = '';
        grow();
      }
    });
    input.addEventListener('input', grow);
    log.addEventListener('click', function () { if (!window.getSelection || String(window.getSelection()) === '') { input.focus(); } });

    var el = h('section', { class: 'panel term', id: 'terminal' },
      h('h2', null, 'Terminal'),
      h('p', { class: 'muted term-note' }, 'Runs on this lab’s files (nothing leaves your browser). Commands that write a graded file fill its Workspace box. Type help for what it supports.'),
      log,
      h('div', { class: 'term-line' }, promptEl, input));
    syncPrompt();
    append('Simulated shell in ~/lab-kit/workspace/soc/' + lab.id + ' — type help. Try: ls\n', 'term-banner');
    return {
      el: el,
      exec: exec,
      focus: function () { input.focus(); }
    };
  }

  /* ---------- lab view ---------- */
  function readDrafts() {
    try { return JSON.parse(lsGet(DRAFT_KEY) || '{}') || {}; } catch (e) { return {}; }
  }
  function writeDraft(id, name, text) {
    var d = readDrafts();
    d[id] = d[id] || {};
    d[id][name] = text;
    lsSet(DRAFT_KEY, JSON.stringify(d));
  }

  function labView(id) {
    var idx = BY_ID[id];
    if (idx === undefined) {
      view.appendChild(h('p', null, 'No such lab: ' + id + '. ', h('a', { href: '#/' }, 'Back to the track')));
      current = null;
      return;
    }
    var lab = LABS[idx];
    if (!accessible(LABS, State, idx)) {
      var fi = frontierIndex(LABS, State);
      view.appendChild(h('div', { class: 'banner' },
        h('p', null, '○ ' + lab.id + ' is locked. Labs unlock in order: pass or skip the lab before it first.'),
        fi === -1 ? null : h('a', { class: 'btn primary', href: '#/lab/' + LABS[fi].id }, 'Go to ' + LABS[fi].id)));
      current = null;
      return;
    }
    State.start(lab.id);

    var ui = { filter: null };
    var drafts = readDrafts()[lab.id] || {};
    var texts = {};
    lab.graded_files.forEach(function (g) { texts[g.name] = typeof drafts[g.name] === 'string' ? drafts[g.name] : g.prefill; });

    var root = h('div', null);
    root.appendChild(h('p', { class: 'crumbs' }, h('a', { href: '#/' }, '← Track'), ' · ',
      DATA.track.phases[lab.phase] || lab.phase));
    root.appendChild(h('header', { class: 'lab-head' },
      h('h1', null, lab.id + ' — ' + lab.meta.title),
      h('p', { class: 'objective' }, lab.meta.objective),
      h('div', { class: 'badges' }, badges(lab))));

    if (lab.recall) { root.appendChild(recallPanel(lab)); }

    var secs = Md.sections(lab.lab_md);
    var guidedSteps = [];
    secs.forEach(function (s) { if (/guided steps/i.test(s.title)) { guidedSteps = Md.steps(s.body); } });
    // Steps that only matter on a real machine are folded so the first real task is visible.
    function foldStep(src) {
      if (/\b(sudo|apt(-get)?)\b[^\n]*\binstall\b/.test(src)) { return 'Install the tools: not needed here, they are built into this page'; }
      var code = /```\w*\n([\s\S]*?)```/.exec(src);
      if (code && /^\s*cd\s+(\.\/)?workspace\/soc\/[\w.-]+\s*$/.test(code[1]) && src.replace(code[0], '').length < 400) {
        return 'Move into your workspace: you are already there';
      }
      return null;
    }
    var firstReal = 0;
    while (firstReal < guidedSteps.length && foldStep(guidedSteps[firstReal])) { firstReal++; }
    var fileNames = lab.graded_files.map(function (g) { return g.name; });
    var qCount = 0;
    lab.graded_files.forEach(function (g) {
      if (g.template) { (g.prefill.match(/^[A-Za-z0-9_]+=/gm) || []).forEach(function () { qCount++; }); }
    });
    var taskText;
    if (!fileNames.length) { taskText = 'Read the evidence, then press Check.'; }
    else if (qCount) { taskText = 'Fill ' + fileNames.join(', ') + ' (' + qCount + ' answer lines) from the evidence, then press Check.'; }
    else { taskText = 'Produce ' + fileNames.length + ' file' + (fileNames.length === 1 ? '' : 's') + ': ' + fileNames.join(', ') + '. Each Workspace box shows the step that makes it.'; }
    if (firstReal > 0 && guidedSteps.length) { taskText += ' Start at step ' + (firstReal + 1) + '.'; }
    root.appendChild(h('div', { class: 'task', id: 'task' }, h('strong', null, 'Your task: '), taskText));

    secs.forEach(function (s) {
      var isOnion = /security onion/i.test(s.title);
      var inner = '<h2>' + Md.esc(s.title) + '</h2>' + Md.render(s.body, /guided steps/i.test(s.title) ? { fold: foldStep } : null);
      if (isOnion) {
        root.appendChild(h('details', { class: 'panel md', html: '<summary>' + Md.esc(s.title) + '</summary>' + Md.render(s.body) }));
      } else {
        root.appendChild(h('section', { class: 'panel md', html: inner }));
      }
    });

    // workspace: one box per graded file, each with the guided step(s) that produce it
    var ws = h('section', { class: 'panel', id: 'workspace' }, h('h2', null, 'Workspace'));
    var areas = {};
    function directionsFor(g) {
      var re = new RegExp('(^|[^\\w.-])' + g.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '($|[^\\w-])');
      var hits = [];
      guidedSteps.forEach(function (src, i) { if (re.test(src)) { hits.push({ n: i + 1, src: src }); } });
      return hits;
    }
    lab.graded_files.forEach(function (g) {
      var ta = h('textarea', { id: 'ws-' + g.name.replace(/[^\w]/g, '_'), 'data-name': g.name, spellcheck: 'false', autocomplete: 'off', autocapitalize: 'off' });
      ta.value = texts[g.name];
      ta.rows = Math.max(4, Math.min(18, ta.value.split('\n').length + 1));
      ta.addEventListener('input', function () { texts[g.name] = ta.value; writeDraft(lab.id, g.name, ta.value); });
      areas[g.name] = ta;
      var box = h('div', { class: 'ws-file', 'data-file': g.name }, h('label', { for: ta.id }, g.name));
      var dirs = directionsFor(g);
      dirs.forEach(function (d) {
        box.appendChild(h('div', { class: 'directions' },
          h('div', { class: 'dir-title' }, 'Step ' + d.n + ' of ' + guidedSteps.length + ' makes this file'),
          h('div', { class: 'md', html: Md.render(d.src) })));
      });
      if (!dirs.length && g.template) {
        box.appendChild(h('div', { class: 'directions' },
          h('div', { class: 'dir-title' }, 'What to write here'),
          h('p', null, 'One answer per line. The text after # on each line says exactly what that line wants; answer it from the evidence, then delete or keep the comment.')));
      }
      box.appendChild(ta);
      if (g.tool_output) {
        box.appendChild(h('button', { type: 'button', class: 'fill', onclick: function () {
          ta.value = g.expected; texts[g.name] = g.expected; writeDraft(lab.id, g.name, g.expected);
        } }, 'Fill from expected output'));
      }
      ws.appendChild(box);
    });
    if (!lab.graded_files.length) { ws.appendChild(h('p', { class: 'muted' }, 'This lab has no files to write. Read the evidence, then press Check.')); }

    var term = termPanel(lab, texts, areas, {
      check: function () { return doCheck(); },
      hint: function () { return hintText(); },
      status: function () { var r = State.rec(lab.id); return lab.id + ': ' + (r.status || 'not started') + ' · attempts ' + r.attempts + ' · hints used ' + r.hints_used + '/' + lab.hints.length; }
    });
    root.appendChild(term.el);
    root.appendChild(evidencePanel(lab, ui));
    root.appendChild(ws);

    // hints
    var hintBox = h('div', { id: 'hints' });
    var hintBtn = h('button', { type: 'button', id: 'btn-hint' }, 'Hint');
    function drawHints(announce) {
      var used = State.rec(lab.id).hints_used;
      var total = lab.hints.length;
      hintBox.textContent = '';
      for (var i = 0; i < used && i < total; i++) {
        hintBox.appendChild(h('div', { class: 'hint' },
          h('div', { class: 'hh' }, '[hint ' + (i + 1) + '/' + total + '] ' + TRACK_ID + ' ' + lab.id),
          h('p', null, lab.hints[i])));
      }
      if (used > 0) {
        var rem = total - used;
        hintBox.appendChild(h('p', { class: 'muted' }, rem > 0
          ? '(' + rem + ' hint' + (rem === 1 ? '' : 's') + ' remaining)'
          : '(that was the last hint)'));
      }
      hintBtn.disabled = used >= total;
      hintBtn.textContent = used >= total ? 'No more hints' : (used === 0 ? 'Hint' : 'Next hint');
      if (announce && used >= total) { /* last hint already announced inline */ }
    }
    function hintText() {
      var used = State.rec(lab.id).hints_used;
      var total = lab.hints.length;
      if (used >= total) { return 'no more hints for ' + TRACK_ID + ' ' + lab.id + ' — all ' + total + ' shown.'; }
      State.hint(lab.id, total);
      drawHints(true);
      var rem = total - used - 1;
      return '\n[hint ' + (used + 1) + '/' + total + '] ' + TRACK_ID + ' ' + lab.id + '\n  ' + lab.hints[used] + '\n\n' +
        (rem > 0 ? '(' + rem + ' hint' + (rem === 1 ? '' : 's') + ' remaining — run lab hint ' + TRACK_ID + ' ' + lab.id + ' again for the next)' : '(that was the last hint)');
    }
    hintBtn.addEventListener('click', function () { hintText(); });

    // check + quiz
    var resultsBox = h('div', { id: 'results' });
    var quizBox = h('div', { id: 'quiz' });
    var doneBox = h('div', { id: 'done' });
    var meta = h('p', { class: 'muted', id: 'attempts' });
    function drawMeta() {
      var r = State.rec(lab.id);
      meta.textContent = 'attempts: ' + r.attempts + ' · hints used: ' + r.hints_used + '/' + lab.hints.length;
    }
    function drawDone() {
      doneBox.textContent = '';
      var r = State.rec(lab.id);
      if (r.status === 'passed') {
        doneBox.appendChild(h('div', { class: 'banner passed' }, h('strong', null, '✓ passed ' + lab.id),
          h('div', { class: 'recap' }, h('p', { class: 'muted' }, 'recap'), h('ul', null, lab.recap.map(function (l) { return h('li', null, l); })))));
        var ni = idx + 1;
        if (ni < LABS.length) {
          doneBox.appendChild(h('a', { class: 'btn primary', id: 'btn-next', href: '#/lab/' + LABS[ni].id }, 'Next lab: ' + LABS[ni].id));
        } else {
          doneBox.appendChild(h('p', null, 'That was the last lab in the track.'));
        }
      }
    }

    function showQuiz() {
      quizBox.textContent = '';
      var form = h('form', { id: 'quiz-form', 'aria-label': 'Quiz' }, h('h3', null, 'Quiz — ' + lab.quiz.length + ' questions'));
      var fields = lab.quiz.map(function (q, i) { return questionField(q, i, 'Q'); });
      fields.forEach(function (f) { form.appendChild(f.el); });
      var verdict = h('div', null);
      form.appendChild(h('div', { class: 'actions' }, h('button', { type: 'submit', class: 'primary', id: 'btn-quiz' }, 'Submit quiz')));
      form.appendChild(verdict);
      form.addEventListener('submit', function (ev) {
        ev.preventDefault();
        var res = Quiz.grade(lab.quiz, fields.map(function (f) { return f.value(); }));
        verdict.textContent = '';
        var all = res.correct === res.total;
        verdict.appendChild(h('p', { class: 'verdict ' + (all ? 'ok' : 'bad'), id: 'quiz-verdict' },
          'quiz: ' + res.correct + '/' + res.total + (all ? '' : ' (missed ' + res.missed.map(function (n) { return 'Q' + n; }).join(',') + ')')));
        if (all) {
          if (State.rec(lab.id).status !== 'passed') { State.pass(lab.id, lab.recap); }
          drawDone();
          drawMeta();
        } else {
          verdict.appendChild(h('p', { class: 'muted' }, 'quiz not passed — re-run check.'));
        }
      });
      quizBox.appendChild(form);
    }

    function doCheck() {
      State.attempt(lab.id);
      drawMeta();
      resultsBox.textContent = '';
      quizBox.textContent = '';
      var res = Grader.run(lab, texts);
      var list = h('ul', { class: 'results' });
      res.results.forEach(function (r, i) {
        list.appendChild(h('li', { class: 'res ' + (r.ok ? 'ok' : 'bad') },
          h('span', { class: 'mk' }, r.ok ? '✓' : '✗'), '[' + (i + 1) + '] ' + r.msg,
          r.terminal ? h('span', { class: 'term' }, 'terminal-only, counted satisfied here' + (r.hint ? ' — ' + r.hint : '')) : null,
          !r.ok && r.hint ? h('span', { class: 'look' }, 'look at: ' + r.hint) : null));
      });
      resultsBox.appendChild(list);
      resultsBox.appendChild(h('p', { class: 'tally', id: 'tally' }, 'checks ' + res.passed + '/' + res.total));
      if (res.pass) { showQuiz(); }
      else { resultsBox.appendChild(h('p', { class: 'muted' }, 'Fix the failing checks, then press Check again.')); }
      return res;
    }

    var checkBtn = h('button', { type: 'button', class: 'primary', id: 'btn-check', onclick: doCheck }, 'Check');
    var skipBtn = h('button', { type: 'button', id: 'btn-skip', onclick: function () {
      if (!window.confirm('Skip ' + lab.id + '? It is marked ⏭ and the next lab unlocks. You can still open it later.')) { return; }
      State.skip(lab.id);
      var n = idx + 1 < LABS.length ? LABS[idx + 1].id : null;
      window.location.hash = n ? '#/lab/' + n : '#/';
    } }, 'Skip lab');

    var actions = h('div', { class: 'actions' }, checkBtn, hintBtn);
    if (lab.ungradable) {
      actions.appendChild(h('button', { type: 'button', id: 'btn-complete', onclick: function () {
        State.attempt(lab.id);
        State.pass(lab.id, lab.recap);
        drawDone(); drawMeta();
      } }, 'Mark complete'));
    }
    actions.appendChild(skipBtn);
    root.appendChild(h('section', { class: 'panel', id: 'grader' }, h('h2', null, 'Check'), actions, meta, hintBox, resultsBox, quizBox, doneBox));
    drawHints(false);
    drawMeta();
    drawDone();

    var nav = h('div', { class: 'nav-row' },
      idx > 0 ? h('a', { class: 'btn', href: '#/lab/' + LABS[idx - 1].id }, '← ' + LABS[idx - 1].id) : h('span'),
      idx + 1 < LABS.length && accessible(LABS, State, idx + 1) ? h('a', { class: 'btn', href: '#/lab/' + LABS[idx + 1].id }, LABS[idx + 1].id + ' →') : h('span'));
    root.appendChild(nav);
    view.appendChild(root);

    current = {
      check: doCheck,
      hint: function () { hintBtn.click(); },
      next: function () {
        var st = State.rec(lab.id);
        if ((st.status === 'passed' || st.skipped) && idx + 1 < LABS.length) { window.location.hash = '#/lab/' + LABS[idx + 1].id; }
        else { toast('Pass or skip ' + lab.id + ' before moving on.'); }
      },
      filter: function () { if (ui.filter) { ui.filter(); } },
      runCode: function (btn) {
        var holder = btn.closest('.code');
        var code = holder.querySelector('pre').textContent.replace(/\n+$/, '');
        var res = term.exec(code);
        var outEl = holder.nextElementSibling && holder.nextElementSibling.classList.contains('run-out') ? holder.nextElementSibling : null;
        if (!outEl) { outEl = h('pre', { class: 'run-out' }); holder.parentNode.insertBefore(outEl, holder.nextSibling); }
        outEl.textContent = res.text === '' ? '(no output — the command succeeded; check the file it wrote in Workspace)' : res.text;
        outEl.className = 'run-out' + (res.status !== 0 ? ' err' : '');
      }
    };
  }

  /* ---------- router / chrome ---------- */
  function route() {
    view.textContent = '';
    var m = /^#\/lab\/([\w.-]+)$/.exec(window.location.hash);
    if (m) { labView(m[1]); } else { homeView(); }
    window.scrollTo(0, 0);
  }

  function setTheme(t) {
    document.documentElement.setAttribute('data-theme', t);
  }

  function download(name, text) {
    var blob = new Blob([text], { type: 'application/json' });
    var a = h('a', { href: URL.createObjectURL(blob), download: name });
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    setTimeout(function () { URL.revokeObjectURL(a.href); }, 1000);
  }

  function boot() {
    view = document.getElementById('view');
    document.getElementById('brand-title').textContent = DATA.track.title;
    document.getElementById('brand-tag').textContent = DATA.track.tagline;
    document.title = DATA.track.title;

    var saved = lsGet(THEME_KEY);
    if (saved === 'light' || saved === 'dark') { setTheme(saved); }
    document.getElementById('btn-theme').addEventListener('click', function () {
      var eff = document.documentElement.getAttribute('data-theme') ||
        (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
      var next = eff === 'dark' ? 'light' : 'dark';
      lsSet(THEME_KEY, next);
      setTheme(next);
    });

    document.getElementById('btn-export').addEventListener('click', function () {
      download('progress.json', JSON.stringify(State.doc(), null, 2) + '\n');
    });
    var fileIn = document.getElementById('file-import');
    document.getElementById('btn-import').addEventListener('click', function () { fileIn.click(); });
    fileIn.addEventListener('change', function () {
      var f = fileIn.files && fileIn.files[0];
      if (!f) { return; }
      var rd = new FileReader();
      rd.onload = function () {
        try {
          var d = JSON.parse(String(rd.result));
          if (!stateValid(d)) { throw new Error('not a LAB-KIT progress.json (version 1)'); }
          State.replace(d);
          toast('Progress imported.');
          route();
        } catch (e) { toast('Import failed: ' + e.message); }
        fileIn.value = '';
      };
      rd.readAsText(f);
    });
    document.getElementById('btn-reset').addEventListener('click', function () {
      if (!window.confirm('Erase all SOC progress stored in this browser?')) { return; }
      State.reset();
      lsSet(DRAFT_KEY, '{}');
      toast('Progress reset.');
      if (window.location.hash && window.location.hash !== '#/') { window.location.hash = '#/'; } else { route(); }
    });

    view.addEventListener('click', function (ev) {
      var rb = ev.target.closest ? ev.target.closest('[data-run]') : null;
      if (rb) { if (current && current.runCode) { current.runCode(rb); } return; }
      var b = ev.target.closest ? ev.target.closest('[data-copy]') : null;
      if (!b) { return; }
      var pre = b.parentNode.querySelector('pre');
      copyText(pre ? pre.textContent : '').then(function () {
        b.textContent = 'copied';
        setTimeout(function () { b.textContent = 'copy'; }, 1200);
      });
    });

    document.addEventListener('keydown', function (ev) {
      if (ev.ctrlKey || ev.metaKey || ev.altKey) { return; }
      var t = ev.target;
      var typing = t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.tagName === 'SELECT' || t.isContentEditable);
      if (ev.key === 'Escape' && typing) { t.blur(); return; }
      if (typing || !current) { return; }
      if (ev.key === 'c' && current.check) { ev.preventDefault(); current.check(); }
      else if (ev.key === 'h' && current.hint) { ev.preventDefault(); current.hint(); }
      else if (ev.key === 'n' && current.next) { ev.preventDefault(); current.next(); }
      else if (ev.key === '/' && current.filter) { ev.preventDefault(); current.filter(); }
    });

    window.addEventListener('hashchange', route);
    route();
  }

  boot();
})();
