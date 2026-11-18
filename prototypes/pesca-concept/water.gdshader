// PROTOTYPE - NOT FOR PRODUCTION
// Question: Is the cast -> bite -> tension-fight loop tense and rewarding with one thumb on a phone?
// Date: 2026-11-18
shader_type canvas_item;

uniform vec4 shallow : source_color = vec4(0.24, 0.6, 0.74, 1.0);
uniform vec4 deep : source_color = vec4(0.08, 0.25, 0.46, 1.0);
uniform vec2 rect_size = vec2(800.0, 260.0);

void fragment() {
	vec2 p = floor(UV * rect_size / 2.0) * 2.0;
	float t = TIME;
	float w = sin(p.x * 0.07 + t * 1.3 + sin(p.y * 0.05 + t * 0.7) * 2.0) * sin(p.y * 0.13 - t * 1.0);
	vec4 c = mix(deep, shallow, clamp(UV.y * 1.3, 0.0, 1.0));
	if (w > 0.86) {
		c.rgb += vec3(0.26);
	} else if (w > 0.62) {
		c.rgb += vec3(0.07);
	}
	COLOR = c;
}
