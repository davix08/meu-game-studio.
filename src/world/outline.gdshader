// Dark outline around props (Lakebound), technical-artist, 2026-11-22.
// Target: Godot 4.7 Mobile renderer. Budget: no texture reads, unshaded. Used as the next pass
// of the painted props: an "inverted hull" (the mesh pushed out along its normals, back faces
// only), which leaves a thin dark line around the silhouette like the hand-drawn diorama look.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(0.16, 0.11, 0.08, 1.0);
/** Line width in world meters (kept the same on big and small instances). */
uniform float width = 0.035;

void vertex() {
	float scale = max(length(MODEL_MATRIX[0].xyz), 0.001);
	VERTEX += NORMAL * width / scale;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
