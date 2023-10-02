shader_type canvas_item;

uniform vec4 tint_color: source_color;
uniform float tint_effect_factor : hint_range(0, 1) = 0.1;
uniform float multiplier = 0.4;
uniform float softness = 0.5;
uniform float brightness = 0.0;

mat4 brightnessMatrix( float _brightness ){
    return mat4( vec4(1, 0, 0, 0),
                 vec4(0, 1, 0, 0),
                 vec4(0, 0, 1, 0),
                 vec4(_brightness, _brightness, _brightness, 1));
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec4 c2 = c * tint_color;
	COLOR = brightnessMatrix(brightness - 0.2) * mix(c * 2.0, c2, tint_effect_factor);
	float value = distance(UV, vec2(0.5)); // center
	COLOR.a = 0.65-vec4(COLOR.rgb, smoothstep(multiplier, softness, value)).a;
}
