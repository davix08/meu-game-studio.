// Hand-painted props (Lakebound), technical-artist, 2026-11-22.
// Target: Godot 4.7 Mobile renderer, mid-range Android. Budget: no texture reads, one value
// noise (4 hashes), no loops. Variants: one material per look (foliage, rock, wood), same shader.
// The diorama look the user asked for (trees, pines, mossy rocks, logs): soft two-tone toon
// wrapped light with a painted fill in the shade, brush-like color patches that vary with the world position (so instanced props never
// look identical), a warm sunny tint on top-facing parts and, for rocks and logs, moss on top.
// Colors come from the mesh's vertex colors times the MultiMesh instance color.
shader_type spatial;
render_mode diffuse_lambert_wrap, specular_disabled, cull_disabled;

/** World meters per brush patch (smaller = finer strokes). */
uniform float brush_scale = 0.55;
/** How much the patches lighten or darken the color (0 = flat color). */
uniform float brush_strength = 0.18;
/** Warm tint added to the parts that face the sky. */
uniform vec4 sun_tint : source_color = vec4(1.0, 0.93, 0.62, 1.0);
uniform float sun_amount = 0.22;
/** Moss on top-facing parts (rocks, logs, stumps). 0 = none. */
uniform vec4 moss_color : source_color = vec4(0.36, 0.55, 0.2, 1.0);
uniform float moss_amount = 0.0;
/** Light added in the shade, like the bright painted shadows of the diorama. */
uniform float shade_fill = 0.18;

varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash(i), hash(i + vec3(1.0, 0.0, 0.0)), f.x);
	float b = mix(hash(i + vec3(0.0, 1.0, 1.0)), hash(i + vec3(1.0, 1.0, 1.0)), f.x);
	return mix(a, b, f.y * 0.5 + f.z * 0.5);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// COLOR (vertex x instance color) and source_color uniforms arrive already linear.
	vec3 base = COLOR.rgb;
	float n = value_noise(world_pos / brush_scale);
	// Patches snap to three steps, like separate brush dabs.
	float dab = floor(n * 3.0) / 2.0 - 0.5;
	vec3 col = base * (1.0 + dab * brush_strength * 2.0);
	float up = clamp(world_normal.y, 0.0, 1.0);
	col = mix(col, col * sun_tint.rgb * 1.25, up * sun_amount);
	float moss = smoothstep(0.35, 0.75, up + (n - 0.5) * 0.5) * moss_amount;
	col = mix(col, moss_color.rgb * (0.85 + n * 0.3), moss);
	ALBEDO = col;
	EMISSION = col * shade_fill;
	ROUGHNESS = 1.0;
}
