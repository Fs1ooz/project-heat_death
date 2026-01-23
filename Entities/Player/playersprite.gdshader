shader_type canvas_item;
render_mode world_vertex_coords, blend_mix;

uniform vec2 resolution = vec2(128, 128);
uniform sampler2D gradient_tex;

uniform float frequency: hint_range(1.0, 50.0, 0.1) = 1.0;
uniform float speed: hint_range(1.0, 50.0, 0.1) = 1.0;
uniform float brightness: hint_range(1.0, 50.0, 0.1) = 20.0;
uniform float balance: hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float octaves: hint_range(1.0, 10.0, 1.0) = 1.0;
uniform float pixel_size = 128.0;

varying flat vec4 modulate;

// ---------- smoothing della texture ----------
vec4 sampleTextureSmooth(sampler2D textureSampler, vec2 uvCoords, vec2 texelSize)
{
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

// ---------- funzione spirale ----------
float draw_spiral(vec2 uv, float rotation)
{
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

void vertex() {
    modulate = COLOR;
}

void fragment()
{
    // --- smoothing texture originale ---
    vec4 sampled = sampleTextureSmooth(TEXTURE, UV, TEXTURE_PIXEL_SIZE);

    // discard corretto in base all’alpha della texture
    if (sampled.a < 0.1)
        discard;
	float aspect_ratio = resolution.x / resolution.y;
	
    // --- coordinate spirale pixelate ---
    vec2 uv = UV - 0.5;
	uv.x *= aspect_ratio;
    uv = floor(uv * pixel_size) / pixel_size;

    float spiral = 0.0;
    for (float i = 0.0; i < octaves; i += 1.0)
        spiral += draw_spiral(uv, TIME * speed * (0.5 + sin(i)));

    spiral /= octaves;

    float r = clamp(length(uv), 0.0, 1.0);
    vec3 gradient_color = texture(gradient_tex, vec2(r, 0.0)).rgb;

    vec3 spiral_color = spiral * gradient_color * brightness;

    // combina con modulate e alpha originale
    COLOR = vec4(spiral_color * modulate.rgb, sampled.a * modulate.a);
}
