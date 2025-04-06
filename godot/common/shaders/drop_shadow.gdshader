shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;
uniform vec4 shadow_color;
uniform vec2 direction;

void fragment() {
	vec4 texture_data = texture(SCREEN_TEXTURE, SCREEN_UV);
	if(texture_data.a >= 0.3) {
		COLOR = texture_data;
	} else {
		vec4 shadow = vec4(0.0);
		shadow += texture(SCREEN_TEXTURE, SCREEN_UV) * 0.2270270270;
		shadow += texture(SCREEN_TEXTURE, SCREEN_UV + 2.0 * (direction / 100.0)) * 0.1216216216;
		shadow += texture(SCREEN_TEXTURE, SCREEN_UV + 3.0 * (direction / 100.0)) * 0.0540540541;
		shadow += texture(SCREEN_TEXTURE, SCREEN_UV + 4.0 * (direction / 100.0)) * 0.0162162162;
		shadow = shadow_color * vec4(100.0, 100.0, 100.0, shadow.w) / 1.0;
		
		COLOR = shadow;
	}
	
	// Sample the original content
    
}
