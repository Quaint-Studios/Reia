shader_type canvas_item;

uniform sampler2D gradient_a;
uniform sampler2D gradient_b;

void fragment() {
	// Place fragment code here.
	vec4 color = texture(TEXTURE, UV);
	vec4 color_a = texture(gradient_a, UV);
	vec4 color_b = texture(gradient_b, UV);

	COLOR = color * color_a * color_b;
}
