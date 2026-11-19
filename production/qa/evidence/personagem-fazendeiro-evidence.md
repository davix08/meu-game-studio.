# Evidence: personagem principal (modelo texturizado do fazendeiro)

**Date**: 2026-11-19
**Change**: the fisherman now uses `assets/characters/fazendeiro.glb` (one mesh, 30k vertices, its own JPEG texture with UVs, Y-up, facing +z). At load the mesh is cut once into hat, head, torso, arms, legs and boots by heights and widths in `world_look.json` (`split_*`), and each piece goes under the existing animation pivots, so walking, running, casting, fighting and the catch pose keep working. The model keeps its own texture through `src/player/spatial_char_textured.gdshader`. The clothes shop recolors the hat (and band), the red shirt pixels and the boots; default pieces keep the texture. `model_kind` in the data can switch back to the previous parts model (`parts`) or the code-built one.

**Captured**: Godot 4.7.2, Xvfb, gl_compatibility renderer (brighter than the phone), 1280x720.
**Checks**: import without errors; headless smoke test of every system and screen passed.
**Not verified**: load time of the cut on the phone (done once per run); frame rate with the 30k-vertex model.
**Sign-off**: pending the user on the phone.
