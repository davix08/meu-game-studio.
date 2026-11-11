// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Every tuning value lives here, each with value, min, max and step. The game reads them live
// through tune.<name> (index.html); the tweak panel, an add-on, writes them back here.
// Species, rods, baits and items (tables, not single knobs) live in data.js.
window.CONFIG = {
  seed: 1, // every gameplay random call reads rng(), seeded from this (or ?seed= in the address)
  volume: { value: 0.5, min: 0, max: 1, step: 0.05 },

  // --- Movement (world pixels per second; a tile is 16 px) ---
  walkSpeed: { value: 52, min: 20, max: 120, step: 2 },
  runSpeed: { value: 88, min: 40, max: 180, step: 2 },
  runDrain: { value: 0.5, min: 0, max: 5, step: 0.1 },        // energy per second while running
  autoRunTiles: { value: 7, min: 2, max: 30, step: 1 },       // a tap path longer than this runs

  // --- Time (game minutes) ---
  minutesPerSecond: { value: 2, min: 0.5, max: 20, step: 0.5 }, // 2 = one game hour every 30 s
  dayStart: { value: 360, min: 240, max: 600, step: 10 },       // 06:00
  dayEnd: { value: 1560, min: 1200, max: 1680, step: 10 },      // 02:00 next morning: auto sleep

  // --- Energy (0-100) ---
  castCost: { value: 6, min: 0, max: 30, step: 1 },
  restRegen: { value: 7, min: 1, max: 50, step: 1 },           // energy per second while resting
  restTimeMult: { value: 5, min: 1, max: 20, step: 1 },        // time runs this much faster while resting
  snackEnergy: { value: 40, min: 5, max: 100, step: 5 },

  // --- Fishing: the wait ---
  castTime: { value: 0.55, min: 0.2, max: 2, step: 0.05 },     // seconds the bobber flies
  waitMin: { value: 2.5, min: 0.5, max: 20, step: 0.5 },       // seconds before a bite, before bait
  waitMax: { value: 7, min: 1, max: 30, step: 0.5 },
  reactWindow: { value: 1.4, min: 0.4, max: 4, step: 0.1 },    // seconds to press PUXAR after the bite
  reactHard: { value: 0.55, min: 0, max: 1.5, step: 0.05 },    // window shrinks this much at difficulty 1

  // --- Fishing: the fight (bar is 0..1) ---
  pullAccel: { value: 3.2, min: 0.5, max: 10, step: 0.1 },     // holding PUXAR pushes the indicator
  fallAccel: { value: 2.6, min: 0.5, max: 10, step: 0.1 },     // releasing lets it fall back
  maxVel: { value: 1.3, min: 0.3, max: 4, step: 0.1 },
  zoneBase: { value: 0.30, min: 0.08, max: 0.8, step: 0.01 },  // green zone width with the bamboo rod
  zoneShrink: { value: 0.15, min: 0, max: 0.4, step: 0.01 },   // narrower by this at difficulty 1
  zoneMin: { value: 0.08, min: 0.03, max: 0.3, step: 0.01 },
  zoneSpeed: { value: 0.18, min: 0, max: 2, step: 0.02 },      // zone drift at difficulty 0 (bar per s)
  zoneSpeedHard: { value: 0.85, min: 0, max: 3, step: 0.05 },  // extra drift at difficulty 1
  dartChance: { value: 0.75, min: 0, max: 3, step: 0.05 },     // sudden darts per second at difficulty 1
  progressStart: { value: 0.28, min: 0.05, max: 0.9, step: 0.01 },
  progressGain: { value: 0.30, min: 0.05, max: 1.5, step: 0.01 }, // per second inside the zone
  progressLoss: { value: 0.20, min: 0.02, max: 1.5, step: 0.01 }, // per second outside, at difficulty 0
  progressLossHard: { value: 0.22, min: 0, max: 1.5, step: 0.01 }, // extra loss at difficulty 1

  // --- Fish odds (relative weight per rarity) ---
  wCommon: { value: 60, min: 0, max: 100, step: 1 },
  wUncommon: { value: 26, min: 0, max: 100, step: 1 },
  wRare: { value: 10, min: 0, max: 100, step: 0.5 },
  wEpic: { value: 3.4, min: 0, max: 50, step: 0.1 },
  wLegendary: { value: 0.9, min: 0, max: 20, step: 0.1 },
  deepBonus: { value: 0.3, min: 0, max: 2, step: 0.05 },       // per rarity step, cast into deep water
  spotBonus: { value: 0.35, min: 0, max: 2, step: 0.05 },      // per rarity step, cast on a bubbling school
  spotWait: { value: 0.6, min: 0.1, max: 1, step: 0.05 },      // wait multiplier on a school
  spotRadius: { value: 22, min: 6, max: 60, step: 1 },         // world px
  newBias: { value: 2, min: 1, max: 10, step: 0.5 },           // an undiscovered species weighs this much more
  luckMult: { value: 2.5, min: 1, max: 10, step: 0.1 },        // luck bait: rare and above weigh this much more
  luckMinutes: { value: 120, min: 10, max: 600, step: 10 },    // game minutes a luck bait lasts
  weightSkew: { value: 1.8, min: 1, max: 4, step: 0.1 },       // >1 makes heavy fish rarer

  // --- Economy and levels ---
  bagSize: { value: 20, min: 5, max: 60, step: 1 },
  startCoins: { value: 30, min: 0, max: 5000, step: 10 },
  need2: { value: 5, min: 1, max: 35, step: 1 },     // species discovered to reach Pescador
  need3: { value: 12, min: 1, max: 35, step: 1 },    // Veterano
  need4: { value: 19, min: 1, max: 35, step: 1 },    // Mestre
  need5: { value: 25, min: 1, max: 35, step: 1 },    // Lenda
  need6: { value: 35, min: 1, max: 35, step: 1 },    // Lenda do Lago: the full book
  reward2: { value: 100, min: 0, max: 20000, step: 50 },
  reward3: { value: 300, min: 0, max: 20000, step: 50 },
  reward4: { value: 900, min: 0, max: 20000, step: 50 },
  reward5: { value: 2500, min: 0, max: 50000, step: 100 },
  reward6: { value: 8000, min: 0, max: 50000, step: 100 },

  // --- World ---
  fishShadows: { value: 16, min: 0, max: 60, step: 1 },
  schoolCount: { value: 3, min: 0, max: 8, step: 1 },
  schoolMoveSeconds: { value: 75, min: 10, max: 600, step: 5 }, // a school moves on after this
  autosaveSeconds: { value: 10, min: 2, max: 120, step: 1 },
};
