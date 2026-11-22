# Evidence: animal animations, horse bought, truck cage, sounds, new HUD (2026-11-22)

Godot 4.7.2 here (OpenGL compatibility, xvfb). Screenshots in `2026-11-22-animacoes-sons-interface/`.

| Asked | Checked | Result |
|---|---|---|
| Animations from the owner's sheets on the cow and horse | Rig showcase; corral; barn; riding | Models cut into body, head, tail, four legs (src/world/animal_models.gd + animal_rig.gd): idle, walk, gallop, graze, sleep, rear (`01`). Cows walk and graze in the corral and lie down at night (`02`); barn horses stand and eat; the ridden horse gallops while moving and rears before the farmer climbs on |
| Horse is bought | Auction order, delivery, stall | "Cavalo" (1500) in the Leilão, home "Baias do celeiro" (3); stalls show only owned horses; "Sem cavalo" + hint when none |
| Truck with a cage for animals | Order a horse, wait for the truck | Cage with the animal on the bed during the trip; a cage is left at the barn door; "Abrir gaiola" → horse in its stall (`03`, `04`) |
| Sounds | Run without errors | Synthesized WAVs (tools/asset-pipeline/make_sounds.py → assets/audio): cow, horse, chicken, pig, sheep calls near the animals; farm birds and wind loop; lake water louder near the shore; truck engine while driving and a horn at each stop; doors of house and barn; cast whoosh, bobber splash, reel during the fight; swim strokes; hooves while riding |
| Money and bottom buttons like the picture | HUD | Wooden money plate with a light border and "$ 98.530"; bottom bar of square cream icon buttons (Loja, Livro, Mochila, Vara/Guardar) (`05`) |

Not done: jump, hurt and death animations (nothing in the game triggers them yet). Sounds were
checked for loading and playing without errors, not by ear. Not verified on the phone.
Regression: admin, Continue, field, menu, barn, sleep, voxel models, riding all pass.
