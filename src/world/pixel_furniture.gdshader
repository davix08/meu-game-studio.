// Pixel-art furniture (Lakebound), technical-artist, 2026-11-22.
// Target: Godot 4.7 Mobile renderer. Budget: no texture reads, 2 hashes, no loops.
// Variants: none (the house and barn interiors share one material).
// The voxel-furniture look the user asked for: every box face (MeshBuilder.add_box gives UV =
// position on the face in meters, UV2 = face size) gets a dark 1-pixel border, a light bevel
// pixel inside it, and pixel-sized color noise stretched into a grain. Faces with no UV (other
// shapes) keep the plain vertex color.
shader_type spatial;
render_mode specular_disabled, cull_disabled;

/** Size of one "pixel" in meters (16 pixels per block). */
uniform float pixel_size = 0.0625;
/** Brightness change of the pixel noise. */
uniform float pixel_noise = 0.07;
/** How dark the border pixel is (0 = black, 1 = no border). */
uniform float border_dark = 0.6;
/** How light the bevel pixel is. */
uniform float bevel_light = 1.14;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 col = COLOR.rgb;
	if (UV2.x > 0.0) {
		vec2 cell = floor(UV / pixel_size);
		// Grain: noise cells three pixels long along the face, snapped to 4 levels.
		float n = floor(hash(vec2(floor(cell.x / 3.0), cell.y)) * 4.0) / 3.0 - 0.5;
		col *= 1.0 + n * pixel_noise * 2.0;
		vec2 far_side = UV2 - UV;
		float edge = min(min(UV.x, far_side.x), min(UV.y, far_side.y));
		float small = min(UV2.x, UV2.y);
		if (edge < pixel_size && small > pixel_size * 2.5) {
			col *= border_dark;
		} else if (edge < pixel_size * 2.0 && small > pixel_size * 4.5) {
			col *= bevel_light;
		}
	}
	ALBEDO = col;
	ROUGHNESS = 0.9;
}
