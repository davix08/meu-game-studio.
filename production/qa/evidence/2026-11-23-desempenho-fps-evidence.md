# Evidence: walking stutter on phones, FPS counter (2026-11-23)

Measured here with Godot 4.7.2 (software OpenGL, so frame rates are not phone numbers; the
triangle and draw-call counts are). Same view while walking:

| | Triangles / frame | Draw calls |
|---|---|---|
| Before | 638 860 | 202 |
| After, full graphics | 424 566 | 204 |
| After, light graphics (phone default) | 199 371 | 152 |

Causes found: the owner's cow and horse models (~50 000 triangles each), the farmer's baked
parts (~54 000), 722 trees of ~540 triangles drawn again for the outline and for the sun
shadow. Scripts were not the problem (every system under 0.1 ms per frame).

Fixes: light versions of the cow, horse and farmer (~6 000 triangles each, Godot's mesh
simplifier, tools/asset-pipeline/bake_low_poly.gd); simpler tree and pine meshes; a "Gráficos"
setting, "Leve (celular)" by default on phones: no outlines, trees/rocks cast no shadow,
shorter and smaller sun shadow, 3D at 75% resolution, no MSAA, small decorations only near;
phones use the Compatibility (OpenGL) renderer. FPS counter on by default (green ≥ 50,
yellow ≥ 28, red), toggled in Ajustes (`01`, `02`).

APK rebuilt (0.2-teste, same debug key, installs over 0.1). Not measured on a phone here.

## Second pass (0.3-teste), after the owner measured 9-13 FPS on the phone

The phone draws the 3D at its native screen resolution (about 2400x1080): the GPU was limited
by pixels, not triangles (worst near the water: transparent water over the lake bed). Light
graphics now:

- 3D drawn about 560 pixels high whatever the screen (performance.low_render_height), so a
  1080-pixel screen draws about a third of the pixels; it adapts every 2 s: below 26 FPS one
  step lower (down to 35%), above 50 FPS back up to the target.
- No sun shadows at all, no color-adjust pass.
- Cheap shader paths (`cheap` uniform): props without brush noise/moss, ground with one noise
  octave, water with one ripple read and no waves, glints or current stripes.

Here: 182 165 triangles, 133 draw calls in light mode; frame time on this software renderer
from ~200 ms (start) to ~55 ms. Not measured on the phone (`03`).
