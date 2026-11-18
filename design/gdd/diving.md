# Diving with a Harpoon (first dive spot, thin slice)

> Status: Approved as a thin stand-in (autonomous session, 2026-11-18, under the user's
> "take the recommended decisions" instruction) · Source: user's chat ("mergulhar para
> pescar e explorar com arma, arpão"), TXT Etapa 5, `design/game-brief.md` Challenge
> (oxygen, provisional loss rule) and Build order step 6 · Code: `src/core/dive.gd`,
> `src/world/dive_view.gd`, `src/ui/dive_hud.gd`

## 1. Overview
A red buoy past the end of the pier marks the first dive spot. Standing at the pier end
shows **Mergulhar**. The game switches to an underwater arena: sandy floor, rocks and
seaweed under blue fog. The diver swims with the left stick and fires the **harpoon**
(ARPÃO) where they face. Fish from the lake bottom swim around: acará, perca, camarão,
caranguejo, baiacu, carpa, lagosta, polvo, moreia and náutilo, capped by the player's
level like the rod. Oxygen runs down. **Subir** keeps everything speared. Running out of
air brings the diver up and keeps only half of that dive's fish.

## 2. Player Fantasy
"A second way to fish." The surface is calm and patient. The bottom is active: you hunt,
aim, and keep an eye on the air. Coming up with a full net just as the bar turns red is
the thrill.

## 3. Detailed Rules
1. Start: costs `energy_cost` (15) energy. Refused with a message if energy is lower or
   the bag is full. Nothing changes on refusal.
2. The arena is 22 × 14 blocks with `fish_count` (7) fish, each with a rolled species and
   weight/size (the same `FishRoller` as the rod, so records and the guide work the same).
3. The diver swims at `swim_speed` (3.2 blocks/s), clamped to the arena. Fish wander in
   straight lines and bounce off the edges.
4. Harpoon: hits the **nearest** fish whose center is within `harpoon_hit_radius` (0.7)
   of the shot line and at most `harpoon_range` (4.5) ahead. A miss also uses the shot.
   Reload is `harpoon_reload` (0.8 s), and the button greys out while reloading.
5. Oxygen: `oxygen_seconds` (45) of real time. Below 25%, the bar turns red and pulses.
6. Subir: all speared fish go to the bag and the guide. A catch card shows, and coop
   friends get the catch toasts.
7. Out of air: back on the surface. The **first** ⌈n · (1 − loss_fraction)⌉ fish speared
   are kept and the rest are lost. Never coins, gear or progress (brief §Challenge).
8. Bag overflow: fish beyond the bag's room stay on the bottom, and the message says how many.
9. Level-up is checked after the dive, the same as after a rod catch.

## 4. Formulas
- Kept on out-of-air: `kept = ceil(n · (1 − loss_fraction))`. With loss 0.5: n=1 → 1,
  n=3 → 2, n=5 → 3. One fish is never lost, so a single quick spear is safe.
- Hit test: `along = (fish − diver) · aim ∈ [0, range]` and `|(fish − diver) × aim| ≤ hit_radius`.
- Pace: a full dive is 45 s with a 0.8 s reload. That is about 56 shots in theory, but
  with 7 fish moving 0.6–1.6 blocks/s a skilled dive spears 4–6. At about 12 coins per
  common fish, a dive is worth roughly 50–70 coins for 15 energy. A rod cast costs 6
  energy for 1 fish (about 12 coins). Diving pays a bit better per energy and asks for
  attention and aim.

## 5. Edge Cases
- Dive started while a coop session runs: presence keeps going and friends see the diver
  standing at the pier. Underwater coop is not in this slice.
- Pausing the game (settings open) underwater: the diver stops, but the oxygen keeps
  running. This is on purpose for this slice: the dive is a short, timed run.
- Day ends (sleep) while diving: impossible. Sleep is only available on the surface.
- No rod: diving works anyway (the harpoon is separate gear). This gives a second way to
  get started.
- Art: the diver and fish are placeholder low-poly shapes. The art bible should replace
  them (`/art-bible`).

## 6. Dependencies
- Uses: `FishRoller` (species/weight/size), `GameState.record_catch` (shared with the
  rod; refactored out of `FishingMachine`), `Progression`, `Energy`, `Fisherman`,
  `FishIcon.body_color`.
- Used by: future dive spots and new areas (Etapa 6), harpoon upgrades (shop), and
  underwater coop.

## 7. Tuning Knobs
All of them are in `src/data/dive.json`.
| Knob | Default | Safe range | Effect |
|---|---|---|---|
| `oxygen_seconds` | 45 | 20–120 | Dive length |
| `energy_cost` | 15 | 0–40 | Dive cost vs. a cast (6) |
| `fish_count` | 7 | 3–15 | Density of targets |
| `harpoon_range` | 4.5 | 2–8 | Reach (blocks) |
| `harpoon_hit_radius` | 0.7 | 0.3–1.5 | Aim forgiveness |
| `harpoon_reload` | 0.8 | 0.3–2 | Shot rate |
| `swim_speed` | 3.2 | 2–6 | Diver speed |
| `fish_speed_min/max` | 0.6 / 1.6 | min < max ≤ swim_speed | How hard fish are to line up |
| `loss_fraction` | 0.5 | 0–1 | Out-of-air penalty |
| `species` | 10 bottom species | ids in species.json | What lives at this spot |
| `spot` | pier end, buoy | on the pier / on water | Where to dive |

## 8. Acceptance Criteria
- [x] AC1: Start spends energy, fills the air and spawns fish. A refusal (no energy) changes nothing.
- [x] AC2: At level 1 only common fish appear.
- [x] AC3: The harpoon hits a fish in line and range, and misses out of range or behind. It must reload.
- [x] AC4: Surfacing keeps all fish. Out of air keeps ⌈n/2⌉ (the formula is tested at 0, 1 and 5).
- [x] AC5: The diver and fish stay inside the arena.
- [x] AC6: `record_catch` is shared with fishing (new/record flags and count).
- [x] AC7 (visual): buoy and Mergulhar, underwater arena, harpoon hit with toast and count, low air (red bar), back on the surface with the catch card. Evidence: `production/qa/evidence/diving/01–05`.

AC1–AC6: `tests/unit/diving/diving_dive_test.gd` (11 tests).
