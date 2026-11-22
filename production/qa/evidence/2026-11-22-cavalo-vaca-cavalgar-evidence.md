# Evidence: the owner's cow and horse models, riding the horse (2026-11-22)

Godot 4.7.2 here; screenshots in `2026-11-22-cavalo-vaca-cavalgar/`.

| Asked | Checked | Result |
|---|---|---|
| Use the cow .glb instead of the block cow | Corral with three cows | The textured model, turned to walk forward, 1.1 m tall; was black at first (glTF default metallic = 1), now matte (`02`) |
| Use the horse .glb, with the picture's texture | Barn stalls, close render | The .glb had no texture or UVs: the picture's side/front/back/top views were projected onto it as vertex colors (tools/asset-pipeline/bake_horse.py): chestnut coat, dark mane and tail, white blaze and socks (`01`, `03`) |
| Ride the horse on the farm, mount animation, put it back in the barn | Stall spot inside the barn, ride, barn door | "Montar no cavalo" → outside the door, climbs on (1 s, right leg over the back) → `riding true`, seat 0.74 m up; rides at 2x speed with a gallop rock, water blocks the horse; at the barn door "Guardar cavalo" → climbs down, horse back in its stall, "Entrar no celeiro" again (`04`, `05`) |

While riding: no fishing, no other buttons except "Guardar cavalo"; a new day ends the ride
and the horse goes back to the barn. Regression: admin, Continue, field, menu, barn, sleep,
voxel models all pass. Not verified on the phone.
