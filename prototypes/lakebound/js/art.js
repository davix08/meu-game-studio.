// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Rendering and animation: palette, pixel sprites generated in code (fish, items), the fisherman
// and the shopkeeper. Every figure is drawn here; no emoji, no images.
'use strict';

const PAL = {
  outline: '#1a1c2c',
  grass: '#5d9e3f', grass2: '#4f8a35', grass3: '#73b44a',
  dirt: '#a27b4c', dirt2: '#8a663c', dirt3: '#bb9462',
  sand: '#dcc68c', sand2: '#c8b076',
  shallow: '#3f8fbf', deep: '#2a6496', deeper: '#1f4f7c', foam: '#d8f0ff', wave: '#7cc4e8',
  wood: '#8a5a32', wood2: '#6e4424', wood3: '#a87444',
  roof: '#a2402e', roof2: '#7e2e22',
  leaf: '#3f8a3a', leaf2: '#2f6e2e', leaf3: '#5aae4a', pine: '#2a6a46', pine2: '#1e5236',
  trunk: '#6a4426', rock: '#8c9098', rock2: '#686c76',
  ui: '#2b1d14', ui2: '#4a3222', uiEdge: '#e8c98a', cream: '#f6ecd0', ink: '#1a1208',
};

function makeCanvas(w, h) { const c = document.createElement('canvas'); c.width = w; c.height = h; return c; }
/** Deterministic hash of integer coords to [0,1): used for decoration and patterns, never gameplay. */
function hash2(x, y, s = 0) {
  let h = (Math.imul(x | 0, 374761393) + Math.imul(y | 0, 668265263) + Math.imul(s | 0, 982451653)) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967296;
}
const _rgb = {};
function rgba(hex) {
  if (_rgb[hex]) return _rgb[hex];
  const n = hex.replace('#', '');
  const v = [parseInt(n.slice(0, 2), 16), parseInt(n.slice(2, 4), 16), parseInt(n.slice(4, 6), 16), n.length >= 8 ? parseInt(n.slice(6, 8), 16) : 255];
  return (_rgb[hex] = v);
}
/** Builds a pixel sprite from fn(x, y) -> colour or null, then outlines it. */
function spriteFrom(w, h, fn, outline = PAL.outline) {
  const c = makeCanvas(w, h), g = c.getContext('2d'), img = g.createImageData(w, h);
  const filled = new Uint8Array(w * h);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const col = fn(x + 0.5, y + 0.5);
    if (!col) continue;
    const [r, gg, b, a] = rgba(col), i = (y * w + x) * 4;
    img.data[i] = r; img.data[i + 1] = gg; img.data[i + 2] = b; img.data[i + 3] = a; filled[y * w + x] = 1;
  }
  if (outline) {
    const [r, gg, b] = rgba(outline);
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
      if (filled[y * w + x]) continue;
      const n = (x > 0 && filled[y * w + x - 1] === 1) || (x < w - 1 && filled[y * w + x + 1] === 1) ||
        (y > 0 && filled[(y - 1) * w + x] === 1) || (y < h - 1 && filled[(y + 1) * w + x] === 1);
      if (n) { const i = (y * w + x) * 4; img.data[i] = r; img.data[i + 1] = gg; img.data[i + 2] = b; img.data[i + 3] = 255; filled[y * w + x] = 2; }
    }
  }
  g.putImageData(img, 0, 0);
  return c;
}
/** Silhouette copy (for undiscovered species in the book). */
function silhouette(src, col = '#0c1018') {
  const c = makeCanvas(src.width, src.height), g = c.getContext('2d');
  g.drawImage(src, 0, 0); g.globalCompositeOperation = 'source-in'; g.fillStyle = col; g.fillRect(0, 0, c.width, c.height);
  return c;
}
function distSeg(px, py, ax, ay, bx, by) {
  const dx = bx - ax, dy = by - ay, l = dx * dx + dy * dy;
  let t = l ? ((px - ax) * dx + (py - ay) * dy) / l : 0; t = Math.max(0, Math.min(1, t));
  return [Math.hypot(px - ax - t * dx, py - ay - t * dy), t];
}
/** Inside a chain of capsules [[x,y,r],...]: returns the fraction along the chain or -1. */
function inChain(x, y, pts) {
  for (let i = 0; i < pts.length - 1; i++) {
    const a = pts[i], b = pts[i + 1], [d, t] = distSeg(x, y, a[0], a[1], b[0], b[1]);
    if (d <= a[2] + (b[2] - a[2]) * t) return (i + t) / (pts.length - 1);
  }
  return -1;
}

// ---------------------------------------------------------------------------------------------
// Fish sprites: 40 x 24, facing right.
const FW = 40, FH = 24;
function fishGeneric(sp) {
  const cy = 12, len = sp.L * 31, tl = sp.tl ?? 0.28, bill = sp.bill || 0;
  const total = len * (1 + tl + bill);
  const x0 = (FW - total) / 2 + len * tl, hh = sp.H * len;
  const [C0, C1, C2, C3] = sp.c, FIN = sp.fin || C2, TAIL = sp.tailCol || FIN;
  return (x, y) => {
    const u = (x - x0) / len, v = y - cy;
    // body
    if (u >= 0 && u <= 1) {
      let prof = Math.pow(Math.sin(Math.PI * Math.min(1, u * 0.9 + 0.1)), sp.snout === 'point' ? 0.9 : 0.62);
      if (u < 0.12) prof = Math.max(prof, 0.28 * (sp.tail === 'shark' || sp.tail === 'lunate' ? 0.7 : 1));
      if (sp.snout === 'flat' && u > 0.85) prof = Math.max(prof, 0.75);
      const hb = Math.max(1.2, hh * prof);
      let top = -hb, bot = hb;
      if (sp.snout === 'up' && u > 0.8) top = -hb * 0.6;
      if (v >= top && v <= bot) {
        // eye
        const ex = x0 + len * (sp.snout === 'point' ? 0.88 : 0.84), ey = cy - hb * 0.25 - (sp.snout === 'flat' ? -1 : 0);
        const er = sp.eyeR || (len > 22 ? 1.4 : 1.1);
        if (Math.hypot(x - ex, y - ey) < er) return (x < ex && y < ey) ? '#ffffff' : '#101018';
        if (sp.barbels && u > 0.95 && v > 0 && v < 2) return C2;
        if (u > 0.7 && u < 0.74 && Math.abs(v) < hb * 0.6 && sp.pat !== 'ghost') return C2; // gill
        return bodyCol(sp, u, v, hb, x, y);
      }
      // dorsal fin
      if (sp.dorsal && v < 0 && u > sp.dA && u < sp.dB) {
        const k = (u - sp.dA) / (sp.dB - sp.dA);
        let fh;
        if (sp.dshape === 'tri') fh = sp.dorsal * hh * (k < 0.6 ? k / 0.6 : (1 - k) / 0.4 * 0.4 + 0) * 1.6;
        else if (sp.dshape === 'sail') fh = sp.dorsal * hh * 2.2 * Math.sin(Math.PI * Math.min(1, k * 1.1)) * (1 - k * 0.5);
        else if (sp.dshape === 'spiky') fh = sp.dorsal * hh * (0.6 + 0.4 * Math.abs(Math.sin(k * Math.PI * 5)));
        else fh = sp.dorsal * hh * Math.sin(Math.PI * k);
        if (-v <= hb + fh) return FIN;
      }
      // anal fin (arowana) / generic small ventral
      if (sp.anal && v > 0 && u > 0.68 && u < 0.94) { if (v <= hb + hh * 0.35 * Math.sin(Math.PI * (u - 0.68) / 0.26)) return FIN; }
      if (sp.dorsal && sp.dA < 0.3 && v > 0 && u > 0.25 && u < 0.55) { if (v <= hb + hh * 0.25 * Math.sin(Math.PI * (u - 0.25) / 0.3)) return FIN; }
      // pectoral (sharks)
      if (sp.pectoral && v > 0 && u > 0.55 && u < 0.72) { const k = (u - 0.55) / 0.17; if (v <= hb + sp.pectoral * hh * 1.6 * (1 - k)) return C2; }
      // coelacanth lobes
      if (sp.lobes && ((v > 0 && Math.hypot((u - 0.45) * len, v - hb - 1.5) < 2.2) || (v < 0 && Math.hypot((u - 0.55) * len, -v - hb - 1.5) < 2.2) || (v > 0 && Math.hypot((u - 0.7) * len, v - hb - 1.2) < 2))) return C2;
      if (sp.finlets && Math.abs(v) > hb && Math.abs(v) < hb + 1.2 && u > 0.08 && u < 0.3 && Math.floor(u * 30) % 2 === 0) return C3;
      if (sp.hammer && u > 0.86 && u < 0.98 && Math.abs(v) < hh * 1.9) return C2;
    }
    // bill
    if (bill && u > 1 && u < 1 + bill && Math.abs(v + 0.5) < 0.9 * (1 - (u - 1) / bill * 0.5)) return C2;
    // tail
    if (u < 0 && u >= -tl) {
      const k = -u / tl, tv = Math.abs(v), base = hh * 0.25;
      switch (sp.tail) {
        case 'fork': { const half = base + hh * 0.95 * k; const notch = k > 0.4 ? hh * (k - 0.4) * 1.5 : -1; if (tv <= half && tv >= notch) return TAIL; break; }
        case 'round': { if ((k / 1) ** 2 + (tv / (base + hh * 0.75)) ** 2 <= 1 || tv <= base + hh * 0.7 * Math.sin(Math.PI * Math.min(1, k * 0.9 + 0.1))) return TAIL; break; }
        case 'fan': { const half = base + hh * 1.3 * Math.sin(Math.PI * 0.5 * Math.min(1, k * 1.3)); const notch = k > 0.6 ? hh * (k - 0.6) * 1.2 : -1; if (tv <= half && tv >= notch) return (Math.floor(k * 8) % 2 ? TAIL : C3); break; }
        case 'lunate': { const half = base * 0.6 + hh * 1.3 * k * k; const notch = k > 0.35 ? hh * 1.1 * (k - 0.35) * 1.4 : -1; if (tv <= half && tv >= notch) return TAIL; break; }
        case 'shark': { const upper = base * 0.6 + hh * 1.9 * k * k, lower = base * 0.6 + hh * 0.9 * k * k; const notch = k > 0.5 ? hh * (k - 0.5) : -1; if (v <= 0 ? -v <= upper && -v >= notch * 1.6 : v <= lower && v >= notch); else break; return v < 0 ? C2 : C0; }
        case 'tri': { if (tv <= base + hh * 0.8 * (1 - Math.abs(k - 0.5) * 1.4) || (tv < 1 && k < 1.2)) return TAIL; break; }
      }
    }
    return null;
  };
}
function bodyCol(sp, u, v, hb, x, y) {
  const [C0, C1, C2, C3] = sp.c, n = sp.n || 4;
  const back = v < -hb * 0.45, belly = v > hb * 0.35;
  switch (sp.pat) {
    case 'vbands': if (u > 0.15 && u < 0.78 && Math.floor(u * n * 1.4) % 2 === 1 && !belly) return C3; break;
    case 'dots': if (Math.abs(v + hb * 0.15) < 0.7 && Math.floor(x) % 3 === 0 && u > 0.2 && u < 0.7) return C3; break;
    case 'waves': if (v < -hb * 0.05 && Math.sin(u * 40 + v * 1.4) > 0.35) return C3; break;
    case 'spots': if (hash2(Math.floor(x), Math.floor(y), 7) > 0.78 && !belly) return C3; break;
    case 'neon': if (Math.abs(v + hb * 0.1) < 0.8 && u > 0.1) return C3; if (u < 0.25 && v > -hb * 0.2) return '#e0453a'; break;
    case 'scales': if ((Math.floor(x) + Math.floor(y)) % 3 === 0 && !belly) return C2; break;
    case 'salmon': if (Math.abs(v) < hb * 0.25 && u > 0.1 && u < 0.85) return C3; if (back && hash2(Math.floor(x), Math.floor(y), 3) > 0.7) return '#2a3440'; break;
    case 'clown': { const b = [[0.28, 0.36], [0.55, 0.62], [0.8, 0.86]]; for (const [a, c] of b) { if (u > a && u < c) return C3; if (u > a - 0.04 && u < c + 0.04) return '#101010'; } break; }
    case 'surgeon': if (v < 0 && v > -hb * 0.7 && u > 0.25 && u < 0.8 && Math.abs(v + hb * 0.35 - Math.sin(u * 6) * 1.2) < 1.1) return C3; break;
    case 'koi': { const s = hash2(Math.floor(x / 3), Math.floor(y / 3), 11); if (s > 0.55 && !belly) return C3; if (s < 0.1 && back) return '#202020'; break; }
    case 'ghost': if (Math.abs(v) < 0.6 && u > 0.05 && u < 0.8) return '#ffffffe0'; if (Math.abs(v) < hb * 0.7 && Math.floor(u * 14) % 2 === 0 && Math.abs(v) > 0.5 && u > 0.1 && u < 0.7) return '#f0f6ffd0'; break;
    case 'counter': if (belly) return C1; if (back) return C2; return C0;
    case 'tuna': if (Math.abs(v) < 0.8 && u > 0.2 && u < 0.85) return C3; if (belly) return C1; return back ? C2 : C0;
    case 'whale': if (back || !belly) { if ((Math.floor(x) % 3 === 0 && Math.floor(y) % 3 === 0) || (Math.floor(x) % 5 === 2 && Math.floor(y) % 4 === 1)) return C3; } break;
  }
  if (belly) return C1;
  if (back) return C2;
  return C0;
}
function fishSpecial(sp) {
  const [C0, C1, C2, C3] = sp.c;
  switch (sp.s) {
    case 'shrimp': return (x, y) => {
      const dx = x - 20, dy = y - 7, r = Math.hypot(dx, dy), a = Math.atan2(dy, dx) * 180 / Math.PI;
      if (a > 20 && a < 168) { const k = (a - 20) / 148, th = 3.6 - k * 2.4; if (r > 7 - th / 2 && r < 7 + th / 2) { if (Math.hypot(x - 26.5, y - 9.5) < 1) return '#101018'; return Math.floor(a / 14) % 2 ? C0 : C1; } }
      if (a >= 166 && a < 192 && r > 4 && r < 10) return C2;
      if (distSeg(x, y, 27, 9, 38, 2)[0] < 0.6 || distSeg(x, y, 27, 10, 38, 6)[0] < 0.6) return C2;
      for (let i = 0; i < 4; i++) { const ax = 22 - i * 3; if (distSeg(x, y, ax, 14 - i * 0.3, ax + 1, 17)[0] < 0.55) return C2; }
      return null;
    };
    case 'crab': return (x, y) => {
      if (((x - 20) / 9) ** 2 + ((y - 14) / 5) ** 2 <= 1) { if (y < 12 && hash2(x | 0, y | 0, 5) > 0.75) return C1; return y > 16 ? C2 : C0; }
      for (const s of [-1, 1]) {
        const cx = 20 + s * 13, cyy = 7;
        if (Math.hypot(x - cx, y - cyy) < 3.4 && !(Math.abs(x - cx - s * 1) < 1.2 && y < cyy)) return C0;
        if (distSeg(x, y, 20 + s * 7, 12, cx, cyy + 2)[0] < 1.2) return C0;
        for (let i = 0; i < 3; i++) if (distSeg(x, y, 20 + s * (5 + i * 2), 17, 20 + s * (9 + i * 3), 21)[0] < 0.6) return C2;
        if (distSeg(x, y, 20 + s * 2.5, 10, 20 + s * 3, 7)[0] < 0.6) return C2;
        if (Math.hypot(x - 20 - s * 3, y - 6.5) < 1.1) return '#101018';
      }
      return null;
    };
    case 'lobster': return (x, y) => {
      const t = inChain(x, y, [[4, 12, 1.5], [9, 12, 3.2], [16, 12, 3.6], [24, 12, 4], [29, 12, 3]]);
      if (t >= 0) { if (Math.hypot(x - 27, y - 10.5) < 1) return '#101018'; return (Math.floor(x / 2.5) % 2 && x < 22) ? C2 : (y > 13.5 ? C3 : C0); }
      if (x < 5 && x > 1 && Math.abs(y - 12) < (5 - x) * 1.2 + 1) return C3;
      for (const s of [-1, 1]) {
        if (distSeg(x, y, 27, 12 + s * 2, 32, 12 + s * 6)[0] < 1) return C0;
        if (((x - 35) / 3.4) ** 2 + ((y - 12 - s * 7) / 2.2) ** 2 <= 1 && !(x > 36 && Math.abs(y - 12 - s * 7) < 0.7)) return C3;
        if (distSeg(x, y, 30, 11 + s, 39, 3 + (s > 0 ? 18 : 0) * 0 + (s > 0 ? 17 : 0))[0] < 0.5) return C2;
        for (let i = 0; i < 3; i++) if (distSeg(x, y, 14 + i * 4, 12 + s * 3, 12 + i * 4, 12 + s * 6)[0] < 0.55) return C2;
      }
      return null;
    };
    case 'octopus': return (x, y) => {
      if (((x - 20) / 7) ** 2 + ((y - 7.5) / 6.5) ** 2 <= 1) { if (Math.hypot(x - 17, y - 9) < 1.2 || Math.hypot(x - 23, y - 9) < 1.2) return '#101018'; if (hash2(x | 0, y | 0, 9) > 0.8) return C1; return C0; }
      for (let i = 0; i < 6; i++) {
        const bx = 11 + i * 3.6, cx = bx + Math.sin(y * 0.55 + i * 1.3) * 1.6 + (i - 2.5) * (y - 12) * 0.12;
        if (y > 11 && y < 22 + (i % 2) && Math.abs(x - cx) < 1.5 - (y - 11) / 14) return (Math.floor(y) % 3 === 0) ? C3 : C2;
      }
      return null;
    };
    case 'cuttle': return (x, y) => {
      if (((x - 17) / 11) ** 2 + ((y - 12) / 5.8) ** 2 <= 1) { if (((x - 17) / 9) ** 2 + ((y - 12) / 4) ** 2 > 1) return C3; if (Math.hypot(x - 25, y - 11) < 1.3) return '#101018'; return Math.sin(x * 1.3) * Math.cos(y * 1.7) > 0.3 ? C2 : C0; }
      for (let i = 0; i < 4; i++) { const yy = 10 + i * 1.4; if (x > 27 && x < 33 + (i % 2) * 2 && Math.abs(y - yy - Math.sin(x) * 0.4) < 0.6) return C1; }
      return null;
    };
    case 'squid': return (x, y) => {
      // mantle pointing left, fins at the tip, long tentacles to the right
      if (x > 2 && x < 21) { const k = (x - 2) / 19, half = 1 + k * 4.2; if (Math.abs(y - 12) < half) { if (x > 17 && x < 19 && y < 11 && y > 9) return '#101018'; return (Math.floor(x / 3) % 2 ? C0 : C2); } }
      if (x > 1 && x < 8 && Math.abs(y - 12) < (8 - x) * 1.1 && Math.abs(y - 12) > 1) return C1;
      if (x >= 21 && x < 24 && Math.abs(y - 12) < 3.6) return C0;
      for (let i = 0; i < 6; i++) { const off = (i - 2.5) * 1.3, wav = Math.sin(x * 0.6 + i) * (x - 24) * 0.12; if (x >= 24 && x < 34 + (i === 0 || i === 5 ? 5 : 0) && Math.abs(y - 12 - off - wav) < 0.6) return C2; }
      if (x > 36 && x < 40 && (Math.abs(y - 12 + 3.6 + Math.sin(x * 0.6) * 1.2) < 1.2 || Math.abs(y - 12 - 3.2 - Math.sin(x * 0.6 + 5) * 1.2) < 1.2)) return C2;
      return null;
    };
    case 'seahorse': return (x, y) => {
      const t = inChain(x, y, [[24, 4.5, 2.6], [21.5, 7.5, 2.2], [19.5, 11, 3.4], [20, 14.5, 3.4], [21, 17.5, 2.3], [20.5, 20.5, 1.6], [18.5, 21.5, 1.3], [17, 20, 1.1], [17.6, 18.4, 1]]);
      if (t >= 0) { if (Math.hypot(x - 24.5, y - 4) < 0.9) return '#101018'; if (x > 21 && t > 0.25 && t < 0.6 && Math.floor(y) % 2) return C1; return Math.floor(y) % 2 && t > 0.2 ? C2 : C0; }
      if (distSeg(x, y, 25, 4.8, 30, 6)[0] < 1) return C0;
      if (distSeg(x, y, 23, 1, 22, 3)[0] < 0.7) return C3;
      if (x < 18 && x > 15 && y > 9 && y < 14 && Math.abs(x - 17 + (y - 9) * 0.2) < 1) return C1;
      return null;
    };
    case 'manta': return (x, y) => {
      const dx = Math.abs(x - 20), dy = y - 10;
      if (dx <= 18) { const top = -4 + (dx / 18) ** 2 * 7, bot = 5 - dx * 0.34; if (dy >= top && dy <= bot) { if (dx < 7 && dy > -1 && dy < 3 && !(dx < 2)) return C1; if (dx < 2.5 && dy > 3) return C3; return dy < 0 && dx > 10 ? C2 : C0; } }
      if (dx > 2 && dx < 4.5 && dy < -3 && dy > -7.5) return C0;
      if (dx < 0.8 && dy > 4 && dy < 13) return C2;
      return null;
    };
    case 'nautilus': return (x, y) => {
      const dx = x - 17, dy = y - 12, r = Math.hypot(dx, dy), a = Math.atan2(dy, dx);
      if (r < 9.5) {
        const sp = 2 + ((a + Math.PI) / (2 * Math.PI)) * 2.6;
        if (Math.abs(r - sp) < 0.6 || Math.abs(r - sp - 2.6) < 0.5) return C3;
        if (r > 4 && Math.floor((a + Math.PI) * 4) % 2 === 0 && dy < 3) return C2;
        return r < 4 ? C1 : C0;
      }
      if (x > 24 && x < 33 && Math.abs(y - 13 - Math.sin(x) * 0.3) < 3.2 - (x - 24) * 0.3) { if (Math.floor(y) % 2) return '#e8b0a0'; return '#f0c8b8'; }
      if (Math.hypot(x - 25.5, y - 9.5) < 1.1) return '#101018';
      return null;
    };
    case 'eel': return (x, y) => {
      const pts = []; for (let i = 0; i <= 12; i++) { const px = 3 + i * 2.8; pts.push([px, 12 + Math.sin(px * 0.33) * 4, 0.9 + i * 0.22]); }
      const t = inChain(x, y, pts);
      if (t >= 0) { const head = pts[12]; if (Math.hypot(x - head[0] + 1, y - head[1] + 1.2) < 1) return '#ffffff'; if (Math.hypot(x - head[0] - 1.5, y - head[1] + 0.5) < 0.8) return '#101018'; return hash2(x | 0, y | 0, 13) > 0.8 ? C3 : (y > 12 + Math.sin(x * 0.33) * 4 + 1 ? C1 : C0); }
      return null;
    };
    case 'puffer': return (x, y) => {
      const dx = x - 21, dy = y - 12, r = Math.hypot(dx, dy), a = Math.atan2(dy, dx);
      if (r < 7.5) { if (Math.hypot(x - 25, y - 10) < 1.3) return '#101018'; if (dy > 2) return C1; if (hash2(x | 0, y | 0, 17) > 0.75) return C3; return C0; }
      if (r < 10.2 && Math.abs(((a * 12 / Math.PI) % 1 + 1) % 1 - 0.5) < 0.16 && dx < 7) return C2;
      if (x < 14 && x > 9 && Math.abs(y - 12) < (14 - x) * 0.9) return C2;
      return null;
    };
    case 'lion': {
      const base = fishGeneric({ L: 0.66, H: 0.3, tail: 'round', c: sp.c, pat: 'vbands', n: 8, fin: C2 });
      return (x, y) => {
        const b = base(x, y); if (b) return b === C3 ? '#7a2010' : b;
        for (let i = 0; i < 7; i++) { const sx = 13 + i * 2.6; if (distSeg(x, y, sx, 9, sx - 2, 1 + (i % 2) * 2)[0] < 0.5) return i % 2 ? C2 : C0; }
        for (let i = 0; i < 5; i++) if (distSeg(x, y, 24, 14, 14 + i * 2, 22 - (i % 2))[0] < 0.6) return i % 2 ? C2 : C1;
        return null;
      };
    }
    case 'sunfish': return (x, y) => {
      const dx = x - 22, dy = y - 12;
      if ((dx / 11) ** 2 + (dy / 8.5) ** 2 <= 1 && x > 11 + Math.abs(Math.sin(dy * 1.1)) * 1.3) { if (Math.hypot(x - 29, y - 10) < 1.3) return '#101018'; if (dy > 4) return C1; return x < 14 ? C2 : C0; }
      if (x > 12 && x < 17 && y < 5 && y > 0 && Math.abs(x - 14.5 + (5 - y) * 0.25) < 2 - (5 - y) * 0.25) return C2;
      if (x > 12 && x < 17 && y > 19 && y < 24 && Math.abs(x - 14.5 + (y - 19) * 0.25) < 2 - (y - 19) * 0.25) return C2;
      return null;
    };
    case 'oarfish': return (x, y) => {
      const pts = []; for (let i = 0; i <= 14; i++) { const px = 1 + i * 2.6; pts.push([px, 13 + Math.sin(px * 0.25 + 1) * 3.5, i < 2 ? 0.6 + i * 0.6 : 1.9]); }
      const t = inChain(x, y, pts);
      if (t >= 0) { const h = pts[14]; if (Math.hypot(x - h[0], y - h[1] + 0.4) < 0.8) return '#101018'; return (Math.floor(x) % 4 === 0) ? C2 : C0; }
      for (const p of pts) if (Math.abs(x - p[0]) < 1.3 && y < p[1] - p[2] && y > p[1] - p[2] - 1.3) return C3;
      const h = pts[14];
      for (let i = 0; i < 4; i++) if (distSeg(x, y, h[0] - 1 - i, h[1] - 2, h[0] - 3 - i * 2, h[1] - 8 + i)[0] < 0.55) return C3;
      return null;
    };
  }
  return () => null;
}
/** Every species' sprite, its silhouette, and a small swimming shadow; built once. */
const FISH_ART = {};
function buildFishArt() {
  for (const sp of DATA.species) {
    const a = sp.art;
    const fn = a.s === 'fish' ? fishGeneric(a) : fishSpecial(a);
    const img = spriteFrom(FW, FH, fn);
    FISH_ART[sp.id] = { img, sil: silhouette(img) };
  }
}

// ---------------------------------------------------------------------------------------------
// People: anchor at the feet. dir: 0 down, 1 up, 2 left, 3 right.
const LOOK_FISHER = { hat: '#d8b860', hat2: '#a88a3a', skin: '#f0c098', hair: '#6a3e22', shirt: '#3a8a6a', shirt2: '#2a6a50', pants: '#3a4e8a', boots: '#4a2e1c' };
const LOOK_KEEPER = { hat: null, skin: '#e0a880', hair: '#d8d8d8', shirt: '#c85a3a', shirt2: '#f0e6d0', pants: '#5a4a3a', boots: '#3a2a1c', beard: '#e8e8e8' };

function R(g, x, y, w, h, c) { g.fillStyle = c; g.fillRect(x, y, w, h); }
/**
 * Draws a person; returns the rod tip in world coordinates when a rod is shown.
 * pose: idle | walk | run | cast | wait | fight | catch | rest
 */
function drawPerson(g, x, y, dir, pose, t, L, opt = {}) {
  x = Math.round(x); y = Math.round(y);
  const flip = dir === 3;
  const d = flip ? 2 : dir;
  g.save(); g.translate(x, y); if (flip) g.scale(-1, 1);
  let tip = null;
  // shadow
  g.fillStyle = 'rgba(0,0,0,0.28)'; g.fillRect(-5, -1, 10, 2); g.fillRect(-4, 0, 8, 1);
  if (pose === 'rest') {
    // sitting, eyes closed
    R(g, -5, -5, 4, 3, L.pants); R(g, 1, -5, 4, 3, L.pants); R(g, -6, -3, 3, 2, L.boots); R(g, 3, -3, 3, 2, L.boots);
    R(g, -4, -11, 8, 7, L.shirt); R(g, -4, -6, 8, 1, L.shirt2);
    R(g, -6, -10, 2, 5, L.shirt); R(g, 4, -10, 2, 5, L.shirt); R(g, -6, -6, 2, 1, L.skin); R(g, 4, -6, 2, 1, L.skin);
    R(g, -4, -17, 8, 6, L.skin); R(g, -4, -17, 8, 2, L.hair);
    R(g, -3, -13, 2, 1, PAL.outline); R(g, 1, -13, 2, 1, PAL.outline);
    if (L.hat) { R(g, -6, -17, 12, 2, L.hat); R(g, -3, -20, 6, 3, L.hat); R(g, -3, -18, 6, 1, L.hat2); }
    // rod lying beside
    g.fillStyle = '#c8a45a'; g.fillRect(6, -2, 9, 1);
    g.restore(); return null;
  }
  const f = Math.floor(t * (pose === 'run' ? 12 : 8)) % 4;
  const moving = pose === 'walk' || pose === 'run';
  const swing = moving ? [0, 1, 0, -1][f] * (pose === 'run' ? 2 : 1) : 0;
  const bob = moving && (f === 1 || f === 3) ? -1 : 0;
  const lean = pose === 'run' ? 1 : 0;
  g.translate(0, bob);
  // legs
  if (d === 2) {
    R(g, -2 + swing, -5, 3, 4, L.pants); R(g, -1 - swing, -5, 3, 4, L.pants);
    R(g, -3 + swing, -1, 4, 1, L.boots); R(g, -2 - swing, -1, 4, 1, L.boots);
  } else {
    R(g, -3, -5 + (swing > 0 ? -1 : 0), 3, 4, L.pants); R(g, 0, -5 + (swing < 0 ? -1 : 0), 3, 4, L.pants);
    R(g, -3, -1 + (swing > 0 ? -1 : 0), 3, 1, L.boots); R(g, 0, -1 + (swing < 0 ? -1 : 0), 3, 1, L.boots);
  }
  // body
  g.translate(-lean, 0);
  R(g, -4, -11, 8, 7, L.shirt);
  if (d === 0) { R(g, -1, -11, 2, 7, L.shirt2); R(g, -4, -6, 8, 1, '#5a3a22'); }
  else if (d === 1) { R(g, -4, -11, 8, 1, L.shirt2); R(g, -4, -6, 8, 1, '#5a3a22'); }
  else { R(g, -1, -11, 3, 7, L.shirt2); R(g, -4, -6, 8, 1, '#5a3a22'); }
  // head
  R(g, -4, -17, 8, 6, L.skin);
  if (d === 0) {
    R(g, -4, -17, 8, 2, L.hair); R(g, -2, -14, 1, 2, PAL.outline); R(g, 1, -14, 1, 2, PAL.outline);
    if (L.beard) { R(g, -4, -13, 8, 2, L.beard); R(g, -3, -11, 6, 1, L.beard); }
  } else if (d === 1) { R(g, -4, -17, 8, 5, L.hair); }
  else { R(g, -1, -17, 5, 3, L.hair); R(g, -3, -14, 1, 2, PAL.outline); R(g, -5, -13, 1, 1, L.skin); if (L.beard) { R(g, -4, -13, 4, 2, L.beard); } }
  if (L.hat) {
    R(g, -6, -17, 12, 2, L.hat); R(g, -3, -21, 7, 4, L.hat); R(g, -3, -18, 7, 1, L.hat2);
    if (d === 2) R(g, -7, -17, 2, 1, L.hat);
  } else if (L.hair) { R(g, -4, -18, 8, 1, L.hair); }
  // arms and rod
  const rodCol = opt.rodCol || '#c8a45a';
  const fishing = pose === 'cast' || pose === 'wait' || pose === 'fight' || pose === 'catch';
  if (pose === 'catch') {
    R(g, -6, -19, 2, 8, L.shirt); R(g, 4, -19, 2, 8, L.shirt); R(g, -6, -21, 2, 2, L.skin); R(g, 4, -21, 2, 2, L.skin);
    if (opt.fishImg) { g.save(); g.scale(flip ? -1 : 1, 1); g.drawImage(opt.fishImg, -10, -34, 20, 12); g.restore(); }
  } else if (fishing) {
    // rod angle: cast swings from behind to forward
    let ang;
    if (pose === 'cast') ang = -2.4 + Math.min(1, opt.phase || 0) * 1.9;  // radians, 0 = forward horizontal
    else if (pose === 'fight') ang = -0.9 + Math.sin(t * 30) * 0.08;
    else ang = -0.55 + Math.sin(t * 2) * 0.04;
    const hx = d === 1 ? 2 : -4, hy = -8;
    const fwd = d === 2 ? -1 : 1;
    R(g, d === 2 ? -6 : -5, -10, 2, 4, L.shirt); R(g, d === 2 ? -7 : -5, -7, 2, 2, L.skin);
    const len = 14;
    let tx, ty;
    if (d === 2) { tx = hx + Math.cos(ang) * len * fwd; ty = hy + Math.sin(ang) * len; }
    else if (d === 0) { tx = hx + 6 + Math.cos(ang) * 4; ty = hy + 4 - Math.sin(ang) * -len * 0.6; }
    else { tx = hx + 2 + Math.cos(ang) * 3; ty = hy + Math.sin(ang) * len; }
    g.strokeStyle = rodCol; g.lineWidth = 1; g.beginPath(); g.moveTo(hx + 0.5, hy + 0.5); g.lineTo(tx + 0.5, ty + 0.5); g.stroke();
    R(g, hx - 1, hy - 1, 2, 2, '#3a2a1c');
    tip = { x: x + (flip ? -tx : tx), y: y + bob + ty };
  } else {
    const as = moving ? swing : 0;
    if (d === 2) { R(g, -1 - as, -10, 2, 5, L.shirt); R(g, -1 - as, -6, 2, 1, L.skin); }
    else { R(g, -6, -10 - as * 0.5, 2, 5, L.shirt); R(g, 4, -10 + as * 0.5, 2, 5, L.shirt); R(g, -6, -6 - as * 0.5, 2, 1, L.skin); R(g, 4, -6 + as * 0.5, 2, 1, L.skin); }
    if (opt.rod) { g.strokeStyle = rodCol; g.beginPath(); g.moveTo(3.5, -8.5); g.lineTo(-5.5, -22.5); g.stroke(); }
  }
  g.restore();
  return tip;
}

// ---------------------------------------------------------------------------------------------
// Small item icons (16 x 16) for the shop.
function rodIcon(col) {
  return spriteFrom(16, 16, (x, y) => {
    if (distSeg(x, y, 3, 13, 14, 2)[0] < 0.7) return col;
    if (Math.hypot(x - 4.5, y - 11.5) < 1.6) return '#8a8a92';
    if (x > 2 && x < 5 && y > 12 && y < 15) return '#3a2a1c';
    if (distSeg(x, y, 14, 2, 14, 9)[0] < 0.4) return '#e8e8e8';
    return null;
  });
}
function baitIcon(id, col) {
  return spriteFrom(16, 16, (x, y) => {
    if (id === 'minhoca') return Math.abs(y - 8 - Math.sin(x * 0.9) * 3) < 1.4 && x > 2 && x < 14 ? col : null;
    if (id === 'camaraoreal') { const r = Math.hypot(x - 8, y - 5), a = Math.atan2(y - 5, x - 8); return r > 3 && r < 6.5 && a > 0.2 && a < 3 ? (Math.floor(a * 3) % 2 ? col : '#ffb08a') : null; }
    if (id === 'brilhante') { if (Math.hypot(x - 8, y - 8) < 4) return Math.hypot(x - 7, y - 7) < 1.5 ? '#ffffff' : col; if (Math.abs(x - 8) < 0.6 || Math.abs(y - 8) < 0.6) return Math.hypot(x - 8, y - 8) < 7 ? '#e0fbff' : null; return null; }
    if (id === 'dourada') { const fx = (x - 8) / 6, fy = (y - 8) / 3.2; if (fx * fx + fy * fy < 1) return x < 6 ? '#ffe68a' : col; if (x < 3 && Math.abs(y - 8) < 3 - x * 0.5) return col; return null; }
    if (id === 'cheirosa') { if (Math.hypot(x - 8, y - 10) < 3.5) return col; if (Math.abs(y - 4 - Math.sin(x) * 1) < 0.6 && x > 5 && x < 11) return '#e0f0a0'; return null; }
    if (id === 'sorte') { const a = Math.atan2(y - 8, x - 8), r = Math.hypot(x - 8, y - 8); const star = 4 + 2.5 * Math.cos(a * 5); return r < star ? '#7affa0' : null; }
    if (id === 'lanche') { if (y > 7 && y < 12 && x > 2 && x < 14) return y < 9 ? '#e8c070' : (y < 10 ? '#6ab04a' : '#c86a3a'); if (y >= 4 && y <= 7 && x > 3 && x < 13 && Math.hypot(x - 8, y - 7) < 5.5) return '#e8a850'; if (y >= 12 && y < 14 && x > 3 && x < 13) return '#e8a850'; return null; }
    if (Math.hypot(x - 8, y - 9) < 3.2) return col; if (distSeg(x, y, 8, 2, 8, 6)[0] < 0.5) return '#e8e8e8';
    return null;
  });
}
const ICONS = {};
function buildIcons() {
  for (const r of DATA.rods) ICONS[r.id] = rodIcon(r.col);
  for (const b of DATA.baits) ICONS[b.id] = baitIcon(b.id, b.col);
  ICONS.lanche = baitIcon('lanche'); ICONS.sorte = baitIcon('sorte');
  ICONS.coin = spriteFrom(10, 10, (x, y) => { const r = Math.hypot(x - 5, y - 5); return r < 4 ? (r < 2.2 && x > 4 && x < 6 ? '#c8901a' : (x + y < 7 ? '#fff0a0' : '#ffc93c')) : null; });
  ICONS.bolt = spriteFrom(10, 12, (x, y) => (distSeg(x, y, 7, 1, 3, 6)[0] < 1.3 || distSeg(x, y, 3, 6, 7, 6)[0] < 1.2 || distSeg(x, y, 7, 6, 3, 11)[0] < 1.3) ? '#ffe04a' : null);
  ICONS.bag = spriteFrom(12, 12, (x, y) => { if (((x - 6) / 5) ** 2 + ((y - 7.5) / 4) ** 2 <= 1) return y < 6 ? '#c89a5a' : '#a8784a'; if (y < 4 && y > 1 && Math.abs(x - 6) < 2) return '#8a5a32'; return null; });
  ICONS.book = spriteFrom(12, 12, (x, y) => { if (x > 1 && x < 11 && y > 1 && y < 11) { if (x < 3) return '#5a2e1a'; if (y > 9) return '#f0e6c8'; return '#8a3a22'; } return null; });
  ICONS.speaker = spriteFrom(12, 12, (x, y) => { if (x > 1 && x < 4 && y > 4 && y < 8) return PAL.cream; if (x >= 4 && x < 7 && Math.abs(y - 6) < (x - 2)) return PAL.cream; return null; }, null);
}
