shader_type canvas_item;
render_mode world_vertex_coords, blend_mix;

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_value : hint_range(0.0, 1.0, 0.1) = 0.0;

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

void vertex() {
	modulate = COLOR;
}

void fragment()
{
	// Smooth pixel sampling
	vec4 sampledColor = sampleTextureSmooth(TEXTURE, UV, TEXTURE_PIXEL_SIZE);
	
	// Apply modulation
	vec4 modulatedColor = vec4(sampledColor.rgb * modulate.rgb, sampledColor.a * modulate.a);
	
	// Apply flash effect
	COLOR = mix(modulatedColor, flash_color, flash_value);
	COLOR.a = modulatedColor.a;
}