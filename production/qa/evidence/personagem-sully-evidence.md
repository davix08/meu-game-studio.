# Evidence: personagem principal (modelo 3D do fazendeiro)

**Date**: 2026-11-19
**Change**: the fisherman uses the user-supplied model `assets/characters/sully_fazendeiro.glb` (vertex colors, no UVs, no skeleton). Its parts are split into the existing animation pivots (head, torso, arms, legs); walk, run, cast, fight and the catch pose are unchanged. Texture: `assets/characters/sully_pixels.png`, a 32x32 pixel pattern painted for this project (not taken from the reference picture), projected by `src/player/spatial_char_pixel.gdshader` (box projection, no UVs needed). The clothes shop recolors the hat, band, shirt and boots groups; the default outfit keeps the model colors. If the model file is missing, the code-built fisherman is used.

**Captured**: Godot 4.7.2, Xvfb, gl_compatibility renderer (brighter than the phone Mobile renderer), 1280x720.
**Checks**: headless smoke test of every system and screen passed with the model; no script errors.
**Screenshots**: 01-retrato, 02-no-jogo, 03-andando, 04-roupa-nova (hat, shirt and boots from the clothes shop), 05-loja-roupas.
**Sign-off**: pending the user on the phone.
