// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Save system: automatic saving to the browser's local storage.
'use strict';
const SAVE_KEY = 'lakebound-save-v1';
const SAVE_FIELDS = ['coins', 'level', 'day', 'minutes', 'energy', 'bag', 'book', 'rodsOwned', 'rod', 'baitsOwned', 'bait', 'snacks', 'luckBaits', 'luckLeft', 'map', 'stats'];
function saveGame(s) {
  if (params.get('nosave') === '1') return;
  try {
    const o = {}; for (const k of SAVE_FIELDS) o[k] = s[k];
    o.px = s.player.x; o.py = s.player.y; o.dir = s.player.dir; o.v = 1;
    localStorage.setItem(SAVE_KEY, JSON.stringify(o));
  } catch (e) { /* storage blocked: play on without saving */ }
}
function loadSave() {
  if (params.get('nosave') === '1') return null;
  try { const t = localStorage.getItem(SAVE_KEY); return t ? JSON.parse(t) : null; } catch (e) { return null; }
}
function applySave(s, o) {
  for (const k of SAVE_FIELDS) if (o[k] !== undefined) s[k] = o[k];
  s.player.x = o.px ?? s.player.x; s.player.y = o.py ?? s.player.y; s.player.dir = o.dir ?? 0;
  if (!s.stats) s.stats = { caught: 0, earned: 0 };
  const m = s.map === 'in' ? world.in : world.out;
  if (!boxFree(m, s.player.x, s.player.y)) { const sp = s.map === 'in' ? IN.spawn : OUT.spawn; s.player.x = sp.x; s.player.y = sp.y; }
}
function wipeSave() { try { localStorage.removeItem(SAVE_KEY); } catch (e) { /* ignore */ } }
