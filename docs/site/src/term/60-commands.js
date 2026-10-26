
  /* ---------- commands ---------- */
  var COMMANDS = Object.create(null);

  var TOOL_VERSIONS = {
    jq: 'jq-1.7.1',
    tshark: 'TShark (Wireshark) 4.2.2 (Git v4.2.2 packaged as 4.2.2-1.1build3).',
    dig: 'DiG 9.18.39-0ubuntu0.24.04.1-Ubuntu',
    whois: 'Version 5.5.22.',
    rg: 'ripgrep 14.1.0'
  };

  // Option parser: spec is {short: 'flags with no arg', withArg: 'flags that take an arg', long:{name:'key'|'key=' }}.
  function parseOpts(args, spec) {
    var o = { _: [], flags: {}, vals: {} };
    var i = 0;
    var longs = spec.long || {};
    for (; i < args.length; i++) {
      var a = args[i];
      if (a === '--') { o._ = o._.concat(args.slice(i + 1)); break; }
      if (a.indexOf('--') === 0) {
        var eq = a.indexOf('=');
        var nm = eq > 0 ? a.slice(2, eq) : a.slice(2);
        var def = longs[nm];
        if (def === undefined) { throw ShellError('unrecognized option \'--' + nm + '\'', 2); }
        if (def.slice(-1) === '=') {
          var key = def.slice(0, -1);
          var val = eq > 0 ? a.slice(eq + 1) : args[++i];
          (o.vals[key] = o.vals[key] || []).push(val);
        } else { o.flags[def] = true; }
        continue;
      }
      if (a.length > 1 && a.charAt(0) === '-' && !(spec.numeric && /^-\d+$/.test(a))) {
        for (var j = 1; j < a.length; j++) {
          var ch = a.charAt(j);
          if ((spec.withArg || '').indexOf(ch) !== -1) {
            var v = a.slice(j + 1);
            if (v === '') { v = args[++i]; }
            if (v === undefined) { throw ShellError('option requires an argument -- \'' + ch + '\'', 2); }
            (o.vals[ch] = o.vals[ch] || []).push(v);
            break;
          }
          if ((spec.short || '').indexOf(ch) === -1) { throw ShellError('invalid option -- \'' + ch + '\'', 2); }
          o.flags[ch] = true;
        }
        continue;
      }
      if (spec.stopAtFirst) { o._ = o._.concat(args.slice(i)); break; }
      o._.push(a);
    }
    return o;
  }

  // Read each file operand (or stdin when none). cb(text, displayName). Returns status.
  function eachInput(ctx, files, cb, opts) {
    opts = opts || {};
    var status = 0;
    if (!files.length || (files.length === 1 && files[0] === '-' && ctx.stdin !== null)) {
      if (ctx.stdin === null && !files.length) {
        if (opts.needsInput !== false) { return 0; }
      }
      cb(ctx.stdin === null ? '' : ctx.stdin, '(standard input)');
      return 0;
    }
    files.forEach(function (f) {
      if (f === '-') { cb(ctx.stdin || '', '(standard input)'); return; }
      var p = ctx.sh.path(f);
      if (p === null) { ctx.err(ctx.name + ': ' + f + ': No such file or directory\n'); status = 1; return; }
      if (ctx.vfs.isDir(p) && !ctx.vfs.isFile(p)) { ctx.err(ctx.name + ': ' + f + ': Is a directory\n'); status = 1; return; }
      var text = ctx.vfs.readText(p);
      if (text === null) { ctx.err(ctx.name + ': ' + f + ': No such file or directory\n'); status = 1; return; }
      cb(text, f, p);
    });
    return status;
  }
  function fileText(ctx, f) {
    var p = ctx.sh.path(f);
    if (p === null) { return null; }
    return ctx.vfs.readText(p);
  }
  function usage(ctx, msg) { ctx.err(ctx.name + ': ' + msg + '\n'); return 2; }

  /* ----- builtins ----- */
  COMMANDS.echo = function (ctx) {
    var args = ctx.args.slice();
    var nl = true;
    var esc = false;
    while (args.length && /^-[neE]+$/.test(args[0])) {
      var f = args.shift();
      if (f.indexOf('n') !== -1) { nl = false; }
      if (f.indexOf('e') !== -1) { esc = true; }
      if (f.indexOf('E') !== -1) { esc = false; }
    }
    var s = args.join(' ');
    if (esc) { s = s.replace(/\\c[\s\S]*$/, function () { nl = false; return ''; }); s = ansiC(s); }
    ctx.out(s + (nl ? '\n' : ''));
    return 0;
  };
  function printfFormat(fmt, args) {
    var ai = 0;
    var out = '';
    function once() {
      var consumed = false;
      var res = ansiC(fmt).replace(/%([-+ #0]*)(\d+|\*)?(?:\.(\d+))?([a-zA-Z%])/g, function (m, flags, width, prec, conv) {
        if (conv === '%') { return '%'; }
        consumed = true;
        var a = args[ai++];
        var s;
        if (conv === 's') { s = a === undefined ? '' : a; if (prec !== undefined) { s = s.slice(0, +prec); } }
        else if (conv === 'd' || conv === 'i') { s = String(parseInt(a || '0', 10) || 0); }
        else if (conv === 'x') { s = (parseInt(a || '0', 10) >>> 0).toString(16); }
        else if (conv === 'f') { s = (parseFloat(a || '0') || 0).toFixed(prec === undefined ? 6 : +prec); }
        else if (conv === 'c') { s = (a || '').charAt(0); }
        else { return m; }
        var w = width ? +width : 0;
        if (s.length < w) { s = flags.indexOf('-') !== -1 ? s + ' '.repeat(w - s.length) : (flags.indexOf('0') !== -1 && conv !== 's' ? '0' : ' ').repeat(w - s.length) + s; }
        return s;
      });
      return { s: res, consumed: consumed };
    }
    do {
      var r = once();
      out += r.s;
      if (!r.consumed) { break; }
    } while (ai < args.length);
    return out;
  }
  COMMANDS.printf = function (ctx) {
    if (!ctx.args.length) { return usage(ctx, 'usage: printf format [arguments ...]'); }
    ctx.out(printfFormat(ctx.args[0], ctx.args.slice(1)));
    return 0;
  };
  COMMANDS.pwd = function (ctx) { ctx.out(ctx.sh.pwd() + '\n'); return 0; };
  COMMANDS.cd = function (ctx) {
    var target = ctx.args[0] === undefined || ctx.args[0] === '~' ? '~' : ctx.args[0];
    if (target === '-') { target = ctx.sh.env.OLDPWD; }
    // `cd workspace/soc/<id>` (the lab text starts from the repo root) lands in the workspace root.
    var m = /^(?:(?:\.\/|~\/lab-kit\/|\/home\/analyst\/lab-kit\/)?workspace\/soc\/)([^/]+)\/?$/.exec(target);
    if (m && m[1] === ctx.vfs.id) { ctx.sh.cwd = ''; return 0; }
    var p = ctx.sh.path(target);
    if (p === null || !ctx.vfs.isDir(p)) {
      ctx.err('bash: cd: ' + target + ': No such file or directory\n');
      return 1;
    }
    ctx.sh.cwd = p;
    return 0;
  };
  COMMANDS.true = function () { return 0; };
  COMMANDS[':'] = function () { return 0; };
  COMMANDS.false = function () { return 1; };
  COMMANDS.exit = function (ctx) { var e = new Error('exit'); e.exitShell = true; e.code = parseInt(ctx.args[0] || '0', 10) || 0; throw e; };
  COMMANDS.clear = function (ctx) { ctx.sh.clearFlag = true; return 0; };
  COMMANDS.history = function (ctx) {
    ctx.sh.history.forEach(function (h, i) { ctx.out(('     ' + (i + 1)).slice(-5) + '  ' + h + '\n'); });
    return 0;
  };
  COMMANDS.export = function (ctx) {
    ctx.args.forEach(function (a) {
      var m = /^([A-Za-z_]\w*)=(.*)$/.exec(a);
      if (m) { ctx.sh.env[m[1]] = m[2]; delete ctx.sh.vars[m[1]]; }
    });
    return 0;
  };
  COMMANDS.unset = function (ctx) { ctx.args.forEach(function (a) { delete ctx.sh.vars[a]; delete ctx.sh.env[a]; }); return 0; };
  COMMANDS.env = function (ctx) { Object.keys(ctx.sh.env).forEach(function (k) { ctx.out(k + '=' + ctx.sh.env[k] + '\n'); }); return 0; };
  COMMANDS.printenv = COMMANDS.env;
  COMMANDS.whoami = function (ctx) { ctx.out('analyst\n'); return 0; };
  COMMANDS.id = function (ctx) { ctx.out('uid=1000(analyst) gid=1000(analyst) groups=1000(analyst)\n'); return 0; };
  COMMANDS.hostname = function (ctx) { ctx.out('soc\n'); return 0; };
  COMMANDS.uname = function (ctx) { ctx.out(ctx.args.indexOf('-a') !== -1 ? 'Linux soc 6.6.0 #1 SMP x86_64 GNU/Linux\n' : 'Linux\n'); return 0; };
  COMMANDS.date = function (ctx) {
    var d = new Date();
    if (ctx.args.indexOf('-u') !== -1 || ctx.args.some(function (a) { return a.charAt(0) === '+'; })) {
      var fmt = ctx.args.filter(function (a) { return a.charAt(0) === '+'; })[0];
      if (fmt) { ctx.out(strftimeSimple(d, fmt.slice(1)) + '\n'); return 0; }
    }
    ctx.out(d.toUTCString().replace('GMT', 'UTC') + '\n');
    return 0;
  };
  function strftimeSimple(d, f) {
    function p(n) { return ('0' + n).slice(-2); }
    return f.replace(/%([YmdHMSsFTZ%])/g, function (m, c) {
      switch (c) {
        case 'Y': return String(d.getUTCFullYear());
        case 'm': return p(d.getUTCMonth() + 1);
        case 'd': return p(d.getUTCDate());
        case 'H': return p(d.getUTCHours());
        case 'M': return p(d.getUTCMinutes());
        case 'S': return p(d.getUTCSeconds());
        case 's': return String(Math.floor(d.getTime() / 1000));
        case 'F': return d.getUTCFullYear() + '-' + p(d.getUTCMonth() + 1) + '-' + p(d.getUTCDate());
        case 'T': return p(d.getUTCHours()) + ':' + p(d.getUTCMinutes()) + ':' + p(d.getUTCSeconds());
        case 'Z': return 'UTC';
        default: return '%';
      }
    });
  }
  COMMANDS.sleep = function () { return 0; };
  COMMANDS.which = function (ctx) {
    var st = 0;
    ctx.args.forEach(function (a) { if (COMMANDS[a]) { ctx.out('/usr/bin/' + a + '\n'); } else { st = 1; } });
    return st;
  };
  COMMANDS.type = function (ctx) {
    var st = 0;
    ctx.args.forEach(function (a) { if (COMMANDS[a]) { ctx.out(a + ' is /usr/bin/' + a + '\n'); } else { ctx.err('bash: type: ' + a + ': not found\n'); st = 1; } });
    return st;
  };
  COMMANDS.sudo = function (ctx) {
    if (!ctx.args.length) { return usage(ctx, 'usage: sudo command'); }
    return ctx.sh.runCommand(ctx.args[0], ctx.args.slice(1), { stdin: ctx.stdin, out: ctx.out, err: ctx.err, tty: ctx.tty });
  };
  function pkgManager(ctx) {
    ctx.out('Page terminal: nothing to install. jq, tshark, dig, whois, rg (ripgrep), awk, sed and grep are built in and already "installed".\n' +
      'On your own machine the lab text gives the real apt command.\n');
    return 0;
  }
  COMMANDS['apt-get'] = pkgManager;
  COMMANDS.apt = pkgManager;
  COMMANDS.dpkg = pkgManager;
  COMMANDS.man = function (ctx) { ctx.out('No manual pages in the page terminal. Try: ' + (ctx.args[0] || 'cmd') + ' --help, or help.\n'); return 0; };

  /* ----- file commands ----- */
  function lsKey(n) { return n.toLowerCase().replace(/^[._]+/, ''); }
  COMMANDS.ls = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'alF1hdR' });
    var targets = o._.length ? o._ : ['.'];
    var status = 0;
    var showHeader = targets.length > 1 || o.flags.R;
    function entryLine(dirRel, name) {
      var rel = dirRel ? dirRel + '/' + name : name;
      var isDir = ctx.vfs.isDir(rel) && !ctx.vfs.isFile(rel);
      var size = isDir ? 4096 : ctx.vfs.size(rel);
      return (isDir ? 'drwxr-xr-x' : '-rw-r--r--') + ' 1 analyst analyst ' + ('       ' + size).slice(-6) + ' Jan  1 00:00 ' + name + (o.flags.F && isDir ? '/' : '');
    }
    function listDir(dirRel, label, first) {
      var names = ctx.vfs.list(dirRel);
      if (!o.flags.a) { names = names.filter(function (n) { return n.charAt(0) !== '.'; }); }
      names.sort(function (a, b) { var ka = lsKey(a), kb = lsKey(b); return ka < kb ? -1 : ka > kb ? 1 : a < b ? -1 : 1; });
      if (showHeader) { ctx.out((first ? '' : '\n') + label + ':\n'); }
      if (o.flags.l) {
        ctx.out('total ' + names.length + '\n');
        names.forEach(function (n) { ctx.out(entryLine(dirRel, n) + '\n'); });
      } else if (ctx.tty && !o.flags['1']) {
        var decorated = names.map(function (n) { var rel = dirRel ? dirRel + '/' + n : n; return n + (o.flags.F && ctx.vfs.isDir(rel) && !ctx.vfs.isFile(rel) ? '/' : ''); });
        ctx.out(columns(decorated, 80));
      } else {
        names.forEach(function (n) { ctx.out(n + '\n'); });
      }
      if (o.flags.R) {
        names.forEach(function (n) {
          var rel = dirRel ? dirRel + '/' + n : n;
          if (ctx.vfs.isDir(rel)) { listDir(rel, label + '/' + n, false); }
        });
      }
    }
    var files = [];
    var dirs = [];
    targets.forEach(function (t) {
      var p = ctx.sh.path(t);
      if (p === null || !ctx.vfs.exists(p)) { ctx.err('ls: cannot access \'' + t + '\': No such file or directory\n'); status = 2; return; }
      if (ctx.vfs.isFile(p) || o.flags.d) { files.push({ t: t, p: p }); } else { dirs.push({ t: t, p: p }); }
    });
    if (files.length) {
      files.sort(function (a, b) { return a.t < b.t ? -1 : 1; });
      if (o.flags.l) { files.forEach(function (f) { var parts = f.p.split('/'); var nm = parts.pop(); ctx.out(entryLine(parts.join('/'), nm).replace(/ [^ ]+$/, ' ' + f.t) + '\n'); }); }
      else if (ctx.tty && !o.flags['1']) { ctx.out(columns(files.map(function (f) { return f.t; }), 80)); }
      else { files.forEach(function (f) { ctx.out(f.t + '\n'); }); }
    }
    dirs.sort(function (a, b) { return a.t < b.t ? -1 : 1; });
    dirs.forEach(function (d, i) { listDir(d.p, d.t, i === 0 && !files.length); });
    return status;
  };
  function columns(names, width) {
    if (!names.length) { return ''; }
    var maxLen = Math.max.apply(null, names.map(function (n) { return n.length; })) + 2;
    var perRow = Math.max(1, Math.floor(width / maxLen));
    var rows = Math.ceil(names.length / perRow);
    var out = '';
    for (var r = 0; r < rows; r++) {
      var line = '';
      for (var c = 0; c < perRow; c++) {
        var idx = c * rows + r;
        if (idx >= names.length) { break; }
        line += idx + rows >= names.length ? names[idx] : names[idx] + ' '.repeat(maxLen - names[idx].length);
      }
      out += line.replace(/\s+$/, '') + '\n';
    }
    return out;
  }
  COMMANDS.cat = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'nAb' });
    var n = 0;
    return eachInput(ctx, o._, function (text) {
      if (o.flags.n) {
        splitLines(text).forEach(function (l) { n++; ctx.out(('      ' + n).slice(-6) + '\t' + l + '\n'); });
      } else { ctx.out(text); }
    });
  };
  COMMANDS.less = COMMANDS.cat;
  COMMANDS.more = COMMANDS.cat;
  COMMANDS.tac = function (ctx) {
    return eachInput(ctx, ctx.args, function (text) { ctx.out(joinLines(splitLines(text).reverse())); });
  };
  COMMANDS.head = function (ctx) { return headTail(ctx, true); };
  COMMANDS.tail = function (ctx) { return headTail(ctx, false); };
  function headTail(ctx, isHead) {
    var o = parseOpts(ctx.args, { short: 'qv', withArg: 'nc', numeric: true });
    var n = 10;
    var fromStart = false;
    var bytes = null;
    var files = o._.filter(function (f) { return !/^-\d+$/.test(f); });
    ctx.args.forEach(function (a) { var m = /^-(\d+)$/.exec(a); if (m) { n = parseInt(m[1], 10); } });
    if (o.vals.n) {
      var v = o.vals.n[o.vals.n.length - 1];
      if (!isHead && v.charAt(0) === '+') { fromStart = true; v = v.slice(1); }
      n = parseInt(v, 10);
      if (isNaN(n)) { return usage(ctx, 'invalid number of lines: \'' + v + '\''); }
    }
    if (o.vals.c) { bytes = parseInt(o.vals.c[0], 10); }
    var multi = files.length > 1 && !o.flags.q;
    var idx = 0;
    return eachInput(ctx, files, function (text, name) {
      if (multi || o.flags.v) { ctx.out((idx++ ? '\n' : '') + '==> ' + name + ' <==\n'); }
      if (bytes !== null) { ctx.out(isHead ? text.slice(0, bytes) : text.slice(-bytes)); return; }
      var lines = splitLines(text);
      var sel;
      if (isHead) { sel = n < 0 ? lines.slice(0, Math.max(0, lines.length + n)) : lines.slice(0, n); }
      else { sel = fromStart ? lines.slice(Math.max(0, n - 1)) : (n === 0 ? [] : lines.slice(-n)); }
      ctx.out(joinLines(sel));
    });
  }
  COMMANDS.wc = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'lwcmL' });
    var any = o.flags.l || o.flags.w || o.flags.c || o.flags.m || o.flags.L;
    var rows = [];
    var st = eachInput(ctx, o._, function (text, name, path) {
      var words = text.trim() === '' ? 0 : text.trim().split(/\s+/).length;
      var maxLine = 0;
      text.split('\n').forEach(function (l) { maxLine = Math.max(maxLine, l.length); });
      rows.push({ name: o._.length ? name : '', l: (text.match(/\n/g) || []).length, w: words,
        c: path !== undefined ? ctx.vfs.size(path) : utf8Encode(text).length, m: Array.from(text).length, L: maxLine });
    });
    var cols = [];
    if (!any) { cols = ['l', 'w', 'c']; } else { ['l', 'w', 'm', 'c', 'L'].forEach(function (k) { if (o.flags[k]) { cols.push(k); } }); }
    var total = { l: 0, w: 0, c: 0, m: 0, L: 0 };
    rows.forEach(function (r) { ['l', 'w', 'c', 'm'].forEach(function (k) { total[k] += r[k]; }); total.L = Math.max(total.L, r.L); });
    var show = rows.slice();
    if (rows.length > 1) { show.push(Object.assign({ name: 'total' }, total)); }
    var width = cols.length === 1 && !o._.length ? 0 : Math.max(1, String(Math.max.apply(null, show.map(function (r) { return Math.max.apply(null, cols.map(function (k) { return r[k]; })); }))).length);
    if (cols.length > 1 || show.length > 1) { width = Math.max(width, String(show[show.length - 1].c).length); }
    if (cols.length === 1 && show.length === 1) { width = 0; }
    else if (!o._.length && cols.length > 1) { width = 7; }
    show.forEach(function (r) {
      ctx.out(cols.map(function (k) { return width ? ('            ' + r[k]).slice(-width) : String(r[k]); }).join(' ') + (r.name ? ' ' + r.name : '') + '\n');
    });
    return st;
  };
  COMMANDS.touch = function (ctx) {
    ctx.args.forEach(function (a) {
      var p = ctx.sh.path(a);
      if (p === null) { ctx.err('touch: cannot touch \'' + a + '\': Permission denied\n'); return; }
      if (!ctx.vfs.isFile(p)) { ctx.vfs.write(p, '', true); }
    });
    return 0;
  };
  COMMANDS.mkdir = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'p' });
    var st = 0;
    o._.forEach(function (a) {
      var p = ctx.sh.path(a);
      if (p === null) { ctx.err('mkdir: cannot create directory \'' + a + '\': Permission denied\n'); st = 1; return; }
      if (ctx.vfs.exists(p) && !o.flags.p) { ctx.err('mkdir: cannot create directory \'' + a + '\': File exists\n'); st = 1; return; }
      ctx.vfs.mkdir(p);
    });
    return st;
  };
  COMMANDS.rm = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'rRfdv' });
    var st = 0;
    o._.forEach(function (a) {
      var p = ctx.sh.path(a);
      if (p === null || !ctx.vfs.exists(p)) { if (!o.flags.f) { ctx.err('rm: cannot remove \'' + a + '\': No such file or directory\n'); st = 1; } return; }
      if (ctx.vfs.isDir(p) && !ctx.vfs.isFile(p)) {
        if (!o.flags.r && !o.flags.R) { ctx.err('rm: cannot remove \'' + a + '\': Is a directory\n'); st = 1; return; }
        ctx.vfs.allFiles().forEach(function (f) { if (f.indexOf(p + '/') === 0) { ctx.vfs.remove(f); } });
        return;
      }
      ctx.vfs.remove(p);
    });
    return st;
  };
  function copyOrMove(ctx, move) {
    var o = parseOpts(ctx.args, { short: 'rRfavn' });
    if (o._.length < 2) { return usage(ctx, 'missing file operand'); }
    var dst = o._[o._.length - 1];
    var srcs = o._.slice(0, -1);
    var dp = ctx.sh.path(dst);
    if (dp === null) { ctx.err(ctx.name + ': cannot create regular file \'' + dst + '\': Permission denied\n'); return 1; }
    var dstIsDir = ctx.vfs.isDir(dp) && !ctx.vfs.isFile(dp);
    if (srcs.length > 1 && !dstIsDir) { ctx.err(ctx.name + ': target \'' + dst + '\' is not a directory\n'); return 1; }
    var st = 0;
    srcs.forEach(function (s) {
      var sp = ctx.sh.path(s);
      if (sp === null || !ctx.vfs.exists(sp)) { ctx.err(ctx.name + ': cannot stat \'' + s + '\': No such file or directory\n'); st = 1; return; }
      var base = sp.split('/').pop();
      if (ctx.vfs.isDir(sp) && !ctx.vfs.isFile(sp)) {
        if (!o.flags.r && !o.flags.R && !o.flags.a && !move) { ctx.err('cp: -r not specified; omitting directory \'' + s + '\'\n'); st = 1; return; }
        var target = dstIsDir ? (dp ? dp + '/' : '') + base : dp;
        ctx.vfs.mkdir(target);
        ctx.vfs.allFiles().forEach(function (f) {
          if (f.indexOf(sp + '/') === 0) { ctx.vfs.copy(f, target + '/' + f.slice(sp.length + 1)); if (move) { ctx.vfs.remove(f); } }
        });
        return;
      }
      var to = dstIsDir ? (dp ? dp + '/' : '') + base : dp;
      if (to === sp) { ctx.err(ctx.name + ': \'' + s + '\' and \'' + dst + '\' are the same file\n'); st = 1; return; }
      ctx.vfs.copy(sp, to);
      if (move) { ctx.vfs.remove(sp); }
    });
    return st;
  }
  COMMANDS.cp = function (ctx) { return copyOrMove(ctx, false); };
  COMMANDS.mv = function (ctx) { return copyOrMove(ctx, true); };
  COMMANDS.tee = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'ai' });
    var text = ctx.stdin === null ? '' : ctx.stdin;
    ctx.out(text);
    o._.forEach(function (f) { var p = ctx.sh.path(f); if (p !== null) { ctx.vfs.write(p, text, !!o.flags.a); } });
    return 0;
  };
  COMMANDS.basename = function (ctx) {
    var p = (ctx.args[0] || '').replace(/\/+$/, '').split('/').pop();
    if (ctx.args[1] && p.slice(-ctx.args[1].length) === ctx.args[1]) { p = p.slice(0, -ctx.args[1].length); }
    ctx.out(p + '\n');
    return 0;
  };
  COMMANDS.dirname = function (ctx) {
    var parts = (ctx.args[0] || '').replace(/\/+$/, '').split('/');
    parts.pop();
    ctx.out((parts.join('/') || (ctx.args[0] && ctx.args[0].charAt(0) === '/' ? '/' : '.')) + '\n');
    return 0;
  };
  COMMANDS.seq = function (ctx) {
    var a = ctx.args.map(Number);
    var from = a.length > 1 ? a[0] : 1, step = a.length > 2 ? a[1] : 1, to = a[a.length - 1];
    for (var i = from; step > 0 ? i <= to : i >= to; i += step) { ctx.out(i + '\n'); }
    return 0;
  };
  COMMANDS.find = function (ctx) {
    var args = ctx.args.slice();
    var starts = [];
    while (args.length && args[0].charAt(0) !== '-' && args[0] !== '!' && args[0] !== '(') { starts.push(args.shift()); }
    if (!starts.length) { starts = ['.']; }
    var nameRe = null, iname = false, type = null, maxdepth = Infinity;
    for (var i = 0; i < args.length; i++) {
      if (args[i] === '-name' || args[i] === '-iname') { iname = args[i] === '-iname'; nameRe = globToRegex(args[++i]); if (iname) { nameRe = new RegExp(nameRe.source, 'i'); } }
      else if (args[i] === '-type') { type = args[++i]; }
      else if (args[i] === '-maxdepth') { maxdepth = parseInt(args[++i], 10); }
      else if (args[i] === '-print') { /* default */ }
      else { ctx.err('find: unsupported expression ' + args[i] + ' in the page terminal\n'); return 1; }
    }
    var st = 0;
    starts.forEach(function (s) {
      var p = ctx.sh.path(s);
      if (p === null || !ctx.vfs.exists(p)) { ctx.err('find: \'' + s + '\': No such file or directory\n'); st = 1; return; }
      var all = [];
      function walk(rel, disp, depth) {
        var isDir = ctx.vfs.isDir(rel) && !ctx.vfs.isFile(rel);
        all.push({ rel: rel, disp: disp, isDir: isDir, depth: depth });
        if (isDir && depth < maxdepth) { ctx.vfs.list(rel).forEach(function (n) { walk(rel ? rel + '/' + n : n, disp + '/' + n, depth + 1); }); }
      }
      walk(p, s.replace(/\/$/, '') || s, 0);
      all.forEach(function (e) {
        var base = e.disp.split('/').pop();
        if (nameRe && !nameRe.test(base)) { return; }
        if (type === 'f' && e.isDir) { return; }
        if (type === 'd' && !e.isDir) { return; }
        ctx.out(e.disp + '\n');
      });
    });
    return st;
  };
  COMMANDS.xargs = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'n0', stopAtFirst: true });
    if (!o._.length) { o._ = ['echo']; }
    var items = (ctx.stdin || '').split(/\s+/).filter(Boolean);
    return ctx.sh.runCommand(o._[0], o._.slice(1).concat(items), { stdin: null, out: ctx.out, err: ctx.err, tty: ctx.tty });
  };
  COMMANDS.base64 = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'dw', withArg: 'w', long: { decode: 'd', wrap: 'w=' } });
    var st = eachInput(ctx, o._, function (text) {
      if (o.flags.d) {
        try { ctx.out(utf8Decode(b64ToBytes(text.replace(/\s+/g, '').replace(/=+$/, '')))); } catch (e) { ctx.err('base64: invalid input\n'); }
      } else {
        var enc = bytesToB64(utf8Encode(text));
        var wrap = o.vals.w ? parseInt(o.vals.w[0], 10) : 76;
        ctx.out(wrap > 0 ? enc.replace(new RegExp('.{1,' + wrap + '}', 'g'), '$&\n') : enc + '\n');
      }
    });
    return st;
  };
  function hashCmd(label) {
    return function (ctx) {
      var o = parseOpts(ctx.args, { short: 'b' });
      var st = 0;
      var targets = o._.length ? o._ : ['-'];
      targets.forEach(function (f) {
        var bytes;
        if (f === '-') { bytes = utf8Encode(ctx.stdin || ''); }
        else {
          var p = ctx.sh.path(f);
          bytes = p === null ? null : ctx.vfs.readBytes(p);
          if (bytes === null) { ctx.err(label + ': ' + f + ': No such file or directory\n'); st = 1; return; }
        }
        ctx.out(sha256(bytes) + '  ' + f + '\n');
      });
      return st;
    };
  }
  COMMANDS.sha256sum = hashCmd('sha256sum');
  COMMANDS.file = function (ctx) {
    var st = 0;
    ctx.args.forEach(function (a) {
      var p = ctx.sh.path(a);
      if (p === null || !ctx.vfs.exists(p)) { ctx.out(a + ': cannot open (No such file or directory)\n'); st = 1; return; }
      if (ctx.vfs.isDir(p) && !ctx.vfs.isFile(p)) { ctx.out(a + ': directory\n'); return; }
      var m = ctx.vfs.magicOf(p);
      var label = m || (/^\s*[{[]/.test(ctx.vfs.readText(p) || '') ? 'JSON text data' : (ctx.vfs.size(p) ? 'ASCII text' : 'empty'));
      ctx.out(a + ': ' + label + '\n');
    });
    return st;
  };
  function hexdumpText(bytes, canonical) {
    var out = '';
    for (var off = 0; off < bytes.length; off += 16) {
      var hex = [];
      var asc = '';
      for (var j = 0; j < 16; j++) {
        if (off + j < bytes.length) {
          var c = bytes[off + j];
          hex.push(('0' + c.toString(16)).slice(-2));
          asc += c >= 32 && c < 127 ? String.fromCharCode(c) : '.';
        } else { hex.push('  '); }
      }
      out += ('00000000' + off.toString(16)).slice(-8) + '  ' + hex.slice(0, 8).join(' ') + '  ' + hex.slice(8).join(' ') + '  |' + asc + '|\n';
    }
    void canonical;
    return out + ('00000000' + bytes.length.toString(16)).slice(-8) + '\n';
  }
  COMMANDS.xxd = function (ctx) {
    var st = 0;
    var files = ctx.args.filter(function (a) { return a.charAt(0) !== '-'; });
    var inputs = files.length ? files : ['-'];
    inputs.forEach(function (f) {
      var bytes = f === '-' ? utf8Encode(ctx.stdin || '') : (ctx.sh.path(f) === null ? null : ctx.vfs.readBytes(ctx.sh.path(f)));
      if (!bytes) { ctx.err('xxd: ' + f + ': No such file or directory\n'); st = 1; return; }
      for (var off = 0; off < bytes.length; off += 16) {
        var groups = [];
        var asc = '';
        for (var j = 0; j < 16; j += 2) {
          var chunk = '';
          for (var k = 0; k < 2; k++) {
            if (off + j + k < bytes.length) { var c = bytes[off + j + k]; chunk += ('0' + c.toString(16)).slice(-2); if (k === 0 || true) { asc += c >= 32 && c < 127 ? String.fromCharCode(c) : '.'; } }
          }
          groups.push(chunk + ' '.repeat(4 - chunk.length));
        }
        ctx.out(('00000000' + off.toString(16)).slice(-8) + ': ' + groups.join(' ') + ' ' + asc + '\n');
      }
    });
    return st;
  };
  COMMANDS.hexdump = function (ctx) {
    var f = ctx.args.filter(function (a) { return a.charAt(0) !== '-'; })[0];
    var bytes = f ? ctx.vfs.readBytes(ctx.sh.path(f) || '') : utf8Encode(ctx.stdin || '');
    if (!bytes) { ctx.err('hexdump: ' + f + ': No such file or directory\n'); return 1; }
    ctx.out(hexdumpText(bytes, true));
    return 0;
  };
  COMMANDS.strings = function (ctx) {
    var st = 0;
    ctx.args.filter(function (a) { return a.charAt(0) !== '-'; }).forEach(function (f) {
      var bytes = ctx.sh.path(f) === null ? null : ctx.vfs.readBytes(ctx.sh.path(f));
      if (!bytes) { ctx.err('strings: \'' + f + '\': No such file\n'); st = 1; return; }
      var cur = '';
      for (var i = 0; i <= bytes.length; i++) {
        var c = bytes[i];
        if (c >= 32 && c < 127) { cur += String.fromCharCode(c); }
        else { if (cur.length >= 4) { ctx.out(cur + '\n'); } cur = ''; }
      }
    });
    return st;
  };

  /* ----- text filters ----- */
  function lineRegexFor(pats, mode, icase, whole, word) {
    var srcs = pats.map(function (p) {
      var s = mode === 'fixed' ? p.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') : posixToJs(p, mode);
      if (word) { s = '(?<![A-Za-z0-9_])(?:' + s + ')(?![A-Za-z0-9_])'; }
      if (whole) { s = '^(?:' + s + ')$'; }
      return s;
    });
    try { return new RegExp(srcs.length > 1 ? srcs.map(function (s) { return '(?:' + s + ')'; }).join('|') : srcs[0], (icase ? 'i' : '') + 'g'); } catch (e) { throw ShellError('Invalid regular expression', 2); }
  }
  function grepFiles(ctx, files, recursive) {
    // expand directories when recursive
    var out = [];
    var st = 0;
    files.forEach(function (f) {
      var p = ctx.sh.path(f);
      if (p === null || !ctx.vfs.exists(p)) { ctx.err(ctx.name + ': ' + f + ': No such file or directory\n'); st = 2; return; }
      if (ctx.vfs.isDir(p) && !ctx.vfs.isFile(p)) {
        if (!recursive) { ctx.err(ctx.name + ': ' + f + ': Is a directory\n'); st = st || 2; return; }
        var base = f.replace(/\/+$/, '');
        ctx.vfs.allFiles().forEach(function (fp) {
          if (p === '' || fp.indexOf(p + '/') === 0) { out.push({ disp: (p === '' ? (base === '.' ? '' : base + '/') : base + '/') + (p === '' ? fp : fp.slice(p.length + 1)), path: fp }); }
        });
        return;
      }
      out.push({ disp: f, path: p });
    });
    return { list: out, status: st };
  }
  COMMANDS.grep = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'EFGPivcnhHlLoqsrRwxaIz', withArg: 'eAfBCm', long: { 'extended-regexp': 'E', 'fixed-strings': 'F', 'ignore-case': 'i', 'invert-match': 'v',
      count: 'c', 'line-number': 'n', 'no-filename': 'h', 'with-filename': 'H', 'files-with-matches': 'l', 'files-without-match': 'L', 'only-matching': 'o', quiet: 'q', silent: 'q',
      recursive: 'r', 'word-regexp': 'w', 'line-regexp': 'x', text: 'a', regexp: 'e=', 'after-context': 'A=', 'before-context': 'B=', context: 'C=', color: 'color=', colour: 'color=' }, numeric: true });
    var pats = o.vals.e ? o.vals.e.slice() : null;
    var files = o._.filter(function (f) { return !/^-\d+$/.test(f); });
    o._.forEach(function (f) { var m = /^-(\d+)$/.exec(f); if (m) { o.vals.C = [m[1]]; } });
    if (!pats) {
      if (!files.length) { return usage(ctx, 'usage: grep [OPTION]... PATTERNS [FILE]...'); }
      pats = [files.shift()];
    }
    var mode = o.flags.F ? 'fixed' : (o.flags.E ? 'ere' : (o.flags.P ? 'pcre' : 'bre'));
    var pl = [];
    pats.forEach(function (p) { pl = pl.concat(p.split('\n')); });
    var re = lineRegexFor(pl, mode, o.flags.i, o.flags.x, o.flags.w);
    var recursive = o.flags.r || o.flags.R;
    var after = o.vals.A ? parseInt(o.vals.A[0], 10) : (o.vals.C ? parseInt(o.vals.C[0], 10) : 0);
    var before = o.vals.B ? parseInt(o.vals.B[0], 10) : (o.vals.C ? parseInt(o.vals.C[0], 10) : 0);
    var inputs = [];
    var status = 0;
    if (!files.length && !recursive) { inputs.push({ text: ctx.stdin || '', disp: '(standard input)' }); }
    else {
      var fl = grepFiles(ctx, files.length ? files : ['.'], recursive);
      status = fl.status;
      fl.list.forEach(function (f) {
        var t = ctx.vfs.readText(f.path);
        if (t !== null) { inputs.push({ text: t, disp: f.disp }); }
      });
    }
    var showName = o.flags.H || (!o.flags.h && (files.length > 1 || recursive));
    var anyMatch = false;
    var maxCount = o.vals.m ? parseInt(o.vals.m[0], 10) : Infinity;
    inputs.forEach(function (inp) {
      var lines = splitLines(inp.text);
      var count = 0;
      var lastPrinted = -1;
      var matched = [];
      lines.forEach(function (l, i) {
        re.lastIndex = 0;
        var hit = re.test(l);
        if (o.flags.v) { hit = !hit; }
        matched.push(hit);
      });
      matched.forEach(function (hit, i) { if (hit) { if (count >= maxCount) { matched[i] = false; } else { count++; } } });
      if (count) { anyMatch = true; }
      if (o.flags.q) { return; }
      if (o.flags.c) { ctx.out((showName ? inp.disp + ':' : '') + count + '\n'); return; }
      if (o.flags.l) { if (count) { ctx.out(inp.disp + '\n'); } return; }
      if (o.flags.L) { if (!count) { ctx.out(inp.disp + '\n'); } return; }
      var sepPrinted = false;
      lines.forEach(function (l, i) {
        if (!matched[i]) { return; }
        var from = Math.max(lastPrinted + 1, i - before);
        if ((before || after) && lastPrinted >= 0 && from > lastPrinted + 1 && sepPrinted) { ctx.out('--\n'); }
        for (var k = from; k < i; k++) { ctx.out((showName ? inp.disp + '-' : '') + (o.flags.n ? (k + 1) + '-' : '') + lines[k] + '\n'); }
        if (o.flags.o && !o.flags.v) {
          re.lastIndex = 0;
          var m;
          while ((m = re.exec(l)) !== null) {
            if (m[0] === '') { re.lastIndex++; continue; }
            ctx.out((showName ? inp.disp + ':' : '') + (o.flags.n ? (i + 1) + ':' : '') + m[0] + '\n');
          }
        } else {
          ctx.out((showName ? inp.disp + ':' : '') + (o.flags.n ? (i + 1) + ':' : '') + l + '\n');
        }
        lastPrinted = i;
        sepPrinted = true;
        for (var a = 1; a <= after && i + a < lines.length && !matched[i + a]; a++) {
          ctx.out((showName ? inp.disp + '-' : '') + (o.flags.n ? (i + a + 1) + '-' : '') + lines[i + a] + '\n');
          lastPrinted = i + a;
        }
      });
    });
    if (status === 2 && !(o.flags.q && anyMatch)) { return 2; }
    return anyMatch ? 0 : 1;
  };
  COMMANDS.egrep = function (ctx) { ctx.args = ['-E'].concat(ctx.args); return COMMANDS.grep(ctx); };
  COMMANDS.fgrep = function (ctx) { ctx.args = ['-F'].concat(ctx.args); return COMMANDS.grep(ctx); };

  COMMANDS.rg = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'inlFwvcNHhsSjuaP', withArg: 'egtTgmAB', long: { 'no-ignore': 'u0', hidden: 'u1', 'ignore-case': 'i', 'line-number': 'n', 'no-line-number': 'N', 'files-with-matches': 'l',
      'fixed-strings': 'F', 'word-regexp': 'w', 'invert-match': 'v', count: 'c', 'with-filename': 'H', 'no-filename': 'h', 'smart-case': 'S', version: 'version', regexp: 'e=', glob: 'g=',
      'no-heading': 'noheading', heading: 'heading', 'color': 'color=', 'files': 'files', 'only-matching': 'o', 'max-count': 'm=', 'type': 't=', 'follow': 'L', 'no-messages': 's', 'text': 'a', 'trim': 'trim' } });
    if (o.flags.version) { ctx.out(TOOL_VERSIONS.rg + '\n'); return 0; }
    var pats = o.vals.e ? o.vals.e.slice() : null;
    var paths = o._.slice();
    if (!pats) {
      if (!paths.length) { return usage(ctx, 'error: the following required arguments were not provided:\n  <PATTERN>'); }
      pats = [paths.shift()];
    }
    var icase = o.flags.i || (o.flags.S && !/[A-Z]/.test(pats.join('')));
    var re = lineRegexFor(pats, o.flags.F ? 'fixed' : 'pcre', icase, false, o.flags.w);
    var globs = (o.vals.g || []).map(function (g) { return globToRegex(g.replace(/^\*\*\//, '')); });
    var useDefault = !paths.length;
    var targets = useDefault ? ['.'] : paths;
    var fl = grepFiles(ctx, targets, true);
    var single = targets.length === 1 && ctx.vfs.isFile(ctx.sh.path(targets[0]) || '') ;
    var list = fl.list.filter(function (f) {
      if (!globs.length) { return true; }
      var base = f.path.split('/').pop();
      return globs.some(function (g) { return g.test(base); });
    }).sort(function (a, b) { return a.disp < b.disp ? -1 : a.disp > b.disp ? 1 : 0; });
    var heading = ctx.tty && !o.flags.noheading && !single;
    var lineNo = o.flags.N ? false : (o.flags.n || ctx.tty);
    var any = false;
    var firstFile = true;
    list.forEach(function (f) {
      var text = ctx.vfs.readText(f.path);
      if (text === null) { return; }
      var disp = f.disp.replace(/^\.\//, '');
      var lines = splitLines(text);
      var hits = [];
      lines.forEach(function (l, i) {
        re.lastIndex = 0;
        var hit = re.test(l);
        if (o.flags.v) { hit = !hit; }
        if (hit) { hits.push(i); }
      });
      if (!hits.length) { return; }
      any = true;
      if (o.flags.l) { ctx.out(disp + '\n'); return; }
      if (o.flags.c) { ctx.out((single ? '' : disp + ':') + hits.length + '\n'); return; }
      if (heading) { ctx.out((firstFile ? '' : '\n') + disp + '\n'); }
      firstFile = false;
      hits.forEach(function (i) {
        var prefix = (heading || single ? '' : disp + ':') + (lineNo ? (i + 1) + ':' : '');
        if (o.flags.o) {
          re.lastIndex = 0;
          var m;
          while ((m = re.exec(lines[i])) !== null) { if (m[0] === '') { re.lastIndex++; continue; } ctx.out(prefix + m[0] + '\n'); }
        } else { ctx.out(prefix + lines[i] + '\n'); }
      });
    });
    if (fl.status) { return 2; }
    return any ? 0 : 1;
  };

  function splitFieldsSpec(spec) {
    var out = [];
    spec.split(',').forEach(function (part) {
      var m = /^(\d*)-(\d*)$/.exec(part);
      if (m) { out.push({ from: m[1] === '' ? 1 : +m[1], to: m[2] === '' ? Infinity : +m[2] }); }
      else if (/^\d+$/.test(part)) { out.push({ from: +part, to: +part }); }
      else { throw ShellError('cut: invalid field range', 1); }
    });
    return out;
  }
  function inSpec(spec, n) { return spec.some(function (r) { return n >= r.from && n <= r.to; }); }
  COMMANDS.cut = function (ctx) {
    var o = parseOpts(ctx.args, { short: 's', withArg: 'dfcb', long: { 'output-delimiter': 'od=', delimiter: 'd=', fields: 'f=' } });
    var delim = o.vals.d ? o.vals.d[0] : '\t';
    var spec = o.vals.f ? splitFieldsSpec(o.vals.f[0]) : (o.vals.c ? splitFieldsSpec(o.vals.c[0]) : (o.vals.b ? splitFieldsSpec(o.vals.b[0]) : null));
    if (!spec) { return usage(ctx, 'you must specify a list of bytes, characters, or fields'); }
    var od = o.vals.od ? o.vals.od[0] : delim;
    return eachInput(ctx, o._, function (text) {
      splitLines(text).forEach(function (l) {
        if (o.vals.f) {
          if (l.indexOf(delim) === -1) { if (!o.flags.s) { ctx.out(l + '\n'); } return; }
          var parts = l.split(delim);
          ctx.out(parts.filter(function (p, i) { return inSpec(spec, i + 1); }).join(od) + '\n');
        } else {
          var chars = Array.from(l);
          ctx.out(chars.filter(function (p, i) { return inSpec(spec, i + 1); }).join('') + '\n');
        }
      });
    });
  };
  function expandTrSet(s) {
    var classes = { alpha: 'A-Za-z', digit: '0-9', alnum: 'A-Za-z0-9', upper: 'A-Z', lower: 'a-z', space: ' \t\n\r\f\v', blank: ' \t', punct: '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~', xdigit: '0-9A-Fa-f' };
    s = s.replace(/\[:(\w+):\]/g, function (m, c) { return classes[c] || ''; });
    s = ansiC(s.replace(/\\(?=[^nrtvfab0-7\\'"])/g, '\\\\'));
    var out = [];
    var chars = Array.from(s);
    for (var i = 0; i < chars.length; i++) {
      if (chars[i + 1] === '-' && i + 2 < chars.length) {
        for (var c = chars[i].charCodeAt(0); c <= chars[i + 2].charCodeAt(0); c++) { out.push(String.fromCharCode(c)); }
        i += 2;
      } else { out.push(chars[i]); }
    }
    return out;
  }
  COMMANDS.tr = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'dsc' });
    if (!o._.length) { return usage(ctx, 'missing operand'); }
    var set1 = expandTrSet(o._[0]);
    var set2 = o._[1] !== undefined ? expandTrSet(o._[1]) : [];
    var text = ctx.stdin === null ? '' : ctx.stdin;
    var inSet1 = function (ch) { var has = set1.indexOf(ch) !== -1; return o.flags.c ? !has : has; };
    var out = '';
    var lastOut = null;
    Array.from(text).forEach(function (ch) {
      var res = ch;
      if (inSet1(ch)) {
        if (o.flags.d) { return; }
        if (set2.length) {
          if (o.flags.c) { res = set2[set2.length - 1]; }
          else { var k = set1.indexOf(ch); res = k < set2.length ? set2[k] : set2[set2.length - 1]; }
        }
        if (o.flags.s && lastOut === res && (set2.length ? set2.indexOf(res) !== -1 : true)) { return; }
      }
      out += res;
      lastOut = inSet1(ch) ? res : null;
    });
    ctx.out(out);
    return 0;
  };
  function sortKeyCmp(spec) {
    return function (a, b) {
      for (var i = 0; i < spec.keys.length; i++) {
        var k = spec.keys[i];
        var x = extractKey(a, k, spec), y = extractKey(b, k, spec);
        var c = compareKey(x, y, k.numeric || spec.numeric, k.fold || spec.fold);
        if (k.reverse || (spec.reverse && !spec.keys[i].own)) { c = -c; }
        if (c) { return c; }
      }
      return 0;
    };
  }
  function extractKey(line, k, spec) {
    var fields;
    if (spec.sep !== null) { fields = line.split(spec.sep); }
    else { fields = line.match(/\S+\s*|\s+/g) || ['']; fields = line.split(/(?<=\S)(?=\s)/).length ? line.match(/\s*\S+/g) || [''] : fields; }
    var s;
    if (spec.sep !== null) { s = fields.slice(k.from - 1, k.to === Infinity ? undefined : k.to).join(spec.sep); }
    else { s = fields.slice(k.from - 1, k.to === Infinity ? undefined : k.to).join(''); if (k.fromChar === undefined) { s = s; } }
    if (spec.ignoreBlanks || k.blanks) { s = s.replace(/^\s+/, ''); }
    return s;
  }
  function compareKey(x, y, numeric, fold) {
    if (numeric) {
      var nx = parseFloat(x), ny = parseFloat(y);
      nx = isNaN(nx) ? 0 : nx; ny = isNaN(ny) ? 0 : ny;
      return nx < ny ? -1 : nx > ny ? 1 : 0;
    }
    if (fold) { x = x.toUpperCase(); y = y.toUpperCase(); }
    return x < y ? -1 : x > y ? 1 : 0;
  }
  COMMANDS.sort = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'rnufbcCsV', withArg: 'kt', long: { reverse: 'r', unique: 'u', 'numeric-sort': 'n', 'ignore-case': 'f', key: 'k=', 'field-separator': 't=' } });
    var spec = { keys: [], reverse: !!o.flags.r, numeric: !!o.flags.n, fold: !!o.flags.f, sep: o.vals.t ? o.vals.t[0] : null, ignoreBlanks: !!o.flags.b };
    (o.vals.k || []).forEach(function (kd) {
      var m = /^(\d+)(?:\.\d+)?(?:([bnrf]*))?(?:,(\d+)(?:\.\d+)?([bnrf]*)?)?$/.exec(kd);
      if (!m) { throw ShellError('sort: invalid key ' + kd, 2); }
      var mods = (m[2] || '') + (m[4] || '');
      spec.keys.push({ from: +m[1], to: m[3] ? +m[3] : (kd.indexOf(',') === -1 ? Infinity : +m[1]), numeric: mods.indexOf('n') !== -1, reverse: mods.indexOf('r') !== -1, fold: mods.indexOf('f') !== -1, blanks: mods.indexOf('b') !== -1, own: mods.indexOf('r') !== -1 });
    });
    var useKeys = spec.keys.length > 0;
    if (!useKeys) { spec.keys.push({ from: 1, to: Infinity }); }
    var lines = [];
    var st = eachInput(ctx, o._, function (text) { lines = lines.concat(splitLines(text)); });
    var keyCmp = sortKeyCmp(spec);
    var cmpFn;
    if (useKeys) {
      cmpFn = function (a, b) { return keyCmp(a, b) || (o.flags.s || o.flags.u ? 0 : (spec.reverse ? -1 : 1) * (a < b ? -1 : a > b ? 1 : 0)); };
    } else {
      cmpFn = function (a, b) {
        var c = spec.numeric ? compareKey(a, b, true, false) : compareKey(spec.ignoreBlanks ? a.replace(/^\s+/, '') : a, spec.ignoreBlanks ? b.replace(/^\s+/, '') : b, false, spec.fold);
        if (c === 0 && spec.numeric) { c = a < b ? -1 : a > b ? 1 : 0; }
        return spec.reverse ? -c : c;
      };
    }
    if (o.flags.c || o.flags.C) {
      for (var i = 1; i < lines.length; i++) { if (cmpFn(lines[i - 1], lines[i]) > 0) { ctx.err('sort: -:' + (i + 1) + ': disorder: ' + lines[i] + '\n'); return 1; } }
      return 0;
    }
    var sorted = lines.map(function (l, i) { return { l: l, i: i }; }).sort(function (a, b) { return cmpFn(a.l, b.l) || a.i - b.i; }).map(function (x) { return x.l; });
    if (o.flags.u) {
      var uq = [];
      sorted.forEach(function (l, i) {
        if (i === 0) { uq.push(l); return; }
        var same = useKeys ? keyCmp(uq[uq.length - 1], l) === 0 : (spec.numeric ? compareKey(uq[uq.length - 1], l, true, false) === 0 : compareKey(uq[uq.length - 1], l, false, spec.fold) === 0);
        if (!same) { uq.push(l); }
      });
      sorted = uq;
    }
    ctx.out(joinLines(sorted));
    return st;
  };
  COMMANDS.uniq = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'cduiD', withArg: 'fsw' });
    var lines = [];
    var st = eachInput(ctx, o._.slice(0, 1), function (text) { lines = splitLines(text); });
    var groups = [];
    lines.forEach(function (l) {
      var key = o.flags.i ? l.toLowerCase() : l;
      var last = groups[groups.length - 1];
      if (last && last.key === key) { last.n++; } else { groups.push({ key: key, line: l, n: 1 }); }
    });
    groups.forEach(function (g) {
      if (o.flags.d && g.n < 2) { return; }
      if (o.flags.u && g.n > 1) { return; }
      ctx.out((o.flags.c ? ('       ' + g.n).slice(-7) + ' ' : '') + g.line + '\n');
    });
    return st;
  };
  COMMANDS.column = function (ctx) {
    var o = parseOpts(ctx.args, { short: 't', withArg: 'soc', long: { table: 't', separator: 's=' } });
    return eachInput(ctx, o._, function (text) {
      var lines = splitLines(text);
      if (!o.flags.t) { ctx.out(joinLines(lines)); return; }
      var sep = o.vals.s ? o.vals.s[0] : null;
      var rows = lines.map(function (l) {
        return sep !== null ? l.split(new RegExp('[' + sep.replace(/[\]\\^-]/g, '\\$&') + ']')) : l.split(/[ \t]+/).filter(function (x, i) { return !(i === 0 && x === ''); });
      });
      var ncol = 0;
      rows.forEach(function (r) { ncol = Math.max(ncol, r.length); });
      var widths = [];
      for (var c = 0; c < ncol; c++) { widths[c] = 0; rows.forEach(function (r) { if (r.length > c + 0 && c < r.length - 0) { widths[c] = Math.max(widths[c], (r[c] || '').length); } }); }
      rows.forEach(function (r) {
        var cells = [];
        for (var ci = 0; ci < ncol; ci++) {
          var cell = r[ci] === undefined ? '' : r[ci];
          cells.push(ci === ncol - 1 ? cell : cell + ' '.repeat(widths[ci] - cell.length));
        }
        ctx.out(cells.join('  ') + '\n');
      });
    });
  };
  COMMANDS.nl = function (ctx) {
    var n = 0;
    return eachInput(ctx, ctx.args.filter(function (a) { return a.charAt(0) !== '-'; }), function (text) {
      splitLines(text).forEach(function (l) {
        if (l === '') { ctx.out('       \n'); return; }
        n++; ctx.out(('     ' + n).slice(-6) + '\t' + l + '\n');
      });
    });
  };
  COMMANDS.rev = function (ctx) {
    return eachInput(ctx, ctx.args, function (text) { splitLines(text).forEach(function (l) { ctx.out(Array.from(l).reverse().join('') + '\n'); }); });
  };
  COMMANDS.diff = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'uqiw' });
    if (o._.length !== 2) { return usage(ctx, 'usage: diff FILE1 FILE2'); }
    var a = fileText(ctx, o._[0]), b = fileText(ctx, o._[1]);
    if (a === null || b === null) { ctx.err('diff: ' + (a === null ? o._[0] : o._[1]) + ': No such file or directory\n'); return 2; }
    if (a === b) { return 0; }
    var la = splitLines(a), lb = splitLines(b);
    var out = [];
    var i = 0, j = 0;
    while (i < la.length || j < lb.length) {
      if (la[i] === lb[j]) { i++; j++; continue; }
      var k = lb.indexOf(la[i], j);
      if (i < la.length && k !== -1 && (k - j) < 6) { while (j < k) { out.push('> ' + lb[j++]); } continue; }
      if (i < la.length) { out.push('< ' + la[i++]); } else { out.push('> ' + lb[j++]); }
    }
    ctx.out(joinLines(out));
    return 1;
  };

  /* ----- awk / sed / jq front ends ----- */
  function loadInputs(ctx, files) {
    var list = [];
    var st = 0;
    files.forEach(function (f) {
      if (f === '-') { list.push({ name: '-', text: ctx.stdin || '' }); return; }
      var t = fileText(ctx, f);
      if (t === null) { ctx.err(ctx.name + ': ' + f + ': No such file or directory\n'); st = 2; list.push({ name: f, error: true }); return; }
      list.push({ name: f, text: t });
    });
    return { list: list, status: st };
  }
  function awkCmd(ctx) {
    var o = parseOpts(ctx.args, { short: '', withArg: 'Fvf', stopAtFirst: false, long: { 'field-separator': 'F=', assign: 'v=', file: 'f=' } });
    var prog;
    var files = o._.slice();
    if (o.vals.f) { prog = o.vals.f.map(function (f) { var t = fileText(ctx, f); if (t === null) { throw ShellError('awk: can\'t open file ' + f, 2); } return t; }).join('\n'); }
    else { if (!files.length) { return usage(ctx, 'usage: awk [-F fs][-v var=value][prog | -f progfile][file ...]'); } prog = files.shift(); }
    var vars = {};
    (o.vals.v || []).forEach(function (kv) { var m = /^([A-Za-z_]\w*)=(.*)$/.exec(kv); if (m) { vars[m[1]] = Awk.unescape(m[2]); } });
    var fs = o.vals.F ? o.vals.F[0] : undefined;
    if (fs === 't') { fs = '\t'; } else if (fs !== undefined) { fs = Awk.unescape(fs); }
    var ast;
    try { ast = Awk.parse(prog); } catch (e) { if (e.awk) { ctx.err('awk: ' + e.message + '\n'); return 2; } throw e; }
    var inputs = loadInputs(ctx, files);
    var pend = {};
    var code;
    try {
      code = Awk.run(ast, {
        fs: fs, vars: vars, files: inputs.list, stdin: ctx.stdin || '',
        out: ctx.out, err: ctx.err,
        write: function (name, text, append) {
          var p = ctx.sh.path(name);
          if (p === null) { return; }
          ctx.vfs.write(p, text, append || pend[name]);
          pend[name] = true;
        }
      });
    } catch (e) { if (e.awk) { ctx.err('awk: ' + e.message + '\n'); return 2; } throw e; }
    return inputs.status || code || 0;
  }
  COMMANDS.awk = awkCmd;
  COMMANDS.gawk = awkCmd;
  COMMANDS.mawk = awkCmd;
  COMMANDS.sed = function (ctx) {
    var o = parseOpts(ctx.args, { short: 'nEriszu', withArg: 'ef', long: { quiet: 'n', silent: 'n', 'regexp-extended': 'E', expression: 'e=', 'in-place': 'i', file: 'f=' } });
    var files = o._.slice();
    var scripts = o.vals.e ? o.vals.e.slice() : [];
    if (o.vals.f) { o.vals.f.forEach(function (f) { var t = fileText(ctx, f); if (t === null) { throw ShellError('sed: couldn\'t open file ' + f + ': No such file or directory', 1); } scripts.push(t); }); }
    if (!scripts.length) {
      if (!files.length) { return usage(ctx, 'Usage: sed [OPTION]... {script-only-if-no-other-script} [input-file]...'); }
      scripts.push(files.shift());
    }
    var cmds;
    try { cmds = Sed.parse(scripts.join('\n'), !!(o.flags.E || o.flags.r)); } catch (e) { if (e.sed) { ctx.err('sed: -e expression #1, char 0: ' + e.message + '\n'); return 1; } throw e; }
    var st = 0;
    if (o.flags.i) {
      files.forEach(function (f) {
        var p = ctx.sh.path(f);
        var t = p === null ? null : ctx.vfs.readText(p);
        if (t === null) { ctx.err('sed: can\'t read ' + f + ': No such file or directory\n'); st = 2; return; }
        ctx.vfs.write(p, Sed.run(cmds, t, { quiet: !!o.flags.n }), false);
      });
      return st;
    }
    var inputs = files.length ? files : [];
    if (!inputs.length) { ctx.out(Sed.run(cmds, ctx.stdin || '', { quiet: !!o.flags.n })); return 0; }
    var all = '';
    st = eachInput(ctx, inputs, function (text) { all += text; });
    ctx.out(Sed.run(cmds, all, { quiet: !!o.flags.n }));
    return st;
  };
  COMMANDS.jq = function (ctx) {
    var args = ctx.args.slice();
    var flags = {};
    var vars = {};
    var named = {};
    var program = null;
    var files = [];
    var indent = '  ';
    for (var i = 0; i < args.length; i++) {
      var a = args[i];
      if (a === '--version') { ctx.out(TOOL_VERSIONS.jq + '\n'); return 0; }
      if (a === '--arg') { vars[args[i + 1]] = args[i + 2]; i += 2; continue; }
      if (a === '--argjson') { try { vars[args[i + 1]] = JSON.parse(args[i + 2]); } catch (e) { ctx.err('jq: Invalid JSON text passed to --argjson\n'); return 2; } i += 2; continue; }
      if (a === '--tab') { indent = '\t'; continue; }
      if (a === '--indent') { indent = ' '.repeat(parseInt(args[++i], 10) || 0); continue; }
      if (a === '--raw-output') { flags.r = true; continue; }
      if (a === '--compact-output') { flags.c = true; continue; }
      if (a === '--slurp') { flags.s = true; continue; }
      if (a === '--null-input') { flags.n = true; continue; }
      if (a === '--sort-keys') { flags.S = true; continue; }
      if (a === '--exit-status') { flags.e = true; continue; }
      if (a === '--join-output') { flags.r = true; flags.j = true; continue; }
      if (a === '--raw-input') { flags.R = true; continue; }
      if (a === '--ascii-output' || a === '--unbuffered' || a === '--seq' || a === '--color-output' || a === '--monochrome-output') { continue; }
      if (a === '-f' || a === '--from-file') { var pt = fileText(ctx, args[++i]); if (pt === null) { ctx.err('jq: error: Could not open ' + args[i] + '\n'); return 2; } program = pt; continue; }
      if (a.charAt(0) === '-' && a.length > 1 && !/^-\d/.test(a)) {
        for (var j = 1; j < a.length; j++) {
          var ch = a.charAt(j);
          if ('rcsnSejRaCMh'.indexOf(ch) === -1) { ctx.err('jq: Unknown option: ' + a + '\n'); return 2; }
          if (ch === 'h') { ctx.out('Usage:\tjq [OPTIONS] FILTER [FILES...]\n'); return 0; }
          flags[ch] = true;
        }
        continue;
      }
      if (program === null) { program = a; } else { files.push(a); }
    }
    if (program === null) { ctx.err('Usage:\tjq [OPTIONS] FILTER [FILES...]\n'); return 2; }
    var ast;
    try { ast = Jq.compile(program); } catch (e) {
      if (e instanceof Jq.JqError) { ctx.err('jq: error: ' + e.value + ' at <top-level>, line 1:\n' + program + '\njq: 1 compile error\n'); return 3; }
      throw e;
    }
    var inputs = [];
    var status = 0;
    var raws = [];
    var inp = loadInputs(ctx, files);
    if (!files.length) { inp.list = [{ name: '<stdin>', text: ctx.stdin || '' }]; }
    inp.list.forEach(function (f) { if (!f.error) { raws.push(f); } });
    if (inp.status) { status = 2; }
    try {
      if (flags.R) {
        var all = raws.map(function (r) { return r.text; }).join('');
        inputs = flags.s ? [all] : splitLines(all);
      } else {
        raws.forEach(function (r) { inputs = inputs.concat(Jq.parseStream(r.text)); });
        if (flags.s) { inputs = [inputs]; }
      }
    } catch (e) {
      ctx.err('jq: error (at ' + (raws[0] ? raws[0].name : '<stdin>') + ':0): ' + e.message + '\n');
      return 2;
    }
    if (flags.n) { inputs = [null]; }
    var last;
    var gotOutput = false;
    function emitValue(v) {
      var s;
      if (flags.r && typeof v === 'string') { s = v; }
      else { s = Jq.stringify(v, flags.c ? '' : indent, !!flags.S, ''); }
      ctx.out(s + (flags.j ? '' : '\n'));
      last = v;
      gotOutput = true;
    }
    for (var k = 0; k < inputs.length; k++) {
      try {
        for (var out of Jq.run(ast, inputs[k], vars)) { emitValue(out); }
      } catch (e) {
        if (e instanceof Jq.JqError) {
          if (e.halt) { return e.value === null ? 0 : 5; }
          var msg = typeof e.value === 'string' ? e.value : Jq.toJSON(e.value) + ' (not a string)';
          ctx.err('jq: error (at ' + (raws[0] ? raws[0].name : '<stdin>') + ':' + k + '): ' + msg + '\n');
          status = 5;
        } else { throw e; }
      }
    }
    if (flags.e && status === 0) { return !gotOutput ? 4 : (last === null || last === false ? 1 : 0); }
    return status;
  };

  /* ----- tshark ----- */
  COMMANDS.tshark = function (ctx) {
    var args = ctx.args.slice();
    var file = null, filter = null, fields = [], quiet = false, tmode = 'text', follow = null, count = Infinity;
    var sep = '\t', header = false, version = false;
    for (var i = 0; i < args.length; i++) {
      var a = args[i];
      if (a === '-r') { file = args[++i]; }
      else if (a === '-n') { /* no name resolution: always */ }
      else if (a === '-q') { quiet = true; }
      else if (a === '-Y' || a === '-R') { filter = args[++i]; }
      else if (a === '-T') { tmode = args[++i]; }
      else if (a === '-e') { fields.push(args[++i]); }
      else if (a === '-c') { count = parseInt(args[++i], 10); }
      else if (a === '-E') {
        var kv = /^(\w+)=(.*)$/.exec(args[++i] || '');
        if (kv && kv[1] === 'separator') { sep = kv[2] === '/t' ? '\t' : kv[2] === '/s' ? ' ' : kv[2]; }
        if (kv && kv[1] === 'header') { header = kv[2] === 'y'; }
      }
      else if (a === '-z') {
        var z = /^follow,tcp,ascii,(\d+)$/.exec(args[++i] || '');
        if (!z) { ctx.err('tshark: -z option "' + args[i] + '" is not available in the page terminal (supported: follow,tcp,ascii,N)\n'); return 2; }
        follow = parseInt(z[1], 10);
      }
      else if (a === '--version' || a === '-v') { version = true; }
      else if (a === '-o' || a === '-d' || a === '-t' || a === '-w') { i++; }
      else if (a === '-V' || a === '-x') { ctx.err('tshark: ' + a + ' is not available in the page terminal\n'); return 2; }
      else if (a.charAt(0) === '-' && a.length > 1) { /* ignore other flags */ }
    }
    if (version) {
      ctx.out(TOOL_VERSIONS.tshark + '\n\nCopyright 1998-2023 Gerald Combs <gerald@wireshark.org> and contributors.\nLicense GPLv2+: GNU GPL version 2 or later <https://www.gnu.org/licenses/gpl-2.0.html>\n');
      return 0;
    }
    if (file === null) { ctx.err('tshark: live capture is not available in the page terminal; read a capture with -r FILE\n'); return 2; }
    var p = ctx.sh.path(file);
    var entry = p === null ? null : ctx.vfs.entry(p);
    if (!entry) { ctx.err('tshark: The file "' + file + '" doesn\'t exist.\n'); return 2; }
    var bytes = ctx.vfs.readBytes(p);
    var cap;
    try { cap = Pcap.parse(bytes); } catch (e) { if (e.pcap) { ctx.err('tshark: The file "' + file + '" isn\'t a capture file in a format TShark understands.\n'); return 2; } throw e; }
    var pred = function () { return true; };
    if (filter) {
      try { pred = Pcap.compileFilter(filter); } catch (e) { if (e.pcap) { ctx.err('tshark: "' + filter + '" isn\'t a valid display filter: ' + e.message + '\n'); return 2; } throw e; }
    }
    var pkts = cap.packets.filter(pred).slice(0, count === Infinity ? undefined : count);
    if (tmode === 'fields') {
      if (!fields.length) { ctx.err('tshark: Some fields aren\'t valid; use -e with -T fields\n'); return 2; }
      if (header) { ctx.out(fields.join(sep) + '\n'); }
      pkts.forEach(function (pk) {
        ctx.out(fields.map(function (f) { return (pk.f[f] || []).join(','); }).join(sep) + '\n');
      });
    } else if (tmode !== 'text') {
      ctx.err('tshark: -T ' + tmode + ' is not available in the page terminal (supported: text, fields)\n');
      return 2;
    } else if (!quiet) {
      var rendered = entry.rendered || '';
      var byNum = {};
      rendered.split('\n').forEach(function (l) { var m = /^\s*(\d+) /.exec(l); if (m && byNum[m[1]] === undefined) { byNum[m[1]] = l; } });
      pkts.forEach(function (pk) { if (byNum[pk.num]) { ctx.out(byNum[pk.num] + '\n'); } });
    }
    if (follow !== null) {
      try { ctx.out(Pcap.follow(cap, follow)); } catch (e) { if (e.pcap) { ctx.err('tshark: ' + e.message + '\n'); return 2; } throw e; }
    }
    return 0;
  };
  COMMANDS.dig = function (ctx) {
    if (ctx.args.indexOf('-v') !== -1 || ctx.args.indexOf('-V') !== -1) { ctx.out(TOOL_VERSIONS.dig + '\n'); return 0; }
    ctx.err('dig: no network in the page terminal. The labs ship the answers as evidence files; read those instead.\n');
    return 9;
  };
  COMMANDS.whois = function (ctx) {
    if (ctx.args.indexOf('--version') !== -1) { ctx.out(TOOL_VERSIONS.whois + '\n\nReport bugs to <md+whois@linux.it>.\n'); return 0; }
    var staged = ctx.vfs.allFiles().filter(function (f) { return /^whois-/.test(f); })[0];
    ctx.err('whois: no network in the page terminal.' + (staged ? ' The staged report is ' + staged + ' (try: cat ' + staged + ').' : '') + '\n');
    return 2;
  };
  COMMANDS.python3 = function (ctx) {
    var code = null;
    for (var i = 0; i < ctx.args.length; i++) { if (ctx.args[i] === '-c') { code = ctx.args[i + 1]; } }
    if (code && /fromisoformat/.test(code) && /total_seconds/.test(code)) {
      // The L2.6 idiom: print the seconds between consecutive ISO timestamps on stdin.
      var times = splitLines(ctx.stdin || '').map(function (l) { return Date.parse(l.trim().replace('Z', '+00:00').replace(' ', 'T')); });
      for (var k = 1; k < times.length; k++) { var d = (times[k] - times[k - 1]) / 1000; ctx.out((Number.isInteger(d) ? d.toFixed(1) : String(d)) + '\n'); }
      return 0;
    }
    ctx.err('python3: the page terminal only emulates the timestamp-delta snippet from L2.6. Use awk, jq or the terminal kit for other scripts.\n');
    return 1;
  };
  COMMANDS.python = COMMANDS.python3;

  /* ----- the lab bridge ----- */
  COMMANDS.lab = function (ctx) {
    var sub = ctx.args[0];
    var hooks = ctx.sh.hooks;
    if (sub === 'check' || sub === 'hint' || sub === 'status') {
      var ids = ctx.args.slice(1);
      if (ids.length >= 2 && ids[1] !== ctx.vfs.id) {
        ctx.err('lab: this page terminal is attached to ' + ctx.vfs.id + '; open ' + ids[1] + ' in the track list to work on it.\n');
        return 2;
      }
    }
    if (sub === 'check' && hooks.check) {
      var res = hooks.check();
      res.results.forEach(function (r, i) {
        ctx.out('  ' + (r.ok ? '✓' : '✗') + '  [' + (i + 1) + '] ' + r.msg + '\n');
        if (!r.ok && r.hint) { ctx.out('           look at: ' + r.hint + '\n'); }
        if (r.terminal) { ctx.out('           (terminal-only check, counted satisfied here)\n'); }
      });
      ctx.out('checks ' + res.passed + '/' + res.total + '\n');
      if (res.pass) { ctx.out('\nAll checks passed. Answer the quiz in the Check panel below to finish the lab.\n'); return 0; }
      return 1;
    }
    if (sub === 'hint' && hooks.hint) { var h = hooks.hint(); ctx.out(h + '\n'); return 0; }
    if (sub === 'status' && hooks.status) { ctx.out(hooks.status() + '\n'); return 0; }
    if (sub === 'start') { ctx.out('This page already opened ' + ctx.vfs.id + '. The workspace is the current directory.\n'); return 0; }
    ctx.out('lab (page terminal): check | hint | status\n  lab check soc ' + ctx.vfs.id + '    run the grader on your files\n');
    return sub ? 2 : 0;
  };

  COMMANDS.help = function (ctx) {
    ctx.out('Simulated terminal for ' + ctx.vfs.id + '. It runs on this lab\'s own files; nothing leaves the page.\n\n' +
      'Files: ls cat head tail less wc cp mv rm mkdir touch find file sha256sum base64 xxd\n' +
      'Text:  grep rg sed awk cut tr sort uniq column nl rev tee diff xargs\n' +
      'Data:  jq (JSON)  tshark (packet captures: -r -Y -T fields -e -z follow,tcp,ascii,N)\n' +
      'Other: echo printf cd pwd env history clear which; pipes | redirects > >> < 2>&1; && || ;\n' +
      'Lab:   lab check soc ' + ctx.vfs.id + '   lab hint soc ' + ctx.vfs.id + '\n\n' +
      'Output you redirect into a graded file (answers.txt, toolcheck.txt, ...) shows up in the Workspace box.\n' +
      'dig and whois print only their version here: there is no network. Tab completes; Up/Down recalls history.\n');
    return 0;
  };
