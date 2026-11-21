# Evidence: real-time production systems (2026-11-21)

The farm now has these systems, built on the existing game. Timers are real time and keep running while the game is closed (`Production`, `src/core/production.gd`; values in `src/data/farm_prod.json`).

## Systems

- **Farm levels**: 1 to 20, each unlocking crops, buildings, recipes and animals.
- **Field**: open from the start with 6 plots, more bought with coins, up to 22.
  - Crops: wheat, corn, soy, carrot and sugar cane.
  - Each crop is planted from your own harvest; harvesting gives 2 and drops rare materials now and then.
- **Silo and barn**: crops go to the silo, everything else to the barn (the old shed). The bag now holds fish only.
  - Both have a limit, raised with rare materials.
- **Factories**: each has a queue with timers and extra slots for coins.
  - Built with wood, stone and coins: feed mill (level 2), bakery (3), dairy (6), sugar mill (8, in the east area).
- **Animals**: each eats its own feed and produces after real time.
  - Chicken and cow (milking by hand, or the milking machine collects by itself).
  - Pig pen (level 10, south-west area) and sheep pen (level 12, north-east area).
  - Calves grow into cows after 3 feeds.
- **Order board**: 6 orders that pay coins and XP.
  - The delivery truck comes to take the box.
  - An order can be swapped; a new one comes after a few minutes.
- **Roadside stall**: 4 slots, with product, quantity and price chosen by the player. A cheaper price sells faster.
- **Land expansion**: 3 fenced forest areas.
  - Opening one needs a deed, a sledgehammer and a stake, plus coins and level.
  - The trees go away and the lots inside become buildable.

## Other changes

- A green "!" over a lot shows something ready.
- Fishing, the fish book, cutting trees and rocks, the phone shop and the purchase truck stay as they were.
- Day and night stay as they were.

## Checks

- **Production test** (fake clock): plant, harvest all, build 5 buildings, two feeds in the queue, collect, feed and collect animals, bread and cheese, deliver an order (the truck takes it), stall sale, barn upgrade, open the east area, every screen, save and reload. All passed.
- **Screenshots**: 00-11 (gl_compatibility, Xvfb).
- **Sign-off**: pending the user.
