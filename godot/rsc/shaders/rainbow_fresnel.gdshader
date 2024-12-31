shader_type spatial;

uniform float exponent = 4;
uniform float intensity = 4.5;
uniform vec3 color_factor : source_color = vec3(1.0, 1.0, 1.0);
uniform float color_multiplier = 1.0;
uniform float pulse_factor = 0.0;
uniform float core_factor = 0.5;
uniform float fresnel_multiplier = 8.0;

vec3 fresnel_glow(float expo, float inten, vec3 color, vec3 normal, vec3 view)
{
	return pow((1.0 - dot(-normalize(normal), -normalize(view))), expo) * color * inten;
}

void fragment() {
	float r = clamp(sin(TIME*2.0), 0.4, 1.0);
	float g = clamp(cos(TIME/2.0), 0.6, 1.0);
	float b = clamp(cos(TIME*2.0), 0.4, 1.0);

	vec3 color = vec3(r, g, b);
	color = color * (color_factor * color_multiplier); // Force a color
	color = (color * core_factor) + fresnel_glow(exponent * ((sin(TIME * 2.0 * pulse_factor) + 8.0) / 10.0), intensity, color * (fresnel_multiplier), NORMAL, VIEW);

	ALBEDO = color;
}
