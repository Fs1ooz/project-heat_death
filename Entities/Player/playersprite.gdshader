shader_type canvas_item;
render_mode blend_mix;


// --- UNIFORMS COLOR ---
uniform vec4 global_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// --- UNIFORMS OUTLINE ---
group_uniforms Outline;
uniform sampler2D outline_gradient;
uniform float outline_width : hint_range(0, 10) = 1.0;
uniform int pattern : hint_range(0, 2) = 0; // 0: diamond, 1: circle, 2: square
uniform bool inside = false;
uniform bool add_margins = true;

// --- UNIFORMS FLASH ---
group_uniforms Flash;
uniform sampler2D flash_gradient_tex : repeat_enable;
uniform float flash_offset = 0.0;
uniform float flash_alpha : hint_range(0.0, 4.0) = 0.0;

// --- UNIFORMS SPIRAL ---
group_uniforms Spiral;
uniform bool add_spiral = true;
uniform sampler2D gradient_tex;
uniform float frequency: hint_range(1.0, 50.0, 0.1) = 1.0;
uniform float speed: hint_range(1.0, 50.0, 0.1) = 1.0;
uniform float brightness: hint_range(1.0, 50.0, 0.1) = 20.0;
uniform float balance: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float octaves: hint_range(1.0, 10.0, 1.0) = 1.0;
uniform float pixel_size = 256.0;
uniform float spiral_aspect_ratio : hint_range(0.1, 3.0) = 0.75;

// --- VARYINGS ---
varying flat vec4 modulate;

// --- FUNZIONI HELPER SPIRAL ---
vec4 sampleTextureSmooth(sampler2D textureSampler, vec2 uvCoords, vec2 texelSize) {
	vec2 screenDerivX = dFdx(uvCoords);
	vec2 screenDerivY = dFdy(uvCoords);
	vec2 gradientLength = sqrt(screenDerivX * screenDerivX + screenDerivY * screenDerivY);
	vec2 uvInPixels = uvCoords / texelSize;
	vec2 pixelCenter = round(uvInPixels) - vec2(0.5);
	vec2 offsetFromCenter = uvInPixels - pixelCenter;
	offsetFromCenter = clamp(
		(offsetFromCenter - vec2(0.5)) * texelSize / gradientLength + vec2(0.5),
		0.0,
		1.0
	);
	vec2 adjustedUV = pixelCenter * texelSize;
	return textureGrad(
		textureSampler,
		adjustedUV + offsetFromCenter * texelSize,
		screenDerivX,
		screenDerivY
	);
}

float draw_spiral(vec2 uv, float rotation) {
	float uv_radius = length(uv);
	float uv_phi = atan(uv.y, uv.x) + rotation;
	float spiral_phi = (log(uv_radius) * frequency - uv_phi) / TAU;
	float spiral_ceil_radius = exp((TAU * ceil(spiral_phi) + uv_phi) / frequency);
	float spiral_floor_radius = exp((TAU * floor(spiral_phi) + uv_phi) / frequency);
	return mix(
		mix(abs(uv_radius - spiral_ceil_radius),
			abs(uv_radius - spiral_floor_radius),
			balance),
		max(abs(uv_radius - spiral_ceil_radius),
			abs(uv_radius - spiral_floor_radius)),
		balance
	);
}

// --- FUNZIONI HELPER OUTLINE ---
bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D tex) {
	for (float i = -ceil(outline_width); i <= ceil(outline_width); i++) {
		float x = abs(i) > outline_width ? outline_width * sign(i) : i;
		float offset;

		if (pattern == 0) {
			offset = outline_width - abs(x);
		} else if (pattern == 1) {
			offset = floor(sqrt(pow(outline_width + 0.5, 2) - x * x));
		} else if (pattern == 2) {
			offset = outline_width;
		}

		for (float j = -ceil(offset); j <= ceil(offset); j++) {
			float y = abs(j) > offset ? offset * sign(j) : j;
			vec2 xy = uv + texture_pixel_size * vec2(x, y);

			if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(tex, xy).a <= 0.0) == inside) {
				return true;
			}
		}
	}

	return false;
}

void vertex() {
	if (add_margins) {
		VERTEX += (UV * 2.0 - 1.0) * outline_width;
	}
	modulate = COLOR;
}

void fragment() {
	vec2 uv = UV;

	// 1. Gestione Coordinate Outline
	if (add_margins) {
		vec2 texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(outline_width * 2.0));
		uv = (uv - texture_pixel_size * outline_width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;

		if (uv != clamp(uv, vec2(0.0), vec2(1.0))) {
			COLOR.a = 0.0;
		} else {
			COLOR = texture(TEXTURE, uv);
		}
	} else {
		COLOR = texture(TEXTURE, uv);
	}

	// 2. Logica Spirale (interno)
	if (COLOR.a > 0.0) {
		vec4 sampled = sampleTextureSmooth(TEXTURE, uv, TEXTURE_PIXEL_SIZE);

		vec2 spiral_uv = uv - 0.5;

		// PRIMA pixelizza (pixel quadrati)
		spiral_uv = floor(spiral_uv * pixel_size) / pixel_size;

		// POI applica aspect ratio (distorce solo la spirale, non i pixel)
		spiral_uv.x *= spiral_aspect_ratio;

		// Calcola la spirale
		float spiral = 0.0;
		if (add_spiral == true){
			for (float i = 0.0; i < octaves; i += 1.0)
				spiral += draw_spiral(spiral_uv, TIME * speed * (0.5 + sin(i)));
				}
		spiral /= octaves;

		float r = clamp(length(spiral_uv), 0.0, 1.0);
		vec3 gradient_color = texture(gradient_tex, vec2(r, 0.0)).rgb;
		vec3 spiral_final_color = spiral * gradient_color * brightness;
		if (add_spiral == true)
			COLOR = vec4(spiral_final_color * modulate.rgb, sampled.a * modulate.a);
		else
			COLOR = vec4(modulate.rgb, sampled.a * modulate.a);
	}

	// 3. Logica Outline con GRADIENTE
	if ((COLOR.a > 0.0) == inside && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
		vec4 out_grad_col = texture(outline_gradient, UV);
		COLOR.rgb = inside ? mix(COLOR.rgb, out_grad_col.rgb, out_grad_col.a) : out_grad_col.rgb;
		COLOR.a += (1.0 - COLOR.a) * out_grad_col.a;
	}

	if (flash_alpha > 0.0 && COLOR.a > 0.0) {
		vec3 flash_col = texture(flash_gradient_tex, vec2(fract(UV.x + flash_offset), 0.5)).rgb;
		COLOR.rgb = mix(COLOR.rgb, flash_col, flash_alpha);
	}

	COLOR *= global_tint;

	if (COLOR.a <= 0.0) {
		discard;
	}
}