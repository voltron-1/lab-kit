
  /* ---------- pcap + tshark ----------
   * A small libpcap/Ethernet/IPv4/TCP/UDP dissector (DNS, HTTP request/response,
   * TLS ClientHello SNI) plus the tshark options the labs use: -r -n -q -c -Y
   * -T fields -e -E, and -z follow,tcp,ascii,N. The default one-line-per-packet
   * view reuses the real tshark text the build captured. */
  var Pcap = (function () {
    function PcapError(msg) { var e = new Error(msg); e.pcap = true; return e; }

    function ipStr(b, o) { return b[o] + '.' + b[o + 1] + '.' + b[o + 2] + '.' + b[o + 3]; }
    function ascii(b, s, e) {
      var out = '';
      for (var i = s; i < e; i++) { out += String.fromCharCode(b[i]); }
      return out;
    }

    function dnsName(b, off, base) {
      var labels = [];
      var jumped = false;
      var end = off;
      var guard = 0;
      while (guard++ < 64) {
        var len = b[off];
        if (len === undefined) { break; }
        if (len === 0) { if (!jumped) { end = off + 1; } break; }
        if ((len & 0xc0) === 0xc0) {
          if (!jumped) { end = off + 2; }
          off = base + (((len & 0x3f) << 8) | b[off + 1]);
          jumped = true;
          continue;
        }
        labels.push(ascii(b, off + 1, off + 1 + len));
        off += len + 1;
        if (!jumped) { end = off; }
      }
      return { name: labels.join('.'), end: end };
    }

    function parseDns(b, off, f) {
      if (b.length - off < 12) { return false; }
      var id = (b[off] << 8) | b[off + 1];
      var flags = (b[off + 2] << 8) | b[off + 3];
      var qd = (b[off + 4] << 8) | b[off + 5];
      var an = (b[off + 6] << 8) | b[off + 7];
      f['dns.id'] = ['0x' + ('0000' + id.toString(16)).slice(-4)];
      f['dns.flags.response'] = [(flags >> 15) & 1 ? '1' : '0'];
      f['dns.flags.opcode'] = [String((flags >> 11) & 15)];
      f['dns.flags.rcode'] = [String(flags & 15)];
      f['dns.count.queries'] = [String(qd)];
      f['dns.count.answers'] = [String(an)];
      var p = off + 12;
      f['dns.qry.name'] = [];
      f['dns.qry.type'] = [];
      for (var i = 0; i < qd; i++) {
        var q = dnsName(b, p, off);
        p = q.end;
        f['dns.qry.name'].push(q.name);
        f['dns.qry.type'].push(String((b[p] << 8) | b[p + 1]));
        p += 4;
      }
      if (!f['dns.qry.name'].length) { delete f['dns.qry.name']; delete f['dns.qry.type']; }
      f['dns.resp.name'] = [];
      f['dns.a'] = [];
      f['dns.aaaa'] = [];
      f['dns.cname'] = [];
      f['dns.resp.type'] = [];
      for (var j = 0; j < an; j++) {
        var rn = dnsName(b, p, off);
        p = rn.end;
        var type = (b[p] << 8) | b[p + 1];
        var rdlen = (b[p + 8] << 8) | b[p + 9];
        p += 10;
        f['dns.resp.name'].push(rn.name);
        f['dns.resp.type'].push(String(type));
        if (type === 1 && rdlen === 4) { f['dns.a'].push(ipStr(b, p)); }
        else if (type === 5) { f['dns.cname'].push(dnsName(b, p, off).name); }
        p += rdlen;
      }
      ['dns.resp.name', 'dns.a', 'dns.aaaa', 'dns.cname', 'dns.resp.type'].forEach(function (k) { if (!f[k].length) { delete f[k]; } });
      return true;
    }

    function parseHttp(b, s, e, f) {
      var text = ascii(b, s, e);
      var head = text.split('\r\n\r\n')[0];
      var lines = head.split('\r\n');
      var m = /^([A-Z]+) (\S+) HTTP\/(\d\.\d)$/.exec(lines[0]);
      var r = /^HTTP\/(\d\.\d) (\d{3})(?: (.*))?$/.exec(lines[0]);
      if (!m && !r) { return false; }
      if (m) {
        f['http.request'] = ['1'];
        f['http.request.method'] = [m[1]];
        f['http.request.uri'] = [m[2]];
        f['http.request.version'] = ['HTTP/' + m[3]];
      } else {
        f['http.response'] = ['1'];
        f['http.response.code'] = [r[2]];
        f['http.response.phrase'] = [r[3] || ''];
      }
      lines.slice(1).forEach(function (l) {
        var h = /^([^:]+):\s*(.*)$/.exec(l);
        if (!h) { return; }
        var k = h[1].toLowerCase();
        if (k === 'host') { f['http.host'] = [h[2]]; }
        else if (k === 'user-agent') { f['http.user_agent'] = [h[2]]; }
        else if (k === 'content-type') { f['http.content_type'] = [h[2]]; }
        else if (k === 'content-length') { f['http.content_length'] = [h[2]]; }
        else if (k === 'server') { f['http.server'] = [h[2]]; }
        else if (k === 'referer') { f['http.referer'] = [h[2]]; }
      });
      if (m && f['http.host']) { f['http.request.full_uri'] = ['http://' + f['http.host'][0] + m[2]]; }
      return true;
    }

    function parseTlsHello(b, s, e, f) {
      if (e - s < 6 || b[s] !== 22 || b[s + 5] !== 1) { return false; }
      f['tls.record.content_type'] = ['22'];
      f['tls.handshake.type'] = ['1'];
      var p = s + 5 + 4 + 2 + 32;
      var sid = b[p];
      p += 1 + sid;
      var cs = (b[p] << 8) | b[p + 1];
      p += 2 + cs;
      var cm = b[p];
      p += 1 + cm;
      var extLen = (b[p] << 8) | b[p + 1];
      p += 2;
      var end = Math.min(p + extLen, e);
      while (p + 4 <= end) {
        var t = (b[p] << 8) | b[p + 1];
        var l = (b[p + 2] << 8) | b[p + 3];
        if (t === 0) {
          var nl = (b[p + 7] << 8) | b[p + 8];
          f['tls.handshake.extensions_server_name'] = [ascii(b, p + 9, p + 9 + nl)];
        }
        p += 4 + l;
      }
      return true;
    }

    function parse(bytes) {
      if (bytes.length < 24) { throw PcapError('the file is not a capture file'); }
      var dv = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
      var magic = dv.getUint32(0, false);
      var le;
      var nano = false;
      if (magic === 0xd4c3b2a1) { le = true; }
      else if (magic === 0xa1b2c3d4) { le = false; }
      else if (magic === 0x4d3cb2a1) { le = true; nano = true; }
      else if (magic === 0xa1b23c4d) { le = false; nano = true; }
      else { throw PcapError('the file isn\'t a capture file in a format tshark understands'); }
      var link = dv.getUint32(20, le);
      var pos = 24;
      var packets = [];
      var t0 = null;
      var streams = {};
      var nstream = 0;
      while (pos + 16 <= bytes.length) {
        var sec = dv.getUint32(pos, le);
        var frac = dv.getUint32(pos + 4, le);
        var incl = dv.getUint32(pos + 8, le);
        var orig = dv.getUint32(pos + 12, le);
        pos += 16;
        var b = bytes.subarray(pos, pos + incl);
        pos += incl;
        var t = sec + frac / (nano ? 1e9 : 1e6);
        if (t0 === null) { t0 = t; }
        var pk = { num: packets.length + 1, time: t - t0, len: orig, f: {}, proto: '', src: '', dst: '', payload: null, stream: null };
        var f = pk.f;
        f['frame.number'] = [String(pk.num)];
        f['frame.len'] = [String(orig)];
        f['frame.time_relative'] = [(t - t0).toFixed(9)];
        if (link === 1 && b.length >= 14) {
          var et = (b[12] << 8) | b[13];
          f['eth.type'] = ['0x' + ('0000' + et.toString(16)).slice(-4)];
          if (et === 0x0800 && b.length >= 34) {
            var ihl = (b[14] & 15) * 4;
            var proto = b[14 + 9];
            pk.src = ipStr(b, 14 + 12);
            pk.dst = ipStr(b, 14 + 16);
            f['ip.src'] = [pk.src];
            f['ip.dst'] = [pk.dst];
            f['ip.addr'] = [pk.src, pk.dst];
            f['ip.proto'] = [String(proto)];
            f['ip.ttl'] = [String(b[14 + 8])];
            var tp = 14 + ihl;
            pk.proto = 'IPv4';
            if (proto === 17 && b.length >= tp + 8) {
              var us = (b[tp] << 8) | b[tp + 1];
              var ud = (b[tp + 2] << 8) | b[tp + 3];
              f['udp.srcport'] = [String(us)]; f['udp.dstport'] = [String(ud)]; f['udp.port'] = [String(us), String(ud)];
              pk.proto = 'UDP';
              if (us === 53 || ud === 53) { if (parseDns(b, tp + 8, f)) { pk.proto = 'DNS'; } }
            } else if (proto === 6 && b.length >= tp + 20) {
              var ts = (b[tp] << 8) | b[tp + 1];
              var td = (b[tp + 2] << 8) | b[tp + 3];
              var dof = (b[tp + 12] >> 4) * 4;
              var fl = b[tp + 13];
              var pl = tp + dof;
              f['tcp.srcport'] = [String(ts)]; f['tcp.dstport'] = [String(td)]; f['tcp.port'] = [String(ts), String(td)];
              f['tcp.flags'] = ['0x' + ('000' + fl.toString(16)).slice(-3)];
              f['tcp.flags.syn'] = [fl & 2 ? '1' : '0'];
              f['tcp.flags.ack'] = [fl & 16 ? '1' : '0'];
              f['tcp.flags.fin'] = [fl & 1 ? '1' : '0'];
              f['tcp.flags.reset'] = [fl & 4 ? '1' : '0'];
              f['tcp.flags.push'] = [fl & 8 ? '1' : '0'];
              f['tcp.len'] = [String(Math.max(0, b.length - pl))];
              var key = [pk.src + ':' + ts, pk.dst + ':' + td].sort().join('|');
              if (streams[key] === undefined) { streams[key] = { id: nstream++, client: pk.src + ':' + ts, server: pk.dst + ':' + td, chunks: [] }; }
              pk.stream = streams[key];
              f['tcp.stream'] = [String(pk.stream.id)];
              pk.proto = 'TCP';
              if (b.length > pl) {
                pk.payload = b.subarray(pl);
                pk.stream.chunks.push({ from: pk.src + ':' + ts, data: pk.payload });
                if (parseHttp(b, pl, b.length, f)) { pk.proto = 'HTTP'; }
                else if (parseTlsHello(b, pl, b.length, f)) { pk.proto = 'TLSv1'; }
              }
            }
          }
        }
        f['_ws.col.Protocol'] = [pk.proto];
        f['_ws.col.protocol'] = [pk.proto];
        f['_ws.col.Source'] = [pk.src];
        f['_ws.col.Destination'] = [pk.dst];
        packets.push(pk);
      }
      return { packets: packets, streams: streams };
    }

    /* ----- display filter ----- */
    function tokenizeFilter(src) {
      var toks = [];
      var i = 0;
      while (i < src.length) {
        var c = src.charAt(i);
        if (/\s/.test(c)) { i++; continue; }
        var m;
        if (c === '"') {
          var j = i + 1;
          var s = '';
          while (j < src.length && src.charAt(j) !== '"') { if (src.charAt(j) === '\\') { j++; } s += src.charAt(j); j++; }
          toks.push({ t: 'str', v: s });
          i = j + 1;
          continue;
        }
        if ((m = /^(==|!=|<=|>=|&&|\|\||[<>()!])/.exec(src.slice(i)))) { toks.push({ t: 'op', v: m[1] }); i += m[1].length; continue; }
        if ((m = /^[A-Za-z0-9_.:\/-]+/.exec(src.slice(i)))) {
          var w = m[0];
          var lw = w.toLowerCase();
          if (['and', 'or', 'not', 'eq', 'ne', 'contains', 'gt', 'lt', 'ge', 'le', 'matches'].indexOf(lw) !== -1) { toks.push({ t: 'op', v: lw }); }
          else { toks.push({ t: 'word', v: w }); }
          i += w.length;
          continue;
        }
        throw PcapError('Invalid character "' + c + '" in display filter');
      }
      return toks;
    }
    function ipInCidr(ip, cidr) {
      var parts = cidr.split('/');
      var bits = parts.length > 1 ? parseInt(parts[1], 10) : 32;
      function toInt(s) { return s.split('.').reduce(function (a, x) { return a * 256 + parseInt(x, 10); }, 0); }
      var mask = bits === 0 ? 0 : Math.pow(2, 32) - Math.pow(2, 32 - bits);
      return (Math.floor(toInt(ip) / Math.pow(2, 32 - bits)) === Math.floor(toInt(parts[0]) / Math.pow(2, 32 - bits))) || mask === 0;
    }
    function compileFilter(src) {
      var toks = tokenizeFilter(src);
      var p = 0;
      function isOp(v) { return toks[p] && toks[p].t === 'op' && toks[p].v === v; }
      function parseOr() {
        var l = parseAnd();
        while (isOp('||') || isOp('or')) { p++; var r = parseAnd(); l = (function (a, b) { return function (pk) { return a(pk) || b(pk); }; })(l, r); }
        return l;
      }
      function parseAnd() {
        var l = parseNot();
        while (isOp('&&') || isOp('and')) { p++; var r = parseNot(); l = (function (a, b) { return function (pk) { return a(pk) && b(pk); }; })(l, r); }
        return l;
      }
      function parseNot() {
        if (isOp('!') || isOp('not')) { p++; var e = parseNot(); return function (pk) { return !e(pk); }; }
        return parseCmp();
      }
      function parseCmp() {
        if (isOp('(')) { p++; var e = parseOr(); if (!isOp(')')) { throw PcapError('Unmatched ( in display filter'); } p++; return e; }
        var tk = toks[p++];
        if (!tk || tk.t !== 'word') { throw PcapError('Syntax error in display filter'); }
        var field = tk.v;
        var opTok = toks[p];
        var cmpOps = ['==', '!=', 'eq', 'ne', '<', '>', '<=', '>=', 'gt', 'lt', 'ge', 'le', 'contains', 'matches'];
        if (!opTok || opTok.t !== 'op' || cmpOps.indexOf(opTok.v) === -1) {
          return function (pk) { return !!(pk.f[field] && pk.f[field].length) || (field === 'tcp' && pk.proto !== 'IPv4' && pk.f['tcp.srcport'] !== undefined) || (field === 'dns' && pk.f['dns.id'] !== undefined) || (field === 'http' && (pk.f['http.request'] || pk.f['http.response']) !== undefined) || (field === 'udp' && pk.f['udp.srcport'] !== undefined) || (field === 'ip' && pk.f['ip.src'] !== undefined) || (field === 'tls' && pk.f['tls.handshake.type'] !== undefined); };
        }
        p++;
        var vt = toks[p++];
        if (!vt) { throw PcapError('Syntax error in display filter'); }
        var op = opTok.v;
        var val = vt.v;
        var re = null;
        if (op === 'matches') { re = new RegExp(val, 'i'); }
        function one(x) {
          var num = /^(0x[0-9a-f]+|\d+(\.\d+)?)$/i.test(x) && /^(0x[0-9a-f]+|\d+(\.\d+)?)$/i.test(val);
          switch (op) {
            case '==': case 'eq':
              if (/^\d+\.\d+\.\d+\.\d+\/\d+$/.test(val)) { return ipInCidr(x, val); }
              if (val === 'true') { val = '1'; } if (val === 'false') { val = '0'; }
              return num ? Number(x) === Number(val) : x === val;
            case '!=': case 'ne': return num ? Number(x) !== Number(val) : x !== val;
            case '<': case 'lt': return Number(x) < Number(val);
            case '>': case 'gt': return Number(x) > Number(val);
            case '<=': case 'le': return Number(x) <= Number(val);
            case '>=': case 'ge': return Number(x) >= Number(val);
            case 'contains': return x.indexOf(val) !== -1;
            case 'matches': return re.test(x);
            default: return false;
          }
        }
        return function (pk) {
          var vals = pk.f[field] || [];
          if (op === '!=' || op === 'ne') { return vals.length > 0 && vals.every(one); }
          return vals.some(one);
        };
      }
      var fn = parseOr();
      if (p < toks.length) { throw PcapError('Syntax error in display filter near "' + (toks[p].v) + '"'); }
      return fn;
    }

    /* ----- follow stream ----- */
    function follow(cap, n) {
      var st = null;
      Object.keys(cap.streams).forEach(function (k) { if (cap.streams[k].id === n) { st = cap.streams[k]; } });
      if (!st) { throw PcapError('Follow: no such stream ' + n); }
      var out = '\n===================================================================\n';
      out += 'Follow: tcp,ascii\nFilter: tcp.stream eq ' + n + '\n';
      out += 'Node 0: ' + st.client + '\nNode 1: ' + st.server + '\n';
      st.chunks.forEach(function (c) {
        var text = '';
        for (var i = 0; i < c.data.length; i++) {
          var ch = c.data[i];
          text += (ch === 10 || ch === 13 || ch === 9 || (ch >= 32 && ch < 127)) ? String.fromCharCode(ch) : '.';
        }
        out += (c.from === st.client ? '' : '\t') + c.data.length + '\n' + text + '\n';
      });
      return out + '===================================================================\n';
    }

    return { parse: parse, compileFilter: compileFilter, follow: follow, PcapError: PcapError };
  })();
