// Textured main character (Lakebound), gameplay-programmer, 2026-11-19.
// Target: Godot 4.7 Mobile renderer, mid-range Android. Budget: 1 texture read, no loops, no
// branches. Variants: none (one material per clothing group, same shader).
// Draws the model's own texture (assets/characters/fazendeiro.glb) with crisp pixels. For the
// clothes shop (Story 017) a group can be recolored: "red" pixels (the shirt, the hat band) take
// red_color, the other pixels of the group take main_color; brightness is kept from the texture.
shader_type spatial;

group_uniforms texture_look;
uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_disable;
uniform float roughness = 0.9;
group_uniforms outfit;
uniform vec4 main_color : source_color = vec4(1.0);
/** 1 recolors the non-red pixels of this group. */
uniform float use_main = 0.0;
/** Brightness of those pixels in the texture (keeps light and dark parts after recoloring). */
uniform float main_ref = 0.3;
uniform vec4 red_color : source_color = vec4(1.0);
/** 1 recolors the red pixels of this group. */
uniform float use_red = 0.0;
uniform float red_ref = 0.1;
group_uniforms;

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	// How "red" the pixel is: red channel clearly above green and blue.
	float red = smoothstep(0.04, 0.12, c.r - max(c.g, c.b) * 1.2);
	vec3 as_red = red_color.rgb * clamp(luma / max(red_ref, 0.001), 0.4, 2.0);
	vec3 as_main = main_color.rgb * clamp(luma / max(main_ref, 0.001), 0.4, 2.0);
	vec3 col = mix(c, as_red, use_red * red);
	col = mix(col, as_main, use_main * (1.0 - red));
	ALBEDO = col;
	ROUGHNESS = roughness;
}
