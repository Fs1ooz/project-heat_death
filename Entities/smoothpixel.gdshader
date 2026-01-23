shader_type canvas_item;
render_mode world_vertex_coords, blend_mix;

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

varying flat vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment()
{
	vec4 sampledColor = sampleTextureSmooth(TEXTURE, UV, TEXTURE_PIXEL_SIZE);

	COLOR = vec4(sampledColor.rgb * modulate.rgb, sampledColor.a * modulate.a);
}