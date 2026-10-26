
  /* ---------- shell: tokenizer, parser, executor ---------- */
  function Incomplete(why) { var e = new Error('incomplete: ' + why); e.incomplete = true; return e; }

  function ansiC(s) {
    return s.replace(/\\(x[0-9a-fA-F]{1,2}|[0-7]{1,3}|.)/g, function (m, c) {
      var map = { n: '\n', t: '\t', r: '\r', '\\': '\\', "'": "'", '"': '"', a: '\x07', b: '\b', e: '\x1b', f: '\f', v: '\v' };
      if (c.charAt(0) === 'x' && c.length > 1) { return String.fromCharCode(parseInt(c.slice(1), 16)); }
      if (/^[0-7]+$/.test(c)) { return String.fromCharCode(parseInt(c, 8)); }
      return map.hasOwnProperty(c) ? map[c] : '\\' + c;
    });
  }

  // Scan from `i` (just after an opening "(" of $( ) to its matching ")". Returns index of ")".
  function scanParen(src, i) {
    var depth = 1;
    while (i < src.length) {
      var c = src.charAt(i);
      if (c === '\\') { i += 2; continue; }
      if (c === "'") { var e = src.indexOf("'", i + 1); if (e < 0) { throw Incomplete('quote'); } i = e + 1; continue; }
      if (c === '"') {
        i++;
        while (i < src.length && src.charAt(i) !== '"') { if (src.charAt(i) === '\\') { i++; } i++; }
        if (i >= src.length) { throw Incomplete('quote'); }
        i++;
        continue;
      }
      if (c === '(') { depth++; }
      else if (c === ')') { depth--; if (depth === 0) { return i; } }
      i++;
    }
    throw Incomplete('$(');
  }
  function scanBrace(src, i) {
    var depth = 1;
    while (i < src.length) {
      var c = src.charAt(i);
      if (c === '{') { depth++; } else if (c === '}') { depth--; if (depth === 0) { return i; } }
      i++;
    }
    throw Incomplete('${');
  }

  function tokenize(src) {
    var toks = [];
    var i = 0;
    var n = src.length;
    var cur = null;
    function add(txt, q) {
      if (!cur) { cur = { segs: [] }; }
      var last = cur.segs[cur.segs.length - 1];
      if (last && last.q === q) { last.s += txt; } else { cur.segs.push({ s: txt, q: q }); }
    }
    function flush() { if (cur) { toks.push({ t: 'word', w: cur }); cur = null; } }
    function curIsDigit() {
      return cur && cur.segs.length === 1 && cur.segs[0].q === 0 && /^[0-9]$/.test(cur.segs[0].s);
    }
    while (i < n) {
      var c = src.charAt(i);
      if (c === '\\') {
        if (i + 1 >= n) { throw Incomplete('backslash'); }
        if (src.charAt(i + 1) === '\n') { i += 2; continue; }
        add(src.charAt(i + 1), 1);
        i += 2;
        continue;
      }
      if (c === ' ' || c === '\t' || c === '\r') { flush(); i++; continue; }
      if (c === '\n') { flush(); toks.push({ t: 'op', v: '\n' }); i++; continue; }
      if (c === '#' && !cur) { while (i < n && src.charAt(i) !== '\n') { i++; } continue; }
      if (c === "'") {
        var e = src.indexOf("'", i + 1);
        if (e < 0) { throw Incomplete('quote'); }
        if (!cur) { cur = { segs: [] }; }
        add(src.slice(i + 1, e), 1);
        i = e + 1;
        continue;
      }
      if (c === '"') {
        i++;
        if (!cur) { cur = { segs: [] }; }
        var buf = '';
        var closed = false;
        while (i < n) {
          var d = src.charAt(i);
          if (d === '"') { closed = true; i++; break; }
          if (d === '\\' && i + 1 < n) {
            var nx = src.charAt(i + 1);
            if (nx === '"' || nx === '\\' || nx === '$' || nx === '`') {
              if (buf) { add(buf, 2); buf = ''; }
              add(nx, 1);
              i += 2;
              continue;
            }
            if (nx === '\n') { i += 2; continue; }
            buf += '\\';
            i++;
            continue;
          }
          if (d === '$' && src.charAt(i + 1) === '(') {
            var pe = scanParen(src, i + 2);
            buf += src.slice(i, pe + 1);
            i = pe + 1;
            continue;
          }
          if (d === '$' && src.charAt(i + 1) === '{') {
            var be = scanBrace(src, i + 2);
            buf += src.slice(i, be + 1);
            i = be + 1;
            continue;
          }
          buf += d;
          i++;
        }
        if (!closed) { throw Incomplete('quote'); }
        if (buf) { add(buf, 2); } else if (cur.segs.length === 0) { cur.segs.push({ s: '', q: 1 }); }
        continue;
      }
      if (c === '$' && src.charAt(i + 1) === "'") {
        var e2 = i + 2;
        while (e2 < n && src.charAt(e2) !== "'") { if (src.charAt(e2) === '\\') { e2++; } e2++; }
        if (e2 >= n) { throw Incomplete('quote'); }
        add(ansiC(src.slice(i + 2, e2)), 1);
        i = e2 + 1;
        continue;
      }
      if (c === '$' && src.charAt(i + 1) === '(') {
        var pe2 = scanParen(src, i + 2);
        add(src.slice(i, pe2 + 1), 0);
        i = pe2 + 1;
        continue;
      }
      if (c === '$' && src.charAt(i + 1) === '{') {
        var be2 = scanBrace(src, i + 2);
        add(src.slice(i, be2 + 1), 0);
        i = be2 + 1;
        continue;
      }
      if (c === '`') {
        var e3 = i + 1;
        while (e3 < n && src.charAt(e3) !== '`') { if (src.charAt(e3) === '\\') { e3++; } e3++; }
        if (e3 >= n) { throw Incomplete('backtick'); }
        add(src.slice(i, e3 + 1), 0);
        i = e3 + 1;
        continue;
      }
      if (c === '|') {
        flush();
        if (src.charAt(i + 1) === '|') { toks.push({ t: 'op', v: '||' }); i += 2; } else { toks.push({ t: 'op', v: '|' }); i++; }
        continue;
      }
      if (c === '&') {
        flush();
        if (src.charAt(i + 1) === '&') { toks.push({ t: 'op', v: '&&' }); i += 2; }
        else if (src.charAt(i + 1) === '>') { toks.push({ t: 'redir', fd: 'both', op: src.charAt(i + 2) === '>' ? '>>' : '>' }); i += src.charAt(i + 2) === '>' ? 3 : 2; }
        else { toks.push({ t: 'op', v: '&' }); i++; }
        continue;
      }
      if (c === ';') { flush(); toks.push({ t: 'op', v: ';' }); i++; continue; }
      if (c === '(' || c === ')') { flush(); toks.push({ t: 'op', v: c }); i++; continue; }
      if (c === '>' || c === '<') {
        var fd = c === '>' ? 1 : 0;
        if (curIsDigit()) { fd = parseInt(cur.segs[0].s, 10); cur = null; } else { flush(); }
        var op = c;
        i++;
        if (c === '>' && src.charAt(i) === '>') { op = '>>'; i++; }
        if (c === '>' && src.charAt(i) === '&') {
          var dm = /^&(\d+|-)/.exec(src.slice(i));
          if (dm) { toks.push({ t: 'redir', fd: fd, op: '>&', dup: dm[1] }); i += dm[0].length; continue; }
          toks.push({ t: 'redir', fd: 'both', op: '>' });
          i++;
          continue;
        }
        if (c === '<' && src.charAt(i) === '<') { throw ShellError('here-documents are not supported in the page terminal', 2); }
        toks.push({ t: 'redir', fd: fd, op: op });
        continue;
      }
      if ((c === '{' || c === '}') && !cur) {
        var nx2 = src.charAt(i + 1);
        if (c === '{' ? /[\s]/.test(nx2) : (nx2 === '' || /[\s;|&)]/.test(nx2))) {
          toks.push({ t: 'op', v: c });
          i++;
          continue;
        }
      }
      add(c, 0);
      i++;
    }
    flush();
    return toks;
  }

  function parseScript(src) {
    var toks = tokenize(src);
    var p = 0;
    function peek() { return toks[p]; }
    function isOp(v) { return toks[p] && toks[p].t === 'op' && toks[p].v === v; }
    function skipSeps() { while (isOp('\n') || isOp(';')) { p++; } }

    var RESERVED = /^(for|while|until|if|then|elif|else|fi|do|done|in)$/;
    function kwAt(i) {
      var tk = toks[i];
      if (!tk || tk.t !== 'word' || tk.w.segs.length !== 1 || tk.w.segs[0].q !== 0) { return null; }
      return RESERVED.test(tk.w.segs[0].s) ? tk.w.segs[0].s : null;
    }
    function atStop(stop) {
      if (!stop) { return false; }
      var tk = toks[p];
      if (!tk) { return false; }
      if (tk.t === 'op') { return stop.indexOf(tk.v) !== -1; }
      var k = kwAt(p);
      return k !== null && stop.indexOf(k) !== -1;
    }
    function expectKw(k) {
      if (kwAt(p) !== k) { if (p >= toks.length) { throw Incomplete('missing ' + k); } throw ShellError("syntax error near unexpected token `" + (toks[p].v || (toks[p].w && toks[p].w.segs[0].s) || 'word') + "'", 2); }
      p++;
    }
    function parseList(stop) {
      var items = [];
      skipSeps();
      while (p < toks.length && !atStop(stop)) {
        var node = parseAndOr();
        var sep = ';';
        if (isOp(';') || isOp('\n') || isOp('&')) { sep = toks[p].v === '\n' ? ';' : toks[p].v; p++; }
        else if (p < toks.length && !atStop(stop)) { throw ShellError('syntax error near unexpected token `' + (toks[p].v || (toks[p].w && toks[p].w.segs[0].s) || 'word') + "'", 2); }
        items.push({ node: node, sep: sep });
        skipSeps();
      }
      if (stop && !atStop(stop)) { throw Incomplete('missing ' + stop[0]); }
      return items;
    }
    function parseAndOr() {
      var first = parsePipeline();
      var rest = [];
      while (isOp('&&') || isOp('||')) {
        var op = toks[p++].v;
        while (isOp('\n')) { p++; }
        if (p >= toks.length) { throw Incomplete(op); }
        rest.push({ op: op, node: parsePipeline() });
      }
      return { t: 'andor', first: first, rest: rest };
    }
    function parsePipeline() {
      var neg = false;
      var first = peek();
      if (first && first.t === 'word' && first.w.segs.length === 1 && first.w.segs[0].s === '!' && first.w.segs[0].q === 0) { neg = true; p++; }
      var cmds = [parseCommand()];
      while (isOp('|')) {
        p++;
        while (isOp('\n')) { p++; }
        if (p >= toks.length) { throw Incomplete('|'); }
        cmds.push(parseCommand());
      }
      return { t: 'pipeline', cmds: cmds, neg: neg };
    }
    function parseRedirs(node) {
      while (peek() && peek().t === 'redir') {
        var r = toks[p++];
        if (r.op === '>&') { node.redirs.push({ fd: r.fd, op: '>&', dup: r.dup }); continue; }
        var tw = peek();
        if (!tw || tw.t !== 'word') { throw ShellError("syntax error near unexpected token `newline'", 2); }
        p++;
        node.redirs.push({ fd: r.fd, op: r.op, target: tw.w });
      }
    }
    function parseCommand() {
      var k = kwAt(p);
      if (k === 'for') {
        p++;
        var nameTok = toks[p++];
        if (!nameTok || nameTok.t !== 'word') { throw Incomplete('for'); }
        var words = [];
        if (kwAt(p) === 'in') {
          p++;
          while (toks[p] && toks[p].t === 'word' && kwAt(p) !== 'do') { words.push(toks[p++].w); }
        }
        skipSeps();
        expectKw('do');
        var fbody = parseList(['done']);
        expectKw('done');
        var floop = { t: 'for', name: nameTok.w.segs[0].s, words: words, body: fbody, redirs: [] };
        parseRedirs(floop);
        return floop;
      }
      if (k === 'while' || k === 'until') {
        p++;
        var cond = parseList(['do']);
        expectKw('do');
        var wbody = parseList(['done']);
        expectKw('done');
        var wl = { t: 'while', until: k === 'until', cond: cond, body: wbody, redirs: [] };
        parseRedirs(wl);
        return wl;
      }
      if (k === 'if') {
        p++;
        var clauses = [];
        var els = null;
        var c1 = parseList(['then']);
        expectKw('then');
        clauses.push({ cond: c1, body: parseList(['elif', 'else', 'fi']) });
        while (kwAt(p) === 'elif') {
          p++;
          var ce = parseList(['then']);
          expectKw('then');
          clauses.push({ cond: ce, body: parseList(['elif', 'else', 'fi']) });
        }
        if (kwAt(p) === 'else') { p++; els = parseList(['fi']); }
        expectKw('fi');
        var ifn = { t: 'if', clauses: clauses, els: els, redirs: [] };
        parseRedirs(ifn);
        return ifn;
      }
      if (isOp('{') || isOp('(')) {
        var open = toks[p++].v;
        var body = parseList([open === '{' ? '}' : ')']);
        p++;
        var grp = { t: 'group', body: body, redirs: [] };
        parseRedirs(grp);
        return grp;
      }
      var cmd = { t: 'simple', assigns: [], words: [], redirs: [] };
      for (;;) {
        var tk = peek();
        if (!tk) { break; }
        if (tk.t === 'redir') { parseRedirs(cmd); continue; }
        if (tk.t !== 'word') { break; }
        p++;
        var first = tk.w.segs[0];
        var am = !cmd.words.length && first.q === 0 ? /^([A-Za-z_][A-Za-z0-9_]*)=/.exec(first.s) : null;
        if (am) {
          var segs = tk.w.segs.map(function (s) { return { s: s.s, q: s.q }; });
          segs[0].s = segs[0].s.slice(am[0].length);
          cmd.assigns.push({ name: am[1], w: { segs: segs } });
          continue;
        }
        cmd.words.push(tk.w);
      }
      if (!cmd.words.length && !cmd.assigns.length && !cmd.redirs.length) {
        throw ShellError("syntax error near unexpected token `" + (peek() ? (peek().v || 'word') : 'newline') + "'", 2);
      }
      return cmd;
    }
    var items = parseList(null);
    return items;
  }

  function globToRegex(pat) {
    var out = '^';
    for (var i = 0; i < pat.length; i++) {
      var c = pat.charAt(i);
      if (c === '\\') { i++; out += (pat.charAt(i) || '').replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }
      else if (c === '*') { out += '[^/]*'; }
      else if (c === '?') { out += '[^/]'; }
      else if (c === '[') {
        var e = pat.indexOf(']', i + 2);
        if (e < 0) { out += '\\['; } else {
          var body = pat.slice(i + 1, e).replace(/^!/, '^').replace(/\\/g, '\\\\');
          out += '[' + body + ']';
          i = e;
        }
      } else { out += c.replace(/[.*+?^${}()|\\]/g, '\\$&'); }
    }
    return new RegExp(out + '$');
  }

  function arith(expr) {
    var s = expr.replace(/\s+/g, '');
    var pos = 0;
    function num() {
      var m = /^-?\d+/.exec(s.slice(pos));
      if (s.charAt(pos) === '(') { pos++; var v = add(); pos++; return v; }
      if (!m) { throw ShellError('arithmetic syntax error', 1); }
      pos += m[0].length;
      return parseInt(m[0], 10);
    }
    function mul() {
      var v = num();
      while (s.charAt(pos) === '*' || s.charAt(pos) === '/' || s.charAt(pos) === '%') {
        var op = s.charAt(pos++);
        var r = num();
        if (op === '*') { v *= r; } else if (r === 0) { throw ShellError('division by 0', 1); } else if (op === '/') { v = Math.trunc(v / r); } else { v %= r; }
      }
      return v;
    }
    function add() {
      var v = mul();
      while (s.charAt(pos) === '+' || s.charAt(pos) === '-') {
        var op = s.charAt(pos++);
        var r = mul();
        v = op === '+' ? v + r : v - r;
      }
      return v;
    }
    return add();
  }

  /* ---------- the shell ---------- */
  function Shell(opts) {
    this.vfs = opts.vfs;
    this.hooks = opts.hooks || {};
    this.cwd = '';
    this.env = { HOME: this.vfs.abs, USER: 'analyst', LOGNAME: 'analyst', SHELL: '/bin/bash', PATH: '/usr/local/bin:/usr/bin:/bin',
      LANG: 'C.UTF-8', TERM: 'xterm', HOSTNAME: 'soc', PWD: this.vfs.abs, OLDPWD: this.vfs.abs };
    this.vars = {};
    this.status = 0;
    this.history = [];
    this.depth = 0;
    this.steps = 0;
    this.scratchWrites = 0;
  }
  Shell.prototype.pwd = function () { return this.cwd ? this.vfs.abs + '/' + this.cwd : this.vfs.abs; };
  Shell.prototype.prompt = function () {
    var shown = this.cwd ? '~/lab-kit/workspace/soc/' + this.vfs.id + '/' + this.cwd : '~/lab-kit/workspace/soc/' + this.vfs.id;
    return 'analyst@soc:' + shown + '$ ';
  };
  Shell.prototype.getVar = function (n) {
    if (Object.prototype.hasOwnProperty.call(this.vars, n)) { return this.vars[n]; }
    if (n === '?') { return String(this.status); }
    if (n === '$') { return '4242'; }
    if (n === '0') { return 'bash'; }
    if (n === 'PWD') { return this.pwd(); }
    return Object.prototype.hasOwnProperty.call(this.env, n) ? this.env[n] : '';
  };

  Shell.prototype.incomplete = function (line) {
    try { parseScript(line); return false; } catch (e) { if (e.incomplete) { return true; } return false; }
  };

  // Expand a word to a list of argument strings.
  Shell.prototype.expand = function (w, sink, noGlob) {
    var self = this;
    var fields = [];
    var cur = '';
    var glob = '';
    var started = false;
    function endField() { if (started) { fields.push({ text: cur, glob: glob }); } cur = ''; glob = ''; started = false; }
    function escG(s) { return s.replace(/[*?\[\]\\]/g, '\\$&'); }
    w.segs.forEach(function (seg, si) {
      if (seg.q === 1) { cur += seg.s; glob += escG(seg.s); started = true; return; }
      var txt = seg.s;
      var out = '';
      var j = 0;
      var splittable = [];
      if (seg.q === 0 && si === 0 && (txt === '~' || txt.indexOf('~/') === 0)) { txt = self.vfs.abs + txt.slice(1); }
      while (j < txt.length) {
        var ch = txt.charAt(j);
        if (ch === '$') {
          var rest = txt.slice(j);
          var m;
          if (rest.indexOf('$((') === 0) {
            var ae = scanParen(txt, j + 2);
            var inner = txt.slice(j + 3, ae - 1 >= j + 3 ? ae : ae);
            var exprSrc = txt.slice(j + 3, ae).replace(/\)$/, '');
            out += String(arith(self.expandString(exprSrc, sink).replace(/[A-Za-z_][A-Za-z0-9_]*/g, function (nm) { return self.getVar(nm) || '0'; })));
            void inner;
            j = ae + 1;
            splittable.push([out.length]);
            continue;
          }
          if (rest.charAt(1) === '(') {
            var pe = scanParen(txt, j + 2);
            var sub = self.captureSub(txt.slice(j + 2, pe), sink);
            out += sub;
            if (seg.q === 0) { splittable.push([out.length - sub.length, out.length]); }
            j = pe + 1;
            continue;
          }
          if (rest.charAt(1) === '{') {
            var be = scanBrace(txt, j + 2);
            var spec = txt.slice(j + 2, be);
            var val;
            var pm = /^([A-Za-z_][A-Za-z0-9_]*|\?)(:?[-=+])(.*)$/.exec(spec);
            if (spec.charAt(0) === '#' && /^#[A-Za-z_]\w*$/.test(spec)) { val = String(self.getVar(spec.slice(1)).length); }
            else if (pm) {
              var base = self.getVar(pm[1]);
              var colon = pm[2].charAt(0) === ':';
              var empty = colon ? base === '' : !Object.prototype.hasOwnProperty.call(self.vars, pm[1]) && !Object.prototype.hasOwnProperty.call(self.env, pm[1]);
              var kind = pm[2].charAt(pm[2].length - 1);
              if (kind === '-') { val = empty ? self.expandString(pm[3], sink) : base; }
              else if (kind === '+') { val = empty ? '' : self.expandString(pm[3], sink); }
              else { if (empty) { self.vars[pm[1]] = self.expandString(pm[3], sink); } val = self.getVar(pm[1]); }
            } else { val = self.getVar(spec); }
            out += val;
            if (seg.q === 0) { splittable.push([out.length - val.length, out.length]); }
            j = be + 1;
            continue;
          }
          if ((m = /^\$([A-Za-z_][A-Za-z0-9_]*|\?|\$|0|[1-9])/.exec(rest))) {
            var v = self.getVar(m[1]);
            out += v;
            if (seg.q === 0) { splittable.push([out.length - v.length, out.length]); }
            j += m[0].length;
            continue;
          }
          out += '$';
          j++;
          continue;
        }
        if (ch === '`') {
          var ce = j + 1;
          while (ce < txt.length && txt.charAt(ce) !== '`') { if (txt.charAt(ce) === '\\') { ce++; } ce++; }
          var cs = self.captureSub(txt.slice(j + 1, ce), sink);
          out += cs;
          if (seg.q === 0) { splittable.push([out.length - cs.length, out.length]); }
          j = ce + 1;
          continue;
        }
        out += ch;
        j++;
      }
      if (seg.q === 2) { cur += out; glob += escG(out); started = true; return; }
      // unquoted: split the expanded pieces on whitespace
      var spans = splittable.filter(function (s) { return s.length === 2; });
      if (!spans.length) { cur += out; glob += out; started = started || out !== ''; return; }
      var k = 0;
      spans.forEach(function (sp) {
        var lit = out.slice(k, sp[0]);
        cur += lit; glob += lit;
        if (lit) { started = true; }
        var exp = out.slice(sp[0], sp[1]);
        var pieces = exp.split(/[ \t\n]+/);
        pieces.forEach(function (piece, pi) {
          if (pi > 0) { endField(); }
          if (piece !== '') { cur += piece; glob += escG(piece); started = true; }
        });
        k = sp[1];
      });
      var tail = out.slice(k);
      cur += tail; glob += tail;
      if (tail) { started = true; }
    });
    endField();
    var results = [];
    fields.forEach(function (f) {
      if (!noGlob && /[*?\[]/.test(f.glob.replace(/\\./g, ''))) {
        var matches = self.globMatch(f.glob);
        if (matches.length) { results = results.concat(matches); return; }
      }
      results.push(f.text);
    });
    return results;
  };
  Shell.prototype.expandString = function (s, sink) {
    return this.expand({ segs: [{ s: s, q: 2 }] }, sink, true).join(' ');
  };
  Shell.prototype.captureSub = function (cmd, sink) {
    var buf = '';
    var sub = { out: function (t) { buf += t; }, err: function (t) { sink.err(t); } };
    this.depth++;
    try { this.execItems(parseScript(cmd), { stdin: null, out: sub.out, err: sub.err, tty: false }); } finally { this.depth--; }
    return buf.replace(/\n+$/, '');
  };
  Shell.prototype.globMatch = function (pattern) {
    var self = this;
    if (pattern.charAt(0) === '/') { return []; }
    var segs = pattern.split('/').filter(function (s) { return s !== ''; });
    var results = [];
    function walk(dirRel, idx, prefix) {
      if (idx === segs.length) { results.push(prefix); return; }
      var seg = segs[idx];
      var last = idx === segs.length - 1;
      if (!/[*?\[]/.test(seg.replace(/\\./g, ''))) {
        var lit = seg.replace(/\\(.)/g, '$1');
        var next = dirRel ? dirRel + '/' + lit : lit;
        if (self.vfs.exists(next)) { walk(next, idx + 1, prefix ? prefix + '/' + lit : lit); }
        return;
      }
      var re = globToRegex(seg);
      self.vfs.list(dirRel).forEach(function (name) {
        if (name.charAt(0) === '.' && seg.charAt(0) !== '.') { return; }
        if (!re.test(name)) { return; }
        var np = dirRel ? dirRel + '/' + name : name;
        if (!last && !self.vfs.isDir(np)) { return; }
        walk(np, idx + 1, prefix ? prefix + '/' + name : name);
      });
    }
    walk(this.cwd, 0, '');
    return results.map(function (r) { return r; }).sort();
  };

  Shell.prototype.path = function (p) {
    var r = this.vfs.resolve(this.cwd, p);
    return r;
  };

  Shell.prototype.execItems = function (items, io) {
    var status = this.status;
    for (var i = 0; i < items.length; i++) {
      status = this.execAndOr(items[i].node, io);
      this.status = status;
    }
    return status;
  };
  Shell.prototype.execAndOr = function (node, io) {
    var status = this.execPipeline(node.first, io);
    this.status = status;
    for (var i = 0; i < node.rest.length; i++) {
      var r = node.rest[i];
      if (r.op === '&&' && status !== 0) { continue; }
      if (r.op === '||' && status === 0) { continue; }
      status = this.execPipeline(r.node, io);
      this.status = status;
    }
    return status;
  };
  Shell.prototype.execPipeline = function (node, io) {
    var self = this;
    if (++this.steps > 200000) { throw ShellError('command limit exceeded', 1); }
    var stdin = io.stdin;
    var status = 0;
    for (var i = 0; i < node.cmds.length; i++) {
      var last = i === node.cmds.length - 1;
      var buf = '';
      var stageIo = {
        stdin: stdin,
        out: last ? io.out : function (t) { buf += t; },
        err: io.err,
        tty: last && io.tty
      };
      status = this.execCommand(node.cmds[i], stageIo);
      if (!last) { stdin = buf; }
    }
    void self;
    return node.neg ? (status === 0 ? 1 : 0) : status;
  };
  Shell.prototype.execCommand = function (cmd, io) {
    var self = this;
    var out = io.out;
    var err = io.err;
    var stdin = io.stdin;
    var pending = [];
    var tty = io.tty;
    var outRedirected = false;
    var errToOut = false;
    // redirections
    for (var i = 0; i < cmd.redirs.length; i++) {
      var r = cmd.redirs[i];
      if (r.op === '>&') {
        if (r.fd === 2 && r.dup === '1') { errToOut = true; }
        else if (r.fd === 1 && r.dup === '2') { out = err; outRedirected = false; }
        continue;
      }
      var tgt = this.expand(r.target, io, true);
      if (tgt.length !== 1) { err('bash: ' + (tgt[0] || '') + ': ambiguous redirect\n'); return 1; }
      var name = tgt[0];
      if (r.op === '<') {
        var rp = this.path(name);
        var content = rp === null ? null : this.vfs.readText(rp);
        if (content === null) { err('bash: ' + name + ': No such file or directory\n'); return 1; }
        stdin = content;
        continue;
      }
      var sink;
      if (name === '/dev/null') { sink = function () {}; }
      else if (name === '/dev/stdout') { sink = out; }
      else if (name === '/dev/stderr') { sink = err; }
      else {
        var wp = this.path(name);
        if (wp === null) { err('bash: ' + name + ': Permission denied (outside the lab workspace)\n'); return 1; }
        if (this.vfs.isDir(wp)) { err('bash: ' + name + ': Is a directory\n'); return 1; }
        var append = r.op === '>>';
        var holder = { buf: '' };
        if (!append) { this.vfs.write(wp, '', false); }
        pending.push({ path: wp, holder: holder, append: append });
        sink = (function (h) { return function (t) { h.buf += t; }; })(holder);
      }
      if (r.fd === 'both') { out = sink; err = sink; outRedirected = true; }
      else if (r.fd === 2) { err = sink; }
      else if (r.fd === 1) { out = sink; outRedirected = true; }
    }
    if (errToOut) { err = out; }
    var cio = { stdin: stdin, out: out, err: err, tty: tty && !outRedirected };
    var status;
    try {
      if (cmd.t === 'group') {
        status = this.execItems(cmd.body, cio);
      } else if (cmd.t === 'for') {
        status = this.execFor(cmd, cio);
      } else if (cmd.t === 'while') {
        status = this.execWhile(cmd, cio);
      } else if (cmd.t === 'if') {
        status = this.execIf(cmd, cio);
      } else {
        status = this.execSimple(cmd, cio);
      }
    } catch (e) {
      if (e && e.shellError) { err((e.message.indexOf(':') > 0 && !/^[a-z]+: /.test(e.message) ? '' : '') + e.message + '\n'); status = e.code || 1; }
      else { throw e; }
    }
    pending.forEach(function (pd) { if (pd.holder.buf !== '' || !pd.append) { self.vfs.write(pd.path, pd.holder.buf, true); } });
    return status;
  };

  Shell.prototype.execFor = function (cmd, io) {
    var self = this;
    var items = [];
    cmd.words.forEach(function (w) { items = items.concat(self.expand(w, io)); });
    var status = 0;
    for (var i = 0; i < items.length; i++) {
      this.vars[cmd.name] = items[i];
      status = this.execItems(cmd.body, io);
    }
    return status;
  };
  Shell.prototype.execWhile = function (cmd, io) {
    var status = 0;
    var guard = 0;
    for (;;) {
      if (++guard > 10000) { throw ShellError('loop limit exceeded', 1); }
      var c = this.execItems(cmd.cond, io);
      if ((c === 0) === !!cmd.until) { break; }
      status = this.execItems(cmd.body, io);
    }
    return status;
  };
  Shell.prototype.execIf = function (cmd, io) {
    for (var i = 0; i < cmd.clauses.length; i++) {
      if (this.execItems(cmd.clauses[i].cond, io) === 0) { return this.execItems(cmd.clauses[i].body, io); }
    }
    return cmd.els ? this.execItems(cmd.els, io) : 0;
  };

  Shell.prototype.execSimple = function (cmd, io) {
    var self = this;
    var words = [];
    cmd.words.forEach(function (w) { words = words.concat(self.expand(w, io)); });
    if (!words.length) {
      cmd.assigns.forEach(function (a) { self.vars[a.name] = self.expand(a.w, io, true).join(' '); });
      return 0;
    }
    var saved = {};
    cmd.assigns.forEach(function (a) {
      saved[a.name] = Object.prototype.hasOwnProperty.call(self.vars, a.name) ? self.vars[a.name] : undefined;
      self.vars[a.name] = self.expand(a.w, io, true).join(' ');
    });
    try {
      return this.runCommand(words[0], words.slice(1), io);
    } finally {
      Object.keys(saved).forEach(function (k) { if (saved[k] === undefined) { delete self.vars[k]; } else { self.vars[k] = saved[k]; } });
    }
  };
  Shell.prototype.runCommand = function (name, args, io) {
    var fn = COMMANDS[name];
    if (!fn && name.indexOf('/') !== -1) {
      var base = name.split('/').pop();
      if (/^(\/usr)?\/(local\/)?(s?bin)\//.test(name) && COMMANDS[base]) { fn = COMMANDS[base]; name = base; }
    }
    if (!fn) {
      io.err('bash: ' + name + ': command not found' + suggest(name) + '\n');
      return 127;
    }
    var ctx = {
      name: name, args: args, stdin: io.stdin, tty: io.tty, sh: this, vfs: this.vfs,
      out: io.out, err: io.err
    };
    return fn(ctx);
  };
  function suggest(name) {
    var near = Object.keys(COMMANDS).filter(function (c) { return c.length > 2 && (c.indexOf(name) === 0 || name.indexOf(c) === 0); });
    return near.length ? '\n(the page terminal has: ' + near.slice(0, 4).join(', ') + ')' : '';
  }

  // Run a full command line. Returns {chunks:[{t,e}], status, clear}.
  Shell.prototype.run = function (line) {
    var chunks = [];
    var self = this;
    function push(t, e) {
      if (!t) { return; }
      var last = chunks[chunks.length - 1];
      if (last && last.e === e) { last.t += t; } else { chunks.push({ t: t, e: e }); }
    }
    var io = { stdin: null, out: function (t) { push(t, false); }, err: function (t) { push(t, true); }, tty: true };
    this.clearFlag = false;
    this.steps = 0;
    if (line.trim() !== '') { this.history.push(line); }
    try {
      var items = parseScript(line);
      this.execItems(items, io);
    } catch (e) {
      if (e && e.shellError) { push('bash: ' + e.message + '\n', true); this.status = e.code || 2; }
      else if (e && e.incomplete) { push('bash: syntax error: unexpected end of input\n', true); this.status = 2; }
      else if (e && e.exitShell) { this.status = e.code; push('(the page terminal has no session to close; reload the page to start over)\n', false); }
      else { push('bash: internal error: ' + (e && e.message ? e.message : e) + '\n', true); this.status = 70; }
    }
    void self;
    return { chunks: chunks, status: this.status, clear: this.clearFlag };
  };

  // Tab completion: returns {prefix, matches}
  Shell.prototype.complete = function (line) {
    var m = /(\S*)$/.exec(line);
    var word = m ? m[1] : '';
    var before = line.slice(0, line.length - word.length);
    var isCmd = /^\s*$/.test(before) || /[|;&]\s*$/.test(before) || /^\s*(sudo)\s+$/.test(before);
    var cands;
    if (isCmd && word.indexOf('/') === -1) {
      cands = Object.keys(COMMANDS).filter(function (c) { return c.indexOf(word) === 0; });
    } else {
      var slash = word.lastIndexOf('/');
      var dirPart = slash >= 0 ? word.slice(0, slash + 1) : '';
      var namePart = slash >= 0 ? word.slice(slash + 1) : word;
      var dir = this.vfs.resolve(this.cwd, dirPart === '' ? '.' : dirPart);
      cands = [];
      if (dir !== null) {
        var self = this;
        cands = this.vfs.list(dir).filter(function (n) { return n.indexOf(namePart) === 0; }).map(function (n) {
          return dirPart + n + (self.vfs.isDir(dir ? dir + '/' + n : n) ? '/' : '');
        });
      }
    }
    return { before: before, word: word, matches: cands.sort() };
  };
