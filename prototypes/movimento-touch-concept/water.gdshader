// PROTOTYPE - NOT FOR PRODUCTION
// Question: Does moving with a left virtual stick (+ run) across dock and shore feel immediate and comfortable?
// Date: 2026-11-13
shader_type canvas_item;

uniform vec4 shallow : source_color = vec4(0.22, 0.58, 0.74, 1.0);
uniform vec4 deep : source_color = vec4(0.09, 0.27, 0.48, 1.0);
uniform vec2 rect_size = vec2(520.0, 768.0);

void fragment() {
	vec2 p = floor(UV * rect_size / 2.0) * 2.0;
	float t = TIME;
	float w = sin(p.x * 0.07 + t * 1.4 + sin(p.y * 0.045 + t * 0.8) * 2.0) * sin(p.y * 0.12 - t * 1.1);
	vec4 c = mix(shallow, deep, clamp(UV.x * 1.6, 0.0, 1.0));
	if (w > 0.86) {
		c.rgb += vec3(0.28);
	} else if (w > 0.62) {
		c.rgb += vec3(0.07);
	}
	COLOR = c;
}
