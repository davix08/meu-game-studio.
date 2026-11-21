# Evidence: textura da água (2026-11-21)

The water uses `assets/water/ondas.png`, a seamless 512x512 grey ripple picture.

- **Source**: made from the user's second photo. The top square was cut out, turned to grey levels and mirrored into a seamless 2x2 tile.
- **Shader**: `water.gdshader` samples it twice in world space, scrolling in two directions. Its brightness shades the water color and its bright crests sparkle.
- **Colors**: teal for shallow water, after the second photo; dark blue-grey for deep water, after the first.
- **First image not used as a file**: it carries a stock-site watermark that would show on the water, so only its color was taken.
- **Settings**: scale, speed, strength and sparkle are in `world_look.json` (water.ripple_*).

**Captured**: Godot 4.7.2, gl_compatibility, Xvfb.
**Sign-off**: pending the user.
