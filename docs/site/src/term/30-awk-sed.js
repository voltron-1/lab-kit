
  /* ---------- awk ----------
   * Tree-walking interpreter for the POSIX awk the labs use: patterns, BEGIN/END,
   * fields, arrays, user functions, printf, the common builtins. */
  var Awk = (function () {
    function AwkError(msg) { var e = new Error(msg); e.awk = true; return e; }
    var NUM_RE = /^\s*[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?\s*$/;
    var NUM_PREFIX = /^\s*[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/;

    function strnum(s) { return NUM_RE.test(s) ? { s: s, n: parseFloat(s) } : s; }
    function isStrnum(v) { return v !== null && typeof v === 'object' && typeof v.n === 'number'; }
    function toNum(v) {
      if (typeof v === 'number') { return v; }
      if (v === undefined) { return 0; }
      if (isStrnum(v)) { return v.n; }
      var m = NUM_PREFIX.exec(v);
      return m ? parseFloat(m[0]) : 0;
    }
    function fmtG(n, prec) {
      if (n === 0) { return '0'; }
      var p = prec === undefined ? 6 : (prec === 0 ? 1 : prec);
      var exp = Math.floor(Math.log10(Math.abs(n)));
      var s;
      if (exp < -4 || exp >= p) {
        s = n.toExponential(p - 1).replace(/\.?0+e/, 'e');
        s = s.replace(/e([+-])(\d)$/, 'e$10$2');
      } else {
        s = n.toFixed(Math.max(0, p - 1 - exp));
        if (s.indexOf('.') !== -1) { s = s.replace(/\.?0+$/, ''); }
      }
      return s;
    }
    function toStr(v) {
      if (typeof v === 'string') { return v; }
      if (v === undefined) { return ''; }
      if (isStrnum(v)) { return v.s; }
      if (Number.isInteger(v)) { return String(v); }
      return fmtG(v, 6);
    }
    function toBool(v) {
      if (typeof v === 'number') { return v !== 0; }
      if (v === undefined) { return false; }
      if (isStrnum(v)) { return v.n !== 0; }
      return v !== '';
    }
    function compare(a, b) {
      var an = typeof a === 'number' || isStrnum(a) || a === undefined;
      var bn = typeof b === 'number' || isStrnum(b) || b === undefined;
      if (an && bn) { var x = toNum(a), y = toNum(b); return x < y ? -1 : x > y ? 1 : 0; }
      var s = toStr(a), t = toStr(b);
      return s < t ? -1 : s > t ? 1 : 0;
    }
    function unescapeStr(s) {
      return s.replace(/\\(?:([0-7]{1,3})|(.))/g, function (m, oct, c) {
        if (oct) { return String.fromCharCode(parseInt(oct, 8)); }
        var map = { n: '\n', t: '\t', r: '\r', '\\': '\\', '"': '"', '/': '/', a: '\x07', b: '\b', f: '\f', v: '\v' };
        return map.hasOwnProperty(c) ? map[c] : '\\' + c;
      });
    }

    /* ----- lexer ----- */
    var KW = { BEGIN: 1, END: 1, 'function': 1, func: 1, 'if': 1, 'else': 1, 'while': 1, 'for': 1, 'do': 1, 'break': 1,
      'continue': 1, next: 1, exit: 1, 'return': 1, 'delete': 1, print: 1, printf: 1, 'in': 1, getline: 1 };
    var BUILTINS = { length: 1, substr: 1, index: 1, split: 1, sub: 1, gsub: 1, match: 1, tolower: 1, toupper: 1,
      sprintf: 1, 'int': 1, sqrt: 1, exp: 1, log: 1, sin: 1, cos: 1, atan2: 1, rand: 1, srand: 1, system: 1 };
    function lex(src) {
      var toks = [];
      var i = 0;
      var n = src.length;
      function prevIsOperand() {
        var t = toks[toks.length - 1];
        if (!t) { return false; }
        if (t.t === 'num' || t.t === 'str' || t.t === 'name' || t.t === 'builtin' || t.t === 'ere') { return true; }
        if (t.t === 'op' && (t.v === ')' || t.v === ']' || t.v === '$' || t.v === '++' || t.v === '--')) { return true; }
        return false;
      }
      while (i < n) {
        var c = src.charAt(i);
        if (c === ' ' || c === '\t' || c === '\r') { i++; continue; }
        if (c === '\\' && src.charAt(i + 1) === '\n') { i += 2; continue; }
        if (c === '\n') { toks.push({ t: 'nl' }); i++; continue; }
        if (c === '#') { while (i < n && src.charAt(i) !== '\n') { i++; } continue; }
        if (c === '"') {
          var j = i + 1;
          var buf = '';
          while (j < n && src.charAt(j) !== '"') {
            if (src.charAt(j) === '\\') { buf += src.substr(j, 2); j += 2; } else { buf += src.charAt(j); j++; }
          }
          if (j >= n) { throw AwkError('non-terminated string'); }
          toks.push({ t: 'str', v: unescapeStr(buf) });
          i = j + 1;
          continue;
        }
        var m;
        if ((m = /^(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/.exec(src.slice(i)))) {
          toks.push({ t: 'num', v: parseFloat(m[0]) });
          i += m[0].length;
          continue;
        }
        if (/[A-Za-z_]/.test(c)) {
          m = /^[A-Za-z_][A-Za-z0-9_]*/.exec(src.slice(i));
          var w = m[0];
          i += w.length;
          if (KW[w]) { toks.push({ t: 'kw', v: w === 'func' ? 'function' : w }); }
          else if (BUILTINS[w]) { toks.push({ t: 'builtin', v: w }); }
          else if (src.charAt(i) === '(') { toks.push({ t: 'funcname', v: w }); }
          else { toks.push({ t: 'name', v: w }); }
          continue;
        }
        if (c === '/' && !prevIsOperand()) {
          var k = i + 1;
          var re = '';
          var inBr = false;
          while (k < n && (src.charAt(k) !== '/' || inBr)) {
            var ch = src.charAt(k);
            if (ch === '\\' && k + 1 < n) { re += ch + src.charAt(k + 1); k += 2; continue; }
            if (ch === '[') { inBr = true; } else if (ch === ']') { inBr = false; }
            if (ch === '\n') { throw AwkError('newline in regex'); }
            re += ch;
            k++;
          }
          toks.push({ t: 'ere', v: re.replace(/\\\//g, '/') });
          i = k + 1;
          continue;
        }
        var three = src.substr(i, 3);
        var two = src.substr(i, 2);
        if (three === '**=') { toks.push({ t: 'op', v: '^=' }); i += 3; continue; }
        if (['&&', '||', '==', '!=', '<=', '>=', '++', '--', '+=', '-=', '*=', '/=', '%=', '^=', '>>', '!~'].indexOf(two) !== -1) {
          toks.push({ t: 'op', v: two }); i += 2; continue;
        }
        if (two === '**') { toks.push({ t: 'op', v: '^' }); i += 2; continue; }
        toks.push({ t: 'op', v: c });
        i++;
      }
      toks.push({ t: 'eof' });
      return toks;
    }

    /* ----- parser ----- */
    function parseProgram(src) {
      var toks = lex(src);
      var p = 0;
      var noIn = 0;
      var noGt = 0;
      function peek() { return toks[p]; }
      function isOp(v) { return toks[p].t === 'op' && toks[p].v === v; }
      function isKw(v) { return toks[p].t === 'kw' && toks[p].v === v; }
      function expectOp(v) { if (!isOp(v)) { throw AwkError('syntax error: expected ' + v); } p++; }
      function skipNl() { while (toks[p].t === 'nl') { p++; } }
      function skipTerms() { while (toks[p].t === 'nl' || isOp(';')) { p++; } }

      var prog = { begin: [], end: [], rules: [], funcs: {} };
      skipTerms();
      while (peek().t !== 'eof') {
        if (isKw('function')) {
          p++;
          var name = toks[p++].v;
          expectOp('(');
          var params = [];
          while (!isOp(')')) {
            params.push(toks[p++].v);
            if (isOp(',')) { p++; skipNl(); }
          }
          p++;
          skipNl();
          prog.funcs[name] = { params: params, body: parseBlock() };
        } else if (isKw('BEGIN')) { p++; skipNl(); prog.begin.push(parseBlock()); }
        else if (isKw('END')) { p++; skipNl(); prog.end.push(parseBlock()); }
        else {
          var pat = null;
          var pat2 = null;
          if (!isOp('{')) {
            pat = parseExpr();
            if (isOp(',')) { p++; skipNl(); pat2 = parseExpr(); }
          }
          var action = null;
          if (isOp('{')) { action = parseBlock(); }
          prog.rules.push({ pat: pat, pat2: pat2, action: action, inRange: false });
        }
        skipTerms();
      }
      return prog;

      function parseBlock() {
        expectOp('{');
        var stmts = [];
        skipTerms();
        while (!isOp('}')) {
          stmts.push(parseStmt());
          skipTerms();
        }
        p++;
        return { t: 'block', stmts: stmts };
      }
      function endStmt() {
        if (isOp(';') || toks[p].t === 'nl') { p++; return; }
        if (isOp('}') || toks[p].t === 'eof') { return; }
        throw AwkError('syntax error near ' + (toks[p].v !== undefined ? toks[p].v : toks[p].t));
      }
      function parseSimpleOrBlock() {
        skipNl();
        if (isOp(';')) { p++; return { t: 'block', stmts: [] }; }
        return parseStmt();
      }
      function parseStmt() {
        var tk = peek();
        if (isOp('{')) { return parseBlock(); }
        if (tk.t === 'kw') {
          switch (tk.v) {
            case 'if': {
              p++; expectOp('(');
              var cond = parseExpr();
              expectOp(')');
              var then = parseSimpleOrBlock();
              var save = p;
              skipTerms();
              if (isKw('else')) { p++; return { t: 'if', cond: cond, then: then, els: parseSimpleOrBlock() }; }
              p = save;
              return { t: 'if', cond: cond, then: then, els: null };
            }
            case 'while': {
              p++; expectOp('(');
              var wc = parseExpr();
              expectOp(')');
              if (isOp(';')) { p++; return { t: 'while', cond: wc, body: { t: 'block', stmts: [] } }; }
              return { t: 'while', cond: wc, body: parseSimpleOrBlock() };
            }
            case 'do': {
              p++;
              var body = parseSimpleOrBlock();
              skipTerms();
              if (!isKw('while')) { throw AwkError('syntax error: expected while'); }
              p++; expectOp('(');
              var dc = parseExpr();
              expectOp(')');
              endStmt();
              return { t: 'do', cond: dc, body: body };
            }
            case 'for': {
              p++; expectOp('(');
              if (toks[p].t === 'name' && toks[p + 1].t === 'kw' && toks[p + 1].v === 'in' && toks[p + 3] && toks[p + 3].t === 'op' && toks[p + 3].v === ')') {
                var v = toks[p].v;
                var arr = toks[p + 2].v;
                p += 4;
                return { t: 'forin', v: v, arr: arr, body: parseSimpleOrBlock() };
              }
              var init = isOp(';') ? null : parseSimple();
              expectOp(';'); skipNl();
              var fc = isOp(';') ? null : parseExpr();
              expectOp(';'); skipNl();
              var incr = isOp(')') ? null : parseSimple();
              expectOp(')');
              return { t: 'for', init: init, cond: fc, incr: incr, body: parseSimpleOrBlock() };
            }
            case 'break': p++; endStmt(); return { t: 'break' };
            case 'continue': p++; endStmt(); return { t: 'continue' };
            case 'next': p++; endStmt(); return { t: 'next' };
            case 'exit': {
              p++;
              var ex = null;
              if (!isOp(';') && !isOp('}') && toks[p].t !== 'nl' && toks[p].t !== 'eof') { ex = parseExpr(); }
              endStmt();
              return { t: 'exit', e: ex };
            }
            case 'return': {
              p++;
              var re = null;
              if (!isOp(';') && !isOp('}') && toks[p].t !== 'nl' && toks[p].t !== 'eof') { re = parseExpr(); }
              endStmt();
              return { t: 'return', e: re };
            }
            case 'delete': {
              p++;
              var an = toks[p++].v;
              var idx = null;
              if (isOp('[')) { p++; idx = parseExprList(); expectOp(']'); }
              endStmt();
              return { t: 'delete', arr: an, idx: idx };
            }
            default: break;
          }
        }
        var st = parseSimple();
        endStmt();
        return st;
      }
      function parseSimple() {
        if (isKw('print') || isKw('printf')) {
          var isPrintf = toks[p].v === 'printf';
          p++;
          var args = [];
          noGt++;
          if (!isOp(';') && !isOp('}') && !isOp('>') && !isOp('>>') && !isOp('|') && toks[p].t !== 'nl' && toks[p].t !== 'eof') {
            args = parseExprList();
          }
          noGt--;
          if (args.length === 1 && args[0].t === 'group' && args[0].list) { args = args[0].list; }
          var dest = null;
          if (isOp('>') || isOp('>>')) {
            var app = toks[p++].v === '>>';
            noGt++;
            var target = parseConcat();
            noGt--;
            dest = { append: app, e: target };
          }
          return { t: isPrintf ? 'printf' : 'print', args: args, dest: dest };
        }
        return { t: 'expr', e: parseExpr() };
      }
      function parseExprList() {
        var list = [parseExpr()];
        while (isOp(',')) { p++; skipNl(); list.push(parseExpr()); }
        return list;
      }
      function parseExpr() { return parseTernary(); }
      function isLvalue(e) { return e.t === 'var' || e.t === 'field' || e.t === 'index'; }
      function parseTernary() {
        var c = parseOr();
        if (isOp('?')) {
          p++; skipNl();
          var a = parseTernary();
          skipNl();
          expectOp(':'); skipNl();
          var b = parseTernary();
          return { t: 'cond', c: c, a: a, b: b };
        }
        if (isLvalue(c)) {
          var tk = peek();
          if (tk.t === 'op' && ['=', '+=', '-=', '*=', '/=', '%=', '^='].indexOf(tk.v) !== -1) {
            p++; skipNl();
            return { t: 'assign', op: tk.v, l: c, r: parseTernary() };
          }
        }
        return c;
      }
      function parseOr() {
        var l = parseAnd();
        while (isOp('||')) { p++; skipNl(); l = { t: 'or', l: l, r: parseAnd() }; }
        return l;
      }
      function parseAnd() {
        var l = parseIn();
        while (isOp('&&')) { p++; skipNl(); l = { t: 'and', l: l, r: parseIn() }; }
        return l;
      }
      function parseIn() {
        var l = parseMatch();
        while (isKw('in') && !noIn) { p++; var an = toks[p++].v; l = { t: 'in', key: l, arr: an }; }
        return l;
      }
      function parseMatch() {
        var l = parseCmp();
        while (isOp('~') || isOp('!~')) {
          var neg = toks[p++].v === '!~';
          l = { t: 'match', l: l, r: parseCmp(), neg: neg };
        }
        return l;
      }
      function parseCmp() {
        var l = parseConcat();
        var tk = peek();
        if (tk.t === 'op' && ['<', '<=', '==', '!=', '>=', '>'].indexOf(tk.v) !== -1 && !(tk.v === '>' && noGt)) {
          p++;
          return { t: 'cmp', op: tk.v, l: l, r: parseConcat() };
        }
        return l;
      }
      function startsOperand() {
        var tk = peek();
        if (tk.t === 'num' || tk.t === 'str' || tk.t === 'name' || tk.t === 'funcname' || tk.t === 'builtin' || tk.t === 'ere') { return true; }
        if (tk.t === 'op' && (tk.v === '$' || tk.v === '(' || tk.v === '!' || tk.v === '-' || tk.v === '+' || tk.v === '++' || tk.v === '--')) {
          return tk.v === '$' || tk.v === '(' || tk.v === '++' || tk.v === '--';
        }
        return false;
      }
      function parseConcat() {
        var l = parseAdd();
        while (startsOperand() && !isKw('in')) { l = { t: 'cat', l: l, r: parseAdd() }; }
        return l;
      }
      function parseAdd() {
        var l = parseMul();
        while (isOp('+') || isOp('-')) { var op = toks[p++].v; l = { t: 'bin', op: op, l: l, r: parseMul() }; }
        return l;
      }
      function parseMul() {
        var l = parseUnary();
        while (isOp('*') || isOp('/') || isOp('%')) { var op = toks[p++].v; l = { t: 'bin', op: op, l: l, r: parseUnary() }; }
        return l;
      }
      function parseUnary() {
        if (isOp('!')) { p++; return { t: 'not', e: parseUnary() }; }
        if (isOp('-')) { p++; return { t: 'neg', e: parseUnary() }; }
        if (isOp('+')) { p++; return { t: 'plus', e: parseUnary() }; }
        return parsePow();
      }
      function parsePow() {
        var base = parsePostfix();
        if (isOp('^')) { p++; return { t: 'bin', op: '^', l: base, r: parseUnaryPow() }; }
        return base;
      }
      function parseUnaryPow() {
        if (isOp('-')) { p++; return { t: 'neg', e: parseUnaryPow() }; }
        if (isOp('+')) { p++; return parseUnaryPow(); }
        var b = parsePostfix();
        if (isOp('^')) { p++; return { t: 'bin', op: '^', l: b, r: parseUnaryPow() }; }
        return b;
      }
      function parsePostfix() {
        var e = parsePrimary();
        if (isLvalue(e) && (isOp('++') || isOp('--'))) { var op = toks[p++].v; return { t: 'postinc', op: op, l: e }; }
        return e;
      }
      function parsePrimary() {
        var tk = toks[p];
        if (tk.t === 'num') { p++; return { t: 'num', v: tk.v }; }
        if (tk.t === 'str') { p++; return { t: 'str', v: tk.v }; }
        if (tk.t === 'ere') { p++; return { t: 'ere', v: tk.v }; }
        if (tk.t === 'op') {
          if (tk.v === '$') { p++; return { t: 'field', e: parseFieldIndex() }; }
          if (tk.v === '(') {
            p++;
            var save = noIn; noIn = 0;
            var saveGt = noGt; noGt = 0;
            var list = parseExprList();
            noIn = save; noGt = saveGt;
            expectOp(')');
            if (list.length > 1) { return { t: 'group', list: list }; }
            return { t: 'group', e: list[0], list: null };
          }
          if (tk.v === '++' || tk.v === '--') {
            p++;
            var target = parsePrimary();
            return { t: 'preinc', op: tk.v, l: target };
          }
          if (tk.v === '-') { p++; return { t: 'neg', e: parsePow() }; }
          if (tk.v === '!') { p++; return { t: 'not', e: parsePow() }; }
        }
        if (tk.t === 'builtin') {
          p++;
          var args = [];
          if (isOp('(')) {
            p++;
            var s1 = noIn; noIn = 0; var s2 = noGt; noGt = 0;
            if (!isOp(')')) { args = parseExprList(); }
            noIn = s1; noGt = s2;
            expectOp(')');
          } else if (tk.v !== 'length') { throw AwkError('syntax error: ' + tk.v + ' needs arguments'); }
          return { t: 'builtin', name: tk.v, args: args };
        }
        if (tk.t === 'funcname') {
          p++; expectOp('(');
          var fargs = [];
          var s3 = noIn; noIn = 0; var s4 = noGt; noGt = 0;
          if (!isOp(')')) { fargs = parseExprList(); }
          noIn = s3; noGt = s4;
          expectOp(')');
          return { t: 'call', name: tk.v, args: fargs };
        }
        if (tk.t === 'name') {
          p++;
          if (isOp('[')) { p++; var idx = parseExprList(); expectOp(']'); return { t: 'index', name: tk.v, idx: idx }; }
          return { t: 'var', name: tk.v };
        }
        throw AwkError('syntax error near ' + (tk.v !== undefined ? tk.v : tk.t));
      }
      function parseFieldIndex() {
        if (isOp('$')) { p++; return { t: 'field', e: parseFieldIndex() }; }
        if (isOp('++') || isOp('--')) { var op = toks[p++].v; return { t: 'preinc', op: op, l: parsePrimary() }; }
        if (isOp('-')) { p++; return { t: 'neg', e: parseFieldIndex() }; }
        var prim = parsePrimary();
        return prim;
      }
    }

    /* ----- formatting ----- */
    function sprintf(fmt, args) {
      var ai = 0;
      return fmt.replace(/%([-+ #0]*)(\*|\d+)?(?:\.(\*|\d+))?([a-zA-Z%])/g, function (m, flags, width, prec, conv) {
        if (conv === '%') { return '%'; }
        if (width === '*') { width = String(toNum(args[ai++])); }
        if (prec === '*') { prec = String(toNum(args[ai++])); }
        var arg = args[ai++];
        var left = flags.indexOf('-') !== -1;
        var zero = flags.indexOf('0') !== -1 && !left;
        var plus = flags.indexOf('+') !== -1;
        var space = flags.indexOf(' ') !== -1;
        var s;
        switch (conv) {
          case 'd': case 'i': {
            var nv = Math.trunc(toNum(arg));
            if (!isFinite(nv)) { nv = 0; }
            s = String(Math.abs(nv));
            if (prec !== undefined) { while (s.length < +prec) { s = '0' + s; } }
            s = (nv < 0 ? '-' : plus ? '+' : space ? ' ' : '') + s;
            break;
          }
          case 'o': s = (Math.trunc(toNum(arg)) >>> 0).toString(8); break;
          case 'x': s = (Math.trunc(toNum(arg)) >>> 0).toString(16); if (flags.indexOf('#') !== -1) { s = '0x' + s; } break;
          case 'X': s = (Math.trunc(toNum(arg)) >>> 0).toString(16).toUpperCase(); break;
          case 'u': s = String(Math.trunc(toNum(arg)) >>> 0); break;
          case 'c': s = typeof arg === 'number' || isStrnum(arg) ? String.fromCharCode(toNum(arg)) : toStr(arg).charAt(0); break;
          case 's': s = toStr(arg); if (prec !== undefined) { s = s.slice(0, +prec); } break;
          case 'e': case 'E': {
            var ev2 = toNum(arg);
            s = ev2.toExponential(prec === undefined ? 6 : +prec).replace(/e([+-])(\d)$/, 'e$10$2');
            if (conv === 'E') { s = s.toUpperCase(); }
            if (ev2 >= 0 && plus) { s = '+' + s; }
            break;
          }
          case 'f': case 'F': {
            var fv = toNum(arg);
            s = fv.toFixed(prec === undefined ? 6 : +prec);
            if (fv >= 0 && plus) { s = '+' + s; } else if (fv >= 0 && space) { s = ' ' + s; }
            break;
          }
          case 'g': case 'G': {
            var gv = toNum(arg);
            s = fmtG(gv, prec === undefined ? 6 : +prec);
            if (conv === 'G') { s = s.toUpperCase(); }
            if (gv >= 0 && plus) { s = '+' + s; }
            break;
          }
          default: return m;
        }
        var w = width === undefined ? 0 : +width;
        if (s.length < w) {
          if (left) { s = s + ' '.repeat(w - s.length); }
          else if (zero && conv !== 's' && conv !== 'c') {
            var sign = /^[+-]/.test(s) ? s.charAt(0) : '';
            s = sign + '0'.repeat(w - s.length) + s.slice(sign.length);
          } else { s = ' '.repeat(w - s.length) + s; }
        }
        return s;
      });
    }

    /* ----- interpreter ----- */
    // opts: {fs, vars:{}, files:[{name,text}], stdin, readFile(name), out(text), err(text), write(name,text,append)}
    function run(prog, opts) {
      var G = Object.create(null);
      var arrays = Object.create(null);
      var fields = [];
      var rec = '';
      var nf = 0;
      var funcs = prog.funcs;
      var outBuf = [];
      var files = {};
      var rangeState = prog.rules.map(function () { return false; });
      var rx = {};
      var srandSeed = 0;

      G.FS = opts.fs === undefined ? ' ' : opts.fs;
      G.OFS = ' ';
      G.ORS = '\n';
      G.SUBSEP = '\x1c';
      G.NR = 0;
      G.FNR = 0;
      G.CONVFMT = '%.6g';
      G.RSTART = 0;
      G.RLENGTH = -1;
      G.FILENAME = '';
      Object.keys(opts.vars || {}).forEach(function (k) { G[k] = strnum(opts.vars[k]); });

      function regexFor(src, isLiteral) {
        var key = src;
        if (!rx[key]) { rx[key] = makeRegex(src, 'ere', ''); }
        return rx[key];
      }
      function flush() { if (outBuf.length) { opts.out(outBuf.join('')); outBuf = []; } }
      function emit(s) { outBuf.push(s); if (outBuf.length > 512) { flush(); } }

      function splitRecord(text) {
        var fs = toStr(G.FS);
        var parts;
        if (fs === ' ') { parts = text.replace(/^[ \t\n]+|[ \t\n]+$/g, ''); parts = parts === '' ? [] : parts.split(/[ \t\n]+/); }
        else if (text === '') { parts = []; }
        else if (fs === '') { parts = Array.from(text); }
        else if (fs.length === 1 && fs !== '\\') { parts = text.split(fs); }
        else if (fs === '\\t') { parts = text.split('\t'); }
        else { parts = text.split(regexFor(fs)); }
        return parts;
      }
      function setRecord(text) {
        rec = text;
        fields = splitRecord(text).map(strnum);
        nf = fields.length;
      }
      function getField(i) {
        i = Math.floor(i);
        if (i < 0) { throw AwkError('attempt to access field ' + i); }
        if (i === 0) { return strnum(rec); }
        return i <= nf ? fields[i - 1] : undefined;
      }
      function rebuild() { rec = fields.map(toStr).join(toStr(G.OFS)); }
      function setField(i, val) {
        i = Math.floor(i);
        if (i === 0) { setRecord(toStr(val)); return; }
        while (nf < i) { fields.push(''); nf++; }
        fields[i - 1] = typeof val === 'number' ? val : strnum(toStr(val));
        rebuild();
      }
      function getArr(name, locals) {
        if (locals && Object.prototype.hasOwnProperty.call(locals, name) && locals[name] && locals[name].__arr) { return locals[name].__arr; }
        if (locals && Object.prototype.hasOwnProperty.call(locals, name)) {
          if (locals[name] === undefined) { locals[name] = { __arr: Object.create(null) }; return locals[name].__arr; }
        }
        return arrays[name] || (arrays[name] = Object.create(null));
      }
      function keyOf(idx, locals) {
        return idx.map(function (e) { return toStr(evalE(e, locals)); }).join(toStr(G.SUBSEP));
      }

      var BREAK = { b: 1 }, CONTINUE = { c: 1 }, NEXT = { n: 1 };
      function ExitSignal(code) { this.code = code; }
      function ReturnSignal(v) { this.v = v; }

      function lookup(name, locals) {
        if (locals && Object.prototype.hasOwnProperty.call(locals, name)) { return locals[name]; }
        return G[name];
      }
      function assignVar(name, val, locals) {
        if (locals && Object.prototype.hasOwnProperty.call(locals, name)) { locals[name] = val; return; }
        G[name] = val;
        if (name === 'NF') {
          var n = Math.max(0, Math.floor(toNum(val)));
          while (fields.length < n) { fields.push(''); }
          fields.length = n;
          nf = n;
          rebuild();
        }
      }
      function assignTo(l, val, locals) {
        if (l.t === 'var') { assignVar(l.name, val, locals); }
        else if (l.t === 'field') { setField(toNum(evalE(l.e, locals)), val); }
        else { getArr(l.name, locals)[keyOf(l.idx, locals)] = val; }
      }
      function readLv(l, locals) {
        if (l.t === 'var') {
          if (l.name === 'NF') { return nf; }
          return lookup(l.name, locals);
        }
        if (l.t === 'field') { return getField(toNum(evalE(l.e, locals))); }
        return getArr(l.name, locals)[keyOf(l.idx, locals)];
      }

      function doSub(args, locals, global) {
        var re = regexFor(args[0].t === 'ere' ? args[0].v : toStr(evalE(args[0], locals)));
        var repl = toStr(evalE(args[1], locals));
        var target = args[2] || { t: 'field', e: { t: 'num', v: 0 } };
        var s = toStr(readLv(target, locals));
        var count = 0;
        var gre = new RegExp(re.source, 'g' + re.flags.replace('g', ''));
        var out = '';
        var pos = 0;
        var m;
        while ((m = gre.exec(s)) !== null) {
          out += s.slice(pos, m.index);
          out += repl.replace(/\\\\|\\&|&/g, function (x) { return x === '&' ? m[0] : x === '\\&' ? '&' : '\\'; });
          pos = m.index + m[0].length;
          count++;
          if (m[0] === '') {
            if (m.index < s.length) { out += s.charAt(m.index); }
            pos = m.index + 1;
            gre.lastIndex = m.index + 1;
          }
          if (!global) { break; }
        }
        if (count) {
          out += s.slice(Math.min(pos, s.length));
          assignTo(target, out, locals);
        }
        return count;
      }

      function callBuiltin(e, locals) {
        var a = e.args;
        function arg(i) { return evalE(a[i], locals); }
        switch (e.name) {
          case 'length':
            if (!a.length) { return rec.length; }
            if (a[0].t === 'var' && arrays[a[0].name] && !(locals && a[0].name in locals && !locals[a[0].name].__arr)) {
              return Object.keys(arrays[a[0].name]).length;
            }
            return toStr(arg(0)).length;
          case 'substr': {
            var s = toStr(arg(0));
            var m = Math.round(toNum(arg(1)));
            var len = a.length > 2 ? Math.round(toNum(arg(2))) : Infinity;
            var start = Math.max(m, 1);
            var end = a.length > 2 ? start + len : Infinity;
            if (isNaN(end)) { return ''; }
            return end <= start ? '' : s.slice(start - 1, end === Infinity ? undefined : end - 1);
          }
          case 'index': return toStr(arg(0)).indexOf(toStr(arg(1))) + 1;
          case 'split': {
            var str = toStr(arg(0));
            var arrName = a[1].name;
            var sep = a.length > 2 ? (a[2].t === 'ere' ? { re: a[2].v } : toStr(arg(2))) : toStr(G.FS);
            var parts;
            if (typeof sep === 'object') { parts = str === '' ? [] : str.split(regexFor(sep.re)); }
            else if (sep === ' ') { var tr = str.replace(/^[ \t\n]+|[ \t\n]+$/g, ''); parts = tr === '' ? [] : tr.split(/[ \t\n]+/); }
            else if (str === '') { parts = []; }
            else if (sep === '') { parts = Array.from(str); }
            else if (sep.length === 1) { parts = str.split(sep); }
            else { parts = str.split(regexFor(sep)); }
            var target = getArr(arrName, locals);
            Object.keys(target).forEach(function (k) { delete target[k]; });
            parts.forEach(function (x, i) { target[String(i + 1)] = strnum(x); });
            return parts.length;
          }
          case 'sub': return doSub(a, locals, false);
          case 'gsub': return doSub(a, locals, true);
          case 'match': {
            var ms = toStr(arg(0));
            var mre = regexFor(a[1].t === 'ere' ? a[1].v : toStr(arg(1)));
            var mm = mre.exec(ms);
            if (mm) { G.RSTART = mm.index + 1; G.RLENGTH = mm[0].length; } else { G.RSTART = 0; G.RLENGTH = -1; }
            return G.RSTART;
          }
          case 'tolower': return toStr(arg(0)).toLowerCase();
          case 'toupper': return toStr(arg(0)).toUpperCase();
          case 'sprintf': return sprintf(toStr(arg(0)), a.slice(1).map(function (x) { return evalE(x, locals); }));
          case 'int': return Math.trunc(toNum(arg(0)));
          case 'sqrt': return Math.sqrt(toNum(arg(0)));
          case 'exp': return Math.exp(toNum(arg(0)));
          case 'log': return Math.log(toNum(arg(0)));
          case 'sin': return Math.sin(toNum(arg(0)));
          case 'cos': return Math.cos(toNum(arg(0)));
          case 'atan2': return Math.atan2(toNum(arg(0)), toNum(arg(1)));
          case 'rand': srandSeed = (srandSeed * 1103515245 + 12345) & 0x7fffffff; return (srandSeed % 1000003) / 1000003;
          case 'srand': { var prev = srandSeed; srandSeed = a.length ? toNum(arg(0)) : 0; return prev; }
          default: throw AwkError(e.name + ' is not available in the page terminal');
        }
      }

      function evalE(e, locals) {
        switch (e.t) {
          case 'num': return e.v;
          case 'str': return e.v;
          case 'ere': return regexFor(e.v).test(rec) ? 1 : 0;
          case 'group': return e.list ? e.list.map(function (x) { return toStr(evalE(x, locals)); }).join(toStr(G.SUBSEP)) : evalE(e.e, locals);
          case 'var': return e.name === 'NF' ? nf : lookup(e.name, locals);
          case 'field': return getField(toNum(evalE(e.e, locals)));
          case 'index': return getArr(e.name, locals)[keyOf(e.idx, locals)];
          case 'assign': {
            var val;
            if (e.op === '=') { val = evalE(e.r, locals); if (isStrnum(val)) { val = { s: val.s, n: val.n }; } }
            else {
              var cur = toNum(readLv(e.l, locals));
              var rv = toNum(evalE(e.r, locals));
              switch (e.op) {
                case '+=': val = cur + rv; break;
                case '-=': val = cur - rv; break;
                case '*=': val = cur * rv; break;
                case '/=': if (rv === 0) { throw AwkError('division by zero in /='); } val = cur / rv; break;
                case '%=': val = cur % rv; break;
                default: val = Math.pow(cur, rv);
              }
            }
            assignTo(e.l, val, locals);
            return val;
          }
          case 'cond': return toBool(evalE(e.c, locals)) ? evalE(e.a, locals) : evalE(e.b, locals);
          case 'or': return toBool(evalE(e.l, locals)) || toBool(evalE(e.r, locals)) ? 1 : 0;
          case 'and': return toBool(evalE(e.l, locals)) && toBool(evalE(e.r, locals)) ? 1 : 0;
          case 'in': return Object.prototype.hasOwnProperty.call(getArr(e.arr, locals), toStr(evalE(e.key, locals))) ? 1 : 0;
          case 'match': {
            var s = toStr(evalE(e.l, locals));
            var r = e.r.t === 'ere' ? regexFor(e.r.v) : regexFor(toStr(evalE(e.r, locals)));
            var res = r.test(s);
            return (e.neg ? !res : res) ? 1 : 0;
          }
          case 'cmp': {
            var c = compare(evalE(e.l, locals), evalE(e.r, locals));
            switch (e.op) {
              case '<': return c < 0 ? 1 : 0;
              case '<=': return c <= 0 ? 1 : 0;
              case '==': return c === 0 ? 1 : 0;
              case '!=': return c !== 0 ? 1 : 0;
              case '>=': return c >= 0 ? 1 : 0;
              default: return c > 0 ? 1 : 0;
            }
          }
          case 'cat': return toStr(evalE(e.l, locals)) + toStr(evalE(e.r, locals));
          case 'bin': {
            var x = toNum(evalE(e.l, locals));
            var y = toNum(evalE(e.r, locals));
            switch (e.op) {
              case '+': return x + y;
              case '-': return x - y;
              case '*': return x * y;
              case '/': if (y === 0) { throw AwkError('division by zero'); } return x / y;
              case '%': if (y === 0) { throw AwkError('division by zero in %'); } return x % y;
              default: return Math.pow(x, y);
            }
          }
          case 'not': return toBool(evalE(e.e, locals)) ? 0 : 1;
          case 'neg': return -toNum(evalE(e.e, locals));
          case 'plus': return toNum(evalE(e.e, locals));
          case 'preinc': {
            var nv = toNum(readLv(e.l, locals)) + (e.op === '++' ? 1 : -1);
            assignTo(e.l, nv, locals);
            return nv;
          }
          case 'postinc': {
            var old = toNum(readLv(e.l, locals));
            assignTo(e.l, old + (e.op === '++' ? 1 : -1), locals);
            return old;
          }
          case 'builtin': return callBuiltin(e, locals);
          case 'call': {
            var f = funcs[e.name];
            if (!f) { throw AwkError('calling undefined function ' + e.name); }
            var loc = {};
            f.params.forEach(function (pn, i) {
              if (i < e.args.length) {
                var ae = e.args[i];
                if (ae.t === 'var' && (arrays[ae.name] || (locals && locals[ae.name] && locals[ae.name].__arr))) {
                  loc[pn] = { __arr: getArr(ae.name, locals) };
                } else { loc[pn] = evalE(ae, locals); }
              } else { loc[pn] = undefined; }
            });
            try { execS(f.body, loc); } catch (sig) { if (sig instanceof ReturnSignal) { return sig.v; } throw sig; }
            return undefined;
          }
          default: throw AwkError('cannot evaluate ' + e.t);
        }
      }

      function outTarget(dest, locals) {
        var name = toStr(evalE(dest.e, locals));
        return name;
      }
      function writeOut(dest, text, locals) {
        if (!dest) { emit(text); return; }
        var name = outTarget(dest, locals);
        if (name === '/dev/stdout' || name === '-') { emit(text); return; }
        if (name === '/dev/stderr') { opts.err(text); return; }
        var first = !files[name];
        files[name] = true;
        opts.write(name, text, dest.append || !first);
      }

      function execS(s, locals) {
        switch (s.t) {
          case 'block': for (var i = 0; i < s.stmts.length; i++) { execS(s.stmts[i], locals); } return;
          case 'expr': evalE(s.e, locals); return;
          case 'print': {
            var line = s.args.length ? s.args.map(function (x) { return toStrOut(evalE(x, locals)); }).join(toStr(G.OFS)) : toStr(rec);
            writeOut(s.dest, line + toStr(G.ORS), locals);
            return;
          }
          case 'printf': {
            var vals = s.args.map(function (x) { return evalE(x, locals); });
            writeOut(s.dest, sprintf(toStr(vals[0]), vals.slice(1)), locals);
            return;
          }
          case 'if':
            if (toBool(evalE(s.cond, locals))) { execS(s.then, locals); } else if (s.els) { execS(s.els, locals); }
            return;
          case 'while':
            while (toBool(evalE(s.cond, locals))) {
              try { execS(s.body, locals); } catch (sig) { if (sig === BREAK) { break; } if (sig !== CONTINUE) { throw sig; } }
            }
            return;
          case 'do':
            do {
              try { execS(s.body, locals); } catch (sig) { if (sig === BREAK) { break; } if (sig !== CONTINUE) { throw sig; } }
            } while (toBool(evalE(s.cond, locals)));
            return;
          case 'for':
            if (s.init) { execS(s.init, locals); }
            while (!s.cond || toBool(evalE(s.cond, locals))) {
              try { execS(s.body, locals); } catch (sig) { if (sig === BREAK) { break; } if (sig !== CONTINUE) { throw sig; } }
              if (s.incr) { execS(s.incr, locals); }
            }
            return;
          case 'forin': {
            var arr = getArr(s.arr, locals);
            var keys = Object.keys(arr);
            for (var k = 0; k < keys.length; k++) {
              assignVar(s.v, strnum(keys[k]), locals);
              try { execS(s.body, locals); } catch (sig) { if (sig === BREAK) { break; } if (sig !== CONTINUE) { throw sig; } }
            }
            return;
          }
          case 'break': throw BREAK;
          case 'continue': throw CONTINUE;
          case 'next': throw NEXT;
          case 'exit': throw new ExitSignal(s.e ? toNum(evalE(s.e, locals)) : null);
          case 'return': throw new ReturnSignal(s.e ? evalE(s.e, locals) : undefined);
          case 'delete': {
            var a2 = getArr(s.arr, locals);
            if (s.idx) { delete a2[keyOf(s.idx, locals)]; } else { Object.keys(a2).forEach(function (kk) { delete a2[kk]; }); }
            return;
          }
          default: throw AwkError('cannot execute ' + s.t);
        }
      }
      function toStrOut(v) {
        if (typeof v === 'number' && !Number.isInteger(v)) { return fmtG(v, 6); }
        return toStr(v);
      }

      var exitCode = 0;
      var exiting = false;
      function runRules(blocks) {
        for (var i = 0; i < blocks.length; i++) { execS(blocks[i], null); }
      }
      function matchRule(rule, idx) {
        if (!rule.pat) { return true; }
        if (!rule.pat2) { return toBool(evalE(rule.pat, null)); }
        if (!rangeState[idx]) {
          if (toBool(evalE(rule.pat, null))) {
            rangeState[idx] = !toBool(evalE(rule.pat2, null));
            return true;
          }
          return false;
        }
        if (toBool(evalE(rule.pat2, null))) { rangeState[idx] = false; }
        return true;
      }
      try {
        try {
          runRules(prog.begin);
        } catch (sig) {
          if (sig instanceof ExitSignal) { exiting = true; if (sig.code !== null) { exitCode = sig.code; } } else { throw sig; }
        }
        if (!exiting && (prog.rules.length || prog.end.length)) {
          var sources = opts.files.length ? opts.files : [{ name: '', text: opts.stdin || '' }];
          outer:
          for (var fi = 0; fi < sources.length; fi++) {
            var src = sources[fi];
            if (src.error) { opts.err('awk: cannot open "' + src.name + '" (No such file or directory)\n'); exitCode = 2; continue; }
            G.FILENAME = src.name;
            G.FNR = 0;
            var lines = splitLines(src.text);
            for (var li = 0; li < lines.length; li++) {
              G.NR = toNum(G.NR) + 1;
              G.FNR = toNum(G.FNR) + 1;
              setRecord(lines[li]);
              try {
                for (var ri = 0; ri < prog.rules.length; ri++) {
                  var rule = prog.rules[ri];
                  if (!matchRule(rule, ri)) { continue; }
                  if (rule.action) { execS(rule.action, null); }
                  else { emit(rec + toStr(G.ORS)); }
                }
              } catch (sig) {
                if (sig === NEXT) { continue; }
                if (sig instanceof ExitSignal) { exiting = true; if (sig.code !== null) { exitCode = sig.code; } break outer; }
                throw sig;
              }
            }
          }
        }
        try {
          if (!(exiting && false)) { runRules(prog.end); }
        } catch (sig) {
          if (sig instanceof ExitSignal) { if (sig.code !== null) { exitCode = sig.code; } } else { throw sig; }
        }
      } finally {
        flush();
      }
      return exitCode;
    }

    return { parse: parseProgram, run: run, unescape: unescapeStr, AwkError: AwkError };
  })();

  /* ---------- sed ---------- */
  var Sed = (function () {
    function SedError(msg) { var e = new Error(msg); e.sed = true; return e; }

    function parseScript(script, ere) {
      var cmds = [];
      var i = 0;
      var n = script.length;
      function skipWs() { while (i < n && /[ \t]/.test(script.charAt(i))) { i++; } }
      function readDelimited(delim) {
        var out = '';
        while (i < n && script.charAt(i) !== delim) {
          if (script.charAt(i) === '\\' && i + 1 < n) {
            if (script.charAt(i + 1) === delim) { out += delim; i += 2; continue; }
            out += script.substr(i, 2);
            i += 2;
            continue;
          }
          out += script.charAt(i);
          i++;
        }
        if (i >= n) { throw SedError('unterminated `s\' command'); }
        i++;
        return out;
      }
      function readAddr() {
        var c = script.charAt(i);
        if (/\d/.test(c)) {
          var m = /^\d+/.exec(script.slice(i));
          i += m[0].length;
          return { n: parseInt(m[0], 10) };
        }
        if (c === '$') { i++; return { last: true }; }
        if (c === '/' || c === '\\') {
          var delim = '/';
          if (c === '\\') { i++; delim = script.charAt(i); }
          i++;
          var re = readDelimited(delim);
          var flags = '';
          while (script.charAt(i) === 'I' || script.charAt(i) === 'i') { flags += 'i'; i++; }
          return { re: makeRegex(re, ere ? 'ere' : 'bre', flags) };
        }
        return null;
      }
      while (i < n) {
        while (i < n && /[\s;]/.test(script.charAt(i))) { i++; }
        if (i >= n) { break; }
        var cmd = { a1: null, a2: null, neg: false };
        cmd.a1 = readAddr();
        if (cmd.a1 && script.charAt(i) === ',') { i++; cmd.a2 = readAddr(); if (!cmd.a2) { throw SedError('unexpected `,\''); } }
        skipWs();
        if (script.charAt(i) === '!') { cmd.neg = true; i++; skipWs(); }
        var c = script.charAt(i++);
        cmd.c = c;
        if (c === 's') {
          var delim2 = script.charAt(i++);
          var pat = readDelimited(delim2);
          var repl = readDelimited(delim2);
          var flags2 = '';
          cmd.g = false; cmd.p = false; cmd.nth = 0;
          for (;;) {
            var f = script.charAt(i);
            if (f === 'g') { cmd.g = true; i++; }
            else if (f === 'p') { cmd.p = true; i++; }
            else if (f === 'i' || f === 'I') { flags2 += 'i'; i++; }
            else if (/\d/.test(f)) { var mm = /^\d+/.exec(script.slice(i)); cmd.nth = parseInt(mm[0], 10); i += mm[0].length; }
            else { break; }
          }
          cmd.re = makeRegex(pat, ere ? 'ere' : 'bre', flags2 + 'g');
          cmd.repl = repl;
        } else if (c === 'y') {
          var d3 = script.charAt(i++);
          var from = readDelimited(d3);
          var to = readDelimited(d3);
          if (from.length !== to.length) { throw SedError('strings for `y\' command are different lengths'); }
          cmd.from = from; cmd.to = to;
        } else if ('pdq=Dn'.indexOf(c) !== -1) { /* no arguments */ }
        else if (c === '{' || c === '}') { throw SedError('blocks ({ }) are not supported in the page terminal'); }
        else { throw SedError('unknown command: `' + c + '\''); }
        cmds.push(cmd);
      }
      return cmds;
    }

    function expandRepl(repl, m) {
      var out = '';
      for (var i = 0; i < repl.length; i++) {
        var c = repl.charAt(i);
        if (c === '\\' && i + 1 < repl.length) {
          var d = repl.charAt(++i);
          if (/[0-9]/.test(d)) { out += d === '0' ? m[0] : (m[+d] === undefined ? '' : m[+d]); }
          else if (d === 'n') { out += '\n'; }
          else if (d === 't') { out += '\t'; }
          else { out += d; }
        } else if (c === '&') { out += m[0]; }
        else { out += c; }
      }
      return out;
    }

    // returns {out, quit}; lines processed from text
    function run(cmds, text, opts) {
      var lines = splitLines(text);
      var out = [];
      var active = cmds.map(function () { return false; });
      var total = lines.length;
      for (var li = 0; li < total; li++) {
        var ln = li + 1;
        var space = lines[li];
        var deleted = false;
        var quit = false;
        for (var ci = 0; ci < cmds.length; ci++) {
          var cmd = cmds[ci];
          var sel;
          if (!cmd.a1) { sel = true; }
          else if (!cmd.a2) { sel = matchAddr(cmd.a1, space, ln, total); }
          else {
            if (active[ci]) {
              sel = true;
              if (cmd.a2.n !== undefined ? ln >= cmd.a2.n : (cmd.a2.last ? ln === total : cmd.a2.re.test(space))) { active[ci] = false; }
            } else if (matchAddr(cmd.a1, space, ln, total)) {
              sel = true;
              var endNow = cmd.a2.n !== undefined ? ln >= cmd.a2.n : (cmd.a2.last ? ln === total : false);
              active[ci] = !endNow;
            } else { sel = false; }
          }
          if (cmd.neg) { sel = !sel; }
          if (!sel) { continue; }
          switch (cmd.c) {
            case 's': {
              var count = 0;
              var replaced = false;
              var res = space.replace(new RegExp(cmd.re.source, cmd.re.flags), function () {
                var args = Array.prototype.slice.call(arguments);
                var groups = args.slice(0, args.findIndex(function (a) { return typeof a === 'number'; }));
                count++;
                if (cmd.nth && count !== cmd.nth && !(cmd.g && count > cmd.nth)) { return groups[0]; }
                if (!cmd.g && !cmd.nth && count > 1) { return groups[0]; }
                if (!cmd.g && cmd.nth && count > cmd.nth) { return groups[0]; }
                replaced = true;
                return expandRepl(cmd.repl, groups);
              });
              if (replaced) {
                space = res;
                if (cmd.p) { out.push(space); }
              }
              break;
            }
            case 'p': out.push(space); break;
            case 'd': deleted = true; break;
            case 'q': quit = true; break;
            case '=': out.push(String(ln)); break;
            case 'y': {
              var chars = Array.from(space);
              space = chars.map(function (ch) { var k = cmd.from.indexOf(ch); return k === -1 ? ch : cmd.to.charAt(k); }).join('');
              break;
            }
            default: break;
          }
          if (deleted || quit) { break; }
        }
        if (!deleted && !opts.quiet) { out.push(space); }
        if (quit) { break; }
      }
      return joinLines(out);
    }
    function matchAddr(a, space, ln, total) {
      if (a.n !== undefined) { return ln === a.n; }
      if (a.last) { return ln === total; }
      return a.re.test(space);
    }
    return { parse: parseScript, run: run, SedError: SedError };
  })();
