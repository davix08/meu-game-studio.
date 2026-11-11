// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Fishing system: cast -> wait (nibbles) -> bite (react) -> fight on the bar -> caught or escaped.
'use strict';

function newFishing() { return { st: 'idle', t: 0 }; }
const rodOf = s => DATA.rods.find(r => r.id === s.rod);
const baitOf = s => DATA.baits.find(b => b.id === s.bait);

/** Why a cast is not possible right now, or '' when it is. */
function castBlocker(s) {
  if (s.map !== 'out') return 'Não dá para pescar aqui dentro.';
  if (s.fishing.st !== 'idle') return 'busy';
  if (s.bag.length >= tune.bagSize) return 'Bolsa cheia! Venda os peixes na loja.';
  if (s.energy < tune.castCost) return 'Sem energia! Descanse (ZZZ) ou coma um lanche.';
  return '';
}
/** Casts at a water point within the rod's range; returns true when it cast. */
function castAt(s, wx, wy) {
  const why = castBlocker(s);
  if (why) { if (why !== 'busy') toast(why); return false; }
  const P = s.player, fx = P.x, fy = P.y - 8;
  const dist = Math.hypot(wx - fx, wy - fy);
  if (dist > rodOf(s).range) return false;
  if (!isWaterAt(world.out, wx, wy)) return false;
  P.path = null; s.resting = false;
  P.dir = Math.abs(wx - fx) > Math.abs(wy - fy) ? (wx > fx ? 3 : 2) : (wy > fy ? 0 : 1);
  s.energy = Math.max(0, s.energy - tune.castCost);
  const F = s.fishing;
  F.st = 'cast'; F.t = 0; F.tx = wx; F.ty = wy; F.bx = fx; F.by = fy - 10;
  sfx.cast();
  return true;
}
/** Keyboard cast: the farthest water point along the facing direction within range. */
function castForward(s) {
  const P = s.player, d = [[0, 1], [0, -1], [-1, 0], [1, 0]][P.dir];
  const range = rodOf(s).range;
  let best = null;
  for (let k = 12; k <= range; k += 4) { const x = P.x + d[0] * k, y = P.y - 8 + d[1] * k; if (isWaterAt(world.out, x, y)) best = [x, y]; }
  if (!best) { const why = castBlocker(s); toast(why && why !== 'busy' ? why : 'Vire-se para a água para lançar.'); return false; }
  return castAt(s, best[0], best[1]);
}
function cancelFishing(s, msg) {
  const F = s.fishing;
  if (F.st === 'idle') return;
  if (msg) toast(msg);
  s.fishing = newFishing();
}
function inSchool(x, y) { return world.schools.some(sc => Math.hypot(sc.x - x, sc.y - y) < tune.spotRadius); }

/** One fixed step of the fishing state machine. hold: PUXAR held; press: PUXAR went down this step. */
function updateFishing(s, dt, hold, press) {
  const F = s.fishing; F.t += dt;
  switch (F.st) {
    case 'cast': {
      const k = Math.min(1, F.t / tune.castTime);
      F.bobX = F.bx + (F.tx - F.bx) * k; F.bobY = F.by + (F.ty - F.by) * k - Math.sin(Math.PI * k) * 26;
      if (k >= 1) {
        F.st = 'wait'; F.t = 0; F.bobX = F.tx; F.bobY = F.ty;
        F.school = inSchool(F.tx, F.ty);
        F.deep = tileAt(world.out, Math.floor(F.tx / TS), Math.floor(F.ty / TS)) === T.DEEP;
        const base = tune.waitMin + rng() * (tune.waitMax - tune.waitMin);
        F.wait = base * baitOf(s).wait * (F.school ? tune.spotWait : 1);
        F.nibbleAt = F.wait * (0.35 + rng() * 0.3); F.nib = 0;
        splash(F.tx, F.ty, 8, '#d8f0ff'); ripple(F.tx, F.ty); scareShadows(world, F.tx, F.ty); sfx.splash();
      }
      break;
    }
    case 'wait': {
      if (press) { cancelFishing(s, 'Puxou cedo demais: linha recolhida.'); sfx.reel(); return; }
      if (F.t > F.nibbleAt && F.nib <= 0 && F.t < F.wait - 0.6) { F.nib = 0.25; F.nibbleAt = F.t + 0.6 + rng() * 1.2; ripple(F.bobX, F.bobY); sfx.nibble(); }
      if (F.nib > 0) F.nib -= dt;
      if (F.t >= F.wait) {
        const sp = rollSpecies({ level: s.level, bait: baitOf(s), luck: s.luckLeft > 0, deep: F.deep, school: F.school, minutes: s.minutes, book: s.book });
        F.sp = sp; F.st = 'bite'; F.t = 0;
        F.react = tune.reactWindow - sp.d * tune.reactHard;
        splash(F.bobX, F.bobY, 10, '#ffffff'); ripple(F.bobX, F.bobY); sfx.bite();
      }
      break;
    }
    case 'bite': {
      if (press || hold) { startFight(s); return; }
      if (F.t >= F.react) { cancelFishing(s, 'O peixe escapou! Seja mais rápido no PUXAR.'); sfx.escape(); }
      break;
    }
    case 'fight': fightStep(s, dt, hold); break;
    case 'caught': {
      if (F.t >= 1.1) { finishCatch(s); }
      break;
    }
  }
}
function startFight(s) {
  const F = s.fishing, rod = rodOf(s), d = F.sp.d;
  F.st = 'fight'; F.t = 0;
  F.zoneW = Math.max(tune.zoneMin, tune.zoneBase + rod.zone - d * tune.zoneShrink);
  F.zone = 0.5; F.zoneTo = 0.5; F.zoneTimer = 0.4;
  F.pos = 0.3; F.vel = 0;
  F.progress = tune.progressStart;
  F.inZone = false; F.tick = 0;
  sfx.hook();
}
/** The fight on the bar: the zone wanders (and darts, for hard fish); PUXAR pushes the indicator. */
function fightStep(s, dt, hold) {
  const F = s.fishing, d = F.sp.d, rod = rodOf(s);
  // indicator physics
  F.vel += (hold ? tune.pullAccel : -tune.fallAccel) * dt;
  F.vel = Math.max(-tune.maxVel, Math.min(tune.maxVel, F.vel));
  F.pos += F.vel * dt;
  if (F.pos < 0) { F.pos = 0; F.vel = Math.abs(F.vel) * 0.25; }
  if (F.pos > 1) { F.pos = 1; F.vel = -Math.abs(F.vel) * 0.25; }
  // zone movement
  F.zoneTimer -= dt;
  const half = F.zoneW / 2;
  if (F.zoneTimer <= 0) { F.zoneTo = half + rng() * (1 - F.zoneW); F.zoneTimer = (1.6 - d * 1.1) * (0.5 + rng()); }
  if (rng() < tune.dartChance * d * d * dt) { F.zoneTo = half + rng() * (1 - F.zoneW); F.dart = 0.25; }
  const sp = (tune.zoneSpeed + tune.zoneSpeedHard * d) * (F.dart > 0 ? 3 : 1);
  if (F.dart > 0) F.dart -= dt;
  const dz = F.zoneTo - F.zone; F.zone += Math.sign(dz) * Math.min(Math.abs(dz), sp * dt);
  // progress
  F.inZone = Math.abs(F.pos - F.zone) <= half;
  if (F.inZone) F.progress += tune.progressGain * rod.power * (1 - d * 0.4) * dt;
  else F.progress -= (tune.progressLoss + tune.progressLossHard * d) * dt;
  F.tick += dt; if (F.inZone && F.tick > 0.12) { F.tick = 0; sfx.reelTick(F.progress); }
  if (F.progress >= 1) {
    F.st = 'caught'; F.t = 0; F.catch = rollCatch(F.sp);
    splash(F.bobX, F.bobY, 16, '#ffffff'); sfx.catch();
  } else if (F.progress <= 0) {
    cancelFishing(s, 'A linha afrouxou e o peixe escapou!'); sfx.escape(); splash(F.bobX, F.bobY, 6, '#d8f0ff');
  }
}
/** The fish goes into the bag and the book; the catch card opens. */
function finishCatch(s) {
  const F = s.fishing, c = F.catch, sp = F.sp;
  s.bag.push(c);
  const prev = s.book[sp.id];
  const isNew = !prev;
  const record = prev && c.w > prev.best;
  s.book[sp.id] = { n: (prev ? prev.n : 0) + 1, best: Math.max(prev ? prev.best : 0, c.w) };
  s.stats.caught++;
  s.player.catchT = 1.6; s.player.catchId = sp.id;
  s.fishing = newFishing();
  openPanel('catch', { c, sp, isNew, record });
  checkLevelUp(s);
  saveGame(s);
}
