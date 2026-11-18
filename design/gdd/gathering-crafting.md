# Gathering and Crafting (the first rod)

> Status: Approved (autonomous session, 2026-11-18, under the user's "take the
> recommended decisions" instruction) · Source: TXT §9, §10, Etapa 2; `design/game-brief.md`
> Build order step 3 · Code: `src/core/gathering.gd`, `src/world/gather_view.gd`,
> `Screens.open_bench`

## 1. Overview
A new game starts **without a rod**. Around the house and the dock there are glowing
spots to gather: **galhos** (branches), **fibras vegetais** (plant fibers) and
**minhocas** (worms). At the **bench** by the dock (the bench already in the base
scenery), the player turns these materials into an improvised line, the **artisan rod**
and the worm bait. Gathered spots come back after a while.

## 2. Player Fantasy
"I made my own rod." The first few minutes are a small survival goal with a clear
end: look around, pick things up, build, cast. Then the artisan rod is good enough to
start with and weak enough that buying the bamboo rod feels like a real step up.

## 3. Detailed Rules
1. New game: `rod = ""`, `rods_owned = []`. Pressing LANÇAR shows "Você ainda não tem
   vara…" (`CastResult.NO_ROD`). The on-screen hint says to gather and build.
2. Walking within `door_reach` of an available spot shows the context button
   "Coletar <material>". Pressing it adds `amount[kind]` of the material, plays a sound,
   shows a "+N <material>" toast, and hides the spot.
3. A gathered spot comes back once `respawn_minutes[kind]` game minutes have passed,
   counted across days (`GameState.total_minutes()`).
4. The bench context button ("Bancada") opens the bench screen: materials on hand, then
   each recipe with what it needs (and how many you have) and a button: Fazer, Falta
   material or Já tem.
5. Recipes (`recipes.json`):
   - Linha improvisada: 2 fibras → 1 linha.
   - Vara artesanal: 1 galho + 3 fibras + 1 linha → artisan rod, owned and **equipped**.
   - Isca de minhoca: 4 minhocas → the "Minhoca gorda" bait, owned and **equipped**.
6. A rod or bait recipe can be made once (Já tem afterwards). Material recipes can be
   repeated.
7. The artisan rod (`craft_only`) is never sold in the shop. It only appears in the
   shop's rod tab once owned, so the player can re-equip it. The bamboo rod now costs
   60 coins and is the first purchase.
8. With no rod, the character holds nothing. Crafting the rod shows it in hand right away.
9. Materials and spot timers are saved. Saves from before this change keep their rod.

## 4. Formulas
- Spot back at: `back = total_minutes_at_gather + respawn_minutes[kind]`, where
  `total_minutes = (day − 1) · 1440 + minutes`.
- Materials needed for the first rod: galho 1, fibra 3 + 2 (for the line) = **5 fibras**.
  With 4 fiber spots × 2 per gather and 3 branch spots × 1, one sweep of the area gives
  8 fibras and 3 galhos. That covers the rod in one pass, with leftovers.
- Time to the first rod: about 10 spots within roughly 15 blocks of the spawn. At
  walk speed 52/16 ≈ 3.25 blocks/s, that is about 1–2 minutes of play. This matches the
  brief's "first minute" target and its "first real problem at ~3 minutes".
- Artisan rod vs. bamboo rod: range 44 vs. 52, zone −0.03 vs. 0, power 0.85 vs. 1.0. That
  is about 15% weaker on each axis: noticeable, but no worse than the base's starting
  odds.

## 5. Edge Cases
- Gathering a spot that is gone (another tap on the same frame): "Já coletado: volta
  mais tarde", nothing added.
- Crafting without enough materials: Falta material, nothing consumed.
- Load with an unknown material id: dropped. Negative counts are clamped to 0.
- Load with a timer for a spot id that no longer exists: kept, but harmless (never read).
- Old save (rod "bambu" owned): unchanged; the gathering spots are simply extra.
- Workshop upgrade with no rod: the screen says there is no rod; the upgrade cost is −1.
- Bag full or no energy with no rod: NO_ROD is reported first (the most useful reason).

## 6. Dependencies
- Uses: `GameData` (materials, recipes, gathering), `GameState`, `FishingMachine`
  (NO_ROD), `Economy` (craft-only rods are not for sale), `Town` (workshop guard),
  `SaveGame`, `Screens` (bench, bag), `LakeMain` (spots), `Fisherman` (rod visibility).
- Used by: `design/gdd/fish-catch.md` (no fishing until the first rod). Step 4
  shop/upgrades will add recipes and materials here.

## 7. Tuning Knobs
| Knob | Where | Default | Safe range | Effect |
|---|---|---|---|---|
| `respawn_minutes.galho` | `gathering.json` | 720 | 120–1440 | How soon branches come back |
| `respawn_minutes.fibra` | `gathering.json` | 480 | 120–1440 | How soon fibers come back |
| `respawn_minutes.minhoca` | `gathering.json` | 360 | 60–1440 | How soon worms come back (worm bait pace) |
| `amount.*` | `gathering.json` | 1 / 2 / 1 | 1–5 | Material per gather |
| `nodes[]` | `gathering.json` | 10 spots | must stand on free ground (tested) | Where spots are |
| recipe `needs` | `recipes.json` | see §3 | ≥ 1 each | Cost of each craft |
| artisan rod stats | `rods.json` | 44 / −0.03 / 0.85 | below bamboo | How weak the first rod is |
| bamboo `price` | `rods.json` | 60 | 30–150 | First purchase |

## 8. Acceptance Criteria
- [x] AC1: A new game has no rod, and casting reports NO_ROD.
- [x] AC2: Gathering adds the material, hides the spot, and a second gather is GONE.
- [x] AC3: A spot comes back exactly at `respawn_minutes`, also across days.
- [x] AC4: The rod recipe fails (nothing consumed) without the line. One sweep of the branch and fiber spots is enough to make the line and the rod, and the rod ends up equipped.
- [x] AC5: Worm bait consumes 4 worms and equips the bait.
- [x] AC6: The artisan rod cannot be bought.
- [x] AC7: Materials and timers survive save → load.
- [x] AC8: Every spot stands on free ground.
- [x] AC9 (visual): Start with no rod and visible glowing spots, the "Coletar" button, the bench before and after, and the rod in hand. Evidence: `production/qa/evidence/first-rod/01–05`.

AC1–AC8: `tests/unit/gathering/gathering_crafting_test.gd` (10 tests, passing 2026-11-18).
