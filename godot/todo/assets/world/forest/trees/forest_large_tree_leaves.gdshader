shader_type spatial;

uniform sampler2D albedo;
uniform vec3 albedo_color: source_color;
uniform vec3 under_color: source_color;

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
	ALBEDO.rgb *= albedo_color * under_color;
	ALPHA = ALBEDO.g > 0.5 ? 1.0 : 0.0;
	ALPHA_SCISSOR_THRESHOLD = 1.0;
}