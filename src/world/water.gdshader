// Lake water for Story 002 (Lakebound 3D skeleton), gameplay-programmer, 2026-11-11.
// Target: Godot 4.7 Mobile renderer, mid-range Android. Budget: no texture reads, no loops,
// no branches; a few sin/mix/smoothstep per fragment, one sin*cos per vertex.
// Variants: none (one shader, one material).
// The mesh vertex color carries the water depth in COLOR.r (0 at the shore, 1 at the deepest
// point), so the color, the transparency and the shore foam come from the depth.
shader_type spatial;
render_mode cull_disabled;

uniform vec4 shallow_color : source_color = vec4(0.24, 0.78, 0.88, 1.0);
uniform vec4 deep_color : source_color = vec4(0.08, 0.40, 0.72, 1.0);
uniform vec4 foam_color : source_color = vec4(0.92, 0.98, 1.0, 1.0);
uniform vec4 glint_color : source_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform float alpha_shallow = 0.55;
uniform float alpha_deep = 0.92;
uniform float wave_height = 0.03;
uniform float wave_speed = 0.8;
uniform float wave_scale = 1.4;
uniform float foam_width = 0.18;
uniform float glint_strength = 0.6;

varying vec3 wpos;
varying float depth01;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	depth01 = COLOR.r;
	float w = sin(wpos.x * wave_scale + TIME * wave_speed) * cos(wpos.z * wave_scale * 0.8 - TIME * wave_speed * 0.7);
	VERTEX.y += w * wave_height * clamp(depth01 * 4.0, 0.0, 1.0);
}

void fragment() {
	float d = clamp(depth01, 0.0, 1.0);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, smoothstep(0.0, 0.85, d));
	float ripple = sin(wpos.x * 5.0 + TIME * 1.7) * sin(wpos.z * 4.3 - TIME * 1.3);
	col += vec3(0.05 * ripple);
	float shore = 1.0 - smoothstep(0.0, foam_width, d);
	float foam_wave = 0.5 + 0.5 * sin(wpos.x * 3.0 + wpos.z * 2.0 + TIME * 1.6);
	float foam = shore * (0.35 + 0.65 * foam_wave);
	float glint = pow(max(ripple, 0.0), 6.0) * glint_strength;
	ALBEDO = mix(col, foam_color.rgb, foam);
	EMISSION = glint_color.rgb * glint;
	ROUGHNESS = 0.2;
	ALPHA = clamp(mix(alpha_shallow, alpha_deep, d) + foam * 0.4, 0.0, 1.0);
}
