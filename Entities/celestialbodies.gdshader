shader_type canvas_item;
render_mode world_vertex_coords, blend_mix;

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_value : hint_range(0.0, 1.0, 0.1) = 0.0;

group_uniforms Outline;
// Colore freddo: separa i nemici dall'ambra del player e dal viola dello sfondo.
uniform vec4 outline_color : source_color = vec4(0.70, 0.88, 1.0, 1.0);
// Spessore in PIXEL DI SCHERMO: resta costante sia con sprite.scale 25x che 125x,
// e a qualunque zoom della camera.
uniform float outline_width : hint_range(0.0, 8.0) = 2.0;
// Tetto in texel: i frame sono tile 128x128 dentro un atlante, con ~6px di margine
// trasparente. Oltre questo raggio il campionamento sconfina nel frame vicino.
uniform float outline_max_texels : hint_range(1.0, 12.0) = 5.0;

group_uniforms Pulse;
uniform float pulse_speed = 2.2;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.70;
uniform float pulse_max : hint_range(0.0, 1.0) = 1.0;
uniform float pulse_phase = 0.0;

group_uniforms Threat;
// 0 = innocuo/mangiabile, 1 = colpo letale. Lo imposta celestial_body.gd.
uniform float threat : hint_range(0.0, 1.0) = 0.0;
uniform bool threat_enabled = true;
uniform vec4 threat_safe_color : source_color = vec4(0.45, 1.0, 0.60, 1.0);   // verde: lo ingoi
uniform vec4 threat_mid_color : source_color = vec4(0.85, 1.0, 0.35, 1.0);    // giallo-verde: graffio
uniform vec4 threat_warn_color : source_color = vec4(1.0, 0.62, 0.15, 1.0);   // ambra: ti fa male
uniform vec4 threat_danger_color : source_color = vec4(1.0, 0.20, 0.16, 1.0); // rosso: ti stende

varying flat vec4 modulate;

// Performs smooth sampling of a texture using screen-space derivatives
vec4 sampleTextureSmooth(sampler2D textureSampler, vec2 uvCoords, vec2 texelSize)
{
	vec2 screenDerivX = dFdx(uvCoords);
	vec2 screenDerivY = dFdy(uvCoords);
	vec2 gradientLength = sqrt(screenDerivX * screenDerivX + screenDerivY * screenDerivY);
	vec2 uvInPixels = uvCoords / texelSize;
	vec2 pixelCenter = round(uvInPixels) - vec2(0.5f);
	vec2 offsetFromCenter = uvInPixels - pixelCenter;
	offsetFromCenter = clamp((offsetFromCenter - vec2(0.5f)) * texelSize / gradientLength + vec2(0.5f), 0.0f, 1.0f);
	vec2 adjustedUV = pixelCenter * texelSize;
	return textureGrad(textureSampler, adjustedUV + offsetFromCenter * texelSize, screenDerivX, screenDerivY);
}

// Alpha massima trovata su due anelli di campioni attorno al pixel: quanto "silhouette"
// c'e' nel vicinato. Anello doppio (largo + stretto) per non lasciare buchi sugli spigoli.
float silhouette_near(vec2 uv, vec2 texel, float radius_texels, sampler2D tex) {
	const int TAPS = 16;
	float found = 0.0;
	for (int i = 0; i < TAPS; i++) {
		float a = float(i) * (6.2831853 / float(TAPS));
		vec2 dir = vec2(cos(a), sin(a));
		vec2 outer = uv + dir * texel * radius_texels;
		vec2 inner = uv + dir * texel * (radius_texels * 0.55);
		// clamp: mai campionare fuori dall'atlante
		outer = clamp(outer, vec2(0.0), vec2(1.0));
		inner = clamp(inner, vec2(0.0), vec2(1.0));
		found = max(found, max(texture(tex, outer).a, texture(tex, inner).a));
	}
	return found;
}

void vertex() {
	modulate = COLOR;
}

void fragment()
{
	// Smooth pixel sampling
	vec4 sampledColor = sampleTextureSmooth(TEXTURE, UV, TEXTURE_PIXEL_SIZE);

	// Apply modulation
	vec4 col = vec4(sampledColor.rgb * modulate.rgb, sampledColor.a * modulate.a);

	// --- Outline ---
	// Converte outline_width (pixel schermo) in texel: le derivate dicono quanti texel
	// copre un pixel di schermo, quindi lo spessore non dipende da scale ne' da zoom.
	// NB: le derivate vanno calcolate fuori da rami non uniformi, altrimenti sono indefinite.
	vec2 texel = TEXTURE_PIXEL_SIZE;
	float texels_per_px = max(length(dFdx(UV) / texel), length(dFdy(UV) / texel));
	float radius = min(outline_width * texels_per_px, outline_max_texels);

	if (outline_width > 0.0 && col.a < 1.0) {
		float edge = silhouette_near(UV, texel, radius, TEXTURE);
		// disegna solo dove il corpo non c'e' gia': l'outline sta nel bordo trasparente
		float outline_a = edge * (1.0 - col.a);

		if (outline_a > 0.0) {
			vec3 tint = outline_color.rgb;
			float speed = pulse_speed;
			float pmin = pulse_min;

			if (threat_enabled) {
				// Rampa a tre tratti: verde -> azzurro -> ambra -> rosso. L'ambra serve:
				// interpolando azzurro->rosso in RGB si passa da un rosa slavato che non
				// legge come "pericolo crescente".
				if (threat < 0.25) {
					tint = mix(threat_safe_color.rgb, threat_mid_color.rgb, threat / 0.25);
				} else if (threat < 0.6) {
					tint = mix(threat_mid_color.rgb, threat_warn_color.rgb, (threat - 0.25) / 0.35);
				} else {
					tint = mix(threat_warn_color.rgb, threat_danger_color.rgb, (threat - 0.6) / 0.4);
				}
				// piu' e' pericoloso, piu' il battito e' rapido e profondo
				speed = mix(1.2, 7.0, threat);
				pmin = mix(0.85, 0.30, threat);
			}

			float pulse = mix(pmin, pulse_max,
				sin(TIME * speed + pulse_phase) * 0.5 + 0.5);
			outline_a *= outline_color.a * pulse * modulate.a;
			col.rgb = mix(tint, col.rgb, col.a);
			col.a = max(col.a, outline_a);
		}
	}

	// Apply flash effect (sopra tutto, cosi' lampeggia anche l'outline)
	col.rgb = mix(col.rgb, flash_color.rgb, flash_value);

	COLOR = col;
}
