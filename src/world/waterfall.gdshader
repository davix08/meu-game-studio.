// Waterfalls of the river cliff for Story 005 (Lakebound), gameplay-programmer, 2026-11-17.
// Target: Godot 4.7 Mobile renderer, mid-range Android. Budget: no texture reads, no loops, no
// branches; two sin and one smoothstep per fragment. Variants: none.
// UV.y runs from the top of the fall (0) to the bottom (1); streaks scroll down at fall_speed.
shader_type spatial;
render_mode cull_disabled;

group_uniforms look;
uniform vec4 water_color : source_color = vec4(0.62, 0.86, 0.98, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 0.99, 1.0, 1.0);
uniform float alpha = 0.85;
group_uniforms motion;
uniform float fall_speed = 2.5;
uniform float streak_scale = 9.0;
group_uniforms;

void fragment() {
	// Vertical streaks: columns of different phase moving down the fall.
	float col = sin(UV.x * streak_scale * 6.2831) * 0.5 + 0.5;
	float streak = smoothstep(0.4, 1.0, sin(UV.y * 14.0 - TIME * fall_speed * 4.0 + col * 3.0) * 0.5 + 0.5);
	// Whiter near the bottom where the water hits the pool.
	float base_foam = UV.y * UV.y;
	ALBEDO = mix(water_color.rgb, foam_color.rgb, clamp(streak * 0.6 + base_foam * 0.7, 0.0, 1.0));
	ROUGHNESS = 0.3;
	ALPHA = alpha;
}
