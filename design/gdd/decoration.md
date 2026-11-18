# Decorating the House and Yard

> Status: Approved (autonomous session, 2026-11-18, under the user's "take the
> recommended decisions" instruction) · Source: user's chat ("decorar a fazenda, decorar
> a casa"), TXT Etapa 4, `design/game-brief.md` Hooks ("uma doca e fazenda que são suas
> e que você decora") · Code: `src/core/decor.gd`, `src/world/decor_view.gd`, `Screens.open_decor`

## 1. Overview
Six decoration slots around the house and yard, each marked by a ring of pebbles. Walking
up to one shows **Decorar** (or **Trocar decoração**). The screen lists the pieces: vaso
de flores, arbusto podado, lanterna, banco, bandeira, estátua de peixe and the **troféu
do maior peixe**, which shows the player's heaviest catch in its species color. Placing
buys the piece for that slot. Swapping or removing gives back half of the old piece's price.

## 2. Player Fantasy
"This dock is mine." Decorating is a coin sink with a personal touch. The trophy turns
your best catch into something you can see every day.

## 3. Detailed Rules
1. Slots: fixed positions in `decor.json` (3 by the house, 3 in the yard). Each holds one piece or nothing.
2. Place: needs the piece's level and its price minus the refund of the piece being
   replaced. Coins change by `refund(old) − price(new)`.
3. Remove: empties the slot and refunds `floor(price × refund_fraction)`.
4. Same piece again: not offered ("Já está aqui").
5. Trophy: shows the species with the heaviest `best` in the guide. Size follows its
   longest catch, and a band shows its rarity color. It updates after every catch.
6. Saved per slot. Unknown slots or pieces in a save are dropped.
7. Coop: decorations are local to each player in this slice (each phone shows its own).
   A shared farm is the next coop step (see `coop-lan.md` §5).
8. Planting already exists in the base (Campos de plantio: carrot and wheat; plant,
   water, harvest; carrot works as bait). This GDD does not change it.

## 4. Formulas
- Swap cost: `cost = price(new) − floor(price(old) × refund_fraction)`.
- Example: replacing a lantern (90) with a bench (120): 120 − 45 = **75 coins**.
- Coin sink at full yard: placing one of each of 6 pieces costs 40–400 each,
  about 1 000 coins total. That is roughly 80 common fish or 15 dives. It is meant as a
  mid-game goal, not a first-day one.

## 5. Edge Cases
- Not enough coins for the swap: nothing changes ("Moedas insuficientes").
- Trophy with an empty guide: the plaque shows no fish.
- A slot's position became blocked by a future building: covered by the free-ground test.
  Move the slot in `decor.json`.
- Removing an empty slot: `EMPTY`, nothing happens.

## 6. Dependencies
- Uses: `GameState` (coins, level, guide), `GameData` (decor.json), `SaveGame`, `FishIcon.body_color`.
- Used by: future shared-farm coop and a carpenter shop with more pieces.

## 7. Tuning Knobs
| Knob | Where | Default | Safe range | Effect |
|---|---|---|---|---|
| `refund_fraction` | decor.json | 0.5 | 0–1 | Swap and remove refund |
| item `price` / `level` | decor.json | 40–400 / 1–3 | increasing with size | Coin sink pacing |
| `slots[]` | decor.json | 6 | must stand on free ground (tested) | Where pieces go |
| `PIECE_SCALE` | decor_view.gd | 1.5 | 1–2 | Readability on a phone |

## 8. Acceptance Criteria
- [x] AC1: Placing pays the price. Swapping refunds half the old piece. Removing refunds and empties.
- [x] AC2: Blocked by level, by coins (nothing spent), for an unknown slot or item, and for the same piece.
- [x] AC3: The trophy picks the heaviest fish in the guide.
- [x] AC4: Decorations survive save → load. Unknown slots and pieces are dropped.
- [x] AC5: Every slot stands on free ground.
- [x] AC6 (visual): empty slot markers with "Decorar", the Decorar screen, and the yard decorated. Evidence: `production/qa/evidence/decoration/01–03`.

AC1–AC5: `tests/unit/decor/decor_slots_test.gd` (7 tests).
