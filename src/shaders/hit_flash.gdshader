// Flashes a canvas item toward a solid color (hit feedback, parry feedback).
shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = COLOR;
	COLOR = vec4(mix(base.rgb, flash_color.rgb, flash_amount), base.a);
}
