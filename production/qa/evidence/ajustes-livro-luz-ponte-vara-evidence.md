# Evidence: livro, luz, ponte e andar sem vara (2026-11-19)

1. **Fish book**: an open book with two pages.
   - The left page shows the chosen fish: name, picture, rarity, where and when it bites, catches and biggest catch.
   - The right page shows the counter "9 / 35", a sort button (Pescados, Raridade, Nome) and a grid of tiles, with dark silhouettes for fish not caught yet.
   - The fish pictures come from the sheet the user sent (12 sprites in `assets/fish/`), mapped to the 35 species with color tints (`src/data/fish_art.json`).
   - They also appear in the catch card, the minigame, the bag and the shop.
2. **Light**: the day is overcast. The sun is weaker, the sky greyer and the ambient light lower, with some grey fog. Filmic tone mapping lowers exposure, saturation and brightness a little.
3. **Bridge**: where a road crosses water, the bridge is now one straight rectangle across the whole road width.
4. **Rod**: a "Guardar" / "Pegar vara" button lets the farmer walk without the rod.
   - With the rod put away, tapping the water does not cast.
   - The big button reads "PEGAR VARA" and takes the rod out.
   - The choice is saved.

**Checks**: farm smoke test passed; no script errors.
**Screenshots**: 01-06 (gl_compatibility, Xvfb).
**Sign-off**: pending the user.
