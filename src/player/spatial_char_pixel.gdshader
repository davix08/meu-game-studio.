// Pixel texture for the main character model (Lakebound), gameplay-programmer, 2026-11-19.
// Target: Godot 4.7 Mobile renderer, mid-range Android. Budget: 3 texture reads (box projection),
// no loops, no branches. Variants: none (one material per clothing group, same shader).
// The model (assets/characters/sully_fazendeiro.glb) has vertex colors but no UVs and no normals,
// so the pixel texture is projected from the three model axes and the facet normal comes from the
// screen derivatives (flat low-poly shading). An outfit color can replace the vertex color of a
// clothing group (Story 017) while keeping its light and dark parts.
shader_type spatial;
render_mode cull_disabled;

group_uniforms texture_look;
/** Grey pixel pattern, 0.5 = no change. Nearest filtering keeps the pixels crisp. */
uniform sampler2D pixel_tex : filter_nearest, repeat_enable, hint_default_white;
/** Pattern repeats per model unit (the model is about 4.6 units tall). */
uniform float texel_scale = 0.45;
/** How strongly the pattern darkens and lightens the color. */
uniform float detail = 0.35;
/** 1 when the vertex colors are sRGB and must be linearized. */
uniform float colors_srgb = 0.0;
group_uniforms outfit;
uniform vec4 override_color : source_color = vec4(1.0);
/** 0 keeps the model colors, 1 uses override_color. */
uniform float use_override = 0.0;
/** Brightness of the model's own color for this group, so highlights stay brighter. */
uniform float luma_ref = 0.5;
group_uniforms;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	// Facet normal of the model (for the projection weights) and of the view (for lighting).
	vec3 n_local = normalize(cross(dFdx(local_pos), dFdy(local_pos)));
	vec3 w = abs(n_local);
	w /= (w.x + w.y + w.z);
	float t = texture(pixel_tex, local_pos.yz * texel_scale).r * w.x
		+ texture(pixel_tex, local_pos.xz * texel_scale).r * w.y
		+ texture(pixel_tex, local_pos.xy * texel_scale).r * w.z;
	vec3 base = mix(COLOR.rgb, pow(COLOR.rgb, vec3(2.2)), colors_srgb);
	float luma = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	vec3 dressed = override_color.rgb * clamp(luma / max(luma_ref, 0.01), 0.6, 1.6);
	base = mix(base, dressed, use_override);
	ALBEDO = base * (1.0 + (t - 0.5) * 2.0 * detail);
	NORMAL = normalize(cross(dFdy(VERTEX), dFdx(VERTEX)));
	ROUGHNESS = 0.9;
}
