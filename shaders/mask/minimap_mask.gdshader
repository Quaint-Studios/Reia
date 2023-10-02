shader_type canvas_item;

uniform vec4 tint_color: source_color;
uniform float tint_effect_factor : hint_range(0, 1) = 0.1;
uniform float multiplier = 0.4;
uniform float softness = 0.5;
uniform float brightness = 0.0;

float inverse_smoothstep(float a, float b, float c) {
	if(c <= 0.2) return smoothstep(a, b, c/0.35);
	return a-sin(asin(1.0-2.0*b)/c);
}

float radial_smoothstep(float a, float b, float c) {
	if(c >= 0.2 && c <= 0.47) return smoothstep(a, b, c);
	else if(c < 0.2) return 0.0;
}

//---------------------------------------------
//BRIGHTNESS
//---------------------------------------------
mat4 brightnessMatrix( float _brightness ){
    return mat4( vec4(1, 0, 0, 0),
                 vec4(0, 1, 0, 0),
                 vec4(0, 0, 1, 0),
                 vec4(_brightness, _brightness, _brightness, 1));
}

void fragment() {
	// Screen texture stores gaussian blurred copies on mipmaps.
	// COLOR.rgba = textureLod(SCREEN_TEXTURE, SCREEN_UV, (1.0 - base.r) * 4.0).rgba;
	// COLOR.rgb *= texture(SCREEN_TEXTURE, SCREEN_UV).rgb;

	vec4 c = texture(TEXTURE, UV);
	vec4 c2 = c * tint_color;
	COLOR = brightnessMatrix(brightness - 0.2) * mix(c * 2.0, c2, tint_effect_factor);
	float value = distance(UV, vec2(0.5)); // center
	COLOR.a = 0.65-vec4(COLOR.rgb, smoothstep(multiplier, softness, value)).a;
}


