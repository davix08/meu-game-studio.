// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Energy system: casting and running spend it; resting and snacks restore it.
'use strict';
function updateEnergy(s, dt) {
  if (s.resting) {
    s.energy = Math.min(100, s.energy + tune.restRegen * dt);
    if (s.energy >= 100) { s.resting = false; toast('Energia cheia!'); }
  }
}
function toggleRest(s) {
  if (s.resting) { s.resting = false; return; }
  if (s.fishing.st !== 'idle') { toast('Termine a pescaria antes de descansar.'); return; }
  if (s.energy >= 100) { toast('A energia já está cheia.'); return; }
  s.resting = true; s.player.path = null; sfx.click();
}
