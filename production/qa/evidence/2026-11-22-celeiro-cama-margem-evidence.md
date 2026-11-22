# Evidence: barn inside, sleep animation, pixel furniture, road texture, lakeside (2026-11-22)

Godot 4.7.2 here (OpenGL compatibility, xvfb, 1280x720, fixed 30 fps), scratch copy of the
project. Screenshots in `2026-11-22-celeiro-cama-margem/`.

| Asked | Checked | Result |
|---|---|---|
| Barn inside, two floors and stairs; horses below, chests above; when one chest is full the next one | Door spot outside the barn, walk up the stairs, loft spot, chests screen, exit | "Entrar no celeiro" → map `barn`; floor heights ground 0 / stairs 1.2 / loft 2.4; rail and stalls block; climbed to y 2.4; "Baús" only on the loft; 2 chests 25/25 filled in order; exit back to the barn door (`01`-`03`) |
| Lying in bed to rest | Tap Dormir next to the bed | Lies on the bed (head on the pillow), the night passes (day 1 → 2), then stands up next to the bed (`05`, `06`) |
| Better furniture textures | House inside | Pixel-art shader on every box (border, bevel, grain); stove burners and oven, sink and faucet, two-door fridge, microwave, washing machine, armchair (`04`) |
| Road ground from the picture | Farm view | Road blocks use the user's texture (seamless 363 px cut, `assets/terrain/estrada.png`) with a ragged edge into the grass (`07`) |
| Lakeside like the pond picture, all around | Lake shore | Tall grass with seed heads, pebbles and small bushes on every shore block except by the pier and bridges (`08`) |

Regression: admin, Continue with a corral box, crop field, start menu all still pass.
Not verified: the phone (Mobile renderer) and its frame rate. Road texture rights: see
`assets/terrain/LEIA-ME.md`.
