	shader_type canvas_item;

	uniform float pixel_scale = 4.0;

	void vertex() {
		// Spinge la posizione al pixel più vicino
		VERTEX = floor(VERTEX / pixel_scale + 0.5) * pixel_scale;
	}

void fragment() {
	vec2 uv = UV;
	uv = floor(uv * TEXTURE_PIXEL_SIZE / pixel_scale) * pixel_scale / TEXTURE_PIXEL_SIZE;
	COLOR = texture(TEXTURE, uv) * COLOR;
}