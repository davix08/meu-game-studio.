# Fish Catch: Weight, Size and Rarity

> Status: Approved (autonomous session, 2026-11-18, under the user's "take the
> recommended decisions" instruction) · Source: `design/game-brief.md`, Build order step 2
> · Base code: `src/core/fish_roller.gd`, `src/core/fishing_machine.gd`

## 1. Overview
Every fish landed has a **species**, a **rarity** (Comum, Incomum, Raro, Épico,
Lendário), a **weight** in kg and a **size** (length) in cm. Weight and rarity come
from the Lakebound base. This GDD adds size. Each catch is recorded in the fish guide
(`GameState.book`), which keeps the catch count, the heaviest weight and the longest
size per species. The capture card and the guide show all three values.

## 2. Player Fantasy
"Look how big this one is!" Every catch is a small surprise with a number to
brag about. The player sees that a 38 cm tilápia isn't the 50 cm one they're after,
so they cast again. Records turn the same species into a new goal.

## 3. Detailed Rules
1. The species roll is unchanged (`FishRoller.roll_species`): bait, luck, deep water and
   schools tilt it toward rarer fish, and the player's level caps the rarity.
2. The weight roll is unchanged (`FishRoller.roll_catch`): one random draw, skewed so
   heavy fish are rarer (`weight_skew`).
3. **Size is derived from weight and uses no random draw.** A heavier fish of the same
   species is always longer. This keeps the base's RNG draw order, so seeds and saves
   stay compatible.
4. Each species has a size range `cm: [min, max]` in `src/data/species.json`.
5. The size is rounded to whole cm (`length_decimals`, 0).
6. Display: under 100 cm it shows as "38 cm". From 100 cm it shows in meters with one
   decimal ("1,8 m"), with a decimal comma (pt-BR).
7. The guide entry keeps `count`, `best` (heaviest kg) and `longest` (largest cm).
8. **New record** = heavier than the previous best weight (unchanged rule). Size rises
   with weight, so a weight record is also a size record.
9. The capture card shows: title (NOVA ESPÉCIE / NOVO RECORDE / captured), name,
   rarity, "1,40 kg · 38 cm · 12 moedas", then "Capturas: n · Recorde: x kg · y cm".

## 4. Formulas
Weight roll (base, unchanged): `w = kg_min + (kg_max − kg_min) · u^weight_skew`, where
`u ∈ [0,1)` is the RNG draw.

Size from weight (new, cube-root growth because mass grows with volume):
```
t   = (∛w − ∛kg_min) / (∛kg_max − ∛kg_min)     clamped to [0, 1]; t = 0 when kg_max = kg_min
cm  = cm_min + (cm_max − cm_min) · t^length_curve
```
- `length_curve` (tune, default 1.0): 1 = pure cube-root growth; >1 makes long fish rarer.
- Example, tilápia (0,3–2,5 kg, 25–50 cm), w = 1,4 kg: ∛0,3 = 0,669, ∛2,5 = 1,357,
  ∛1,4 = 1,119 → t = 0,654 → cm = 25 + 25·0,654 = 41,4 → **41 cm**.

Sale value (base, unchanged): `value = max(1, round(base_value · (value_base_mult + value_weight_mult · f)))`,
where `f = (w − kg_min)/(kg_max − kg_min)`.

## 5. Edge Cases
- `kg_min == kg_max`: t = 0, so the size is `cm_min`.
- Weight outside the range (old save, data edit): t is clamped, so the size stays within `[cm_min, cm_max]`.
- Old saves without size: bag fish and guide entries get their size computed from
  their weight on load (`longest` from `best`), so nothing is lost.
- A species missing `cm` in `species.json` is a load error naming the entry, like a
  missing `kg`.

## 6. Dependencies
- `GameData` (species table, tune/fixed values), `GameState` (Catch, BookEntry),
  `FishingMachine` (records the catch), `SaveGame` (persistence),
  `FishingHud` (capture card), `Screens` (bag and guide).
- Upcoming: shop/gear (step 4) uses rarity and weight for new fish. Coop (step 5)
  replicates the `Catch` as {id, weight, length, value}.

## 7. Tuning Knobs
| Knob | Where | Default | Safe range | Effect |
|---|---|---|---|---|
| `cm` per species | `species.json` | see file | min > 0, max ≥ min; real-world sizes for the species | Size range shown and recorded |
| `length_curve` | `config.json` tune | 1.0 | 0.5–3.0 | >1: most fish come out short and long ones are rare; <1: most come out long |
| `length_decimals` | `config.json` fixed | 0 | 0–1 | Size rounding |
| `meters_from_cm` | `config.json` fixed | 100 | 50–200 | Where the display switches from cm to m |
| `weight_skew` | `config.json` tune | (base) | (base) | Heavy fish rarer; size follows |

Rationale for the `cm` ranges: real adult sizes per species, scaled down for the
lake fish so the smallest catch is still visible. Rationale for cube-root growth:
body mass grows roughly with length³, so length grows with ∛mass.

## 8. Acceptance Criteria
- [x] AC1: For every species, `fish_length(kg_min) == cm_min` and `fish_length(kg_max) == cm_max`.
- [x] AC2: A heavier fish of the same species is never shorter (monotonic).
- [x] AC3: `roll_catch` makes the same number of RNG draws as before (one).
- [x] AC4: Size survives save → load. An old save without size loads with sizes from weight.
- [x] AC5: The capture card shows weight, size, rarity and value. The guide shows record weight and size. Evidence: `production/qa/evidence/fish-size/01-capture-card.png`, `02-fish-guide.png`, `03-bag.png`.

AC1–AC4 are covered by `tests/unit/fish_catch/fish_catch_length_test.gd` (8 tests, passing 2026-11-18).
