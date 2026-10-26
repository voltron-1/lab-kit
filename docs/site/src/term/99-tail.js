
  /* ---------- public API ---------- */
  function magicOfBytes(b) {
    var hex = '';
    for (var i = 0; i < 4 && i < b.length; i++) { hex += ('0' + b[i].toString(16)).slice(-2); }
    if (/^504b0[3-7]/.test(hex)) { return 'Zip archive data (PK)'; }
    if (hex === 'd0cf11e0') { return 'Composite Document File V2 Document (OLE2)'; }
    if (hex.slice(0, 4) === '4d5a') { return 'PE32 executable (MZ)'; }
    if (hex.slice(0, 4) === 'ffd8') { return 'JPEG image data'; }
    if (hex === '89504e47') { return 'PNG image data'; }
    if (hex === '25504446') { return 'PDF document'; }
    if (/^(d4c3b2a1|a1b2c3d4|0a0d0d0a)/.test(hex)) { return 'pcap capture file'; }
    return 'data';
  }
  // Build the workspace filesystem for a lab (see data bundle). `access.get(name)` / `access.set(name, text)`
  // back the graded files, so the terminal and the Workspace boxes are the same files.
  function vfsFromLab(lab, access) {
    var vfs = new VFS(lab.id);
    lab.files.forEach(function (f) {
      if (f.kind === 'text') { vfs.add(f.name, { text: f.text }); }
      else {
        var bytes = b64ToBytes(f.b64);
        vfs.add(f.name, { bytes: bytes, magic: magicOfBytes(bytes), rendered: f.rendered || '' });
      }
    });
    lab.graded_files.forEach(function (g) {
      if (g.template) { vfs.add(g.template, { text: g.prefill }); }
      vfs.add(g.name, { get: function () { return access.get(g.name); }, set: function (t) { access.set(g.name, t); } });
    });
    return vfs;
  }

  function createShell(opts) { return new Shell(opts); }
  function incomplete(line) {
    try { parseScript(line); return false; } catch (e) { return !!(e && e.incomplete); }
  }
  root.LabTerm = { createShell: createShell, VFS: VFS, incomplete: incomplete, Jq: Jq, Awk: Awk, Sed: Sed, Pcap: Pcap,
    sha256: sha256, vfsFromLab: vfsFromLab, commands: Object.keys(COMMANDS) };
  if (typeof module !== 'undefined' && module.exports) { module.exports = root.LabTerm; }
})(typeof window !== 'undefined' ? window : globalThis);
