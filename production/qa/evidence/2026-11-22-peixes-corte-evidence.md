# Evidence: more fish, chopping with several hits (2026-11-22)

Godot 4.7.2 here. Screenshots in `2026-11-22-peixes-corte/`.

| Asked | Result |
|---|---|
| More fish | 20 new species (55 in the book): Lambari, Bagre, Corvina, Anchova, Traíra, Pacu, Robalo, Truta-arco-íris, Linguado, Piranha, Garoupa, Peixe-voador, Enguia, Peixe-gato, Pintado, Tambaqui, Esturjão, Peixe-sapo, Pirarucu, Peixe-dragão. The picture sent was another game's fish art, so it was only a reference: the sprites are our own, drawn by tools/asset-pipeline/make_fish.py (`01`, `02`) |
| Axe and pickaxe animations, several hits | Each tap of "Cortar"/"Quebrar" is one swing: the tool shows in the hands, goes up and comes down; at the hit the tree/rock shakes, chips fly, chop/clink sound, progress ■■□□□ above it. Tree: 5 hits, rock: 6 (town.json farm_life.chop_hits / rock_hits). Last hit: +3 wood, the tree tips over (or the rock crumbles) with its sound. Test: 5 taps → hits 1..4 then cut, madeira 0 → 3 (`03`, `04`) |

Regression: admin, Continue, menu, barn, sleep, riding, truck cage pass. Not verified on the phone.
