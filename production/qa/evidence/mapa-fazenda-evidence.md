# Evidence: mapa da fazenda + caminhão de entregas (2026-11-19)

**Change**: the whole map was rebuilt as the farm in the user's drawing: house, shed (galpão), chicken coop and the waterfall with its bridge in the north; the lake with its pier in the middle; the milking corral to the west; the field (locked at farm level 8) to the south; the closed road to the city to the east; forest all around.

New systems:
- **Farm level 1-10**, with its own bar in the top HUD. It grows with experience from fishing, cutting trees, breaking rocks, opening boxes, collecting eggs, feeding, milking and building.
- **Shed**: a chest for fish, materials and products. The bag now holds at most 30 items.
- **Cutting trees and breaking rocks** inside the farm gives wood and stone. They grow back after 3 days.
- **Coop** (level 2) and **corral** (level 5) are built with wood, stone and coins.
- **Shop by phone** (sell, rods, baits, items, farm goods, auction, upgrades).
- **Delivery truck**: comes in from the city road (the barrier lifts), leaves a box at the shed, coop or corral door, and drives away.
- **Chickens**: lay eggs in the basket when fed with corn.
- **Cows**: milked by hand once a day when fed; the milking machine (level 6) milks them by itself.
- **Calves**: grow into cows after 4 days.
- **Village**: the city lots and neighbors stay in the code and data (`town_village`, `neighbors_city`) but are off the map.
- **Saves**: older saves keep progress, and the farmer starts at the house.

**Checks**: headless farm loop script: cut, order, truck trip, open box, build coop, chickens, feed, eggs, build corral, cow and calf, milk, milking machine, every screen, save and reload. All passed with no script errors.
**Screenshots**: 00-14 in `mapa-fazenda/` (gl_compatibility under Xvfb, brighter than the phone).
**Not verified**: phone frame rate; the waterfall sits at the north edge of the map, so it shows only when the camera goes up there.
**Sign-off**: pending the user on the phone.
