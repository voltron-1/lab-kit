
  /* ---------- virtual filesystem ----------
   * Paths are relative to the lab workspace root ('' is the root). Entries:
   *   {text}                    static text
   *   {bytes, magic}            binary
   *   {get(), set(t)}           backed by a page widget (a Workspace textarea)
   * A 'files/' prefix aliases the root, because the lab text uses both. */
  function VFS(id) {
    this.id = id;
    this.entries = new Map();
    this.dirs = new Set(['']);
    this.removed = new Set();
    this.abs = '/home/analyst/lab-kit/workspace/soc/' + id;
  }
  VFS.prototype.norm = function (p) {
    var parts = [];
    String(p).split('/').forEach(function (s) {
      if (s === '' || s === '.') { return; }
      if (s === '..') { parts.pop(); return; }
      parts.push(s);
    });
    return parts.join('/');
  };
  // Resolve a user path against a cwd to a root-relative path, or null when it leaves the workspace.
  VFS.prototype.resolve = function (cwd, p) {
    var full;
    if (p === '/dev/null') { return '/dev/null'; }
    if (p === '~' || p.indexOf('~/') === 0) { p = this.abs + p.slice(1); }
    if (p.charAt(0) === '/') {
      if (p === this.abs || p.indexOf(this.abs + '/') === 0) { full = p.slice(this.abs.length); }
      else { return null; }
    } else {
      full = (cwd ? cwd + '/' : '') + p;
    }
    var n = this.norm(full);
    if (n === 'files' || n.indexOf('files/') === 0) {
      if (!this.dirs.has('files')) { n = n === 'files' ? '' : n.slice(6); }
    }
    return n;
  };
  VFS.prototype.addDirs = function (path) {
    var parts = path.split('/');
    parts.pop();
    var cur = '';
    for (var i = 0; i < parts.length; i++) {
      cur = cur ? cur + '/' + parts[i] : parts[i];
      this.dirs.add(cur);
    }
  };
  VFS.prototype.add = function (path, entry) {
    path = this.norm(path);
    this.entries.set(path, entry);
    this.removed.delete(path);
    this.addDirs(path);
  };
  VFS.prototype.entry = function (path) {
    if (path === '/dev/null') { return { text: '' }; }
    if (this.removed.has(path)) { return null; }
    var e = this.entries.get(path);
    if (!e) { return null; }
    if (e.get && String(e.get()).trim() === '') { return null; }
    return e;
  };
  VFS.prototype.isFile = function (path) { return this.entry(path) !== null; };
  VFS.prototype.isDir = function (path) { return this.dirs.has(path); };
  VFS.prototype.exists = function (path) { return this.isFile(path) || this.isDir(path); };
  VFS.prototype.size = function (path) {
    var e = this.entry(path);
    if (!e) { return 0; }
    if (e.bytes) { return e.bytes.length; }
    return utf8Encode(e.get ? e.get() : e.text).length;
  };
  VFS.prototype.readText = function (path) {
    var e = this.entry(path);
    if (!e) { return null; }
    if (e.bytes) { return utf8Decode(e.bytes); }
    return e.get ? String(e.get()) : e.text;
  };
  VFS.prototype.readBytes = function (path) {
    var e = this.entry(path);
    if (!e) { return null; }
    return e.bytes || utf8Encode(e.get ? String(e.get()) : e.text);
  };
  VFS.prototype.write = function (path, text, append) {
    if (path === '/dev/null') { return; }
    path = this.norm(path);
    var cur = this.entries.get(path);
    if (append && this.entry(path)) { text = this.readText(path) + text; }
    if (cur && cur.get) { cur.set(text); }
    else { this.entries.set(path, { text: text }); this.addDirs(path); }
    this.removed.delete(path);
  };
  VFS.prototype.writeBytes = function (path, bytes, magic) {
    path = this.norm(path);
    this.entries.set(path, { bytes: bytes, magic: magic || 'unknown' });
    this.addDirs(path);
    this.removed.delete(path);
  };
  VFS.prototype.remove = function (path) {
    var e = this.entries.get(path);
    if (e && e.get) { e.set(''); } else { this.entries.delete(path); }
    this.removed.add(path);
  };
  VFS.prototype.mkdir = function (path) {
    var parts = this.norm(path).split('/');
    var cur = '';
    for (var i = 0; i < parts.length; i++) {
      cur = cur ? cur + '/' + parts[i] : parts[i];
      if (cur) { this.dirs.add(cur); }
    }
  };
  // Names directly inside dir (files and subdirectories), sorted.
  VFS.prototype.list = function (dir) {
    var pre = dir ? dir + '/' : '';
    var seen = {};
    var self = this;
    this.entries.forEach(function (v, k) {
      if (k.indexOf(pre) !== 0 || !self.isFile(k)) { return; }
      seen[k.slice(pre.length).split('/')[0]] = true;
    });
    this.dirs.forEach(function (d) {
      if (d === '' || d === dir || d.indexOf(pre) !== 0) { return; }
      seen[d.slice(pre.length).split('/')[0]] = true;
    });
    return Object.keys(seen).sort();
  };
  VFS.prototype.allFiles = function () {
    var self = this;
    var out = [];
    this.entries.forEach(function (v, k) { if (self.isFile(k)) { out.push(k); } });
    return out.sort();
  };
  VFS.prototype.copy = function (src, dst) {
    var e = this.entry(src);
    if (e && e.bytes) { this.writeBytes(dst, e.bytes, e.magic); } else { this.write(dst, this.readText(src), false); }
  };
  VFS.prototype.magicOf = function (path) {
    var e = this.entry(path);
    return e && e.magic ? e.magic : null;
  };
