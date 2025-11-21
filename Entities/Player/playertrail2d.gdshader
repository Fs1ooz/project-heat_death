	shader_type canvas_item;

	uniform float pixel_scale = 10.0;

	void vertex() {
	    // Spinge la posizione al pixel più vicino
	    VERTEX = floor(VERTEX / pixel_scale + 0.5) * pixel_scale;
	}
