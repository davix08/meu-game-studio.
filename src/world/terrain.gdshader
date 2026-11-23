// Ground of the farm (Lakebound), technical-artist, 2026-11-22.
// Target: Godot 4.7 Mobile renderer, mid-range Android. Budget: 1 texture read (mipmapped),
// one value noise, no loops. Variants: none.
// The ground keeps its vertex colors (grass patchwork, sand, lake bed); where the vertex color
// alpha says "dirt road" the road texture the user sent (assets/terrain/estrada.png, seamless)
// is drawn instead, projected from above, with a ragged edge into the grass.
shader_type spatial;
render_mode specular_disabled, cull_disabled;

uniform sampler2D road_tex : source_color, filter_linear_mipmap, repeat_enable;
/** Meters covered by one repeat of the road texture. */
uniform float road_tile = 3.0;
/** How ragged the road edge is (0 = smooth blend). */
uniform float edge_noise = 0.35;
/** Tint over the road texture (white = as painted). */
uniform vec4 road_tint : source_color = vec4(1.0);
/** Light graphics (phones): one noise octave instead of two. */
uniform bool cheap = false;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = cheap ? value_noise(world_pos.xz * 2.2) : value_noise(world_pos.xz * 1.7) * 0.6 + value_noise(world_pos.xz * 4.3) * 0.4;
	float road = smoothstep(0.42, 0.58, COLOR.a + (n - 0.5) * edge_noise);
	vec3 dirt = texture(road_tex, world_pos.xz / road_tile).rgb * road_tint.rgb;
	ALBEDO = mix(COLOR.rgb, dirt, road);
	ROUGHNESS = 1.0;
}
