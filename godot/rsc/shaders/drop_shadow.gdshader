shader_type canvas_item;

uniform vec4 background_color : source_color;
uniform vec4 shadow_color : source_color;
// Currently pixels always in application size, so zooming in further wouldn't increase the size of the dropdown
// but changing that would also be relatively trivial
uniform vec2 offset_in_pixels;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {

	// Read screen texture
	vec4 current_color = textureLod(TEXTURE, UV, 0.0);
	vec4 offset_color = textureLod (TEXTURE, UV - (offset_in_pixels  * SCREEN_PIXEL_SIZE), 0.0);
	offset_color = ((offset_color * shadow_color) - current_color);

	if(current_color.a >= 0.1) {
		COLOR = current_color;
	} else {
		COLOR = mix(current_color, offset_color, 0.5);
	}
}