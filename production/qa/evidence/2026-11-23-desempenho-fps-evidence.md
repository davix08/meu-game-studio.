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
