# assets/animals

- `vaca.glb` — cow model with its own texture, sent by the owner on 2026-11-22 (used as is).
- `cavalo.glb` — horse model sent by the owner on 2026-11-22. It had no texture or UVs, so the
  owner's horse reference picture was projected onto it (side, front, back and top views) and
  stored as vertex colors (COLOR_0). Script: tools/asset-pipeline/bake_horse.py (not needed to run
  the game). The game code turns, scales and lifts both models when it loads them
  (src/world/animal_models.gd, sizes in world_look.json "animal_models").
