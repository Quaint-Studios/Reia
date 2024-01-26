shader_type canvas_item;

uniform sampler2D gradient_a;
uniform sampler2D gradient_b;

vec3 overlay(vec3 a, vec3 b) {
	return mix(1.0 - 2.0 * (1.0 - a) * (1.0 - b), 2.0 * a * b, step(a, vec3(0.5)));
}

void fragment() {
	// Place fragment code here.
	vec4 color = texture(TEXTURE, UV);
	vec4 color_a = texture(gradient_a, UV);
	vec4 color_b = texture(gradient_b, UV);

	COLOR = color * vec4(overlay(color_a.rgb, color_b.rgb), 1.0);
}
