# Evidence: voxel cow, horse, barn, farmhouse and crop field (2026-11-22)

The owner sent pictures (cow and horse model sheets, a red barn, a farmhouse with a porch, a
fenced crop field). They are pictures, not 3D files, so these are our own block models in that
style (src/world/voxel_models.gd), drawn with the pixel material (border, bevel, grain on every
box). Godot 4.7.2 here; screenshots in `2026-11-22-modelos-voxel/`.

| Asked | Result |
|---|---|
| Cow model and texture | Holstein cow: jagged black patches, blaze, pink muzzle and udder, horns, ears, black hooves, tail tuft; used for cows and calves in the corral (`01`, `06`) |
| Horse model and texture | Chestnut horse: dark stepped mane, white blaze and socks, ears, chunky tail; head and tail still move; in the barn stalls (lower walls now) (`01`, `07`) |
| Barn like the picture | Red board walls, white trim, stepped gambrel roof, X double doors under a little roof with a lantern, hay-loft window, lean-to with hay bales and a cart, windmill, barrel, planter, fence (`02`) |
| House like the picture | Two storeys: stone footing, plaster and timber, porch with rails, steps and lanterns, red stepped tile roofs, windows with shutters and a flower box, stone chimney (smoke follows it) (`03`, `08`) |
| Crop field like the picture | Post-and-rail fence with the gate gap, scarecrow, two lantern posts, crates of produce; blocky soil rows; ripe wheat, corn, soy, carrot and cane each with its own block model, growing plants as green blocks (`04`, `05`) |

Also: all farm buildings and animals now use the pixel material; an empty mesh (a building with
no glass) no longer raises an engine error.
Regression: admin, Continue, field, menu, barn, sleep all pass. Not verified on the phone.
