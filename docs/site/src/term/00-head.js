/* term — simulated shell for the lab page. Concatenated from src/term/*.js
 * (build-site.sh) into one IIFE. Runs a bash-like language over the lab's own
 * files: no real processes, no network. Command behaviour follows GNU
 * coreutils / grep / sed / gawk / jq 1.7 for the options the labs teach. */
(function (root) {
  'use strict';

  function splitLines(text) {
    if (text === '') { return []; }
    var l = text.split('\n');
    if (l[l.length - 1] === '') { l.pop(); }
    return l;
  }
  function joinLines(arr) { return arr.length ? arr.join('\n') + '\n' : ''; }
  function isBin(x) { return x && typeof x === 'object' && x.bytes instanceof Uint8Array; }

  function ShellError(msg, code) {
    var e = new Error(msg);
    e.shellError = true;
    e.code = code || 1;
    return e;
  }

  function utf8Encode(s) { return new TextEncoder().encode(s); }
  function utf8Decode(b) { return new TextDecoder('utf-8').decode(b); }
  function b64ToBytes(b64) {
    var bin = atob(b64);
    var out = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) { out[i] = bin.charCodeAt(i); }
    return out;
  }
  function bytesToB64(bytes) {
    var s = '';
    for (var i = 0; i < bytes.length; i++) { s += String.fromCharCode(bytes[i]); }
    return btoa(s);
  }

  /* ---------- sha256 ---------- */
  var K256 = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
  ];
  function sha256(bytes) {
    var h = [0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19];
    var len = bytes.length;
    var padLen = (((len + 9 + 63) >> 6) << 6);
    var m = new Uint8Array(padLen);
    m.set(bytes);
    m[len] = 0x80;
    var dv = new DataView(m.buffer);
    dv.setUint32(padLen - 8, Math.floor(len / 0x20000000), false);
    dv.setUint32(padLen - 4, (len << 3) >>> 0, false);
    var w = new Array(64);
    function rotr(x, n) { return (x >>> n) | (x << (32 - n)); }
    for (var off = 0; off < padLen; off += 64) {
      var t;
      for (t = 0; t < 16; t++) { w[t] = dv.getUint32(off + t * 4, false); }
      for (t = 16; t < 64; t++) {
        var s0 = rotr(w[t - 15], 7) ^ rotr(w[t - 15], 18) ^ (w[t - 15] >>> 3);
        var s1 = rotr(w[t - 2], 17) ^ rotr(w[t - 2], 19) ^ (w[t - 2] >>> 10);
        w[t] = (w[t - 16] + s0 + w[t - 7] + s1) | 0;
      }
      var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
      for (t = 0; t < 64; t++) {
        var S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
        var ch = (e & f) ^ (~e & g);
        var t1 = (hh + S1 + ch + K256[t] + w[t]) | 0;
        var S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
        var maj = (a & b) ^ (a & c) ^ (b & c);
        var t2 = (S0 + maj) | 0;
        hh = g; g = f; f = e; e = (d + t1) | 0; d = c; c = b; b = a; a = (t1 + t2) | 0;
      }
      h[0] = (h[0] + a) | 0; h[1] = (h[1] + b) | 0; h[2] = (h[2] + c) | 0; h[3] = (h[3] + d) | 0;
      h[4] = (h[4] + e) | 0; h[5] = (h[5] + f) | 0; h[6] = (h[6] + g) | 0; h[7] = (h[7] + hh) | 0;
    }
    return h.map(function (x) { return ('00000000' + (x >>> 0).toString(16)).slice(-8); }).join('');
  }

  /* ---------- POSIX regex -> JS ---------- */
  var CLASSES = {
    alpha: 'A-Za-z', digit: '0-9', alnum: 'A-Za-z0-9', upper: 'A-Z', lower: 'a-z',
    space: ' \\t\\n\\r\\f\\v', blank: ' \\t', punct: '!-\\/:-@\\[-`{-~', print: ' -~',
    graph: '!-~', cntrl: '\\x00-\\x1f\\x7f', xdigit: '0-9A-Fa-f', word: 'A-Za-z0-9_'
  };

  // mode: 'ere' | 'bre' | 'pcre'. Returns a JS RegExp source string.
  function posixToJs(pat, mode) {
    if (mode === 'pcre') { return pat; }
    var ere = mode === 'ere';
    var out = '';
    var i = 0;
    var n = pat.length;
    while (i < n) {
      var c = pat.charAt(i);
      if (c === '[') {
        var j = i + 1;
        var neg = false;
        var body = '';
        if (pat.charAt(j) === '^') { neg = true; j++; }
        var first = true;
        while (j < n && (pat.charAt(j) !== ']' || first)) {
          first = false;
          if (pat.charAt(j) === '[' && pat.charAt(j + 1) === ':') {
            var e = pat.indexOf(':]', j + 2);
            if (e > 0) { body += CLASSES[pat.slice(j + 2, e)] || ''; j = e + 2; continue; }
          }
          var ch = pat.charAt(j);
          body += (ch === '\\' || ch === ']' || ch === '[' || ch === '^') ? '\\' + ch : ch;
          j++;
        }
        if (j >= n) { out += '\\['; i++; continue; }
        out += '[' + (neg ? '^' : '') + body + ']';
        i = j + 1;
        continue;
      }
      if (c === '\\') {
        var d = pat.charAt(i + 1);
        i += 2;
        if (d === '') { out += '\\\\'; break; }
        if (!ere && '(){}|+?'.indexOf(d) !== -1) { out += d === '(' || d === ')' || d === '|' || d === '+' || d === '?' ? d : d; continue; }
        if (d === '<' || d === '>') { out += '\\b'; continue; }
        if ('wWsSbB'.indexOf(d) !== -1) { out += '\\' + d; continue; }
        if (/[0-9]/.test(d)) { out += '\\' + d; continue; }
        if (/[A-Za-z]/.test(d)) { out += d === 'n' ? '\\n' : d === 't' ? '\\t' : d; continue; }
        out += '\\' + d;
        continue;
      }
      if (!ere && (c === '(' || c === ')' || c === '|' || c === '+' || c === '?' || c === '{' || c === '}')) {
        out += '\\' + c; i++; continue;
      }
      if (ere && c === '{') {
        var m = /^\{(\d+)(,(\d*))?\}/.exec(pat.slice(i));
        if (m) { out += m[0]; i += m[0].length; continue; }
        out += '\\{'; i++; continue;
      }
      if (c === '}' && ere) { out += '\\}'; i++; continue; }
      out += c;
      i++;
    }
    return out;
  }
  function makeRegex(pat, mode, flags) {
    try { return new RegExp(posixToJs(pat, mode), flags || ''); } catch (e) {
      throw ShellError('Invalid regular expression: ' + pat, 2);
    }
  }
