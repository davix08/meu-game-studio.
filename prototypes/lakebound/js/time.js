// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Time system: the clock, the four periods, day and night light, the automatic sleep.
'use strict';
const PERIODS = [[0, 'Madrugada'], [6, 'Manhã'], [12, 'Tarde'], [18, 'Noite']];
function periodName(min) { const h = (min / 60) % 24; let n = 'Madrugada'; for (const [a, name] of PERIODS) if (h >= a) n = name; return n; }
function clockText(min) { const h = Math.floor(min / 60) % 24, m = Math.floor(min % 60); return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`; }
function updateTime(s, dt) {
  const mult = s.resting ? tune.restTimeMult : 1;
  const dm = tune.minutesPerSecond * dt * mult;
  s.minutes += dm;
  if (s.luckLeft > 0) s.luckLeft = Math.max(0, s.luckLeft - dm);
  if (s.minutes >= tune.dayEnd) sleepNewDay(s, true);
}
/** Ends the day: next morning, full energy. */
function sleepNewDay(s, auto) {
  s.day++; s.minutes = tune.dayStart; s.energy = 100; s.resting = false;
  s.fishing = newFishing(); s.player.path = null;
  if (s.map === 'out') { s.player.x = OUT.spawn.x; s.player.y = OUT.spawn.y; s.player.dir = 0; }
  openPanel('sleep', { auto, day: s.day });
  saveGame(s);
}
/** Darkness (0..1) and tint for the hour. */
function lightAt(min) {
  const h = (min / 60) % 24 + (min >= 1440 ? 0 : 0);
  const hh = min >= 1440 ? 24 + ((min - 1440) / 60) : h;
  let dark = 0, tint = null;
  if (hh < 6) dark = 0.62;
  else if (hh < 7) { dark = 0.3 * (7 - hh); tint = ['255,170,140', 0.12 * (7 - hh)]; }
  else if (hh < 16.5) dark = 0;
  else if (hh < 18.5) { tint = ['255,140,60', 0.16 * (hh - 16.5) / 2]; }
  else if (hh < 20) { dark = 0.5 * (hh - 18.5) / 1.5; tint = ['255,120,60', 0.16 * (20 - hh) / 1.5]; }
  else if (hh < 24) dark = 0.5 + 0.08 * (hh - 20) / 4;
  else dark = 0.6;
  return { dark, tint };
}
