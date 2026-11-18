# Systems Index: Mystic Tides

> Updated 2026-11-18 (autonomous session). Source of scope: `design/game-brief.md`.
> Base systems come from the Lakebound import and have no GDD yet (`/reverse-document`).

| System | Status | GDD | Code | Tests |
|---|---|---|---|---|
| Rod fishing (cast, bite, fight) | Base, extended | — (base) | `core/fishing_machine.gd` | via gear tests |
| Fish weight, size, rarity, guide | Done (step 2) | [fish-catch.md](fish-catch.md) | `core/fish_roller.gd` | `tests/unit/fish_catch` (8) |
| Gathering + bench, artisan rod | Done (step 3) | [gathering-crafting.md](gathering-crafting.md) | `core/gathering.gd` | `tests/unit/gathering` (10) |
| Lines + hooks (gear for heavy fish) | Done (step 4) | [gear-upgrades.md](gear-upgrades.md) | `core/fishing_machine.gd`, `core/economy.gd` | `tests/unit/gear` (10) |
| Shop, rods, baits, items, workshop | Base | — (base) | `core/economy.gd`, `core/town.gd` | — |
| Coop on same Wi-Fi (up to 4) | Thin slice (step 5) | [coop-lan.md](coop-lan.md) | `net/` | `tests/unit/net` (7) + integration |
| Harpoon diving (first spot) | Thin slice (step 6) | [diving.md](diving.md) | `core/dive.gd` | `tests/unit/diving` (11) |
| House and yard decoration | Done (step 7) | [decoration.md](decoration.md) | `core/decor.gd` | `tests/unit/decor` (7) |
| Farm (plant, water, harvest), ranch | Base | — (base) | `core/town.gd` | — |
| Town building, NPC requests, restaurant, clothes | Base | — (base) | `core/town.gd` | — |
| Day/night, energy, levels, save | Base | — (base) | `core/game_clock.gd`, `core/energy.gd`, `core/save_game.gd` | via save round-trips |
| New regions + new fish, boats | Not started | — | — | — |
| NPC quests, competitions, weather | Not started | — | — | — |
| Shared-world coop (clock, farm, spots) | Not started | coop-lan.md §5 | — | — |
| Android APK export | **Blocked** (no Android SDK reachable) | — | — | — |
