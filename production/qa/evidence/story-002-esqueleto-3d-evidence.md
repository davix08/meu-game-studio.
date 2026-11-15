# Evidence: Story 002 — Esqueleto 3D: terreno, lago, câmera e pescador

**Story**: `production/epics/lakebound-aventura-de-pesca/story-002-esqueleto-3d.md`
**Date**: 2026-11-15
**Build**: commit 689d77f (isometric orthographic camera + fisherman restyled), run in the Godot 4.7 editor on the user's Android phone

## Screenshots

- `production/qa/evidence/story-002-esqueleto-3d/02-camera-isometrica-pescador-novo.jpg` — current build: isometric orthographic camera, Lago Esmeralda with house, path, trees, pines, bushes, flowers, lake with reeds and lily pads, islet with tree, pier with lantern and rowboat, fisherman with straw hat, joystick, HUD (region, FPS 74)
- `production/qa/evidence/story-002-esqueleto-3d/01-camera-perspectiva-antes.jpg` — earlier build with the perspective camera and the first fisherman (FPS 83), kept for comparison

## Observations

- FPS 74 in the editor on the phone (target 30)
- Joystick moves the fisherman in the right screen direction and runs when fully pushed (user confirmed)
- Water sparkle shows a regular dot grid in deep water: to improve in Story 005
- Fisherman reads small at camera size 14: accepted as is

## Sign-off

- [x] Approved — art/look (user, 2026-11-15)
- [x] Approved — feel and controls (user, 2026-11-15)
- [x] Approved — deviation: own VirtualStick instead of the VirtualJoystick node (user, 2026-11-15)
