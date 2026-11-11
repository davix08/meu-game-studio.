// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Level system: discovering species raises the level; each level opens a rarity.
'use strict';
function levelNeed(l) { return tune['need' + l]; }
/** Levels up as species are discovered; each level opens a rarity, shop items and a reward. */
function checkLevelUp(s) {
  while (s.level < 6 && discovered(s) >= levelNeed(s.level + 1)) {
    s.level++;
    const reward = tune['reward' + s.level];
    s.coins += reward;
    const r = Math.min(s.level - 1, 4);
    queuePanel('levelup', {
      level: s.level, reward,
      species: s.level <= 5 ? DATA.species.filter(x => x.r === r) : [],
      items: [...DATA.rods, ...DATA.baits, ...DATA.items].filter(x => x.level === s.level),
    });
  }
}
