// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Interface: HUD, touch buttons, panels (catch card, level-up, shop, book, sleep), toasts.
// Drawn on the 1280 x 720 logical canvas over the 320 x 180 pixel world.
'use strict';

const UIF = '"Courier New", Courier, monospace';
function utext(s, x, y, size, col, align = 'left', bold = true, shadow = true) {
  ctx.font = `${bold ? 'bold ' : ''}${size}px ${UIF}`; ctx.textAlign = align; ctx.textBaseline = 'middle';
  if (shadow) { ctx.fillStyle = 'rgba(0,0,0,0.7)'; ctx.fillText(s, x + 2, y + 2); }
  ctx.fillStyle = col; ctx.fillText(s, x, y);
}
function textW(s, size) { ctx.font = `bold ${size}px ${UIF}`; return ctx.measureText(s).width; }
/** A retro wooden panel with a light inner border. */
function panel(x, y, w, h, fill = PAL.ui, edge = PAL.uiEdge) {
  ctx.fillStyle = PAL.ink; ctx.fillRect(x - 4, y - 4, w + 8, h + 8);
  ctx.fillStyle = edge; ctx.fillRect(x - 2, y - 2, w + 4, h + 4);
  ctx.fillStyle = fill; ctx.fillRect(x, y, w, h);
  ctx.fillStyle = 'rgba(255,255,255,0.06)'; ctx.fillRect(x, y, w, 4);
}
function icon(img, x, y, scale) { ctx.imageSmoothingEnabled = false; ctx.drawImage(img, Math.round(x), Math.round(y), img.width * scale, img.height * scale); }

// ---- Toasts -----------------------------------------------------------------------------------
const toasts = [];
function toast(msg) { if (toasts.length && toasts[toasts.length - 1].msg === msg) { toasts[toasts.length - 1].life = 2.6; return; } toasts.push({ msg, life: 2.6 }); if (toasts.length > 2) toasts.shift(); }
function updateToasts(dt) { for (const t of toasts) t.life -= dt; while (toasts.length && toasts[0].life <= 0) toasts.shift(); }
function drawToasts() {
  toasts.forEach((t, i) => {
    const w = Math.min(1180, textW(t.msg, 22) + 40), y = 96 + i * 52;
    ctx.globalAlpha = Math.min(1, t.life * 3);
    panel(640 - w / 2, y, w, 40, '#3a2618'); utext(t.msg, 640, y + 21, 22, PAL.cream, 'center');
    ctx.globalAlpha = 1;
  });
}

// ---- Panels -----------------------------------------------------------------------------------
function openPanel(kind, data = {}) {
  if (state.panel) { state.panelQ.push({ kind, data }); return; }
  state.panel = { kind, data, t: 0 }; state.ui.scroll = 0;
  if (kind === 'levelup') sfx.level();
}
function queuePanel(kind, data) { openPanel(kind, data); }
function closePanel() {
  sfx.click();
  const next = state.panelQ.shift();
  state.panel = null;
  if (next) openPanel(next.kind, next.data);
}

// ---- Buttons ----------------------------------------------------------------------------------
// Every interactive element is a button from layoutButtons(): the same list is drawn and hit-tested.
function btn(id, x, y, w, h, label, opt = {}) { return { id, x, y, w, h, label, ...opt }; }
function nearDoor(s) { const P = s.player; return s.map === 'out' && Math.hypot(P.x - (OUT.door.x * TS + 8), P.y - ((OUT.door.y + 1) * TS + 10)) < 22; }
function nearCounter(s) { const P = s.player; return s.map === 'in' && P.y < (IN.counter.y + 2) * TS + 6 && P.x > IN.counter.x0 * TS && P.x < (IN.counter.x1 + 1) * TS; }

function layoutButtons(s) {
  const b = [];
  const p = s.panel;
  if (p) {
    if (p.kind === 'catch' || p.kind === 'sleep') b.push(btn('panel:close', 0, 0, 1280, 720, '', { invisible: true }));
    if (p.kind === 'levelup') b.push(btn('panel:close', 490, 580, 300, 70, 'CONTINUAR', { col: '#3a8a3a' }));
    if (p.kind === 'shop') {
      b.push(btn('panel:close', 1010, 82, 140, 52, 'FECHAR', { col: '#8a3a2a' }));
      ['VENDER', 'VARAS', 'ISCAS', 'ITENS'].forEach((t, i) => b.push(btn('tab:' + i, 150 + i * 214, 150, 200, 54, t, { sel: s.ui.shopTab === i })));
      if (s.ui.shopTab === 0) b.push(btn('sell', 440, 580, 400, 78, `VENDER TUDO  +${bagValue(s)}`, { on: s.bag.length > 0, col: '#3a8a3a' }));
      if (s.ui.shopTab === 1) DATA.rods.forEach((r, i) => b.push(gearBtn(s, 'rod', r, 940, 222 + i * 90)));
      if (s.ui.shopTab === 2) DATA.baits.forEach((r, i) => b.push(gearBtn(s, 'bait', r, 940, 218 + i * 76, 60)));
      if (s.ui.shopTab === 3) DATA.items.forEach((it, i) => {
        const lock = s.level < it.level;
        b.push(btn('item:' + it.id, 940, 236 + i * 120, 200, 64, lock ? `NÍVEL ${it.level}` : `COMPRAR ${it.price}`, { on: !lock && s.coins >= it.price, col: '#3a6a8a' }));
      });
    }
    if (p.kind === 'book') {
      b.push(btn('panel:close', 1080, 44, 140, 50, 'FECHAR', { col: '#8a3a2a' }));
      DATA.species.forEach((sp, i) => b.push(btn('cell:' + i, 66 + (i % 7) * 116, 116 + Math.floor(i / 7) * 112, 110, 106, '', { invisible: true })));
    }
    return b;
  }
  // HUD
  b.push(btn('pause', 1150, 12, 56, 46, 'II', { small: true }));
  b.push(btn('mute', 1214, 12, 56, 46, muted ? 'X' : '', { small: true, iconImg: ICONS.speaker }));
  const F = s.fishing, active = F.st === 'bite' || F.st === 'fight';
  b.push(btn('pull', 1066, 524, 196, 178, 'PUXAR', { hold: true, col: active ? '#c84a2a' : '#7a3a26', flash: F.st === 'bite', big: true }));
  b.push(btn('book', 944, 632, 112, 70, 'LIVRO', { iconImg: ICONS.book }));
  b.push(btn('rest', 822, 632, 112, 70, s.resting ? 'ACORDAR' : 'ZZZ', { col: s.resting ? '#3a5a9a' : undefined }));
  if (nearDoor(s)) b.push(btn('enter', 1066, 428, 196, 84, 'ENTRAR', { col: '#3a8a3a' }));
  if (s.map === 'in') {
    b.push(btn('exit', 1066, 428, 196, 84, 'SAIR', { col: '#8a5a2a' }));
    if (nearCounter(s)) b.push(btn('shop', 1066, 332, 196, 84, 'LOJA', { col: '#3a8a3a' }));
  }
  b.push(btn('snack', 18, 632, 170, 70, `LANCHE ${s.snacks}`, { on: s.snacks > 0, iconImg: ICONS.lanche }));
  b.push(btn('luck', 198, 632, 170, 70, `SORTE ${s.luckBaits}`, { on: s.luckBaits > 0, iconImg: ICONS.sorte }));
  return b;
}
function gearBtn(s, kind, item, x, y, h = 66) {
  const owned = (kind === 'rod' ? s.rodsOwned : s.baitsOwned).includes(item.id);
  const eq = (kind === 'rod' ? s.rod : s.bait) === item.id;
  const lock = s.level < item.level;
  let label, on = true, col = '#3a6a8a';
  if (eq) { label = kind === 'rod' ? 'EQUIPADA' : 'EQUIPADA'; on = false; col = '#3a8a3a'; }
  else if (owned) { label = 'EQUIPAR'; col = '#3a8a3a'; }
  else if (lock) { label = `NÍVEL ${item.level}`; on = false; }
  else { label = `COMPRAR ${item.price}`; on = s.coins >= item.price; }
  return btn(`${kind}:${item.id}`, x, y, 200, h - 8, label, { on, col, eq });
}
function hitButton(s, x, y) {
  const list = layoutButtons(s);
  for (let i = list.length - 1; i >= 0; i--) { const b = list[i]; if (x >= b.x && x <= b.x + b.w && y >= b.y && y <= b.y + b.h) return b; }
  return null;
}
function drawButton(b, s) {
  if (b.invisible) return;
  const pressed = s.ui.pullHeld && b.id === 'pull';
  const off = b.on === false;
  let base = b.col || '#5a3a24';
  if (b.sel) base = '#a8742a';
  const flash = b.flash && Math.floor(s.t * 8) % 2 === 0;
  ctx.globalAlpha = off ? 0.75 : 1;
  ctx.fillStyle = PAL.ink; ctx.fillRect(b.x - 3, b.y - 3, b.w + 6, b.h + 6);
  ctx.fillStyle = flash ? '#ffd23a' : PAL.uiEdge; ctx.fillRect(b.x - 1, b.y - 1, b.w + 2, b.h + 2);
  ctx.fillStyle = pressed ? '#5a2a1a' : base; ctx.fillRect(b.x + 2, b.y + 2, b.w - 4, b.h - 4);
  ctx.fillStyle = 'rgba(255,255,255,0.14)'; ctx.fillRect(b.x + 2, b.y + 2, b.w - 4, 6);
  ctx.fillStyle = 'rgba(0,0,0,0.25)'; ctx.fillRect(b.x + 2, b.y + b.h - 8, b.w - 4, 6);
  const size = b.big ? 34 : b.small ? 24 : (b.label.length > 12 ? 20 : 24);
  if (b.iconImg && !b.label) { icon(b.iconImg, b.x + b.w / 2 - 18, b.y + b.h / 2 - 18, 3); }
  else if (b.iconImg) { icon(b.iconImg, b.x + 10, b.y + b.h / 2 - 16 - (b.iconImg.height > 12 ? 0 : -4), b.iconImg.width > 12 ? 2 : 3); utext(b.label, b.x + b.w / 2 + 18, b.y + b.h / 2 + 1, size - 2, PAL.cream, 'center'); }
  else utext(b.label, b.x + b.w / 2, b.y + b.h / 2 + 1, size, flash ? PAL.ink : PAL.cream, 'center', true, !flash);
  if (b.big) {
    const F = s.fishing;
    const sub = F.st === 'bite' ? 'AGORA!' : F.st === 'fight' ? 'SEGURE' : F.st === 'wait' ? 'recolher' : 'lançar';
    utext(sub, b.x + b.w / 2, b.y + b.h / 2 + 40, 20, flash ? PAL.ink : '#e8d8b0', 'center', true, !flash);
  }
  ctx.globalAlpha = 1;
}

/** Acts on a tapped button. Returns true when handled. */
function pressButton(s, b) {
  const id = b.id;
  if (b.on === false && !id.startsWith('rod:') && !id.startsWith('bait:') && !id.startsWith('item:') && id !== 'sell' && id !== 'snack' && id !== 'luck') return true;
  if (id === 'panel:close') { if (s.panel && s.panel.t > 0.35) closePanel(); return true; }
  if (id.startsWith('tab:')) { s.ui.shopTab = +id.slice(4); sfx.click(); return true; }
  if (id === 'sell') { sellAll(s); return true; }
  if (id.startsWith('rod:')) { shopGear(s, 'rod', DATA.rods.find(r => r.id === id.slice(4))); return true; }
  if (id.startsWith('bait:')) { shopGear(s, 'bait', DATA.baits.find(r => r.id === id.slice(5))); return true; }
  if (id.startsWith('item:')) { shopItem(s, DATA.items.find(r => r.id === id.slice(5))); return true; }
  if (id.startsWith('cell:')) { s.ui.bookSel = +id.slice(5); sfx.click(); return true; }
  switch (id) {
    case 'pause': scene = 'pause'; sfx.click(); return true;
    case 'mute': setMuted(!muted); return true;
    case 'pull': pullPressed = true; s.ui.pullHeld = true; return true;
    case 'book': openPanel('book'); sfx.click(); return true;
    case 'rest': toggleRest(s); return true;
    case 'enter': enterHouse(s); return true;
    case 'exit': exitHouse(s); return true;
    case 'shop': openShop(s); return true;
    case 'snack': eatSnack(s); return true;
    case 'luck': useLuck(s); return true;
  }
  return false;
}
function openShop(s) { if (s.fishing.st !== 'idle') return; s.resting = false; s.ui.shopTab = s.bag.length ? 0 : 1; openPanel('shop'); sfx.click(); }

// ---- HUD --------------------------------------------------------------------------------------
function drawHUD(s) {
  ctx.fillStyle = 'rgba(26,18,8,0.88)'; ctx.fillRect(0, 0, 1280, 70); ctx.fillStyle = PAL.uiEdge; ctx.fillRect(0, 70, 1280, 3); ctx.fillStyle = PAL.ink; ctx.fillRect(0, 73, 1280, 2);
  const m = s.map === 'in' ? 'CASA DE PESCA' : 'LAGO ESMERALDA';
  utext(m, 16, 22, 22, '#a8e0ff');
  utext(`Dia ${s.day} · ${clockText(s.minutes)} · ${periodName(s.minutes)}`, 16, 50, 20, PAL.cream);
  icon(ICONS.coin, 352, 12, 3); utext(`${s.coins}`, 392, 28, 28, '#ffd23a');
  utext(`Nv ${s.level} ${DATA.levels[s.level - 1]}`, 352, 56, 18, PAL.cream);
  const nxt = s.level < 6 ? levelNeed(s.level + 1) : 35;
  utext(`Livro ${discovered(s)}/35`, 590, 22, 20, PAL.cream);
  utext(s.level < 6 ? `próx. nível: ${nxt}` : 'coleção completa!', 590, 50, 16, '#c8b890');
  // energy
  icon(ICONS.bolt, 784, 16, 3);
  const ex = 820, ew = 150;
  ctx.fillStyle = PAL.ink; ctx.fillRect(ex - 2, 20, ew + 4, 26);
  const e = s.energy / 100;
  ctx.fillStyle = e > 0.5 ? '#5ac84a' : e > 0.2 ? '#e8c03a' : '#e04a3a'; ctx.fillRect(ex, 22, ew * e, 22);
  ctx.fillStyle = 'rgba(255,255,255,0.25)'; ctx.fillRect(ex, 22, ew * e, 5);
  utext(`${Math.floor(s.energy)}%`, ex + ew / 2, 34, 18, '#ffffff', 'center');
  utext(s.resting ? 'descansando...' : 'Energia', ex, 60, 15, '#c8b890');
  // bag
  icon(ICONS.bag, 990, 14, 3);
  utext(`${s.bag.length}/${tune.bagSize}`, 1032, 26, 22, s.bag.length >= tune.bagSize ? '#ff8a6a' : PAL.cream);
  utext(`~${bagValue(s)} moedas`, 990, 56, 16, '#ffd23a');
  // luck indicator
  if (s.luckLeft > 0) { const m2 = Math.ceil(s.luckLeft); panel(16, 92, 210, 34, '#1e3a24'); icon(ICONS.sorte, 22, 93, 2); utext(`Sorte ${Math.floor(m2 / 60)}h${String(m2 % 60).padStart(2, '0')}`, 60, 110, 18, '#7affa0'); }
}
/** The bar fight, the bite alert, the first-minute hint. */
function drawFishingUI(s) {
  const F = s.fishing;
  if (F.st === 'bite') {
    const pulse = 1 + Math.sin(s.t * 20) * 0.08;
    ctx.save(); ctx.translate(640, 190); ctx.scale(pulse, pulse);
    panel(-220, -36, 440, 72, '#8a2a1a', '#ffd23a'); utext('MORDEU! PUXAR!', 0, 2, 36, '#ffffff', 'center');
    ctx.restore();
  }
  if (F.st === 'fight' || F.st === 'caught') {
    const x = 290, y = 206, w = 700, h = 44;
    panel(x - 16, y - 96, w + 32, 184, 'rgba(30,20,12,0.92)');
    const rc = F.st === 'caught' ? DATA.rarities[F.sp.r].color : '#c8b890';
    utext(F.st === 'caught' ? 'PEGOU!' : 'Segure PUXAR para ficar na zona verde', 640, y - 74, 22, F.st === 'caught' ? rc : PAL.cream, 'center');
    // progress
    ctx.fillStyle = PAL.ink; ctx.fillRect(x, y - 52, w, 22);
    const pr = F.st === 'caught' ? 1 : Math.max(0, F.progress);
    ctx.fillStyle = pr > 0.66 ? '#5ac84a' : pr > 0.33 ? '#e8c03a' : '#e04a3a'; ctx.fillRect(x + 2, y - 50, (w - 4) * pr, 18);
    utext(`${Math.floor(pr * 100)}%`, x + w / 2, y - 41, 18, '#ffffff', 'center');
    // bar with green zone
    ctx.fillStyle = PAL.ink; ctx.fillRect(x - 2, y - 2, w + 4, h + 4);
    ctx.fillStyle = '#2a4a6a'; ctx.fillRect(x, y, w, h);
    for (let i = 0; i < w; i += 20) { ctx.fillStyle = 'rgba(255,255,255,0.06)'; ctx.fillRect(x + i, y, 10, h); }
    const zx = x + (F.zone - F.zoneW / 2) * w, zw = F.zoneW * w;
    ctx.fillStyle = F.inZone ? '#6ae05a' : '#3aa83a'; ctx.fillRect(zx, y + 2, zw, h - 4);
    ctx.fillStyle = 'rgba(255,255,255,0.3)'; ctx.fillRect(zx, y + 2, zw, 5);
    // indicator: a hook marker
    const ix = x + F.pos * w;
    ctx.fillStyle = PAL.ink; ctx.fillRect(ix - 5, y - 10, 10, h + 20);
    ctx.fillStyle = F.inZone ? '#ffffff' : '#ffb04a'; ctx.fillRect(ix - 3, y - 8, 6, h + 16);
    ctx.fillStyle = PAL.ink; ctx.fillRect(ix - 8, y - 18, 16, 10);
    ctx.fillStyle = '#e04a3a'; ctx.fillRect(ix - 6, y - 16, 12, 6);
    // the fish's mood
    if (F.st === 'fight') {
      const r = F.sp.r, hint = ['calmo', 'agitado', 'forte', 'feroz', 'lendário!'][r];
      utext(`Peixe ${hint}`, x, y + h + 26, 18, DATA.rarities[r].color);
      if (F.dart > 0) utext('TRANCO!', x + w, y + h + 26, 20, '#ff8a6a', 'right');
    }
  }
  if (F.st === 'wait') utext('Esperando a mordida... (PUXAR recolhe)', 640, 572, 20, PAL.cream, 'center');
  if (s.stats.caught === 0 && F.st === 'idle' && !s.panel && s.map === 'out') {
    const msg = s.energy < tune.castCost ? 'Sem energia: toque em ZZZ para descansar' : 'Ande até a beira e toque na água para lançar';
    panel(640 - 300, 548, 600, 44, '#24402a'); utext(msg, 640, 571, 21, '#d8ffc0', 'center');
  }
}

// ---- Panels drawing ---------------------------------------------------------------------------
function drawPanel(s) {
  const p = s.panel; if (!p) return;
  ctx.fillStyle = 'rgba(8,6,4,0.62)'; ctx.fillRect(0, 0, 1280, 720);
  if (p.kind === 'catch') drawCatch(s, p.data, p.t);
  if (p.kind === 'levelup') drawLevelUp(s, p.data, p.t);
  if (p.kind === 'shop') drawShop(s);
  if (p.kind === 'book') drawBook(s);
  if (p.kind === 'sleep') drawSleep(s, p.data, p.t);
  for (const b of layoutButtons(s)) drawButton(b, s);
}
function drawCatch(s, d, t) {
  const rc = DATA.rarities[d.sp.r];
  const k = Math.min(1, t * 4);
  ctx.save(); ctx.translate(640, 360); ctx.scale(0.8 + 0.2 * k, 0.8 + 0.2 * k); ctx.translate(-640, -360);
  panel(330, 120, 620, 470, '#2a1c12', rc.color);
  utext(d.isNew ? 'NOVA ESPÉCIE!' : d.record ? 'NOVO RECORDE!' : 'PEGOU!', 640, 164, 40, d.isNew ? '#ffd23a' : PAL.cream, 'center');
  // sun rays behind the fish
  ctx.save(); ctx.translate(640, 290); ctx.rotate(t * 0.5); ctx.fillStyle = 'rgba(255,230,140,0.10)';
  for (let i = 0; i < 8; i++) { ctx.rotate(Math.PI / 4); ctx.beginPath(); ctx.moveTo(0, 0); ctx.lineTo(-30, -190); ctx.lineTo(30, -190); ctx.fill(); }
  ctx.restore();
  icon(FISH_ART[d.sp.id].img, 640 - 120, 290 - 72 + Math.sin(t * 3) * 4, 6);
  utext(d.sp.name, 640, 404, 38, '#ffffff', 'center');
  utext(rc.name.toUpperCase(), 640, 446, 24, rc.color, 'center');
  utext(`${fmtKg(d.c.w)}  ·  ${d.c.v} moedas`, 640, 488, 26, PAL.cream, 'center');
  const e = s.book[d.sp.id];
  utext(`Capturas: ${e.n}  ·  Recorde: ${fmtKg(e.best)}`, 640, 526, 20, '#c8b890', 'center');
  if (t > 0.35) utext('Toque para continuar', 640, 566, 20, '#a8e0ff', 'center');
  ctx.restore();
}
function drawLevelUp(s, d, t) {
  panel(180, 70, 920, 600, '#2a1c12', '#ffd23a');
  const glow = 0.7 + Math.sin(t * 4) * 0.3;
  ctx.globalAlpha = glow; utext('SUBIU DE NÍVEL!', 640, 118, 30, '#ffd23a', 'center'); ctx.globalAlpha = 1;
  utext(`Nível ${d.level}: ${DATA.levels[d.level - 1].toUpperCase()}`, 640, 168, 44, '#ffffff', 'center');
  if (d.level <= 5) {
    const r = d.level - 1, rc = DATA.rarities[r];
    utext(`Nova raridade liberada: ${rc.name}`, 640, 222, 26, rc.color, 'center');
    const n = d.species.length, cw = 104, x0 = 640 - (n * cw) / 2;
    d.species.forEach((sp, i) => {
      const known = s.book[sp.id];
      panel(x0 + i * cw + 6, 252, cw - 12, 90, '#1a1410', rc.color);
      icon(known ? FISH_ART[sp.id].img : FISH_ART[sp.id].sil, x0 + i * cw + 12, 268, 2);
      utext(known ? sp.name.split('-')[0].slice(0, 8) : '???', x0 + i * cw + cw / 2, 330, 15, PAL.cream, 'center', true, false);
    });
  } else {
    utext('Você completou o Livro de Peixes!', 640, 230, 28, '#ffd23a', 'center');
    utext(`${s.stats.caught} peixes pescados · ${s.day} dias no lago`, 640, 280, 22, PAL.cream, 'center');
    for (let i = 0; i < 5; i++) icon(FISH_ART[DATA.species[30 + i].id].img, 360 + i * 116, 300, 2.5);
  }
  utext('Liberado na loja:', 640, 380, 22, '#a8e0ff', 'center');
  utext(d.items.length ? d.items.map(x => x.name).join(' · ') : '—', 640, 414, d.items.length > 2 ? 18 : 22, PAL.cream, 'center');
  icon(ICONS.coin, 520, 470, 4);
  utext(`+${d.reward} moedas`, 570, 490, 34, '#ffd23a');
  if (t > 0.6) sparkleUI(t);
}
function sparkleUI(t) { for (let i = 0; i < 12; i++) { const a = i * 0.52 + t, r = 300 + Math.sin(t * 2 + i) * 30; const x = 640 + Math.cos(a) * r * 1.4, y = 370 + Math.sin(a) * r * 0.9; if (y > 80 && y < 660) { ctx.fillStyle = i % 2 ? '#ffd23a' : '#ffffff'; ctx.fillRect(x, y, 6, 6); } } }

function drawShop(s) {
  panel(120, 70, 1040, 610);
  utext('LOJA DO LAGO', 150, 108, 32, '#ffd23a');
  icon(ICONS.coin, 560, 92, 3); utext(`${s.coins} moedas`, 600, 108, 26, '#ffd23a');
  const tab = s.ui.shopTab;
  if (tab === 0) {
    if (!s.bag.length) utext('A bolsa está vazia. Vá pescar!', 640, 380, 26, '#c8b890', 'center');
    s.bag.forEach((f, i) => {
      const sp = SPECIES[f.id], cx = 150 + (i % 10) * 98, cy = 226 + Math.floor(i / 10) * 140;
      panel(cx + 4, cy, 88, 124, '#1a1410', DATA.rarities[sp.r].color);
      icon(FISH_ART[f.id].img, cx + 8, cy + 8, 2);
      utext(fmtKg(f.w), cx + 48, cy + 76, 15, PAL.cream, 'center', true, false);
      utext(`${f.v}`, cx + 48, cy + 104, 18, '#ffd23a', 'center', true, false);
    });
    utext(`${s.bag.length} peixe(s) · total ${bagValue(s)} moedas`, 640, 540, 22, PAL.cream, 'center');
  }
  if (tab === 1) DATA.rods.forEach((r, i) => {
    const y = 214 + i * 90;
    panel(150, y, 980, 78, r.id === s.rod ? '#2e4a2a' : '#3a2618');
    icon(ICONS[r.id], 162, y + 8, 4);
    utext(r.name, 240, y + 24, 24, s.level >= r.level ? '#ffffff' : '#8a7a6a');
    utext(`Alcance ${r.range} · Zona verde +${Math.round(r.zone * 100)}% · Força x${r.power.toFixed(2)}`, 240, y + 54, 17, '#c8b890');
  });
  if (tab === 2) DATA.baits.forEach((r, i) => {
    const y = 210 + i * 76;
    panel(150, y, 980, 64, r.id === s.bait ? '#2e4a2a' : '#3a2618');
    icon(ICONS[r.id], 166, y + 4, 3.5);
    utext(r.name, 240, y + 20, 23, s.level >= r.level ? '#ffffff' : '#8a7a6a');
    utext(`Espera -${Math.round((1 - r.wait) * 100)}% · Peixes melhores +${Math.round(r.rare * 100)}%`, 240, y + 46, 17, '#c8b890');
  });
  if (tab === 3) DATA.items.forEach((it, i) => {
    const y = 226 + i * 120, have = it.id === 'lanche' ? s.snacks : s.luckBaits;
    panel(150, y, 980, 84, '#3a2618');
    icon(ICONS[it.id], 164, y + 10, 4);
    utext(`${it.name}  (você tem ${have})`, 240, y + 26, 24, s.level >= it.level ? '#ffffff' : '#8a7a6a');
    utext(it.id === 'lanche' ? `+${tune.snackEnergy} de energia · use pelo botão LANCHE` : `Raros ou melhores x${tune.luckMult} por ${tune.luckMinutes / 60}h · botão SORTE`, 240, y + 58, 17, '#c8b890');
  });
}
function drawBook(s) {
  panel(50, 36, 1180, 650);
  const n = discovered(s);
  utext('LIVRO DE PEIXES', 70, 72, 32, '#ffd23a');
  utext(`${n}/35 descobertos`, 420, 72, 24, PAL.cream);
  ctx.fillStyle = PAL.ink; ctx.fillRect(700, 62, 300, 20); ctx.fillStyle = '#5ac84a'; ctx.fillRect(702, 64, 296 * n / 35, 16);
  const sel = s.ui.bookSel;
  DATA.species.forEach((sp, i) => {
    const x = 66 + (i % 7) * 116, y = 116 + Math.floor(i / 7) * 112, e = s.book[sp.id], rc = DATA.rarities[sp.r];
    ctx.fillStyle = i === sel ? '#ffd23a' : rc.color; ctx.fillRect(x, y, 110, 106);
    ctx.fillStyle = e ? '#2a3a4a' : '#1a1410'; ctx.fillRect(x + 3, y + 3, 104, 100);
    icon(e ? FISH_ART[sp.id].img : FISH_ART[sp.id].sil, x + 15, y + 10, 2);
    utext(e ? sp.name : '???', x + 55, y + 78, sp.name.length > 11 && e ? 14 : 16, e ? '#ffffff' : '#8a7a6a', 'center', true, false);
    if (e) utext(`x${e.n}`, x + 55, y + 96, 14, '#c8b890', 'center', true, false);
  });
  // detail
  const sp = DATA.species[sel], e = s.book[sp.id], rc = DATA.rarities[sp.r];
  panel(890, 116, 320, 552, '#1a1410', rc.color);
  ctx.fillStyle = '#2a4a6a'; ctx.fillRect(906, 132, 288, 180);
  icon(e ? FISH_ART[sp.id].img : FISH_ART[sp.id].sil, 930, 150, 6);
  utext(e ? sp.name : '???', 1050, 342, e && sp.name.length > 13 ? 22 : 28, '#ffffff', 'center');
  utext(rc.name, 1050, 380, 22, rc.color, 'center');
  const when = sp.time === 'night' ? 'à noite' : sp.time === 'day' ? 'de dia' : 'qualquer hora';
  const lines = e
    ? [`Capturas: ${e.n}`, `Maior: ${fmtKg(e.best)}`, `Peso: ${fmtKg(sp.kg[0])}–${fmtKg(sp.kg[1])}`, `Valor base: ${sp.v}`, `Aparece ${when}`, `Dificuldade: ${Math.round(sp.d * 10)}/10`]
    : ['Ainda não descoberto.', `Aparece ${when}`, s.level - 1 < sp.r ? `Liberado no nível ${sp.r + 1}` : 'Já pode morder!'];
  lines.forEach((l, i) => utext(l, 910, 426 + i * 36, 19, PAL.cream));
}
function drawSleep(s, d, t) {
  const a = t < 0.6 ? t / 0.6 : t > 1.9 ? Math.max(0, 1 - (t - 1.9) / 0.6) : 1;
  ctx.fillStyle = `rgba(4,6,20,${a})`; ctx.fillRect(0, 0, 1280, 720);
  ctx.globalAlpha = a;
  utext(d.auto ? 'Já era tarde... você adormeceu.' : 'Você dormiu.', 640, 300, 30, '#a8c0ff', 'center');
  utext(`Bom dia! Dia ${d.day}`, 640, 360, 44, '#ffd23a', 'center');
  utext('Energia recuperada', 640, 414, 24, PAL.cream, 'center');
  ctx.globalAlpha = 1;
}
