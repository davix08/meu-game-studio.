# Gear Upgrades: Lines and Hooks

> Status: Approved (autonomous session, 2026-11-18, under the user's "take the
> recommended decisions" instruction) · Source: TXT Etapa 3 ("Linhas e anzóis",
> "Melhorias de equipamento"); `design/game-brief.md` Challenge and Build order step 4
> · Code: `src/core/fishing_machine.gd`, `src/core/economy.gd`, `Screens` shop tab Linhas

## 1. Overview
The base already sells rods, baits and items, and the workshop upgrades rods. This
adds **lines** and **hooks**. Each line has a load limit (`max_kg`). Fish heavier than
the line are harder to land, and if they get away, the line snaps. Each hook gives more
time to strike and a wider green zone. This is the "new gear for new fish" part of the
brief: heavier species ask for a stronger line.

## 2. Player Fantasy
"That one was too big for my line… next time." A fish that got away should point to a
clear goal (a stronger line) instead of feeling like bad luck. Buying a line and
landing the fish that broke the old one is the payoff.

## 3. Detailed Rules
1. The fish is rolled **at the bite**: species and weight together (`FishingMachine.hooked`).
   Before this change, the weight was rolled at landing. Now the weight is known before the fight.
2. `overweight = weight > line.max_kg`. During the fight, the bar under the progress
   shows "Pesado demais para a sua linha!" in place of the rarity mood.
3. Inside the green zone, progress grows at the base rate × `line_mult(weight)` (§4).
   Losses are unchanged.
4. If progress reaches 0 on an overweight fish, the end reason is `LINE_BROKE` ("A linha
   arrebentou! Peixe pesado demais: compre uma linha mais forte."). Otherwise it is
   `LINE_SLACK` as before. Neither costs coins or items: the bait is not consumed in
   the base, and the fish is simply lost.
5. Hooks add `react` seconds to the bite window and `zone` to the green-zone width.
6. Starting gear: a new game has no line until the artisan rod is crafted. Crafting it
   also gives and equips the **improvised line** (2 kg, never sold). The **simple hook**
   is owned from the start.
7. Shop tab **Linhas** lists lines and then hooks, each with Comprar / Equipar /
   Equipada / Precisa do nível N, like rods.
8. Saves from before lines existed: a player who owns a rod gets the **nylon line**
   (`legacy_line`), so their game does not get harder after updating.

## 4. Formulas
```
line_mult(w) = 1                                        if w ≤ max_kg
             = max(line_min_mult, (max_kg / w)^line_exponent)   otherwise
```
- `line_exponent` (tune, 0.5): square-root falloff. `line_min_mult` (tune, 0.3): floor,
  so any fish is still landable with skill.
- Example: improvised line (2 kg) and a 6 kg tucunaré → (2/6)^0.5 = **0.577**. Progress
  grows at 58% speed, and losing it snaps the line.
- Example: nylon (6 kg) and a 20 000 kg whale shark → (6/20000)^0.5 ≈ 0.017 → floor **0.3**.

Line ladder vs. species weights (`species.json` kg_max by rarity): common ≤ 2.5 kg
(improvised covers most of them), uncommon ≤ 12 kg (nylon 6 kg covers most;
multifilament 25 kg covers all), rare ≤ 120 kg (steel 120 kg), epic ≤ 900 kg (kevlar
600 kg covers most), legendary up to 20 000 kg (abyssal 5 000 kg; the floor carries the
rest). Each line unlocks at the level where its rarity starts appearing (`max_rarity`).

## 5. Edge Cases
- No line equipped (only possible with no rod, where casting is already blocked): `line_max_kg = ∞`, mult 1.
- Unknown line or hook id in a save: dropped, falls back to the first owned (line) or keeps the start hook.
- Buying the improvised line: refused (`LOCKED_BY_LEVEL`), and it is hidden in the shop until owned.
- Equipping a weaker line later: allowed. The shop shows each line's limit.
- RNG order changed (the weight roll moved to the bite). Gameplay odds are unchanged, but a seed's exact sequence differs from the 2D/base. No save stores RNG state, so nothing breaks.

## 6. Dependencies
- Uses: `GameData` (lines.json, hooks.json), `GameState`, `Economy`, `SaveGame`,
  `FishRoller.roll_catch`, `Gathering` (artisan rod gives the improvised line).
- Used by: `fish-catch.md` (weight now known at bite), the HUD (warning), the
  shop. Future: diving (step 6) can reuse `line_mult` for the harpoon cord.

## 7. Tuning Knobs
| Knob | Where | Default | Safe range | Effect |
|---|---|---|---|---|
| `line_exponent` | config tune | 0.5 | 0.1–2.0 | How fast overweight fish get harder |
| `line_min_mult` | config tune | 0.3 | 0.05–1.0 | Hardest it ever gets (1 = lines don't matter) |
| `max_kg` per line | lines.json | 2 / 6 / 25 / 120 / 600 / 5000 | increasing | Gear ladder |
| `price`, `level` per line/hook | lines.json, hooks.json | see files | increasing | Shop pacing |
| `react`, `zone` per hook | hooks.json | 0–0.4 s, 0–0.06 | react < `react_window` | Strike time, zone width |
| `rod_line`, `legacy_line`, `start_hook` | config fixed | improvisada / nylon / simples | ids that exist | Starting gear |

## 8. Acceptance Criteria
- [x] AC1: `line_mult` is 1 up to `max_kg`, (max/w)^0.5 above it, never below the floor (tests: 3).
- [x] AC2: An overweight fish that escapes ends with LINE_BROKE. A light one ends with LINE_SLACK.
- [x] AC3: Crafting the artisan rod gives and equips the improvised line.
- [x] AC4: Lines and hooks can be bought and equipped, and coins are spent. The improvised line is not for sale.
- [x] AC5: A hook widens the green zone by its `zone`.
- [x] AC6: An old save with a rod gets the nylon line. Line and hook survive save → load.
- [x] AC7 (visual): The Linhas tab with limits and level locks, and the overweight warning in the fight. Evidence: `production/qa/evidence/gear/01–02`.

AC1–AC6: `tests/unit/gear/gear_lines_hooks_test.gd` (10 tests, passing 2026-11-18).
