shader_type canvas_item;
uniform float strength : hint_range(0.0, 0.025, 0.0001) = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 offset = vec2(strength, 0.0);
	float r = texture(SCREEN_TEXTURE, SCREEN_UV - offset).r;
	float g = texture(SCREEN_TEXTURE, SCREEN_UV).g;
	float b = texture(SCREEN_TEXTURE, SCREEN_UV + offset).b;
	COLOR = vec4(r, g, b, 1.0);
}
