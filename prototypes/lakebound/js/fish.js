// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Fish system: which species bites, how heavy it is, what it is worth.
'use strict';

const RARITY_W = ['wCommon', 'wUncommon', 'wRare', 'wEpic', 'wLegendary'];
const SPECIES = {}; for (const s of DATA.species) SPECIES[s.id] = s;

/** Highest rarity the player's level allows (level 1 -> 0 Comum ... level 5+ -> 4 Lendário). */
function maxRarity(level) { return Math.min(level - 1, 4); }
function isNight(minutes) { const h = (minutes / 60) % 24; return h >= 18 || h < 6; }

/**
 * Picks the species that bites. ctx: { level, bait, luck, deep, school, minutes, book }.
 * Rarer fish weigh less; bait, luck, deep water and schools tilt the odds upward.
 */
function rollSpecies(ctx) {
  if (!Object.keys(ctx.book).length) return SPECIES.sardinha; // the first catch is the easy Sardinha (First minute)
  const night = isNight(ctx.minutes), top = maxRarity(ctx.level);
  const avail = r => DATA.species.filter(s => s.r === r && (s.time === 'any' || (s.time === 'night') === night));
  const rw = [];
  for (let r = 0; r <= top; r++) {
    if (!avail(r).length) { rw.push(0); continue; }
    let w = tune[RARITY_W[r]] * (1 + ctx.bait.rare * r);
    if (ctx.luck && r >= 2) w *= tune.luckMult;
    if (ctx.deep) w *= 1 + tune.deepBonus * r;
    if (ctx.school) w *= 1 + tune.spotBonus * r;
    rw.push(w);
  }
  let r = pickWeighted(rw);
  const list = avail(r);
  const sw = list.map(s => (ctx.book[s.id] ? 1 : tune.newBias));
  return list[pickWeighted(sw)];
}
function pickWeighted(ws) {
  const tot = ws.reduce((a, b) => a + b, 0); let x = rng() * tot;
  for (let i = 0; i < ws.length; i++) { x -= ws[i]; if (x < 0) return i; }
  return ws.length - 1;
}
/** Rolls a weight (heavier is rarer) and the sale value that follows from it. */
function rollCatch(sp) {
  const f = Math.pow(rng(), tune.weightSkew);
  const w = sp.kg[0] + (sp.kg[1] - sp.kg[0]) * f;
  return { id: sp.id, w: Math.round(w * 100) / 100, v: fishValue(sp, w) };
}
function fishValue(sp, w) { const f = (w - sp.kg[0]) / (sp.kg[1] - sp.kg[0] || 1); return Math.max(1, Math.round(sp.v * (0.7 + 0.6 * f))); }
function fmtKg(w) { return w >= 100 ? `${Math.round(w)} kg` : w >= 1 ? `${w.toFixed(1)} kg` : `${Math.round(w * 1000)} g`; }
