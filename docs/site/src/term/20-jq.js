
  /* ---------- jq ----------
   * A jq 1.7 subset: full filter grammar (pipes, comma, alternatives, paths,
   * assignment, reduce/foreach, if/try, def, string interpolation, @formats)
   * and the common builtins. Evaluation is generator based. */
  var Jq = (function () {
    function JqError(v) { this.value = v; }
    function jerr(msg) { return new JqError(msg); }

    function typeOf(v) {
      if (v === null) { return 'null'; }
      if (Array.isArray(v)) { return 'array'; }
      return typeof v;
    }
    var TYPE_RANK = { 'null': 0, 'boolean': 2, 'number': 3, 'string': 4, 'array': 5, 'object': 6 };
    function rank(v) {
      if (v === false) { return 1; }
      return TYPE_RANK[typeOf(v)];
    }
    function cmp(a, b) {
      var ra = rank(a), rb = rank(b);
      if (ra !== rb) { return ra < rb ? -1 : 1; }
      var t = typeOf(a);
      if (t === 'number') { return a < b ? -1 : a > b ? 1 : 0; }
      if (t === 'string') { return a < b ? -1 : a > b ? 1 : 0; }
      if (t === 'array') {
        for (var i = 0; i < a.length && i < b.length; i++) {
          var c = cmp(a[i], b[i]);
          if (c) { return c; }
        }
        return a.length < b.length ? -1 : a.length > b.length ? 1 : 0;
      }
      if (t === 'object') {
        var ka = Object.keys(a).sort(), kb = Object.keys(b).sort();
        var kc = cmp(ka, kb);
        if (kc) { return kc; }
        for (var j = 0; j < ka.length; j++) {
          var vc = cmp(a[ka[j]], b[ka[j]]);
          if (vc) { return vc; }
        }
      }
      return 0;
    }
    function truthy(v) { return v !== null && v !== false; }

    /* ----- lexer ----- */
    var KEYWORDS = { 'def': 1, 'if': 1, 'then': 1, 'elif': 1, 'else': 1, 'end': 1, 'as': 1, 'reduce': 1,
      'foreach': 1, 'try': 1, 'catch': 1, 'and': 1, 'or': 1, 'label': 1, '__loc__': 1 };
    function lex(src) {
      var toks = [];
      var i = 0;
      var n = src.length;
      function stringLit() {
        // at opening quote; returns {parts}
        var parts = [];
        var cur = '';
        i++;
        while (i < n && src.charAt(i) !== '"') {
          var c = src.charAt(i);
          if (c === '\\') {
            var d = src.charAt(i + 1);
            i += 2;
            if (d === '(') {
              var depth = 1;
              var start = i;
              while (i < n && depth > 0) {
                var ch = src.charAt(i);
                if (ch === '"') { stringLit(); continue; }
                if (ch === '(') { depth++; } else if (ch === ')') { depth--; }
                i++;
              }
              parts.push(cur); cur = '';
              parts.push({ interp: src.slice(start, i - 1) });
              continue;
            }
            var map = { n: '\n', t: '\t', r: '\r', b: '\b', f: '\f', '/': '/', '\\': '\\', '"': '"' };
            if (d === 'u') {
              cur += String.fromCharCode(parseInt(src.slice(i, i + 4), 16));
              i += 4;
            } else if (map.hasOwnProperty(d)) { cur += map[d]; }
            else { throw jerr('invalid escape \\' + d); }
            continue;
          }
          cur += c;
          i++;
        }
        if (i >= n) { throw jerr('unterminated string'); }
        i++;
        parts.push(cur);
        return parts;
      }
      while (i < n) {
        var c = src.charAt(i);
        if (/\s/.test(c)) { i++; continue; }
        if (c === '#') { while (i < n && src.charAt(i) !== '\n') { i++; } continue; }
        if (c === '"') { toks.push({ t: 'str', parts: stringLit() }); continue; }
        var m;
        if ((m = /^(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/.exec(src.slice(i))) && !(c === '.' && !/\d/.test(src.charAt(i + 1)))) {
          toks.push({ t: 'num', v: parseFloat(m[0]) });
          i += m[0].length;
          continue;
        }
        if (c === '.' && src.charAt(i + 1) === '.') { toks.push({ t: 'op', v: '..' }); i += 2; continue; }
        if (c === '.' && (m = /^\.([A-Za-z_][A-Za-z0-9_]*)/.exec(src.slice(i)))) {
          toks.push({ t: 'field', v: m[1] });
          i += m[0].length;
          continue;
        }
        if (c === '.' && src.charAt(i + 1) === '"') {
          i++;
          toks.push({ t: 'fieldstr', parts: stringLit() });
          continue;
        }
        if (c === '$' && (m = /^\$((?:[A-Za-z_][A-Za-z0-9_]*::)*[A-Za-z_][A-Za-z0-9_]*)/.exec(src.slice(i)))) {
          toks.push({ t: 'var', v: m[1] });
          i += m[0].length;
          continue;
        }
        if (c === '@' && (m = /^@[A-Za-z0-9_]+/.exec(src.slice(i)))) {
          toks.push({ t: 'fmt', v: m[0] });
          i += m[0].length;
          continue;
        }
        if ((m = /^[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*/.exec(src.slice(i)))) {
          toks.push({ t: 'id', v: m[0] });
          i += m[0].length;
          continue;
        }
        var three = src.substr(i, 3);
        var two = src.substr(i, 2);
        if (three === '?//' || three === '//=') { toks.push({ t: 'op', v: three }); i += 3; continue; }
        if (['==', '!=', '<=', '>=', '//', '|=', '+=', '-=', '*=', '/=', '%='].indexOf(two) !== -1) {
          toks.push({ t: 'op', v: two }); i += 2; continue;
        }
        if ('.[](){}|,:;=<>+-*/%?'.indexOf(c) !== -1) { toks.push({ t: 'op', v: c }); i++; continue; }
        throw jerr('syntax error: unexpected character ' + JSON.stringify(c));
      }
      toks.push({ t: 'eof' });
      return toks;
    }

    /* ----- parser ----- */
    function parse(src) {
      var toks = lex(src);
      var p = 0;
      function peek() { return toks[p]; }
      function isOp(v) { return toks[p].t === 'op' && toks[p].v === v; }
      function isId(v) { return toks[p].t === 'id' && toks[p].v === v; }
      function expectOp(v) {
        if (!isOp(v)) { throw jerr('syntax error: expected ' + v); }
        p++;
      }
      function expectId(v) {
        if (!isId(v)) { throw jerr('syntax error: expected ' + v); }
        p++;
      }
      function strNode(parts, fmt) {
        var out = parts.map(function (x) {
          if (typeof x === 'string') { return x; }
          return parse(x.interp);
        });
        if (out.length === 1 && typeof out[0] === 'string') { return { t: 'lit', v: out[0] }; }
        return { t: 'strinterp', parts: out, fmt: fmt || null };
      }

      function parsePipe(noComma) {
        if (isId('def')) {
          var def = parseDef();
          var rest = parsePipe(noComma);
          return { t: 'defs', def: def, body: rest };
        }
        var lhs = noComma ? parseAlt() : parseComma();
        if (isId('as')) {
          p++;
          var pats = [parsePattern()];
          while (isOp('?//')) { p++; pats.push(parsePattern()); }
          expectOp('|');
          var body = parsePipe(noComma);
          return { t: 'as', src: lhs, pats: pats, body: body };
        }
        if (isOp('|')) {
          p++;
          return { t: 'pipe', l: lhs, r: parsePipe(noComma) };
        }
        return lhs;
      }
      function parsePattern() {
        if (peek().t === 'var') { return { t: 'pvar', name: toks[p++].v }; }
        if (isOp('[')) {
          p++;
          var items = [parsePattern()];
          while (isOp(',')) { p++; items.push(parsePattern()); }
          expectOp(']');
          return { t: 'parr', items: items };
        }
        if (isOp('{')) {
          p++;
          var ents = [];
          do {
            if (isOp(',')) { p++; }
            var key;
            var tk = peek();
            if (tk.t === 'var') { p++; key = { v: tk.v, var: true }; }
            else if (tk.t === 'id') { p++; key = { lit: tk.v }; }
            else if (tk.t === 'str') { p++; key = { node: strNode(tk.parts) }; }
            else if (isOp('(')) { p++; key = { node: parsePipe() }; expectOp(')'); }
            else { throw jerr('syntax error in object pattern'); }
            var val = null;
            if (isOp(':')) { p++; val = parsePattern(); }
            ents.push({ key: key, val: val });
          } while (isOp(','));
          expectOp('}');
          return { t: 'pobj', ents: ents };
        }
        throw jerr('syntax error in pattern');
      }
      function parseDef() {
        expectId('def');
        var name = toks[p++].v;
        var params = [];
        if (isOp('(')) {
          p++;
          do {
            if (isOp(';')) { p++; }
            var tk = toks[p++];
            params.push(tk.t === 'var' ? '$' + tk.v : tk.v);
          } while (isOp(';'));
          expectOp(')');
        }
        expectOp(':');
        var body = parsePipe();
        expectOp(';');
        return { name: name, params: params, body: body };
      }
      function parseComma() {
        var l = parseAlt();
        while (isOp(',')) { p++; l = { t: 'comma', l: l, r: parseAlt() }; }
        return l;
      }
      function parseAlt() {
        var l = parseAssign();
        if (isOp('//')) { p++; return { t: 'alt', l: l, r: parseAlt() }; }
        return l;
      }
      function parseAssign() {
        var l = parseOr();
        var tk = peek();
        if (tk.t === 'op' && ['=', '|=', '+=', '-=', '*=', '/=', '%=', '//='].indexOf(tk.v) !== -1) {
          p++;
          var r = parseAlt();
          return { t: 'assign', op: tk.v, l: l, r: r };
        }
        return l;
      }
      function parseOr() {
        var l = parseAnd();
        while (isId('or')) { p++; l = { t: 'or', l: l, r: parseAnd() }; }
        return l;
      }
      function parseAnd() {
        var l = parseCmp();
        while (isId('and')) { p++; l = { t: 'and', l: l, r: parseCmp() }; }
        return l;
      }
      function parseCmp() {
        var l = parseAdd();
        var tk = peek();
        if (tk.t === 'op' && ['==', '!=', '<', '<=', '>', '>='].indexOf(tk.v) !== -1) {
          p++;
          return { t: 'bin', op: tk.v, l: l, r: parseAdd() };
        }
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
        if (isOp('-')) { p++; return { t: 'neg', e: parseUnary() }; }
        return parsePostfix();
      }
      function parsePostfix() {
        var t = parsePrimary();
        for (;;) {
          var tk = peek();
          if (tk.t === 'field') { p++; t = { t: 'index', target: t, idx: { t: 'lit', v: tk.v } }; continue; }
          if (tk.t === 'fieldstr') { p++; t = { t: 'index', target: t, idx: strNode(tk.parts) }; continue; }
          if (isOp('.') && toks[p + 1].t === 'str') { p++; t = { t: 'index', target: t, idx: strNode(toks[p++].parts) }; continue; }
          if (isOp('.') && toks[p + 1].t === 'op' && toks[p + 1].v === '[') { p++; continue; }
          if (isOp('[')) {
            p++;
            if (isOp(']')) { p++; t = { t: 'iter', target: t }; continue; }
            if (isOp(':')) {
              p++;
              var to = parsePipe();
              expectOp(']');
              t = { t: 'slice', target: t, from: null, to: to };
              continue;
            }
            var idx = parsePipe();
            if (isOp(':')) {
              p++;
              var to2 = isOp(']') ? null : parsePipe();
              expectOp(']');
              t = { t: 'slice', target: t, from: idx, to: to2 };
              continue;
            }
            expectOp(']');
            t = { t: 'index', target: t, idx: idx };
            continue;
          }
          if (isOp('?')) { p++; t = { t: 'try', body: t, handler: null }; continue; }
          if (isId('as') ) { break; }
          break;
        }
        return t;
      }
      function parsePrimary() {
        var tk = toks[p];
        if (tk.t === 'num') { p++; return { t: 'lit', v: tk.v }; }
        if (tk.t === 'str') { p++; return strNode(tk.parts); }
        if (tk.t === 'fmt') {
          p++;
          if (peek().t === 'str') { var s = toks[p++]; return strNode(s.parts, tk.v); }
          return { t: 'format', name: tk.v };
        }
        if (tk.t === 'field') { p++; return { t: 'index', target: { t: 'id' }, idx: { t: 'lit', v: tk.v } }; }
        if (tk.t === 'fieldstr') { p++; return { t: 'index', target: { t: 'id' }, idx: strNode(tk.parts) }; }
        if (tk.t === 'var') { p++; return { t: 'var', name: tk.v }; }
        if (tk.t === 'op') {
          if (tk.v === '.') {
            p++;
            if (peek().t === 'str') { return { t: 'index', target: { t: 'id' }, idx: strNode(toks[p++].parts) }; }
            return { t: 'id' };
          }
          if (tk.v === '..') { p++; return { t: 'call', name: 'recurse', args: [] }; }
          if (tk.v === '(') { p++; var e = parsePipe(); expectOp(')'); return { t: 'paren', e: e }; }
          if (tk.v === '[') {
            p++;
            if (isOp(']')) { p++; return { t: 'arr', e: null }; }
            var inner = parsePipe();
            expectOp(']');
            return { t: 'arr', e: inner };
          }
          if (tk.v === '{') { return parseObject(); }
          if (tk.v === '-') { p++; return { t: 'neg', e: parsePostfix() }; }
        }
        if (tk.t === 'id') {
          var name = tk.v;
          if (name === 'if') { return parseIf(); }
          if (name === 'try') {
            p++;
            var body = parsePostfixNoTry();
            var handler = null;
            if (isId('catch')) { p++; handler = parsePostfixNoTry(); }
            return { t: 'try', body: body, handler: handler };
          }
          if (name === 'reduce') {
            p++;
            var src = parsePostfix();
            expectId('as');
            var pat = parsePattern();
            expectOp('(');
            var init = parsePipe();
            expectOp(';');
            var upd = parsePipe();
            expectOp(')');
            return { t: 'reduce', src: src, pat: pat, init: init, upd: upd };
          }
          if (name === 'foreach') {
            p++;
            var fsrc = parsePostfix();
            expectId('as');
            var fpat = parsePattern();
            expectOp('(');
            var finit = parsePipe();
            expectOp(';');
            var fupd = parsePipe();
            var fext = null;
            if (isOp(';')) { p++; fext = parsePipe(); }
            expectOp(')');
            return { t: 'foreach', src: fsrc, pat: fpat, init: finit, upd: fupd, ext: fext };
          }
          if (name === 'def') {
            var d = parseDef();
            return { t: 'defs', def: d, body: parsePipe() };
          }
          if (name === 'true') { p++; return { t: 'lit', v: true }; }
          if (name === 'false') { p++; return { t: 'lit', v: false }; }
          if (name === 'null') { p++; return { t: 'lit', v: null }; }
          if (KEYWORDS[name]) { throw jerr('syntax error: unexpected ' + name); }
          p++;
          var args = [];
          if (isOp('(')) {
            p++;
            do {
              if (isOp(';')) { p++; }
              args.push(parsePipe());
            } while (isOp(';'));
            expectOp(')');
          }
          return { t: 'call', name: name, args: args };
        }
        throw jerr('syntax error: unexpected ' + (tk.t === 'eof' ? 'end of input' : tk.v || tk.t));
      }
      function parsePostfixNoTry() {
        // body of try/catch binds a postfix term
        var save = parsePostfix();
        return save;
      }
      function parseIf() {
        expectId('if');
        var cond = parsePipe();
        expectId('then');
        var then = parsePipe();
        var els = null;
        if (isId('elif')) {
          toks[p] = { t: 'id', v: 'if' };
          els = parseIf();
          return { t: 'if', cond: cond, then: then, els: els };
        }
        if (isId('else')) { p++; els = parsePipe(); }
        expectId('end');
        return { t: 'if', cond: cond, then: then, els: els };
      }
      function parseObject() {
        expectOp('{');
        var ents = [];
        if (isOp('}')) { p++; return { t: 'obj', ents: ents }; }
        for (;;) {
          var tk = toks[p];
          var key;
          var val = null;
          if (tk.t === 'var') { p++; key = { t: 'lit', v: tk.v }; val = { t: 'var', name: tk.v }; }
          else if (tk.t === 'id') { p++; key = { t: 'lit', v: tk.v }; }
          else if (tk.t === 'num') { p++; key = { t: 'lit', v: String(tk.v) }; }
          else if (tk.t === 'str') { p++; key = strNode(tk.parts); }
          else if (tk.t === 'fmt' && toks[p + 1].t === 'str') { p++; key = strNode(toks[p++].parts, tk.v); }
          else if (isOp('(')) { p++; key = parsePipe(); expectOp(')'); }
          else { throw jerr('syntax error in object construction'); }
          if (isOp(':')) {
            p++;
            val = parseObjVal();
          } else if (!val) {
            val = { t: 'index', target: { t: 'id' }, idx: key };
          }
          ents.push({ k: key, v: val });
          if (isOp(',')) { p++; continue; }
          break;
        }
        expectOp('}');
        return { t: 'obj', ents: ents };
      }
      function parseObjVal() {
        var l = parseAlt();
        while (isOp('|')) { p++; l = { t: 'pipe', l: l, r: parseAlt() }; }
        return l;
      }

      var ast = parsePipe();
      if (peek().t !== 'eof') { throw jerr('syntax error: unexpected ' + (peek().v || peek().t)); }
      return ast;
    }

    /* ----- environments ----- */
    function Env(parent) { this.parent = parent; this.vars = null; this.funcs = null; }
    Env.prototype.child = function () { return new Env(this); };
    Env.prototype.getVar = function (n) {
      for (var e = this; e; e = e.parent) { if (e.vars && n in e.vars) { return e.vars[n]; } }
      throw jerr('$' + n + ' is not defined');
    };
    Env.prototype.setVar = function (n, v) { (this.vars = this.vars || {})[n] = v; };
    Env.prototype.getFunc = function (key) {
      for (var e = this; e; e = e.parent) { if (e.funcs && key in e.funcs) { return e.funcs[key]; } }
      return null;
    };
    Env.prototype.setFunc = function (key, f) { (this.funcs = this.funcs || {})[key] = f; };

    /* ----- helpers ----- */
    function tostr(v) { return typeof v === 'string' ? v : toJSON(v); }
    function toJSON(v, indent) {
      return stringify(v, indent === undefined ? '' : indent, false, '');
    }
    function esc(s) { return JSON.stringify(s); }
    function stringify(v, indent, sortKeys, cur) {
      if (v === null) { return 'null'; }
      var t = typeof v;
      if (t === 'number') { return isFinite(v) ? String(v) : (v !== v ? 'null' : (v > 0 ? '1.7976931348623157e+308' : '-1.7976931348623157e+308')); }
      if (t === 'boolean') { return String(v); }
      if (t === 'string') { return esc(v); }
      var inner = indent ? cur + indent : '';
      var nl = indent ? '\n' : '';
      if (Array.isArray(v)) {
        if (!v.length) { return '[]'; }
        return '[' + nl + v.map(function (x) { return inner + stringify(x, indent, sortKeys, inner); }).join(',' + nl) + nl + cur + ']';
      }
      var keys = Object.keys(v);
      if (sortKeys) { keys.sort(); }
      if (!keys.length) { return '{}'; }
      return '{' + nl + keys.map(function (k) {
        return inner + esc(k) + (indent ? ': ' : ':') + stringify(v[k], indent, sortKeys, inner);
      }).join(',' + nl) + nl + cur + '}';
    }

    function arith(op, a, b) {
      switch (op) {
        case '+':
          if (a === null) { return b; }
          if (b === null) { return a; }
          if (typeof a === 'number' && typeof b === 'number') { return a + b; }
          if (typeof a === 'string' && typeof b === 'string') { return a + b; }
          if (Array.isArray(a) && Array.isArray(b)) { return a.concat(b); }
          if (typeOf(a) === 'object' && typeOf(b) === 'object') { return Object.assign({}, a, b); }
          break;
        case '-':
          if (typeof a === 'number' && typeof b === 'number') { return a - b; }
          if (Array.isArray(a) && Array.isArray(b)) {
            return a.filter(function (x) { return !b.some(function (y) { return cmp(x, y) === 0; }); });
          }
          break;
        case '*':
          if (typeof a === 'number' && typeof b === 'number') { return a * b; }
          if (typeof a === 'string' && typeof b === 'number') { return b > 0 ? new Array(Math.ceil(b)).fill(a).join('') : null; }
          if (typeof a === 'number' && typeof b === 'string') { return a > 0 ? new Array(Math.ceil(a)).fill(b).join('') : null; }
          if (typeOf(a) === 'object' && typeOf(b) === 'object') { return deepMerge(a, b); }
          break;
        case '/':
          if (typeof a === 'number' && typeof b === 'number') {
            if (b === 0) { throw jerr(describe(a) + ' and ' + describe(b) + ' cannot be divided because the divisor is zero'); }
            return a / b;
          }
          if (typeof a === 'string' && typeof b === 'string') { return a.split(b); }
          break;
        case '%':
          if (typeof a === 'number' && typeof b === 'number') {
            var bi = Math.trunc(b);
            if (bi === 0) { throw jerr(describe(a) + ' and ' + describe(b) + ' cannot be divided because the divisor is zero'); }
            var r = Math.trunc(a) % bi;
            return r === 0 ? 0 : r;
          }
          break;
        default: break;
      }
      var verb = { '+': 'added', '-': 'subtracted', '*': 'multiplied', '/': 'divided', '%': 'divided' }[op];
      throw jerr(describe(a) + ' and ' + describe(b) + ' cannot be ' + verb);
    }
    function deepMerge(a, b) {
      var out = Object.assign({}, a);
      Object.keys(b).forEach(function (k) {
        out[k] = typeOf(out[k]) === 'object' && typeOf(b[k]) === 'object' ? deepMerge(out[k], b[k]) : b[k];
      });
      return out;
    }
    function describe(v) {
      var s = toJSON(v);
      if (s.length > 11) { s = s.slice(0, 10) + '...'; }
      return typeOf(v) + ' (' + s + ')';
    }

    function getIndex(v, k) {
      var tv = typeOf(v), tk = typeOf(k);
      if (tv === 'object' && tk === 'string') { return Object.prototype.hasOwnProperty.call(v, k) ? v[k] : null; }
      if (tv === 'array' && tk === 'number') {
        var i = Math.floor(k);
        if (i < 0) { i += v.length; }
        return i >= 0 && i < v.length ? v[i] : null;
      }
      if (tv === 'null' && (tk === 'string' || tk === 'number' || tk === 'null')) { return null; }
      if (tv === 'array' && tk === 'array') { return indicesOf(v, k); }
      if (tv === 'array' && tk === 'object') { return sliceOf(v, k.start, k.end); }
      if (tk === 'string') { throw jerr('Cannot index ' + tv + ' with "' + k + '"'); }
      throw jerr('Cannot index ' + tv + ' with ' + tk);
    }
    function sliceOf(v, from, to) {
      if (v === null) { return null; }
      if (typeof v !== 'string' && !Array.isArray(v)) { throw jerr('Cannot index ' + typeOf(v) + ' with object'); }
      var len = v.length;
      var a = from === null || from === undefined ? 0 : Math.floor(from);
      var b = to === null || to === undefined ? len : Math.ceil(to);
      if (a < 0) { a += len; }
      if (b < 0) { b += len; }
      a = Math.max(0, Math.min(len, a));
      b = Math.max(a, Math.min(len, b));
      return typeof v === 'string' ? Array.from(v).slice(a, b).join('') : v.slice(a, b);
    }
    function indicesOf(v, k) {
      var out = [];
      if (typeof v === 'string') {
        if (k === '') { return null; }
        var pos = v.indexOf(k);
        while (pos !== -1) { out.push(pos); pos = v.indexOf(k, pos + 1); }
        return out;
      }
      if (!Array.isArray(k)) {
        v.forEach(function (x, i) { if (cmp(x, k) === 0) { out.push(i); } });
        return out;
      }
      if (!k.length) { return null; }
      for (var i = 0; i + k.length <= v.length; i++) {
        var ok = true;
        for (var j = 0; j < k.length; j++) { if (cmp(v[i + j], k[j]) !== 0) { ok = false; break; } }
        if (ok) { out.push(i); }
      }
      return out;
    }

    function getpath(v, path) {
      for (var i = 0; i < path.length; i++) {
        if (v === null) { return null; }
        v = getIndex(v, path[i]);
      }
      return v;
    }
    function setpath(v, path, nv) {
      if (!path.length) { return nv; }
      var k = path[0];
      var rest = path.slice(1);
      var tk = typeOf(k);
      if (tk === 'string') {
        if (v !== null && typeOf(v) !== 'object') { throw jerr('Cannot index ' + typeOf(v) + ' with "' + k + '"'); }
        var o = Object.assign({}, v || {});
        o[k] = setpath(o.hasOwnProperty(k) ? o[k] : null, rest, nv);
        return o;
      }
      if (tk === 'number') {
        if (v !== null && !Array.isArray(v)) { throw jerr('Cannot index ' + typeOf(v) + ' with number'); }
        var a = (v || []).slice();
        var i = Math.floor(k);
        if (i < 0) { i += a.length; if (i < 0) { throw jerr('Out of bounds negative array index'); } }
        while (a.length <= i) { a.push(null); }
        a[i] = setpath(a[i], rest, nv);
        return a;
      }
      if (tk === 'object') {
        var arr = (v || []).slice();
        var s = k.start === null || k.start === undefined ? 0 : k.start;
        var e = k.end === null || k.end === undefined ? arr.length : k.end;
        var cur = sliceOf(arr, s, e);
        var repl = setpath(cur, rest, nv);
        if (!Array.isArray(repl)) { throw jerr('A slice of an array can only be assigned another array'); }
        var s2 = s < 0 ? s + arr.length : s;
        var e2 = e < 0 ? e + arr.length : e;
        arr.splice(Math.max(0, s2), Math.max(0, e2 - Math.max(0, s2)));
        Array.prototype.splice.apply(arr, [Math.max(0, s2), 0].concat(repl));
        return arr;
      }
      throw jerr('Invalid path component ' + toJSON(k));
    }
    function delpaths(v, paths) {
      paths = paths.slice().sort(cmp).reverse();
      paths.forEach(function (p) { v = delpath(v, p); });
      return v;
    }
    function delpath(v, path) {
      if (!path.length) { return null; }
      if (v === null) { return null; }
      var k = path[0];
      if (path.length === 1) {
        if (Array.isArray(v) && typeof k === 'number') {
          var i = k < 0 ? k + v.length : k;
          return v.filter(function (x, j) { return j !== i; });
        }
        if (typeOf(v) === 'object' && typeof k === 'string') {
          var o = Object.assign({}, v);
          delete o[k];
          return o;
        }
        if (Array.isArray(v) && typeOf(k) === 'object') {
          var s = k.start === null || k.start === undefined ? 0 : k.start;
          var e = k.end === null || k.end === undefined ? v.length : k.end;
          if (s < 0) { s += v.length; }
          if (e < 0) { e += v.length; }
          return v.filter(function (x, j) { return j < s || j >= e; });
        }
        throw jerr('Cannot delete field at ' + typeOf(v) + ' index');
      }
      var child = getIndex(v, k);
      if (child === null) { return v; }
      return setpath(v, [k], delpath(child, path.slice(1)));
    }

    function keysOf(v) {
      if (Array.isArray(v)) { return v.map(function (x, i) { return i; }); }
      if (typeOf(v) === 'object') { return Object.keys(v).sort(); }
      throw jerr(describe(v) + ' has no keys');
    }

    /* ----- formats ----- */
    function formatOf(name, v) {
      switch (name) {
        case '@text': return tostr(v);
        case '@json': return toJSON(v);
        case '@html': return tostr(v).replace(/[<>&'"]/g, function (c) {
          return { '<': '&lt;', '>': '&gt;', '&': '&amp;', "'": '&#39;', '"': '&quot;' }[c];
        });
        case '@uri': return encodeURIComponent(tostr(v)).replace(/[!'()*]/g, function (c) {
          return '%' + c.charCodeAt(0).toString(16).toUpperCase();
        });
        case '@csv':
        case '@tsv':
          if (!Array.isArray(v)) { throw jerr(describe(v) + ' cannot be ' + (name === '@csv' ? 'csv' : 'tsv') + '-formatted, only an array can be'); }
          return v.map(function (x) {
            if (x === null) { return ''; }
            if (typeof x === 'boolean') { return String(x); }
            if (typeof x === 'number') { return String(x); }
            if (typeof x === 'string') {
              if (name === '@csv') { return '"' + x.replace(/"/g, '""') + '"'; }
              return x.replace(/\\/g, '\\\\').replace(/\t/g, '\\t').replace(/\n/g, '\\n').replace(/\r/g, '\\r');
            }
            throw jerr(describe(x) + ' is not valid in a csv row');
          }).join(name === '@csv' ? ',' : '\t');
        case '@sh':
          return (Array.isArray(v) ? v : [v]).map(function (x) {
            if (typeof x === 'string') { return "'" + x.replace(/'/g, "'\\''") + "'"; }
            if (typeof x === 'object' && x !== null) { throw jerr(describe(x) + ' can not be escaped for shell'); }
            return toJSON(x);
          }).join(' ');
        case '@base64': return bytesToB64(utf8Encode(tostr(v)));
        case '@base64d': {
          try { return utf8Decode(b64ToBytes(tostr(v).replace(/=+$/, ''))); } catch (e) { throw jerr(describe(v) + ' is not valid base64 data'); }
        }
        default: throw jerr(name.slice(1) + ' is not a valid format');
      }
    }

    /* ----- dates ----- */
    function pad(n, w) { return ('0000' + n).slice(-(w || 2)); }
    function gmtimeOf(secs) {
      var d = new Date(Math.floor(secs) * 1000);
      var start = Date.UTC(d.getUTCFullYear(), 0, 1);
      var yday = Math.floor((d.getTime() - start) / 86400000);
      return [d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), d.getUTCHours(), d.getUTCMinutes(),
        d.getUTCSeconds() + (secs - Math.floor(secs)), d.getUTCDay(), yday];
    }
    function mktimeOf(bt) {
      if (!Array.isArray(bt) || bt.length < 6) { throw jerr('mktime requires array of 6 numbers'); }
      return Math.floor(Date.UTC(bt[0], bt[1], bt[2], bt[3], bt[4], Math.floor(bt[5])) / 1000);
    }
    var DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    var MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    function strftime(v, fmt) {
      var bt = typeof v === 'number' ? gmtimeOf(v) : v;
      if (!Array.isArray(bt)) { throw jerr('strftime/1 requires parsed datetime inputs'); }
      return fmt.replace(/%([a-zA-Z%])/g, function (m, c) {
        switch (c) {
          case 'Y': return String(bt[0]);
          case 'm': return pad(bt[1] + 1);
          case 'd': return pad(bt[2]);
          case 'e': return (' ' + bt[2]).slice(-2);
          case 'H': return pad(bt[3]);
          case 'M': return pad(bt[4]);
          case 'S': return pad(Math.floor(bt[5]));
          case 'Z': return 'UTC';
          case 'z': return '+0000';
          case 'a': return DAYS[bt[6]].slice(0, 3);
          case 'A': return DAYS[bt[6]];
          case 'b': return MONTHS[bt[1]].slice(0, 3);
          case 'B': return MONTHS[bt[1]];
          case 'j': return pad(bt[7] + 1, 3);
          case 's': return String(mktimeOf(bt));
          case 'T': return pad(bt[3]) + ':' + pad(bt[4]) + ':' + pad(Math.floor(bt[5]));
          case 'F': return bt[0] + '-' + pad(bt[1] + 1) + '-' + pad(bt[2]);
          case '%': return '%';
          default: return m;
        }
      });
    }
    function fromIso(s) {
      var m = /^(\d{4})-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(?:\.\d+)?Z$/.exec(s);
      if (!m) { throw jerr('date "' + s + '" does not match format "%Y-%m-%dT%H:%M:%SZ"'); }
      return Math.floor(Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]) / 1000);
    }

    /* ----- regex ----- */
    function jqRegex(re, flags, global) {
      var f = global ? 'g' : '';
      var fl = flags === null || flags === undefined ? '' : flags;
      for (var i = 0; i < fl.length; i++) {
        var c = fl.charAt(i);
        if (c === 'g') { f = f.indexOf('g') === -1 ? f + 'g' : f; }
        else if (c === 'i') { f += 'i'; }
        else if (c === 'x') { re = re.replace(/\s+|#.*$/gm, ''); }
        else if (c === 's') { f += 's'; }
        else if (c === 'n') { /* ignore empty matches: handled by caller */ }
        else if (c === 'l' || c === 'p') { f += 's'; }
        else { throw jerr(fl + ' is not a valid modifier string'); }
      }
      try { return new RegExp(re.replace(/\(\?<([A-Za-z_])/g, '(?<$1'), f); } catch (e) { throw jerr(re + ' (at offset 0) is not a valid regex: ' + e.message); }
    }
    function matchObjects(input, re, flags, testOnly) {
      if (typeof input !== 'string') { throw jerr(describe(input) + ' cannot be matched, as it is not a string'); }
      if (typeof re !== 'string') { throw jerr(describe(re) + ' cannot be matched, as it is not a string'); }
      var global = typeof flags === 'string' && flags.indexOf('g') !== -1;
      var rx = jqRegex(re, flags, true);
      var out = [];
      var m;
      var cps = Array.from(input);
      function cpOffset(strIdx) { return Array.from(input.slice(0, strIdx)).length; }
      while ((m = rx.exec(input)) !== null) {
        var names = m.groups ? Object.keys(m.groups) : [];
        var caps = [];
        for (var gi = 1; gi < m.length; gi++) {
          var nm = null;
          names.forEach(function (n) { if (m.groups[n] === m[gi] && nm === null) { nm = n; } });
          caps.push({ offset: m[gi] === undefined ? -1 : cpOffset(m.index + m[0].indexOf(m[gi])), length: m[gi] === undefined ? 0 : Array.from(m[gi]).length,
            string: m[gi] === undefined ? null : m[gi], name: nm });
        }
        out.push({ offset: cpOffset(m.index), length: Array.from(m[0]).length, string: m[0], captures: caps });
        if (testOnly || !global) { break; }
        if (m[0] === '') { rx.lastIndex++; }
      }
      void cps;
      return out;
    }

    /* ----- evaluator ----- */
    var LIMIT_STEPS = 5000000;
    var steps = 0;
    function tick() { if (++steps > LIMIT_STEPS) { throw jerr('jq: step limit exceeded'); } }

    function* ev(ast, v, env) {
      tick();
      switch (ast.t) {
        case 'id': yield v; return;
        case 'lit': yield ast.v; return;
        case 'paren': yield* ev(ast.e, v, env); return;
        case 'var':
          if (ast.name === 'ENV') { yield Object.assign({}, env.getVarOr('ENV', {})); return; }
          yield env.getVar(ast.name); return;
        case 'neg':
          for (var nv of ev(ast.e, v, env)) {
            if (typeof nv !== 'number') { throw jerr(describe(nv) + ' cannot be negated'); }
            yield -nv;
          }
          return;
        case 'pipe':
          for (var a of ev(ast.l, v, env)) { yield* ev(ast.r, a, env); }
          return;
        case 'comma':
          yield* ev(ast.l, v, env);
          yield* ev(ast.r, v, env);
          return;
        case 'index':
          for (var tgt of ev(ast.target, v, env)) {
            for (var ix of ev(ast.idx, v, env)) {
              yield getIndex(tgt, ix);
            }
          }
          return;
        case 'slice':
          for (var st of ev(ast.target, v, env)) {
            var froms = ast.from ? Array.from(ev(ast.from, v, env)) : [null];
            var tos = ast.to ? Array.from(ev(ast.to, v, env)) : [null];
            for (var tt of tos) { for (var ff of froms) { yield sliceOf(st, ff, tt); } }
          }
          return;
        case 'iter':
          for (var it of ev(ast.target, v, env)) {
            if (Array.isArray(it)) { yield* it; }
            else if (typeOf(it) === 'object') { for (var k in it) { if (Object.prototype.hasOwnProperty.call(it, k)) { yield it[k]; } } }
            else { throw jerr('Cannot iterate over ' + (it === null ? 'null' : typeOf(it) + ' (' + toJSON(it) + ')')); }
          }
          return;
        case 'arr':
          yield ast.e ? Array.from(ev(ast.e, v, env)) : [];
          return;
        case 'obj': {
          var results = [{}];
          for (var ent of ast.ents) {
            var next = [];
            var keys = Array.from(ev(ent.k, v, env));
            for (var base of results) {
              for (var kk of keys) {
                if (typeof kk !== 'string') { throw jerr('Object keys must be strings'); }
                for (var vv of ev(ent.v, v, env)) {
                  var o = Object.assign({}, base);
                  o[kk] = vv;
                  next.push(o);
                }
              }
            }
            results = next;
          }
          yield* results;
          return;
        }
        case 'strinterp': {
          var combos = [''];
          for (var part of ast.parts) {
            if (typeof part === 'string') { combos = combos.map(function (c) { return c + part; }); continue; }
            var vals = Array.from(ev(part, v, env));
            var nx = [];
            vals.forEach(function (val) {
              combos.forEach(function (c) {
                nx.push(c + (ast.fmt ? formatOf(ast.fmt, val) : tostr(val)));
              });
            });
            combos = nx;
          }
          yield* combos;
          return;
        }
        case 'format': yield formatOf(ast.name, v); return;
        case 'bin': {
          for (var r of ev(ast.r, v, env)) {
            for (var l of ev(ast.l, v, env)) {
              switch (ast.op) {
                case '==': yield cmp(l, r) === 0; break;
                case '!=': yield cmp(l, r) !== 0; break;
                case '<': yield cmp(l, r) < 0; break;
                case '<=': yield cmp(l, r) <= 0; break;
                case '>': yield cmp(l, r) > 0; break;
                case '>=': yield cmp(l, r) >= 0; break;
                default: yield arith(ast.op, l, r);
              }
            }
          }
          return;
        }
        case 'and':
          for (var al of ev(ast.l, v, env)) {
            if (!truthy(al)) { yield false; continue; }
            for (var ar of ev(ast.r, v, env)) { yield truthy(ar); }
          }
          return;
        case 'or':
          for (var ol of ev(ast.l, v, env)) {
            if (truthy(ol)) { yield true; continue; }
            for (var or_ of ev(ast.r, v, env)) { yield truthy(or_); }
          }
          return;
        case 'alt': {
          var any = false;
          try {
            for (var lv of ev(ast.l, v, env)) { if (truthy(lv)) { any = true; yield lv; } }
          } catch (e) { if (!(e instanceof JqError)) { throw e; } }
          if (!any) { yield* ev(ast.r, v, env); }
          return;
        }
        case 'if':
          for (var c of ev(ast.cond, v, env)) {
            if (truthy(c)) { yield* ev(ast.then, v, env); }
            else if (ast.els) { yield* ev(ast.els, v, env); }
            else { yield v; }
          }
          return;
        case 'try':
          try {
            for (var tv of ev(ast.body, v, env)) { yield tv; }
          } catch (e) {
            if (!(e instanceof JqError)) { throw e; }
            if (e.isBreak) { throw e; }
            if (ast.handler) { yield* ev(ast.handler, e.value, env); }
          }
          return;
        case 'as':
          for (var src of ev(ast.src, v, env)) {
            for (var benv of bindPatterns(ast.pats, src, v, env)) { yield* ev(ast.body, v, benv); }
          }
          return;
        case 'reduce': {
          for (var init of ev(ast.init, v, env)) {
            var acc = init;
            for (var rs of ev(ast.src, v, env)) {
              for (var renv of bindPatterns([ast.pat], rs, v, env)) {
                var last = null;
                var has = false;
                for (var u of ev(ast.upd, acc, renv)) { last = u; has = true; }
                acc = has ? last : null;
              }
            }
            yield acc;
          }
          return;
        }
        case 'foreach': {
          for (var finit of ev(ast.init, v, env)) {
            var facc = finit;
            for (var fs of ev(ast.src, v, env)) {
              for (var fenv of bindPatterns([ast.pat], fs, v, env)) {
                for (var fu of ev(ast.upd, facc, fenv)) {
                  facc = fu;
                  if (ast.ext) { yield* ev(ast.ext, fu, fenv); } else { yield fu; }
                }
              }
            }
          }
          return;
        }
        case 'defs': {
          var denv = env.child();
          denv.setFunc(ast.def.name + '/' + ast.def.params.length, { def: ast.def, env: denv });
          yield* ev(ast.body, v, denv);
          return;
        }
        case 'assign': yield* evAssign(ast, v, env); return;
        case 'call': yield* evCall(ast, v, env); return;
        default: throw jerr('unsupported jq construct: ' + ast.t);
      }
    }

    Env.prototype.getVarOr = function (n, d) {
      for (var e = this; e; e = e.parent) { if (e.vars && n in e.vars) { return e.vars[n]; } }
      return d;
    };

    function* bindPatterns(pats, src, ctx, env) {
      if (pats.length === 1) { yield* bindPattern(pats[0], src, ctx, env); return; }
      for (var i = 0; i < pats.length; i++) {
        try {
          var out = Array.from(bindPattern(pats[i], src, ctx, env));
          yield* out;
          return;
        } catch (e) {
          if (!(e instanceof JqError) || i === pats.length - 1) { throw e; }
        }
      }
    }
    function* bindPattern(pat, val, ctx, env) {
      if (pat.t === 'pvar') {
        var e = env.child();
        e.setVar(pat.name, val);
        yield e;
        return;
      }
      if (pat.t === 'parr') {
        if (val !== null && !Array.isArray(val)) { throw jerr('Cannot index ' + typeOf(val) + ' with number'); }
        var envs = [env];
        pat.items.forEach(function (sub, i) {
          var nextEnvs = [];
          envs.forEach(function (en) {
            for (var ne of bindPattern(sub, val === null ? null : (i < val.length ? val[i] : null), ctx, en)) { nextEnvs.push(ne); }
          });
          envs = nextEnvs;
        });
        yield* envs;
        return;
      }
      var cur = [env];
      pat.ents.forEach(function (ent) {
        var next = [];
        cur.forEach(function (en) {
          var keys;
          var baseEnv = en;
          if (ent.key.var) {
            baseEnv = en.child();
            baseEnv.setVar(ent.key.v, getIndex(val, ent.key.v));
            keys = [ent.key.v];
          } else if (ent.key.lit !== undefined) { keys = [ent.key.lit]; }
          else { keys = Array.from(ev(ent.key.node, ctx, en)); }
          keys.forEach(function (k) {
            if (ent.val) { for (var ne of bindPattern(ent.val, getIndex(val, k), ctx, baseEnv)) { next.push(ne); } }
            else { next.push(baseEnv); }
          });
        });
        cur = next;
      });
      yield* cur;
    }

    /* paths: yields [path, value] */
    function* evPaths(ast, pv, env) {
      var path = pv[0];
      var v = pv[1];
      switch (ast.t) {
        case 'id': yield pv; return;
        case 'paren': yield* evPaths(ast.e, pv, env); return;
        case 'pipe':
          for (var a of evPaths(ast.l, pv, env)) { yield* evPaths(ast.r, a, env); }
          return;
        case 'comma':
          yield* evPaths(ast.l, pv, env);
          yield* evPaths(ast.r, pv, env);
          return;
        case 'index':
          for (var tp of evPaths(ast.target, pv, env)) {
            for (var ix of ev(ast.idx, v, env)) { yield [tp[0].concat([ix]), tp[1] === null ? null : getIndex(tp[1], ix)]; }
          }
          return;
        case 'slice':
          for (var sp of evPaths(ast.target, pv, env)) {
            var from = ast.from ? Array.from(ev(ast.from, v, env))[0] : null;
            var to = ast.to ? Array.from(ev(ast.to, v, env))[0] : null;
            yield [sp[0].concat([{ start: from, end: to }]), sliceOf(sp[1], from, to)];
          }
          return;
        case 'iter':
          for (var ip of evPaths(ast.target, pv, env)) {
            var it = ip[1];
            if (Array.isArray(it)) { for (var i = 0; i < it.length; i++) { yield [ip[0].concat([i]), it[i]]; } }
            else if (typeOf(it) === 'object') { for (var k of Object.keys(it)) { yield [ip[0].concat([k]), it[k]]; } }
            else if (it !== null) { throw jerr('Cannot iterate over ' + typeOf(it)); }
          }
          return;
        case 'if':
          for (var c of ev(ast.cond, v, env)) {
            if (truthy(c)) { yield* evPaths(ast.then, pv, env); }
            else if (ast.els) { yield* evPaths(ast.els, pv, env); }
            else { yield pv; }
          }
          return;
        case 'alt': {
          var any = false;
          try {
            for (var lp of evPaths(ast.l, pv, env)) { if (truthy(lp[1])) { any = true; yield lp; } }
          } catch (e) { if (!(e instanceof JqError)) { throw e; } }
          if (!any) { yield* evPaths(ast.r, pv, env); }
          return;
        }
        case 'try':
          try { for (var tq of evPaths(ast.body, pv, env)) { yield tq; } } catch (e) { if (!(e instanceof JqError)) { throw e; } }
          return;
        case 'as':
          for (var src of ev(ast.src, v, env)) {
            for (var benv of bindPatterns(ast.pats, src, v, env)) { yield* evPaths(ast.body, pv, benv); }
          }
          return;
        case 'defs': {
          var denv = env.child();
          denv.setFunc(ast.def.name + '/' + ast.def.params.length, { def: ast.def, env: denv });
          yield* evPaths(ast.body, pv, denv);
          return;
        }
        case 'call': yield* evCallPaths(ast, pv, env); return;
        case 'lit':
          if (ast.v === null) { yield [[], null]; return; }
          throw jerr('Invalid path expression with result ' + toJSON(ast.v));
        default:
          for (var res of ev(ast, v, env)) { throw jerr('Invalid path expression with result ' + toJSON(res)); }
      }
    }

    function* evAssign(ast, v, env) {
      var op = ast.op;
      if (op === '=') {
        for (var rv of ev(ast.r, v, env)) {
          var out = v;
          for (var pp of evPaths(ast.l, [[], v], env)) { out = setpath(out, pp[0], rv); }
          yield out;
        }
        return;
      }
      if (op === '|=') {
        var res = v;
        var paths = Array.from(evPaths(ast.l, [[], v], env)).map(function (x) { return x[0]; });
        var dels = [];
        paths.forEach(function (p) {
          var cur = getpath(res, p);
          var first = ev(ast.r, cur, env).next();
          if (first.done) { dels.push(p); } else { res = setpath(res, p, first.value); }
        });
        if (dels.length) { res = delpaths(res, dels); }
        yield res;
        return;
      }
      var bop = op.slice(0, -1);
      for (var rv2 of ev(ast.r, v, env)) {
        var out2 = v;
        for (var p2 of Array.from(evPaths(ast.l, [[], v], env))) {
          var curv = getpath(out2, p2[0]);
          var nv = bop === '//' ? (truthy(curv) ? curv : rv2) : arith(bop, curv, rv2);
          out2 = setpath(out2, p2[0], nv);
        }
        yield out2;
      }
    }

    /* ----- calls ----- */
    function* evCall(ast, v, env) {
      var key = ast.name + '/' + ast.args.length;
      var f = env.getFunc(key);
      if (f) {
        if (f.closure) { yield* ev(f.closure.ast, v, f.closure.env); return; }
        yield* callDef(f, ast.args, v, env);
        return;
      }
      var native = NATIVE[key];
      if (native) { yield* native(v, ast.args, env); return; }
      var cf = CFUNCS[key];
      if (cf) {
        // cartesian product over argument outputs (last arg varies slowest, as jq)
        var argVals = ast.args.map(function (a) { return Array.from(ev(a, v, env)); });
        var combos = [[]];
        for (var i = argVals.length - 1; i >= 0; i--) {
          var nx = [];
          argVals[i].forEach(function (av) { combos.forEach(function (c) { nx.push([av].concat(c)); }); });
          combos = nx;
        }
        for (var cmb of combos) { yield cf.apply(null, [v].concat(cmb)); }
        return;
      }
      throw jerr(ast.name + '/' + ast.args.length + ' is not defined');
    }
    function* callDef(f, argAsts, v, env) {
      var def = f.def;
      var fenv = f.env.child();
      fenv.setFunc(def.name + '/' + def.params.length, f);
      var valueParams = [];
      def.params.forEach(function (pn, i) {
        if (pn.charAt(0) === '$') {
          valueParams.push({ name: pn.slice(1), ast: argAsts[i] });
          fenv.setFunc(pn.slice(1) + '/0', { closure: { ast: { t: 'var', name: pn.slice(1) }, env: fenv } });
        } else {
          fenv.setFunc(pn + '/0', { closure: { ast: argAsts[i], env: env } });
        }
      });
      if (!valueParams.length) { yield* ev(def.body, v, fenv); return; }
      function* bindVals(idx, e) {
        if (idx === valueParams.length) { yield e; return; }
        for (var val of ev(valueParams[idx].ast, v, env)) {
          var e2 = e.child();
          e2.setVar(valueParams[idx].name, val);
          yield* bindVals(idx + 1, e2);
        }
      }
      for (var be of bindVals(0, fenv)) { yield* ev(def.body, v, be); }
    }
    function* evCallPaths(ast, pv, env) {
      var key = ast.name + '/' + ast.args.length;
      var f = env.getFunc(key);
      var v = pv[1];
      if (f) {
        if (f.closure) { yield* evPaths(f.closure.ast, pv, f.closure.env); return; }
        var def = f.def;
        var fenv = f.env.child();
        fenv.setFunc(key, f);
        def.params.forEach(function (pn, i) {
          if (pn.charAt(0) === '$') { throw jerr('path(): value parameters unsupported'); }
          fenv.setFunc(pn + '/0', { closure: { ast: ast.args[i], env: env } });
        });
        yield* evPaths(def.body, pv, fenv);
        return;
      }
      switch (key) {
        case 'empty/0': return;
        case 'select/1':
          for (var c of ev(ast.args[0], v, env)) { if (truthy(c)) { yield pv; } }
          return;
        case 'recurse/0':
          yield* recursePaths(pv);
          return;
        case 'recurse/1':
          yield* recurseF(ast.args[0], pv, env);
          return;
        case 'first/1': {
          var it = evPaths(ast.args[0], pv, env).next();
          if (!it.done) { yield it.value; }
          return;
        }
        case 'last/1': {
          var lastp = null;
          for (var lp of evPaths(ast.args[0], pv, env)) { lastp = lp; }
          if (lastp) { yield lastp; }
          return;
        }
        case 'getpath/1':
          for (var gp of ev(ast.args[0], v, env)) {
            var cur;
            try { cur = getpath(v, gp); } catch (e) { cur = null; }
            yield [pv[0].concat(gp), cur];
          }
          return;
        case 'error/0': case 'error/1': yield* ev(ast, v, env); return;
        default:
          for (var res of ev(ast, v, env)) { throw jerr('Invalid path expression with result ' + toJSON(res)); }
      }
    }
    function* recursePaths(pv) {
      yield pv;
      var v = pv[1];
      if (Array.isArray(v)) { for (var i = 0; i < v.length; i++) { yield* recursePaths([pv[0].concat([i]), v[i]]); } }
      else if (typeOf(v) === 'object') { for (var k of Object.keys(v)) { yield* recursePaths([pv[0].concat([k]), v[k]]); } }
    }
    function* recurseF(fAst, pv, env) {
      yield pv;
      for (var nx of evPaths(fAst, pv, env)) { yield* recurseF(fAst, nx, env); }
    }
    function* recurseVals(v) {
      yield v;
      if (Array.isArray(v)) { for (var i = 0; i < v.length; i++) { yield* recurseVals(v[i]); } }
      else if (typeOf(v) === 'object') { for (var k of Object.keys(v)) { yield* recurseVals(v[k]); } }
    }

    function sortKeyed(arr, keyFn) {
      return arr.map(function (x, i) { return { x: x, k: keyFn(x), i: i }; })
        .sort(function (a, b) { return cmp(a.k, b.k) || a.i - b.i; });
    }

    var NATIVE = {
      'empty/0': function* () { return; },
      'error/0': function* (v) { throw new JqError(v); },
      'error/1': function* (v, args, env) { for (var m of ev(args[0], v, env)) { throw new JqError(m); } },
      'not/0': function* (v) { yield !truthy(v); },
      'path/1': function* (v, args, env) { for (var p of evPaths(args[0], [[], v], env)) { yield p[0]; } },
      'paths/0': function* (v) { for (var p of recursePaths([[], v])) { if (p[0].length) { yield p[0]; } } },
      'paths/1': function* (v, args, env) {
        for (var p of recursePaths([[], v])) {
          if (!p[0].length) { continue; }
          for (var c of ev(args[0], p[1], env)) { if (truthy(c)) { yield p[0]; } }
        }
      },
      'select/1': function* (v, args, env) { for (var c of ev(args[0], v, env)) { if (truthy(c)) { yield v; } } },
      'recurse/0': function* (v) { yield* recurseVals(v); },
      'recurse/1': function* (v, args, env) { for (var p of recurseF(args[0], [[], v], env)) { yield p[1]; } },
      'recurse/2': function* (v, args, env) {
        function* go(x) {
          yield x;
          for (var n of ev(args[0], x, env)) {
            var ok = false;
            for (var c of ev(args[1], n, env)) { ok = truthy(c); }
            if (ok) { yield* go(n); }
          }
        }
        yield* go(v);
      },
      'map/1': function* (v, args, env) {
        var out = [];
        if (Array.isArray(v)) { v.forEach(function (x) { for (var r of ev(args[0], x, env)) { out.push(r); } }); }
        else if (typeOf(v) === 'object') { Object.keys(v).forEach(function (k) { for (var r of ev(args[0], v[k], env)) { out.push(r); } }); }
        else { throw jerr('Cannot iterate over ' + (v === null ? 'null' : typeOf(v))); }
        yield out;
      },
      'first/1': function* (v, args, env) { var it = ev(args[0], v, env).next(); if (!it.done) { yield it.value; } },
      'last/1': function* (v, args, env) {
        var has = false, l = null;
        for (var x of ev(args[0], v, env)) { has = true; l = x; }
        if (has) { yield l; }
      },
      'limit/2': function* (v, args, env) {
        for (var n of ev(args[0], v, env)) {
          if (n <= 0) { continue; }
          var c = 0;
          for (var x of ev(args[1], v, env)) { yield x; if (++c >= n) { break; } }
        }
      },
      'until/2': function* (v, args, env) {
        function* go(x) {
          for (var c of ev(args[0], x, env)) {
            if (truthy(c)) { yield x; } else { for (var nx of ev(args[1], x, env)) { yield* go(nx); } }
          }
        }
        yield* go(v);
      },
      'while/2': function* (v, args, env) {
        function* go(x) {
          for (var c of ev(args[0], x, env)) {
            if (truthy(c)) { yield x; for (var nx of ev(args[1], x, env)) { yield* go(nx); } }
          }
        }
        yield* go(v);
      },
      'repeat/1': function* (v, args, env) {
        function* go(x) { yield x; for (var nx of ev(args[0], x, env)) { yield* go(nx); } }
        yield* go(v);
      },
      'range/1': function* (v, args, env) { for (var n of ev(args[0], v, env)) { for (var i = 0; i < n; i++) { yield i; } } },
      'range/2': function* (v, args, env) {
        for (var a of ev(args[0], v, env)) { for (var b of ev(args[1], v, env)) { for (var i = a; i < b; i++) { yield i; } } }
      },
      'range/3': function* (v, args, env) {
        for (var a of ev(args[0], v, env)) {
          for (var b of ev(args[1], v, env)) {
            for (var s of ev(args[2], v, env)) {
              if (s > 0) { for (var i = a; i < b; i += s) { yield i; } }
              else if (s < 0) { for (var j = a; j > b; j += s) { yield j; } }
            }
          }
        }
      },
      'isempty/1': function* (v, args, env) { yield ev(args[0], v, env).next().done; },
      'any/2': function* (v, args, env) {
        for (var x of ev(args[0], v, env)) { for (var c of ev(args[1], x, env)) { if (truthy(c)) { yield true; return; } } }
        yield false;
      },
      'all/2': function* (v, args, env) {
        for (var x of ev(args[0], v, env)) { for (var c of ev(args[1], x, env)) { if (!truthy(c)) { yield false; return; } } }
        yield true;
      },
      'any/1': function* (v, args, env) {
        if (!Array.isArray(v) && typeOf(v) !== 'object') { throw jerr('Cannot iterate over ' + typeOf(v)); }
        var vals = Array.isArray(v) ? v : Object.keys(v).map(function (k) { return v[k]; });
        for (var x of vals) { for (var c of ev(args[0], x, env)) { if (truthy(c)) { yield true; return; } } }
        yield false;
      },
      'all/1': function* (v, args, env) {
        var vals = Array.isArray(v) ? v : Object.keys(v).map(function (k) { return v[k]; });
        for (var x of vals) { for (var c of ev(args[0], x, env)) { if (!truthy(c)) { yield false; return; } } }
        yield true;
      },
      'sort_by/1': function* (v, args, env) {
        if (!Array.isArray(v)) { throw jerr(describe(v) + ' cannot be sorted, as it is not an array'); }
        yield sortKeyed(v, function (x) { return Array.from(ev(args[0], x, env)); }).map(function (o) { return o.x; });
      },
      'group_by/1': function* (v, args, env) {
        if (!Array.isArray(v)) { throw jerr('Cannot index ' + typeOf(v) + ' with number'); }
        var sorted = sortKeyed(v, function (x) { return Array.from(ev(args[0], x, env)); });
        var groups = [];
        sorted.forEach(function (o) {
          var last = groups[groups.length - 1];
          if (last && cmp(last.k, o.k) === 0) { last.items.push(o.x); } else { groups.push({ k: o.k, items: [o.x] }); }
        });
        yield groups.map(function (g) { return g.items; });
      },
      'unique_by/1': function* (v, args, env) {
        var sorted = sortKeyed(v, function (x) { return Array.from(ev(args[0], x, env)); });
        var out = [];
        var lastK = null;
        sorted.forEach(function (o, i) { if (i === 0 || cmp(lastK, o.k) !== 0) { out.push(o.x); } lastK = o.k; });
        yield out;
      },
      'min_by/1': function* (v, args, env) {
        var s = sortKeyed(v, function (x) { return Array.from(ev(args[0], x, env)); });
        yield s.length ? s[0].x : null;
      },
      'max_by/1': function* (v, args, env) {
        var s = sortKeyed(v, function (x) { return Array.from(ev(args[0], x, env)); });
        var best = null;
        s.forEach(function (o, i) { if (i === 0 || cmp(o.k, best.k) >= 0) { best = o; } });
        yield best ? best.x : null;
      },
      'with_entries/1': function* (v, args, env) {
        var ents = CFUNCS['to_entries/0'](v);
        var out = [];
        ents.forEach(function (e) { for (var r of ev(args[0], e, env)) { out.push(r); } });
        yield CFUNCS['from_entries/0'](out);
      },
      'del/1': function* (v, args, env) {
        yield delpaths(v, Array.from(evPaths(args[0], [[], v], env)).map(function (p) { return p[0]; }));
      },
      'to_entries/0': function* (v) { yield CFUNCS['to_entries/0'](v); },
      'walk/1': function* (v, args, env) {
        function* w(x) {
          var y;
          if (Array.isArray(x)) {
            y = [];
            for (var e of x) { for (var r of w(e)) { y.push(r); } }
          } else if (typeOf(x) === 'object') {
            y = {};
            for (var k of Object.keys(x)) { for (var r2 of w(x[k])) { y[k] = r2; break; } }
          } else { y = x; }
          yield* ev(args[0], y, env);
        }
        yield* w(v);
      },
      'env/0': function* (v, args, env) { yield env.getVarOr('ENV', {}); },
      'input/0': function* () { throw jerr('No more inputs'); },
      'debug/0': function* (v) { yield v; },
      'debug/1': function* (v) { yield v; },
      'stderr/0': function* (v) { yield v; },
      'input_filename/0': function* () { yield null; },
      'splits/1': function* (v, args, env) {
        for (var re of ev(args[0], v, env)) { yield* CFUNCS['_splits/2'](v, re, null); }
      },
      'splits/2': function* (v, args, env) {
        for (var re of ev(args[0], v, env)) { for (var fl of ev(args[1], v, env)) { yield* CFUNCS['_splits/2'](v, re, fl); } }
      },
      'match/1': function* (v, args, env) { yield* matchGen(v, args, env, false); },
      'match/2': function* (v, args, env) { yield* matchGen(v, args, env, false); },
      'test/1': function* (v, args, env) { yield* matchGen(v, args, env, true); },
      'test/2': function* (v, args, env) { yield* matchGen(v, args, env, true); },
      'capture/1': function* (v, args, env) { for (var m of matchGen(v, args, env, false)) { yield capObj(m); } },
      'capture/2': function* (v, args, env) { for (var m of matchGen(v, args, env, false)) { yield capObj(m); } },
      'scan/1': function* (v, args, env) {
        for (var m of matchGen(v, [args[0], { t: 'lit', v: 'g' }], env, false, v)) {
          yield m.captures.length ? m.captures.map(function (c) { return c.string; }) : m.string;
        }
      },
      'scan/2': function* (v, args, env) {
        for (var m of matchGen(v, [args[0], { t: 'call', name: '_gflags', args: [args[1]] }], env, false, v)) {
          yield m.captures.length ? m.captures.map(function (c) { return c.string; }) : m.string;
        }
      },
      'sub/2': function* (v, args, env) { yield* subGen(v, args, env, null); },
      'sub/3': function* (v, args, env) { yield* subGen(v, args, env, null, true); },
      'gsub/2': function* (v, args, env) { yield* subGen(v, args, env, 'g'); },
      'gsub/3': function* (v, args, env) { yield* subGen(v, args, env, 'g', true); },
      'getpath/1': function* (v, args, env) {
        for (var p of ev(args[0], v, env)) { try { yield getpath(v, p); } catch (e) { yield null; } }
      },
      'ltrimstr/1': function* (v, args, env) {
        for (var s of ev(args[0], v, env)) { yield typeof v === 'string' && typeof s === 'string' && v.indexOf(s) === 0 ? v.slice(s.length) : v; }
      },
      'rtrimstr/1': function* (v, args, env) {
        for (var s of ev(args[0], v, env)) {
          yield typeof v === 'string' && typeof s === 'string' && s !== '' && v.slice(-s.length) === s ? v.slice(0, -s.length) : v;
        }
      },
      'tojson/0': function* (v) { yield toJSON(v); },
      'add/1': function* (v, args, env) {
        var acc = null;
        for (var x of ev(args[0], v, env)) { acc = arith('+', acc, x); }
        yield acc;
      },
      'pick/1': function* (v, args, env) {
        var out = null;
        for (var p of evPaths(args[0], [[], v], env)) { out = setpath(out, p[0], getpath(v, p[0])); }
        yield out;
      },
      'input_line_number/0': function* () { yield 0; },
      'ascii/0': function* (v) { yield String.fromCharCode(v); },
      'halt/0': function* () { var e = new JqError(null); e.halt = true; throw e; },
      'halt_error/0': function* (v) { var e = new JqError(v); e.halt = true; throw e; },
      '_gflags/1': function* (v, args, env) { for (var f of ev(args[0], v, env)) { yield 'g' + (f || ''); } }
    };
    function* matchGen(v, args, env, testOnly, input) {
      var inp = input === undefined ? v : input;
      for (var spec of ev(args[0], v, env)) {
        var re = spec, flags = null;
        if (Array.isArray(spec)) { re = spec[0]; flags = spec.length > 1 ? spec[1] : null; }
        var flagVals = args[1] ? Array.from(ev(args[1], v, env)) : [flags];
        for (var fl of flagVals) {
          var ms = matchObjects(inp, re, fl, testOnly);
          if (testOnly) { yield ms.length > 0; } else { yield* ms; }
        }
      }
    }
    function capObj(m) {
      var o = {};
      m.captures.forEach(function (c) { if (c.name) { o[c.name] = c.string; } });
      return o;
    }
    function* subGen(v, args, env, gflag, hasFlags) {
      if (typeof v !== 'string') { throw jerr(describe(v) + ' cannot be matched, as it is not a string'); }
      for (var re of ev(args[0], v, env)) {
        var flagList = hasFlags ? Array.from(ev(args[2], v, env)) : [null];
        for (var fl of flagList) {
          var flags = (gflag || '') + (fl || '');
          var ms = matchObjects(v, re, flags, false);
          var results = [''];
          var pos = 0;
          var chars = Array.from(v);
          ms.forEach(function (m) {
            var piece = chars.slice(pos, m.offset).join('');
            var cap = capObj(m);
            var repls = Array.from(ev(args[1], cap, env));
            var nx = [];
            repls.forEach(function (rp) {
              if (typeof rp !== 'string') { throw jerr(describe(cap) + ' and ' + describe(rp) + ' cannot be added'); }
              results.forEach(function (r) { nx.push(r + piece + rp); });
            });
            results = nx;
            pos = m.offset + m.length;
          });
          var tail = chars.slice(pos).join('');
          for (var r of results) { yield r + tail; }
        }
      }
    }

    var CFUNCS = {
      'length/0': function (v) {
        if (v === null) { return 0; }
        if (typeof v === 'string') { return Array.from(v).length; }
        if (Array.isArray(v)) { return v.length; }
        if (typeof v === 'number') { return Math.abs(v); }
        if (typeof v === 'object') { return Object.keys(v).length; }
        throw jerr(describe(v) + ' has no length');
      },
      'utf8bytelength/0': function (v) {
        if (typeof v !== 'string') { throw jerr(describe(v) + ' only strings have UTF-8 byte length'); }
        return utf8Encode(v).length;
      },
      'keys/0': function (v) { return keysOf(v); },
      'keys_unsorted/0': function (v) { return Array.isArray(v) ? keysOf(v) : Object.keys(v); },
      'has/1': function (v, k) {
        if (Array.isArray(v) && typeof k === 'number') { return k >= 0 && k < v.length; }
        if (typeOf(v) === 'object' && typeof k === 'string') { return Object.prototype.hasOwnProperty.call(v, k); }
        throw jerr('Cannot check whether ' + typeOf(v) + ' has a ' + (typeof k === 'string' ? 'string' : typeOf(k)) + ' key');
      },
      'in/1': function (v, o) { return CFUNCS['has/1'](o, v); },
      'contains/1': function (v, b) { return contains(v, b); },
      'inside/1': function (v, b) { return contains(b, v); },
      'add/0': function (v) {
        if (v === null) { return null; }
        var list = Array.isArray(v) ? v : (typeOf(v) === 'object' ? Object.keys(v).map(function (k) { return v[k]; }) : null);
        if (list === null) { throw jerr('Cannot iterate over ' + typeOf(v)); }
        return list.reduce(function (a, x) { return arith('+', a, x); }, null);
      },
      'type/0': function (v) { return typeOf(v); },
      'tostring/0': function (v) { return tostr(v); },
      'tonumber/0': function (v) {
        if (typeof v === 'number') { return v; }
        if (typeof v === 'string' && v.trim() !== '' && !isNaN(Number(v))) { return Number(v); }
        throw jerr('Cannot parse ' + (typeof v === 'string' ? '"' + v + '"' : describe(v)) + ' as number');
      },
      'ascii_downcase/0': function (v) {
        if (typeof v !== 'string') { throw jerr('ascii_downcase input must be a string'); }
        return v.replace(/[A-Z]/g, function (c) { return c.toLowerCase(); });
      },
      'ascii_upcase/0': function (v) {
        if (typeof v !== 'string') { throw jerr('ascii_upcase input must be a string'); }
        return v.replace(/[a-z]/g, function (c) { return c.toUpperCase(); });
      },
      'startswith/1': function (v, s) {
        if (typeof v !== 'string' || typeof s !== 'string') { throw jerr('startswith() requires string inputs'); }
        return v.indexOf(s) === 0;
      },
      'endswith/1': function (v, s) {
        if (typeof v !== 'string' || typeof s !== 'string') { throw jerr('endswith() requires string inputs'); }
        return s === '' || v.slice(-s.length) === s;
      },
      'trim/0': function (v) { return String(v).trim(); },
      'ltrim/0': function (v) { return String(v).replace(/^\s+/, ''); },
      'rtrim/0': function (v) { return String(v).replace(/\s+$/, ''); },
      'split/1': function (v, s) {
        if (typeof v !== 'string' || typeof s !== 'string') { throw jerr('split input and separator must be strings'); }
        return v === '' ? [] : v.split(s);
      },
      'split/2': function (v, re, fl) {
        var out = [];
        var pos = 0;
        var chars = Array.from(v);
        matchObjects(v, re, 'g' + (fl || ''), false).forEach(function (m) {
          out.push(chars.slice(pos, m.offset).join(''));
          pos = m.offset + m.length;
        });
        out.push(chars.slice(pos).join(''));
        return out;
      },
      '_splits/2': function* (v, re, fl) { yield* CFUNCS['split/2'](v, re, fl); },
      'join/1': function (v, sep) {
        if (!Array.isArray(v)) { throw jerr('Cannot iterate over ' + typeOf(v)); }
        if (!v.length) { return ''; }
        return v.map(function (x) {
          if (x === null) { return ''; }
          if (typeof x === 'string') { return x; }
          if (typeof x === 'number' || typeof x === 'boolean') { return String(x); }
          throw jerr('Cannot join with ' + typeOf(x));
        }).join(sep);
      },
      'explode/0': function (v) { return Array.from(v).map(function (c) { return c.codePointAt(0); }); },
      'implode/0': function (v) { return v.map(function (c) { return String.fromCodePoint(c); }).join(''); },
      'tojson/0': function (v) { return toJSON(v); },
      'fromjson/0': function (v) {
        try { return JSON.parse(v); } catch (e) { throw jerr(v + ' (while parsing \'' + v + '\')'); }
      },
      'sort/0': function (v) {
        if (!Array.isArray(v)) { throw jerr(describe(v) + ' cannot be sorted, as it is not an array'); }
        return v.slice().sort(cmp);
      },
      'unique/0': function (v) {
        var s = v.slice().sort(cmp);
        return s.filter(function (x, i) { return i === 0 || cmp(s[i - 1], x) !== 0; });
      },
      'reverse/0': function (v) {
        if (typeof v === 'string') { return Array.from(v).reverse().join(''); }
        if (v === null) { return []; }
        return v.slice().reverse();
      },
      'min/0': function (v) { return v.length ? v.slice().sort(cmp)[0] : null; },
      'max/0': function (v) {
        if (!v.length) { return null; }
        var best = v[0];
        v.forEach(function (x) { if (cmp(x, best) >= 0) { best = x; } });
        return best;
      },
      'flatten/0': function (v) { return flatten(v, 1e9); },
      'flatten/1': function (v, d) {
        if (d < 0) { throw jerr('flatten depth must not be negative'); }
        return flatten(v, d);
      },
      'floor/0': Math.floor, 'ceil/0': Math.ceil, 'sqrt/0': Math.sqrt,
      'round/0': function (v) { return v < 0 ? -Math.round(-v) : Math.round(v); },
      'fabs/0': Math.abs, 'abs/0': Math.abs, 'trunc/0': Math.trunc,
      'log/0': Math.log, 'log2/0': Math.log2, 'log10/0': Math.log10, 'exp/0': Math.exp,
      'exp2/0': function (v) { return Math.pow(2, v); }, 'exp10/0': function (v) { return Math.pow(10, v); },
      'sin/0': Math.sin, 'cos/0': Math.cos, 'tan/0': Math.tan, 'asin/0': Math.asin, 'acos/0': Math.acos, 'atan/0': Math.atan,
      'pow/2': function (v, a, b) { return Math.pow(a, b); },
      'atan2/2': function (v, a, b) { return Math.atan2(a, b); },
      'fmin/2': function (v, a, b) { return Math.min(a, b); },
      'fmax/2': function (v, a, b) { return Math.max(a, b); },
      'infinite/0': function () { return Infinity; },
      'nan/0': function () { return NaN; },
      'isinfinite/0': function (v) { return v === Infinity || v === -Infinity; },
      'isnan/0': function (v) { return v !== v; },
      'isnormal/0': function (v) { return isFinite(v) && v !== 0; },
      'null/0': function () { return null; },
      'true/0': function () { return true; },
      'false/0': function () { return false; },
      'now/0': function () { return Date.now() / 1000; },
      'to_entries/0': function (v) {
        if (typeOf(v) !== 'object') { throw jerr(describe(v) + ' has no keys'); }
        return Object.keys(v).map(function (k) { return { key: k, value: v[k] }; });
      },
      'from_entries/0': function (v) {
        var o = {};
        v.forEach(function (e) {
          var k = e.key !== undefined ? e.key : (e.k !== undefined ? e.k : (e.name !== undefined ? e.name : (e.Name !== undefined ? e.Name : (e.Key !== undefined ? e.Key : e.K))));
          var val = e.value !== undefined ? e.value : (e.v !== undefined ? e.v : (e.Value !== undefined ? e.Value : e.V));
          if (k === null || k === undefined) { k = 'null'; }
          if (typeof k === 'number' || typeof k === 'boolean') { k = String(k); }
          if (typeof k !== 'string') { throw jerr('Cannot use ' + describe(k) + ' as object key'); }
          o[k] = val === undefined ? null : val;
        });
        return o;
      },
      'transpose/0': function (v) {
        var n = 0;
        v.forEach(function (r) { n = Math.max(n, r.length); });
        var out = [];
        for (var i = 0; i < n; i++) { out.push(v.map(function (r) { return i < r.length ? r[i] : null; })); }
        return out;
      },
      'indices/1': function (v, k) { return v === null ? null : indicesOf(v, k); },
      'index/1': function (v, k) { var r = indicesOf(v, k); return r && r.length ? r[0] : null; },
      'rindex/1': function (v, k) { var r = indicesOf(v, k); return r && r.length ? r[r.length - 1] : null; },
      'todate/0': function (v) { return strftime(v, '%Y-%m-%dT%H:%M:%SZ'); },
      'todateiso8601/0': function (v) { return strftime(v, '%Y-%m-%dT%H:%M:%SZ'); },
      'fromdate/0': function (v) { return fromIso(v); },
      'fromdateiso8601/0': function (v) { return fromIso(v); },
      'gmtime/0': function (v) { return gmtimeOf(v); },
      'mktime/0': function (v) { return mktimeOf(v); },
      'strftime/1': function (v, f) { return strftime(v, f); },
      'strflocaltime/1': function (v, f) { return strftime(v, f); },
      'toarray/0': function (v) { return Array.isArray(v) ? v : [v]; },
      'setpath/2': function (v, p, nv) { return setpath(v, p, nv); },
      'delpaths/1': function (v, ps) { return delpaths(v, ps); },
      'first/0': function (v) { return getIndex(v, 0); },
      'last/0': function (v) { return getIndex(v, -1); },
      'nth/1': function (v, n) { return getIndex(v, n); },
      'ascii/0': function (v) { return String.fromCharCode(v); },
      'builtins/0': function () { return []; },
      'input_line_number/0': function () { return 0; },
      'combinations/0': function (v) {
        var out = [[]];
        v.forEach(function (arr) {
          var nx = [];
          out.forEach(function (pre) { arr.forEach(function (x) { nx.push(pre.concat([x])); }); });
          out = nx;
        });
        return out;
      },
    };
    function contains(a, b) {
      var ta = typeOf(a), tb = typeOf(b);
      if (ta !== tb) { throw jerr(describe(a) + ' and ' + describe(b) + ' cannot have their containment checked'); }
      if (ta === 'object') {
        return Object.keys(b).every(function (k) {
          return Object.prototype.hasOwnProperty.call(a, k) && contains(a[k], b[k]);
        });
      }
      if (ta === 'array') { return b.every(function (y) { return a.some(function (x) { return typeOf(x) === typeOf(y) && contains(x, y); }); }); }
      if (ta === 'string') { return a.indexOf(b) !== -1; }
      return cmp(a, b) === 0;
    }
    function flatten(v, d) {
      var out = [];
      v.forEach(function (x) {
        if (Array.isArray(x) && d > 0) { out = out.concat(flatten(x, d - 1)); } else { out.push(x); }
      });
      return out;
    }

    var PRELUDE = [
      'def values: select(. != null);', 'def nulls: select(. == null);',
      'def booleans: select(type == "boolean");', 'def numbers: select(type == "number");',
      'def strings: select(type == "string");', 'def arrays: select(type == "array");',
      'def objects: select(type == "object");',
      'def iterables: select(type | . == "array" or . == "object");',
      'def scalars: select(type | . != "array" and . != "object");',
      'def map_values(f): .[] |= f;',
      'def leaf_paths: paths(scalars);',
      'def finites: select(isinfinite or isnan | not);',
      'def normals: select(isnormal);',
      'def nth($n; f): last(limit($n + 1; f));',
      'def inputs: empty;'
    ];

    var preludeEnv = null;
    function getPrelude() {
      if (preludeEnv) { return preludeEnv; }
      var env = new Env(null);
      PRELUDE.forEach(function (src) {
        var ast = parse(src + ' .');
        var def = ast.def;
        env.setFunc(def.name + '/' + def.params.length, { def: def, env: env });
      });
      preludeEnv = env;
      return env;
    }

    // run(program, inputs[], opts) -> {out: [values], error?}
    function compile(src) { return parse(src); }
    function* run(ast, input, vars) {
      var env = getPrelude().child();
      Object.keys(vars || {}).forEach(function (k) { env.setVar(k, vars[k]); });
      steps = 0;
      yield* ev(ast, input, env);
    }

    // Split a text holding concatenated JSON values (JSONL, pretty-printed, etc.).
    function parseStream(text) {
      var vals = [];
      var i = 0;
      var n = text.length;
      for (;;) {
        while (i < n && /\s/.test(text.charAt(i))) { i++; }
        if (i >= n) { break; }
        var start = i;
        var c = text.charAt(i);
        var end;
        if (c === '{' || c === '[') {
          var depth = 0;
          var inStr = false;
          for (end = i; end < n; end++) {
            var ch = text.charAt(end);
            if (inStr) {
              if (ch === '\\') { end++; } else if (ch === '"') { inStr = false; }
            } else if (ch === '"') { inStr = true; }
            else if (ch === '{' || ch === '[') { depth++; }
            else if (ch === '}' || ch === ']') { depth--; if (depth === 0) { end++; break; } }
          }
          if (depth !== 0) { throw new Error('Unfinished JSON term at EOF at line ' + (text.slice(0, n).split('\n').length) + ', column 0'); }
        } else if (c === '"') {
          end = i + 1;
          while (end < n && text.charAt(end) !== '"') { if (text.charAt(end) === '\\') { end++; } end++; }
          end++;
        } else {
          end = i;
          while (end < n && !/[\s,\[\]{}]/.test(text.charAt(end))) { end++; }
          if (end === i) { throw new Error('Invalid literal at line 1, column ' + (i + 1)); }
        }
        var chunk = text.slice(start, end);
        try { vals.push(JSON.parse(chunk)); } catch (e) {
          throw new Error('Invalid literal at line ' + (text.slice(0, start).split('\n').length) + ', column ' + (start + 1));
        }
        i = end;
      }
      return vals;
    }

    return { compile: compile, run: run, parseStream: parseStream, stringify: stringify, JqError: JqError, toJSON: toJSON, cmp: cmp };
  })();
