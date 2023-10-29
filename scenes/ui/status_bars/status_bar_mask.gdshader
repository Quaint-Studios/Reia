shader_type canvas_item;

uniform sampler2D mask;
// 1152x110 underlay
// 1246x177 health
// 1231x164 ether

void fragment() {
	COLOR = texture(TEXTURE, UV);

	vec2 muv = UV;
	muv.y = 1.0 - muv.y; // vertical center

	COLOR.a = texture(mask, muv).a;
}
