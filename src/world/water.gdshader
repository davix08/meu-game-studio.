// Lake water for Story 002 (Lakebound 3D skeleton), gameplay-programmer, 2026-11-11.
// Target: Godot 4.7 Mobile renderer, mid-range Android. Budget: no texture reads, no loops,
// no branches; a few sin/mix/smoothstep per fragment, one sin*cos per vertex.
// Variants: none (one shader, one material).
// The mesh vertex color carries the water depth in COLOR.r (0 at the shore, 1 at the deepest
// point), so the color, the transparency and the shore foam come from the depth.
// 2026-11-21: a seamless ripple picture (assets/water/ondas.png, from the user's water photo) is
// sampled twice in world space, scrolling in two directions, to give the surface real ripples
// and sparkles; 2 texture reads per fragment.
// Story 005: COLOR.g is 1 on river water, where stripes of foam run along flow_dir (the current).
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
// River current: direction on the ground (x, z), speed, stripe frequency and foam amount.
uniform vec2 flow_dir = vec2(-0.55, 0.83);
uniform float flow_speed = 1.6;
uniform float flow_scale = 2.4;
uniform float flow_strength = 0.45;

// Ripple picture: grey levels only (the color comes from shallow/deep_color).
uniform sampler2D ripple_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float ripple_scale = 0.18;
uniform float ripple_speed = 0.02;
uniform float ripple_strength = 0.55;
uniform float ripple_sparkle = 0.9;

varying vec3 wpos;
varying float depth01;
varying float river;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	depth01 = COLOR.r;
	river = COLOR.g;
	float w = sin(wpos.x * wave_scale + TIME * wave_speed) * cos(wpos.z * wave_scale * 0.8 - TIME * wave_speed * 0.7);
	VERTEX.y += w * wave_height * clamp(depth01 * 4.0, 0.0, 1.0);
}

void fragment() {
	float d = clamp(depth01, 0.0, 1.0);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, smoothstep(0.0, 0.85, d));
	float ripple = sin(wpos.x * 5.0 + TIME * 1.7) * sin(wpos.z * 4.3 - TIME * 1.3);
	col += vec3(0.015 * ripple);
	float shore = 1.0 - smoothstep(0.0, foam_width, d);
	float foam_wave = 0.5 + 0.5 * sin(wpos.x * 3.0 + wpos.z * 2.0 + TIME * 1.6);
	float foam = shore * (0.35 + 0.65 * foam_wave);
	vec2 uv_a = wpos.xz * ripple_scale + vec2(TIME * ripple_speed, TIME * ripple_speed * 0.6);
	vec2 uv_b = wpos.xz * ripple_scale * 1.7 + vec2(-TIME * ripple_speed * 0.7, TIME * ripple_speed * 0.45);
	float waves = (texture(ripple_tex, uv_a).r + texture(ripple_tex, uv_b).r) * 0.5;
	col *= mix(1.0, 0.6 + waves * 0.8, ripple_strength);
	float glint = pow(max(ripple, 0.0), 8.0) * glint_strength * 0.3 + pow(waves, 4.0) * ripple_sparkle;
	// Current: stripes moving along flow_dir, broken up across the flow by a slower wave.
	float along = dot(wpos.xz, flow_dir) * flow_scale - TIME * flow_speed;
	float across = dot(wpos.xz, vec2(-flow_dir.y, flow_dir.x));
	float stripes = smoothstep(0.55, 1.0, sin(along + sin(across * 1.7) * 1.3));
	foam = max(foam, stripes * flow_strength * river);
	ALBEDO = mix(col, foam_color.rgb, foam);
	EMISSION = glint_color.rgb * glint;
	ROUGHNESS = 0.2;
	ALPHA = clamp(mix(alpha_shallow, alpha_deep, d) + foam * 0.4, 0.0, 1.0);
}
