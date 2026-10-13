// Paste the body of this function into chrome-devtools `evaluate_script` (waitForStableDom: false)
// once, on the page you will record. Navigate afterwards ONLY through in-app clicks (SPA routing):
// a full page load wipes every helper below.
//
// Edit the two constants first.
async () => {
  const API_BASE = 'http://localhost:5294/api/v1'; // backend of the MFE under review (see launchpad list_services)
  const MFE_FIXES = '.css-of4w77{width:100%!important}.css-brix5o{max-height:none!important}';
  // ^ MFE containers sized with 100vw / fixed max-height do not follow CSS zoom. Find them by walking up from
  //   the clipped box and reading getComputedStyle (width: 100vw, max-height: Npx); emotion class hashes differ
  //   per MFE. These two are fee-matrix's.

  const W = window;
  W.__sleep = ms => new Promise(r => setTimeout(r, ms));

  // Authenticated API calls with the page's own session (never copy the token out of the browser).
  const k = Object.keys(localStorage).find(k => k.includes('https://priorx/api'));
  const token = JSON.parse(localStorage.getItem(k)).body.access_token;
  W.__api = async (method, path, body) => {
    const r = await fetch(API_BASE + path, { method, headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' }, body: body ? JSON.stringify(body) : undefined });
    const t = await r.text(); let j; try { j = JSON.parse(t); } catch { j = t; }
    return { status: r.status, body: j };
  };

  // Keep the frame clean: "Priorx Agent not detected" dialog and webpack error overlays from other MFEs.
  const clean = () => {
    document.querySelectorAll('iframe').forEach(f => { try { if (f.contentDocument?.body?.innerText.includes('Compiled with problems')) f.remove(); } catch {} });
    document.querySelectorAll('[role="dialog"]').forEach(d => { if (d.innerText.includes('Priorx Agent')) [...d.querySelectorAll('button')].find(b => b.innerText.includes('Cancel'))?.click(); });
  };
  clean(); W.__cleaner = setInterval(clean, 150);

  // Zoom + overlay styles. Everything under <html> is zoomed, so overlay sizes/positions are divided by Z.
  const st = document.createElement('style'); st.id = '__rstyle'; document.head.appendChild(st);
  W.__setZoom = Z => {
    W.__Z = Z;
    document.documentElement.style.zoom = String(Z);
    st.textContent = `${MFE_FIXES}
    #__cap{position:fixed;right:${24 / Z}px;top:${66 / Z}px;z-index:2147483646;background:#0d1b2a;color:#fff;font:600 ${19 / Z}px 'Segoe UI',Arial;padding:${9 / Z}px ${16 / Z}px;border-radius:${8 / Z}px;max-width:55vw;pointer-events:none}
    .__hl{position:fixed;z-index:2147483645;border:${3 / Z}px solid #ff9f1c;border-radius:${6 / Z}px;pointer-events:none}
    #__cursor{position:fixed;z-index:2147483647;width:${26 / Z}px;height:${26 / Z}px;pointer-events:none;transition:left .45s ease-out, top .45s ease-out}
    #__cursor svg{width:100%;height:100%}
    .tsqd-parent-container, [aria-label="Open React Query Devtools"], .tsqd-open-btn-container{display:none!important}`;
    dispatchEvent(new Event('resize'));
  };

  // Drawn cursor: DevTools clicks do not move the OS cursor, so tab capture never shows one.
  const cur = document.createElement('div'); cur.id = '__cursor'; cur.style.left = '900px'; cur.style.top = '500px';
  cur.innerHTML = '<svg viewBox="0 0 24 24"><path d="M3 2l7.5 19 2.6-7.9L21 10.5z" fill="#111" stroke="#fff" stroke-width="1.6" stroke-linejoin="round"/></svg>';
  document.body.appendChild(cur);
  W.__moveTo = async (el, dx = 0.5, dy = 0.5) => { if (!el) return; const Z = W.__Z; const b = el.getBoundingClientRect(); cur.style.left = (b.left + b.width * dx) / Z + 'px'; cur.style.top = (b.top + b.height * dy) / Z + 'px'; await __sleep(650); };

  // Static caption (no fade) and static highlight boxes.
  W.__caption = t => { let c = document.getElementById('__cap'); if (!t) { c?.remove(); return; } if (!c) { c = document.createElement('div'); c.id = '__cap'; document.body.appendChild(c); } c.textContent = t; };
  W.__hl = (el, pad = 3) => { if (!el) return; const Z = W.__Z; const b = el.getBoundingClientRect(); const h = document.createElement('div'); h.className = '__hl'; Object.assign(h.style, { left: (b.left - pad) / Z + 'px', top: (b.top - pad) / Z + 'px', width: (b.width + pad * 2) / Z + 'px', height: (b.height + pad * 2) / Z + 'px' }); document.body.appendChild(h); };
  W.__hlClear = () => document.querySelectorAll('.__hl').forEach(h => h.remove());

  // Finders.
  W.__until = async (fn, ms = 15000) => { const t = Date.now(); while (Date.now() - t < ms) { const v = fn(); if (v) return v; await __sleep(150); } return null; };
  W.__cell = (rowText, field) => { const row = [...document.querySelectorAll('[role="row"]')].find(r => r.innerText.includes(rowText)); return row && (field ? row.querySelector(`[data-field="${field}"]`) : row); };
  W.__byText = t => [...document.querySelectorAll('main *')].filter(e => e.innerText?.trim() === t && e.getBoundingClientRect().width > 0).filter(e => ![...e.children].some(c => c.innerText?.trim() === t));
  W.__tab = async name => { const t = await __until(() => [...document.querySelectorAll('main [role="tab"]')].filter(t => t.innerText.trim() === name).pop()); await __moveTo(t); t.click(); await __sleep(300); };

  // Shrink zoom until `lastEl()` fits above the bottom edge (use on screens taller than the others).
  W.__fit = async (lastEl, from = W.__Z, min = 0.4) => {
    let z = from;
    for (; z >= min; z -= 0.02) { __setZoom(+z.toFixed(2)); await __sleep(250); const b = lastEl()?.getBoundingClientRect().bottom; if (b && b < innerHeight - 20) break; }
    return +z.toFixed(2);
  };

  // Recorder. getDisplayMedia needs a user gesture: a hidden button clicked through DevTools `click` counts.
  // The user must then press "Share" in Chrome's prompt.
  W.__rec = { chunks: [], state: 'waiting' };
  W.__newRecorder = () => { const rec = new MediaRecorder(W.__rec.stream, { mimeType: 'video/webm;codecs=vp9', videoBitsPerSecond: 10_000_000 }); rec.ondataavailable = e => e.data.size && W.__rec.chunks.push(e.data); rec.start(500); W.__rec.recorder = rec; };
  W.__stopRec = async () => { const rec = W.__rec.recorder; await new Promise(r => { rec.onstop = r; rec.stop(); }); W.__rec.stream.getTracks().forEach(t => t.stop()); W.__rec.state = 'stopped'; };
  W.__exportB64 = async () => { const buf = new Uint8Array(await new Blob(W.__rec.chunks, { type: 'video/webm' }).arrayBuffer()); let bin = ''; for (let i = 0; i < buf.length; i += 0x8000) bin += String.fromCharCode.apply(null, buf.subarray(i, i + 0x8000)); return { bytes: buf.length, b64: btoa(bin) }; };
  const btn = document.createElement('button');
  btn.textContent = 'start-rec'; btn.setAttribute('aria-label', 'start-rec');
  btn.style.cssText = 'position:fixed;right:4px;bottom:4px;z-index:99999;opacity:0.01;width:20px;height:20px';
  btn.onclick = async () => {
    try {
      W.__rec.stream = await navigator.mediaDevices.getDisplayMedia({ video: { frameRate: 30, displaySurface: 'browser' }, audio: false, preferCurrentTab: true, selfBrowserSurface: 'include' });
      W.__rec.state = 'shared';
    } catch (e) { W.__rec.state = 'error: ' + e.message; }
  };
  document.body.appendChild(btn);

  __setZoom(1);
  return 'helpers ready';
}
