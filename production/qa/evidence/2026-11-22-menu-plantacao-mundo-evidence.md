# Evidence: Continue fix, farmer model, crop rows, start menu, painted world (2026-11-22)

Run here with Godot 4.7.2 (official Linux build, OpenGL compatibility under xvfb, 1280x720,
fixed 30 fps) on a scratch copy of the project. Screenshots in
`2026-11-22-menu-plantacao-mundo/`.

| # | What the user asked | What was checked | Result |
|---|---|---|---|
| 1 | Error `Invalid access to property or key 'curral'` (town_plan.gd:162) and Continue froze | Save with `placed = {}` and boxes for "curral" and "galinheiro", reload, `_begin(false)` | `CONTINUE OK boxes=2`, no script error. Cause: the save's boxes were drawn before the placed buildings were restored. Now buildings are restored first, and `TownPlan.lot_rect` falls back to the default spot (or a warning) instead of crashing |
| 2 | "The character model is different" | Model now loads from parts baked once with Godot (`assets/characters/fazendeiro_partes/`: 9 meshes + texture.png), not cut from the .glb at runtime on the phone | `model kind split baked true`; close-up `06` shows the textured farmer |
| 3 | Crops like the picture | Field with plots at sprout, growing and ripe (wheat, carrot, corn) | `04`, `05`: mounded soil rows with clods, sprouts green, growing green-yellow, ripe golden with ears |
| 4 | Menu like the picture, based on the game | Start menu over the live farm; arrow key moves the pill; Ajustes then Voltar; Continuar | `01` logo + cream card; `focus Novo jogo` after one arrow key; `02` short settings; `after continue: open false top true cam 14.0` (`03`) |
| 5 | World textures like the trees, rocks, grass, branches picture | Painted shader + dark outline on trees, pines, bushes, rocks; mossy rocks; fallen logs and stumps (105 placed); fuller grass tufts | `07`, `08`, `09` |

Regression: `admin` scene still passes (coins, goods, level 20, tools, timers, storage).

Not verified here: the phone itself (Mobile renderer on Android) and its frame rate with the
outline pass. The art in the user's pictures was used as a style reference only; every model
and shader here is our own.
