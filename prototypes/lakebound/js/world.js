// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// World and movement: the Lago Esmeralda map, the fishing house interior, collisions,
// tap-to-move pathfinding, and the living things in the water (shadows, schools).
'use strict';

const TS = 16;                       // tile size in world pixels
const T = { GRASS: 0, DIRT: 1, SAND: 2, SHALLOW: 3, DEEP: 4, DOCK: 5, BRIDGE: 6, FLOWERS: 7, FLOOR: 8, WALL: 9, RUG: 10 };
const WALKABLE = new Set([T.GRASS, T.DIRT, T.SAND, T.DOCK, T.BRIDGE, T.FLOWERS, T.FLOOR, T.RUG]);
const isWaterT = t => t === T.SHALLOW || t === T.DEEP;

/** A map: tiles, solid overlay (props), props list, decor, size. */
function makeMap(w, h, fill) {
  return { w, h, tiles: new Uint8Array(w * h).fill(fill), solid: new Uint8Array(w * h), props: [], decor: [], lights: [] };
}
function tileAt(m, tx, ty) { return (tx < 0 || ty < 0 || tx >= m.w || ty >= m.h) ? -1 : m.tiles[ty * m.w + tx]; }
function setT(m, tx, ty, v) { if (tx >= 0 && ty >= 0 && tx < m.w && ty < m.h) m.tiles[ty * m.w + tx] = v; }
function solidAt(m, tx, ty) {
  const t = tileAt(m, tx, ty);
  return t < 0 || !WALKABLE.has(t) || m.solid[ty * m.w + tx] === 1;
}
function isWaterAt(m, wx, wy) { return isWaterT(tileAt(m, Math.floor(wx / TS), Math.floor(wy / TS))); }

// ---------------------------------------------------------------------------------------------
// Lago Esmeralda: 48 x 34 tiles.
const OUT = { house: { x: 6, y: 2, w: 5, h: 4 }, door: { x: 8, y: 5 }, spawn: { x: 9 * TS + 8, y: 7 * TS + 10 },
  pier: { x: 21, y0: 8, y1: 13 }, island: { x: 34, y: 19 }, islet: { x: 17, y: 15 } };

function buildOutdoor() {
  const m = makeMap(48, 34, T.GRASS);
  const lake = (x, y) => {
    let d = ((x - 25) / 15) ** 2 + ((y - 19.5) / 10) ** 2;
    d += 0.09 * Math.sin(x * 0.55) + 0.07 * Math.cos(y * 0.8 + 1);
    d = Math.min(d, ((x - 37) / 7) ** 2 + ((y - 25) / 5) ** 2 + 0.05 * Math.sin(y)); // east cove
    return d;
  };
  for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) {
    const d = lake(x + 0.5, y + 0.5);
    if (d < 1) setT(m, x, y, d < 0.62 ? T.DEEP : T.SHALLOW);
  }
  // islands
  const isl = (cx, cy, r) => { for (let y = cy - 4; y <= cy + 4; y++) for (let x = cx - 4; x <= cx + 4; x++) { const d = Math.hypot(x + 0.5 - cx - 0.5, y + 0.5 - cy - 0.5); if (d < r) setT(m, x, y, d < r - 1 ? T.GRASS : T.SAND); else if (d < r + 1.2 && tileAt(m, x, y) === T.DEEP) setT(m, x, y, T.SHALLOW); } };
  isl(OUT.island.x, OUT.island.y, 2.9); isl(OUT.islet.x, OUT.islet.y, 1.7);
  // sand beaches next to water
  for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) {
    if (tileAt(m, x, y) !== T.GRASS) continue;
    let nearW = false;
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) if (isWaterT(tileAt(m, x + dx, y + dy))) nearW = true;
    if (nearW && hash2(x, y, 1) > 0.35) setT(m, x, y, T.SAND);
  }
  // shallow ring along every shore
  for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) {
    if (tileAt(m, x, y) !== T.DEEP) continue;
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { const t = tileAt(m, x + dx, y + dy); if (t >= 0 && !isWaterT(t)) setT(m, x, y, T.SHALLOW); }
  }
  // dirt path: house door -> pier, and a branch to the island bridge
  const path = [];
  for (let y = OUT.door.y + 1; y <= 7; y++) path.push([OUT.door.x, y]);
  for (let x = OUT.door.x; x <= OUT.pier.x; x++) path.push([x, 7]);
  for (let y = 7; y <= 30; y++) path.push([43, y]);
  for (let x = OUT.pier.x; x <= 43; x++) path.push([x, 6]);
  path.push([OUT.pier.x, 6]);
  for (const [x, y] of path) if (!isWaterT(tileAt(m, x, y))) setT(m, x, y, T.DIRT);
  // pier (2 wide) going south into the lake
  for (let y = OUT.pier.y0; y <= OUT.pier.y1; y++) for (let x = OUT.pier.x; x <= OUT.pier.x + 1; x++) setT(m, x, y, T.DOCK);
  // bridge to the island, from the east shore
  for (let x = OUT.island.x + 2; x < 46; x++) { const t = tileAt(m, x, OUT.island.y); if (isWaterT(t) || t === T.SAND) setT(m, x, OUT.island.y, T.BRIDGE); else break; }
  // flowers
  for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) if (tileAt(m, x, y) === T.GRASS && hash2(x, y, 2) > 0.9) setT(m, x, y, T.FLOWERS);

  // house
  const H = OUT.house;
  for (let y = H.y; y < H.y + H.h; y++) for (let x = H.x; x < H.x + H.w; x++) { setT(m, x, y, T.GRASS); m.solid[y * m.w + x] = 1; }
  m.props.push({ kind: 'house', x: H.x * TS, y: H.y * TS, by: (H.y + H.h) * TS });
  m.lights.push({ x: (H.x + 1) * TS + 4, y: (H.y + 3) * TS, r: 30 }, { x: (H.x + 4) * TS - 4, y: (H.y + 3) * TS, r: 30 });
  // lantern at the end of the pier
  m.props.push({ kind: 'lantern', x: (OUT.pier.x + 1) * TS + 12, y: OUT.pier.y1 * TS + 14, by: OUT.pier.y1 * TS + 15 });
  m.solid[OUT.pier.y1 * m.w + OUT.pier.x + 1] = 0;
  m.lights.push({ x: (OUT.pier.x + 1) * TS + 12, y: OUT.pier.y1 * TS + 4, r: 44 });
  // a sign by the door
  m.props.push({ kind: 'sign', x: (OUT.door.x + 2) * TS + 4, y: (OUT.door.y + 1) * TS + 12, by: (OUT.door.y + 1) * TS + 12 });
  m.solid[(OUT.door.y + 1) * m.w + OUT.door.x + 2] = 1;

  // trees, rocks, bushes
  const clear = (x, y) => {
    if (Math.abs(x - OUT.door.x) <= 3 && y >= OUT.house.y - 1 && y <= OUT.door.y + 3) return false;
    if (Math.abs(x - 9) <= 1 && Math.abs(y - 7) <= 1) return false;
    return true;
  };
  for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) {
    const t = tileAt(m, x, y);
    if (t !== T.GRASS && t !== T.FLOWERS) continue;
    if (m.solid[y * m.w + x] || !clear(x, y)) continue;
    let nearPath = false;
    for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { const n = tileAt(m, x + dx, y + dy); if (n === T.DIRT || n === T.BRIDGE || n === T.DOCK) nearPath = true; }
    const border = x < 2 || y < 1 || x > 45 || y > 31;
    const h = hash2(x, y, 3);
    if ((border && h > 0.12) || (!nearPath && h > 0.9)) {
      m.solid[y * m.w + x] = 1;
      m.props.push({ kind: hash2(x, y, 4) > 0.55 ? 'pine' : 'tree', x: x * TS + 8, y: y * TS + 14, by: y * TS + 14, ph: h * 6 });
    } else if (!nearPath && h > 0.86) {
      m.solid[y * m.w + x] = 1; m.props.push({ kind: 'bush', x: x * TS + 8, y: y * TS + 13, by: y * TS + 13, ph: h * 6 });
    } else if (!nearPath && h > 0.84) {
      m.solid[y * m.w + x] = 1; m.props.push({ kind: 'rock', x: x * TS + 8, y: y * TS + 13, by: y * TS + 13 });
    }
  }
  // a tree on each island
  for (const [x, y] of [[OUT.island.x, OUT.island.y - 1], [OUT.islet.x, OUT.islet.y]]) {
    m.solid[y * m.w + x] = 1; m.props.push({ kind: 'tree', x: x * TS + 8, y: y * TS + 14, by: y * TS + 14, ph: 2 });
  }
  m.solid[(OUT.island.y + 1) * m.w + OUT.island.x - 1] = 1; m.props.push({ kind: 'rock', x: (OUT.island.x - 1) * TS + 8, y: (OUT.island.y + 1) * TS + 13, by: (OUT.island.y + 1) * TS + 13 });
  // decor: grass tufts, reeds and lily pads
  for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) {
    const t = tileAt(m, x, y), h = hash2(x, y, 5);
    if ((t === T.GRASS) && !m.solid[y * m.w + x] && h > 0.55) m.decor.push({ kind: 'tuft', x: x * TS + 3 + (h * 97 % 10), y: y * TS + 6 + (h * 31 % 8), ph: h * 6 });
    if (t === T.SHALLOW) {
      let nearLand = false;
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) { const n = tileAt(m, x + dx, y + dy); if (n >= 0 && !isWaterT(n) && n !== T.DOCK && n !== T.BRIDGE) nearLand = true; }
      if (nearLand && h > 0.72) m.decor.push({ kind: 'reed', x: x * TS + 4 + (h * 53 % 8), y: y * TS + 12, ph: h * 6 });
      else if (h > 0.9) m.decor.push({ kind: 'lily', x: x * TS + 4 + (h * 71 % 8), y: y * TS + 4 + (h * 13 % 8), ph: h * 6, flower: h > 0.96 });
    }
  }
  m.props.sort((a, b) => a.by - b.by);
  // the first-minute hint points at the water tile nearest the spawn
  let best = null;
  for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) if (isWaterT(tileAt(m, x, y))) { const d = Math.hypot(x * TS + 8 - OUT.spawn.x, y * TS + 8 - OUT.spawn.y); if (!best || d < best.d) best = { x: x * TS + 8, y: y * TS + 8, d }; }
  m.hint = best;
  m.name = 'Lago Esmeralda';
  return m;
}

// Fishing house interior: 12 x 8 tiles.
const IN = { door: { x: 6, y: 7 }, counter: { x0: 3, x1: 8, y: 3 }, spawn: { x: 6 * TS + 8, y: 6 * TS + 10 } };
function buildIndoor() {
  const m = makeMap(12, 8, T.FLOOR);
  for (let x = 0; x < 12; x++) { setT(m, x, 0, T.WALL); setT(m, x, 1, T.WALL); setT(m, x, 7, T.WALL); }
  for (let y = 0; y < 8; y++) { setT(m, 0, y, T.WALL); setT(m, 11, y, T.WALL); }
  setT(m, IN.door.x, 7, T.FLOOR);
  for (let x = 4; x <= 7; x++) for (let y = 4; y <= 6; y++) setT(m, x, y, T.RUG);
  for (let x = IN.counter.x0; x <= IN.counter.x1; x++) m.solid[IN.counter.y * m.w + x] = 1;
  m.props.push({ kind: 'counter', x: IN.counter.x0 * TS, y: IN.counter.y * TS, by: (IN.counter.y + 1) * TS - 2 });
  m.props.push({ kind: 'keeper', x: 6 * TS + 8, y: IN.counter.y * TS + 2, by: IN.counter.y * TS + 2 });
  for (const [x, y] of [[1, 2], [1, 3], [10, 2]]) { m.solid[y * m.w + x] = 1; m.props.push({ kind: 'barrel', x: x * TS + 8, y: y * TS + 14, by: y * TS + 14 }); }
  m.solid[6 * m.w + 10] = 1; m.props.push({ kind: 'plant', x: 10 * TS + 8, y: 6 * TS + 14, by: 6 * TS + 14 });
  m.solid[5 * m.w + 1] = 1; m.solid[6 * m.w + 1] = 1; m.props.push({ kind: 'bed', x: 1 * TS, y: 5 * TS, by: 7 * TS - 2 });
  m.props.sort((a, b) => a.by - b.by);
  m.lights.push({ x: 6 * TS, y: 3 * TS, r: 90 });
  m.name = 'Casa de Pesca';
  return m;
}

// ---------------------------------------------------------------------------------------------
// Collision: the player's feet are a small box.
const FEET = { w: 8, h: 5 };
function boxFree(m, x, y) {
  const x0 = Math.floor((x - FEET.w / 2) / TS), x1 = Math.floor((x + FEET.w / 2 - 0.01) / TS);
  const y0 = Math.floor((y - FEET.h) / TS), y1 = Math.floor((y - 0.01) / TS);
  for (let ty = y0; ty <= y1; ty++) for (let tx = x0; tx <= x1; tx++) if (solidAt(m, tx, ty)) return false;
  return true;
}
/** Moves with axis-separated collision; returns true if the move was blocked on both axes. */
function moveBody(m, p, dx, dy) {
  let blocked = 0;
  if (dx) { if (boxFree(m, p.x + dx, p.y)) p.x += dx; else blocked++; }
  if (dy) { if (boxFree(m, p.x, p.y + dy)) p.y += dy; else blocked++; }
  return blocked > 0 && (!dx || !dy || blocked === 2);
}
/** Breadth-first path over walkable tiles; returns tile centres to walk through, or null. */
function findPath(m, sx, sy, goalTest, maxN = 4000) {
  const start = [Math.floor(sx / TS), Math.floor(sy / TS)];
  const prev = new Int32Array(m.w * m.h).fill(-2);
  const q = [start[1] * m.w + start[0]]; prev[q[0]] = -1;
  let head = 0, found = -1;
  while (head < q.length && head < maxN) {
    const i = q[head++], x = i % m.w, y = (i / m.w) | 0;
    if (goalTest(x, y)) { found = i; break; }
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const nx = x + dx, ny = y + dy;
      if (solidAt(m, nx, ny)) continue;
      const j = ny * m.w + nx; if (prev[j] !== -2) continue;
      prev[j] = i; q.push(j);
    }
  }
  if (found < 0) return null;
  const out = [];
  for (let i = found; i !== -1; i = prev[i]) out.push({ x: (i % m.w) * TS + 8, y: ((i / m.w) | 0) * TS + 11 });
  out.reverse(); out.shift();
  return out;
}

// ---------------------------------------------------------------------------------------------
// Living water: fish shadows and bubbling schools.
function spawnWaterLife(w) {
  const m = w.out; w.shadows = []; w.schools = [];
  const water = [];
  for (let y = 0; y < m.h; y++) for (let x = 0; x < m.w; x++) if (isWaterT(tileAt(m, x, y))) water.push([x, y]);
  const deep = water.filter(([x, y]) => tileAt(m, x, y) === T.DEEP);
  for (let i = 0; i < tune.fishShadows; i++) {
    const [x, y] = water[Math.floor(rng() * water.length)];
    w.shadows.push({ x: x * TS + 8, y: y * TS + 8, a: rng() * 6.28, sp: 6 + rng() * 10, turn: rng() * 3, size: 0.7 + rng() * 0.7 });
  }
  for (let i = 0; i < tune.schoolCount; i++) w.schools.push(newSchool(deep));
  w.deepTiles = deep;
}
function newSchool(deep) { const [x, y] = deep[Math.floor(rng() * deep.length)]; return { x: x * TS + 8, y: y * TS + 8, life: tune.schoolMoveSeconds * (0.7 + rng() * 0.6), t: 0 }; }
function updateWaterLife(w, dt) {
  const m = w.out;
  for (const s of w.shadows) {
    s.turn -= dt;
    if (s.turn <= 0) { s.a += (rng() - 0.5) * 2.2; s.turn = 1 + rng() * 3; s.sp = 5 + rng() * 12; }
    if (s.flee > 0) s.flee -= dt;
    const sp = s.flee > 0 ? 40 : s.sp;
    const nx = s.x + Math.cos(s.a) * sp * dt, ny = s.y + Math.sin(s.a) * sp * dt;
    if (isWaterAt(m, nx + Math.cos(s.a) * 6, ny + Math.sin(s.a) * 6)) { s.x = nx; s.y = ny; } else { s.a += Math.PI * (0.6 + rng() * 0.8); }
  }
  for (let i = 0; i < w.schools.length; i++) { const s = w.schools[i]; s.t += dt; s.life -= dt; if (s.life <= 0) w.schools[i] = newSchool(w.deepTiles); }
}
function scareShadows(w, x, y) { for (const s of w.shadows) if (Math.hypot(s.x - x, s.y - y) < 30) { s.flee = 0.8; s.a = Math.atan2(s.y - y, s.x - x); } }

// ---------------------------------------------------------------------------------------------
// Rendering: static ground layer cached per map; animation drawn per frame.
function renderGround(m) {
  const c = makeCanvas(m.w * TS, m.h * TS), g = c.getContext('2d');
  for (let ty = 0; ty < m.h; ty++) for (let tx = 0; tx < m.w; tx++) drawTile(g, m, tx, ty);
  m.ground = c;
}
function drawTile(g, m, tx, ty) {
  const t = tileAt(m, tx, ty), x = tx * TS, y = ty * TS;
  const speck = (c1, c2, n, s) => { for (let i = 0; i < n; i++) { const h = hash2(tx * 16 + i, ty * 16 + i * 3, s); const px = (h * 1000 | 0) % 16, py = (h * 7919 | 0) % 16; R(g, x + px, y + py, 1, 1, i % 2 ? c1 : c2); } };
  switch (t) {
    case T.GRASS: case T.FLOWERS:
      R(g, x, y, TS, TS, PAL.grass); speck(PAL.grass2, PAL.grass3, 10, 1);
      if (t === T.FLOWERS) { const cols = ['#f4e46a', '#ffffff', '#f08ab0', '#b08af0']; for (let i = 0; i < 4; i++) { const h = hash2(tx, ty, 20 + i); const px = x + 2 + (h * 1000 | 0) % 12, py = y + 2 + (h * 7777 | 0) % 12; R(g, px, py, 2, 2, cols[(h * 13 | 0) % 4]); R(g, px, py + 2, 1, 1, PAL.grass2); } }
      break;
    case T.DIRT: R(g, x, y, TS, TS, PAL.dirt); speck(PAL.dirt2, PAL.dirt3, 9, 2); edgeBlend(g, m, tx, ty, PAL.grass); break;
    case T.SAND: R(g, x, y, TS, TS, PAL.sand); speck(PAL.sand2, '#ead8a0', 8, 3); break;
    case T.SHALLOW: case T.DEEP: {
      R(g, x, y, TS, TS, t === T.DEEP ? PAL.deep : PAL.shallow);
      if (t === T.DEEP) speck(PAL.deeper, PAL.deeper, 4, 4);
      // wet sand edge where water meets land
      for (const [dx, dy, ex, ey, ew, eh] of [[0, -1, 0, 0, 16, 2], [0, 1, 0, 14, 16, 2], [-1, 0, 0, 0, 2, 16], [1, 0, 14, 0, 2, 16]]) {
        const n = tileAt(m, tx + dx, ty + dy); if (n >= 0 && !isWaterT(n) && n !== T.DOCK && n !== T.BRIDGE) R(g, x + ex, y + ey, ew, eh, '#6ab0c8');
      }
      break;
    }
    case T.DOCK: case T.BRIDGE: {
      const under = PAL.shallow; R(g, x, y, TS, TS, under);
      if (t === T.DOCK) { for (let i = 0; i < 4; i++) { R(g, x, y + i * 4, TS, 3, i % 2 ? PAL.wood : PAL.wood3); R(g, x, y + i * 4 + 3, TS, 1, PAL.wood2); } R(g, x + 1, y + 1, 1, 1, '#3a2a1c'); R(g, x + 14, y + 9, 1, 1, '#3a2a1c'); }
      else { for (let i = 0; i < 4; i++) { R(g, x + i * 4, y + 2, 3, 12, i % 2 ? PAL.wood : PAL.wood3); R(g, x + i * 4 + 3, y + 2, 1, 12, PAL.wood2); } R(g, x, y + 1, TS, 1, PAL.wood2); R(g, x, y + 14, TS, 1, PAL.wood2); }
      break;
    }
    case T.FLOOR: case T.RUG:
      for (let i = 0; i < 4; i++) { R(g, x, y + i * 4, TS, 4, (i + tx) % 2 ? '#b07a48' : '#a06c3e'); R(g, x + ((tx * 7 + i * 5) % 16), y + i * 4, 1, 4, '#7a4e2a'); }
      if (t === T.RUG) { R(g, x, y, TS, TS, '#9a3a3a'); R(g, x + 2, y + 2, 12, 12, '#b85048'); if ((tx + ty) % 2) R(g, x + 6, y + 6, 4, 4, '#e8c070'); }
      break;
    case T.WALL:
      if (ty <= 1) { R(g, x, y, TS, TS, ty === 0 ? '#5a3a24' : '#7a5232'); for (let i = 0; i < 2; i++) R(g, x, y + i * 8 + 7, TS, 1, '#4a2e1a'); if (ty === 1) R(g, x, y + 14, TS, 2, '#3a2416'); }
      else R(g, x, y, TS, TS, '#3a2416');
      break;
  }
}
function edgeBlend(g, m, tx, ty, col) {
  const x = tx * TS, y = ty * TS;
  for (const [dx, dy] of [[0, -1], [0, 1], [-1, 0], [1, 0]]) {
    const n = tileAt(m, tx + dx, ty + dy);
    if (n === T.GRASS || n === T.FLOWERS) for (let i = 0; i < 16; i += 2) { const h = hash2(tx * 31 + i, ty * 17 + dx * 3 + dy, 9) > 0.5 ? 1 : 0; if (dy === -1) R(g, x + i, y, 2, 1 + h, col); if (dy === 1) R(g, x + i, y + 15 - h, 2, 1 + h, col); if (dx === -1) R(g, x, y + i, 1 + h, 2, col); if (dx === 1) R(g, x + 15 - h, y + i, 1 + h, 2, col); }
  }
}
/** Animated water: wave glints and shore foam on visible water tiles. */
function drawWaterAnim(g, m, cx, cy, vw, vh, t) {
  const x0 = Math.max(0, Math.floor(cx / TS)), y0 = Math.max(0, Math.floor(cy / TS));
  const x1 = Math.min(m.w - 1, Math.floor((cx + vw) / TS)), y1 = Math.min(m.h - 1, Math.floor((cy + vh) / TS));
  for (let ty = y0; ty <= y1; ty++) for (let tx = x0; tx <= x1; tx++) {
    const tt = tileAt(m, tx, ty); if (!isWaterT(tt)) continue;
    const x = tx * TS - cx, y = ty * TS - cy, h = hash2(tx, ty, 6);
    const ph = (t * 0.6 + h) % 1;
    const wx = Math.floor((h * 9 + t * 5) % 12), wy = Math.floor(h * 13) % 12 + 2;
    if (ph < 0.65) { R(g, x + wx, y + wy, 3, 1, PAL.wave); R(g, x + wx + 1, y + wy - 1, 2, 1, tt === T.DEEP ? '#4a8ec0' : '#9ad6f0'); }
    const h2 = hash2(tx, ty, 8), ph2 = (t * 0.45 + h2) % 1;
    if (ph2 < 0.4) R(g, x + (h2 * 113 | 0) % 13, y + (h2 * 57 | 0) % 14, 2, 1, PAL.wave);
    // foam
    for (const [dx, dy] of [[0, -1], [0, 1], [-1, 0], [1, 0]]) {
      const n = tileAt(m, tx + dx, ty + dy); if (n < 0 || isWaterT(n) || n === T.DOCK || n === T.BRIDGE) continue;
      for (let i = 0; i < 16; i += 3) {
        const on = Math.sin(t * 2.2 + i * 0.7 + tx * 1.3 + ty) > 0.1; if (!on) continue;
        const o = Math.sin(t * 1.6 + i) > 0.5 ? 1 : 0;
        if (dy === -1) R(g, x + i, y + 2 + o, 2, 1, PAL.foam); if (dy === 1) R(g, x + i, y + 13 - o, 2, 1, PAL.foam);
        if (dx === -1) R(g, x + 2 + o, y + i, 1, 2, PAL.foam); if (dx === 1) R(g, x + 13 - o, y + i, 1, 2, PAL.foam);
      }
    }
  }
}
function drawDecor(g, d, cx, cy, t) {
  const x = Math.round(d.x - cx), y = Math.round(d.y - cy);
  const sway = Math.round(Math.sin(t * 1.8 + d.ph) * 1.2);
  if (d.kind === 'tuft') { R(g, x, y, 1, 3, PAL.grass2); R(g, x + 2 + sway, y - 1, 1, 4, PAL.grass3); R(g, x + 4, y + 1, 1, 2, PAL.grass2); R(g, x + 2, y + 2, 1, 1, PAL.grass2); }
  else if (d.kind === 'reed') {
    for (let i = 0; i < 3; i++) { const s = Math.round(Math.sin(t * 1.5 + d.ph + i) * 1.4); R(g, x + i * 2 + s, y - 10 + i, 1, 10 - i, '#4a7a2a'); if (i !== 1) R(g, x + i * 2 + s, y - 13 + i, 2, 4, '#7a4a22'); }
    R(g, x - 1, y, 7, 1, '#2f6e8f');
  } else if (d.kind === 'lily') {
    const bob = Math.sin(t * 1.2 + d.ph) > 0.6 ? 1 : 0;
    R(g, x - 3, y - 2 + bob, 7, 4, '#4a9a3a'); R(g, x - 2, y - 3 + bob, 5, 6, '#4a9a3a'); R(g, x, y - 1 + bob, 3, 1, '#2f6e2e'); R(g, x - 2, y + bob, 1, 1, '#6ac04a');
    if (d.flower) { R(g, x - 1, y - 2 + bob, 3, 2, '#f8d0e0'); R(g, x, y - 2 + bob, 1, 1, '#f0e060'); }
  }
}
function drawProp(g, p, cx, cy, t, night) {
  const x = Math.round(p.x - cx), y = Math.round(p.y - cy);
  switch (p.kind) {
    case 'tree': {
      R(g, x - 2, y - 8, 4, 8, PAL.trunk); R(g, x - 1, y - 8, 1, 8, '#8a5a32'); g.fillStyle = 'rgba(0,0,0,0.22)'; g.fillRect(x - 7, y - 1, 14, 3);
      const s = Math.round(Math.sin(t * 1.1 + p.ph) * 0.8);
      const blob = (bx, by, r, c) => { for (let yy = -r; yy <= r; yy++) { const w = Math.round(Math.sqrt(r * r - yy * yy)); R(g, x + bx - w + s, y + by + yy, w * 2, 1, c); } };
      blob(0, -16, 9, PAL.outline); blob(0, -16, 8, PAL.leaf2); blob(-2, -18, 6, PAL.leaf); blob(-3, -20, 3, PAL.leaf3);
      R(g, x + 3 + s, y - 13, 2, 2, PAL.leaf2); R(g, x - 5 + s, y - 12, 2, 1, '#26582a');
      break;
    }
    case 'pine': {
      R(g, x - 1, y - 5, 3, 5, PAL.trunk); g.fillStyle = 'rgba(0,0,0,0.22)'; g.fillRect(x - 6, y - 1, 12, 3);
      const s = Math.round(Math.sin(t * 1.1 + p.ph) * 0.6);
      for (let i = 0; i < 3; i++) { const top = y - 26 + i * 6, w = 4 + i * 3; for (let yy = 0; yy < 9; yy++) { const ww = Math.round(w * yy / 8) + 1; R(g, x - ww + s, top + yy, ww * 2 + 1, 1, yy === 8 ? PAL.outline : (yy < 3 ? '#3a8a5a' : PAL.pine)); } }
      R(g, x - 1 + s, y - 27, 2, 2, PAL.outline);
      break;
    }
    case 'bush': {
      const s = Math.round(Math.sin(t * 1.6 + p.ph) * 0.7);
      g.fillStyle = 'rgba(0,0,0,0.2)'; g.fillRect(x - 6, y - 1, 12, 2);
      R(g, x - 7 + s, y - 8, 14, 8, PAL.outline); R(g, x - 6 + s, y - 9, 12, 8, PAL.leaf2); R(g, x - 4 + s, y - 10, 7, 4, PAL.leaf); R(g, x - 3 + s, y - 8, 2, 2, '#d84a4a'); R(g, x + 2 + s, y - 6, 2, 2, '#d84a4a');
      break;
    }
    case 'rock': R(g, x - 6, y - 7, 12, 7, PAL.outline); R(g, x - 5, y - 8, 10, 7, PAL.rock2); R(g, x - 4, y - 8, 6, 3, PAL.rock); R(g, x - 3, y - 8, 2, 1, '#b0b4bc'); break;
    case 'sign': R(g, x - 1, y - 8, 2, 8, PAL.wood2); R(g, x - 7, y - 16, 14, 9, PAL.outline); R(g, x - 6, y - 15, 12, 7, PAL.wood3); R(g, x - 3, y - 12, 6, 2, '#5aa8ff'); R(g, x + 3, y - 13, 2, 4, '#5aa8ff'); break;
    case 'lantern': {
      R(g, x - 1, y - 18, 2, 18, PAL.wood2); R(g, x - 3, y - 22, 6, 5, PAL.outline);
      R(g, x - 2, y - 21, 4, 3, night ? '#ffe08a' : '#c8b070');
      break;
    }
    case 'house': {
      const w = 5 * TS;
      // walls
      R(g, x, y + 24, w, 40, PAL.outline); R(g, x + 1, y + 25, w - 2, 38, PAL.wood);
      for (let i = 0; i < 9; i++) R(g, x + 1, y + 28 + i * 4, w - 2, 1, PAL.wood2);
      // roof
      for (let i = 0; i < 28; i++) { const inset = Math.max(0, 10 - i); R(g, x - 4 + inset, y + i, w + 8 - inset * 2, 1, i % 4 === 3 ? PAL.roof2 : PAL.roof); }
      R(g, x - 4, y + 27, w + 8, 2, PAL.outline);
      // chimney
      R(g, x + 58, y - 6, 8, 12, '#7a7a82'); R(g, x + 57, y - 7, 10, 2, '#5a5a62');
      const sm = (t * 8) % 12; R(g, x + 60 + Math.round(Math.sin(t * 2) * 2), y - 10 - sm, 3, 3, 'rgba(220,220,220,0.6)');
      // windows
      for (const wx of [x + 8, x + 58]) { R(g, wx, y + 36, 14, 11, PAL.outline); R(g, wx + 1, y + 37, 12, 9, night ? '#ffd870' : '#8ac8e8'); R(g, wx + 6, y + 37, 1, 9, PAL.outline); R(g, wx + 1, y + 41, 12, 1, PAL.outline); R(g, wx - 1, y + 47, 16, 2, PAL.wood2); }
      // door
      R(g, x + 31, y + 40, 18, 24, PAL.outline); R(g, x + 32, y + 41, 16, 23, '#5a3420'); R(g, x + 33, y + 42, 6, 21, '#6e4428'); R(g, x + 44, y + 52, 2, 2, '#ffc93c');
      // fish sign above door
      R(g, x + 30, y + 30, 20, 8, PAL.outline); R(g, x + 31, y + 31, 18, 6, PAL.cream); R(g, x + 34, y + 33, 9, 3, '#3f86b3'); R(g, x + 43, y + 32, 3, 5, '#3f86b3'); R(g, x + 41, y + 33, 1, 1, PAL.outline);
      break;
    }
    case 'counter': {
      const w = 6 * TS;
      R(g, x, y + 2, w, 14, PAL.outline); R(g, x + 1, y + 3, w - 2, 4, PAL.wood3); R(g, x + 1, y + 7, w - 2, 8, PAL.wood);
      for (let i = 0; i < 6; i++) R(g, x + 8 + i * 16, y + 8, 1, 6, PAL.wood2);
      // goods on counter
      R(g, x + 10, y - 2, 8, 5, '#c8a45a'); R(g, x + 11, y - 3, 6, 1, '#e8c070');
      R(g, x + 70, y - 3, 6, 6, '#5aa8ff'); R(g, x + 71, y - 4, 4, 1, '#e8e8e8');
      break;
    }
    case 'keeper': drawPerson(g, x, y, 0, 'idle', t * 0.3, LOOK_KEEPER); break;
    case 'barrel': R(g, x - 6, y - 14, 12, 14, PAL.outline); R(g, x - 5, y - 13, 10, 12, PAL.wood); R(g, x - 5, y - 10, 10, 1, '#5a5a62'); R(g, x - 5, y - 5, 10, 1, '#5a5a62'); R(g, x - 4, y - 13, 8, 2, PAL.wood3); break;
    case 'plant': R(g, x - 4, y - 6, 8, 6, '#a0522d'); for (let i = 0; i < 5; i++) R(g, x - 5 + i * 2 + Math.round(Math.sin(t + i) * 0.6), y - 14 + (i % 2) * 2, 2, 8, i % 2 ? PAL.leaf : PAL.leaf3); break;
    case 'bed': R(g, x + 1, y + 1, 14, 28, PAL.outline); R(g, x + 2, y + 2, 12, 26, '#3a6aa8'); R(g, x + 2, y + 2, 12, 7, '#f0ece0'); R(g, x + 2, y + 12, 12, 1, '#2a4e80'); break;
  }
}
/** The walls of the house interior: shelves, mounted fish, window. */
function drawInteriorWalls(g, cx, cy, night, t) {
  const ox = -cx, oy = -cy;
  // window
  R(g, ox + 150, oy + 6, 22, 16, PAL.outline); R(g, ox + 151, oy + 7, 20, 14, night ? '#1a2a5a' : '#8ac8e8'); R(g, ox + 160, oy + 7, 1, 14, PAL.outline); R(g, ox + 151, oy + 13, 20, 1, PAL.outline);
  if (night) { R(g, ox + 165, oy + 9, 2, 2, '#f0f0d0'); }
  // shelf with rods
  R(g, ox + 20, oy + 22, 40, 2, PAL.wood2);
  for (let i = 0; i < 5; i++) { g.strokeStyle = DATA.rods[i].col; g.beginPath(); g.moveTo(ox + 24 + i * 8 + 0.5, oy + 22); g.lineTo(ox + 24 + i * 8 + 0.5, oy + 4); g.stroke(); }
  // mounted fish trophy
  const koi = FISH_ART.koi; if (koi) { R(g, ox + 80, oy + 6, 30, 16, PAL.wood2); R(g, ox + 81, oy + 7, 28, 14, PAL.wood3); g.drawImage(koi.img, 0, 0, 40, 24, ox + 82, oy + 8, 26, 15); }
  // lamp
  R(g, ox + 95, oy + 24, 2, 4, '#3a2a1c'); R(g, ox + 92, oy + 28, 8, 4, '#ffd870');
}
