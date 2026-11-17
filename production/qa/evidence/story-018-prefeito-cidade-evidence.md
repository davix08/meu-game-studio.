# Evidence: story-018-prefeito-cidade

**Date**: 2026-11-17
**Build**: branch `claude/new-session-1rkxjr`, stories 005-018 built together at the user's request.
**How captured**: Godot 4.7.2 official (Linux), cloud container, virtual display (Xvfb), renderer
`gl_compatibility` (the container has no Vulkan GPU; the project uses the Mobile renderer, so colors and
light on the phone will differ, usually darker and less washed out), 1280x720. A test scene set up a game
(coins, built lots, fish, crops, animals) and opened each screen.

**Automated checks run (same build)**:
- The main scene runs headless with no script errors.
- A smoke script built every lot and used the warehouse, cooking, rod upgrade, seeds, planting, watering,
  animals, troughs, clothes and requests, opened every screen, ran 3 days (growth and animal products),
  and saved and reloaded (format 3).
- A neighbor run: three neighbors walked their routine to the restaurant and bought dishes (meals 2/2).

**Screenshots**: `story-018-prefeito-cidade/23-prefeitura.png`, `story-018-prefeito-cidade/02-centro-vila.png`

**Not verified**: frame rate on the phone (30 fps criterion), touch feel, and the Mobile-renderer look.
**Sign-off**: pending the user's play on the phone.
