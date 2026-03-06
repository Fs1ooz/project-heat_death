shader_type canvas_item;
render_mode unshaded;

const int SHADING_MODE_NONE = 0;
const int SHADING_MODE_SMOOTH = 1;
const int SHADING_MODE_QUANT = 2;
const int SHADING_MODE_DITHER = 3;
const int SHADING_MODE_MAX = 4;

const float COLOUR_ESTIMATION_CUTOFF = 0.001;

// This should usually be set to the side of the rect that is displaying the
// planet, to match the size of pixels of sprites.
uniform float pixel_scale = 256.0;


//// Surface Generation Mode
uniform bool use_texture_surface = false; // false = procedural (gas giant), true = image-based (Earth)
uniform bool use_texture_clouds = false; // false = procedural clouds, true = image-based clouds


//// Surface
uniform float surface_radius : hint_range(0.01, 0.499, 0.001) = .499;

// Image-based surface (Earth mode)
uniform sampler2D surface_texture : filter_linear, hint_default_white;

// Palette for the surface - works for both modes
// Default: 16 color gradient for Earth (blues, greens, browns, whites)
// For gas giants: Use oranges, reds, browns for Jupiter-like, or blues for Neptune-like
uniform sampler2D surface_palette : filter_nearest, hint_default_white;

// Create a default 16-color Earth palette gradient
// Colors go from deep ocean blue -> shallow water -> beach -> grass -> forest -> mountain -> snow
const vec3 DEFAULT_EARTH_PALETTE[16] = vec3[16](
    vec3(0.051, 0.110, 0.235), // Deep ocean
    vec3(0.078, 0.169, 0.361), // Ocean
    vec3(0.110, 0.235, 0.490), // Ocean
    vec3(0.157, 0.329, 0.580), // Shallow ocean
    vec3(0.235, 0.463, 0.698), // Shallow water
    vec3(0.353, 0.580, 0.761), // Very shallow water
    vec3(0.761, 0.698, 0.502), // Beach sand
    vec3(0.639, 0.580, 0.420), // Dry sand
    vec3(0.361, 0.510, 0.282), // Grass green
    vec3(0.282, 0.420, 0.235), // Forest green
    vec3(0.200, 0.329, 0.169), // Dark forest
    vec3(0.420, 0.361, 0.282), // Mountain brown
    vec3(0.502, 0.439, 0.361), // Mountain rock
    vec3(0.698, 0.698, 0.698), // Mountain grey
    vec3(0.878, 0.878, 0.878), // Snow
    vec3(1.000, 1.000, 1.000)  // Pure snow white
);

uniform vec4 background_colour : source_color = vec4(0., 0., 0., 1.0);
uniform float surface_base_rotation : hint_range(0.0, 6.28, 0.1) = 0.0;
uniform float surface_rotation_speed : hint_range(-1.0, 1.0, 0.001) = 0.0;

// Procedural surface options (for gas giants / sun)
// Primary noise layer (main bands/features)
uniform int surface_primary_cell_amount = 10;
uniform float surface_primary_strength : hint_range(-5.0, 5.0, 0.01) = 1.0;
uniform vec3 surface_primary_period = vec3(9.5, 9.5, 9.5);

// Secondary noise (turbulence/detail)
uniform bool surface_secondary_enabled = false;
uniform int surface_secondary_cell_amount = 20;
uniform float surface_secondary_strength : hint_range(-5.0, 5.0, 0.01) = 0.3;
uniform vec3 surface_secondary_period = vec3(9.5, 9.5, 9.5);
uniform float surface_secondary_rotation : hint_range(0.0, 6.28, 0.1) = 0.0;
uniform float surface_secondary_rotation_speed : hint_range(-1.0, 1.0, 0.001) = 0.0;

// Tertiary noise (fine detail)
uniform bool surface_tertiary_enabled = false;
uniform int surface_tertiary_cell_amount = 30;
uniform float surface_tertiary_strength : hint_range(-5.0, 5.0, 0.01) = 0.3;
uniform vec3 surface_tertiary_period = vec3(9.5, 9.5, 9.5);
uniform float surface_tertiary_rotation : hint_range(0.0, 6.28, 0.1) = 0.0;
uniform float surface_tertiary_rotation_speed : hint_range(-1.0, 1.0, 0.001) = 0.0;

// Band distortion for gas giants
uniform bool use_band_distortion = false;
uniform float band_frequency : hint_range(1.0, 50.0, 0.5) = 10.0;
uniform float band_distortion_strength : hint_range(0.0, 1.0, 0.01) = 0.3;


//// Clouds
uniform bool display_cloud_shadows = true;
uniform float cloud_shadow_darkness : hint_range(0.0, 1.0, 0.05) = 0.25;

// First cloud layer
uniform float cloud_1_cover : hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float cloud_1_radius : hint_range(0.01, 0.5, 0.001) = .5;

// Cloud texture (for image-based clouds)
uniform sampler2D cloud_1_texture : filter_linear, hint_default_transparent;

// Cloud palette - works for both procedural and image modes
// Default: 8 color gradient for clouds (whites and grays)
uniform sampler2D cloud_1_palette: filter_nearest, hint_default_transparent;

const vec3 DEFAULT_CLOUD_PALETTE[8] = vec3[8](
    vec3(0.502, 0.502, 0.502), // Dark gray shadow
    vec3(0.639, 0.639, 0.639), // Gray
    vec3(0.761, 0.761, 0.761), // Light gray
    vec3(0.831, 0.831, 0.831), // Lighter gray
    vec3(0.878, 0.878, 0.878), // Very light gray
    vec3(0.925, 0.925, 0.925), // Almost white
    vec3(0.969, 0.969, 0.969), // Near white
    vec3(1.000, 1.000, 1.000)  // Pure white
);

uniform float cloud_1_rotation_speed : hint_range(-1.0, 1.0, 0.001) = 0.03;
uniform float cloud_1_opacity : hint_range(0.0, 1.0, 0.01) = 0.8;

// Procedural cloud options
uniform int cloud_1_cell_amount = 10;
uniform float cloud_1_fluctuation_speed : hint_range(-1.0, 1.0, 0.001) = 0.03;
uniform vec3 cloud_1_period = vec3(9.5, 9.5, 9.5);
uniform vec3 cloud_1_secondary_period = vec3(9.5, 9.5, 9.5);
uniform int cloud_1_secondary_cell_amount = 10;
uniform float cloud_1_secondary_strength : hint_range(-1.0, 1.0, 0.01) = 0.3;

// Second cloud layer
uniform float cloud_2_cover : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float cloud_2_radius : hint_range(0.01, 0.5, 0.001) = .34;
uniform sampler2D cloud_2_texture : filter_linear, hint_default_transparent;
uniform sampler2D cloud_2_palette: filter_nearest, hint_default_transparent;
uniform float cloud_2_rotation_speed : hint_range(-1.0, 1.0, 0.001) = -0.02;
uniform float cloud_2_opacity : hint_range(0.0, 1.0, 0.01) = 0.5;

// Procedural options for cloud 2
uniform int cloud_2_cell_amount = 10;
uniform float cloud_2_fluctuation_speed : hint_range(-1.0, 1.0, 0.001) = 0.03;
uniform vec3 cloud_2_period = vec3(9.5, 9.5, 9.5);
uniform vec3 cloud_2_secondary_period = vec3(9.5, 9.5, 9.5);
uniform int cloud_2_secondary_cell_amount = 10;
uniform float cloud_2_secondary_strength : hint_range(-1.0, 1.0, 0.01) = 0.3;


//// Atmosphere
uniform float atmosphere_radius : hint_range(0.01, 0.5, 0.001) = .34;
uniform sampler2D atmosphere_palette : filter_nearest, hint_default_transparent;


//// Posterisation
uniform bool posterise = false;
uniform sampler2D posterisation_palette : filter_nearest, hint_default_black;


//// Light/shading
uniform int shading_mode : hint_enum(
	"None",
	"Smooth",
	"Quantised",
	"Dithered",
	"Max Brightness"
) = 2;
uniform float maximum_brightness : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float sun_strength = 2.0;
uniform float shade_transition = 10.0;
uniform float shade_step = 8.0;
uniform vec3 sun_direction = vec3(1.0, 0.2, -0.3);
uniform sampler2D dither_texture : filter_nearest;
uniform int dither_levels = 0;

// Noise for shading variation
uniform int shading_noise_cell_amount = 40;
uniform float shading_noise_strength : hint_range(-1.0, 1.0, 0.01) = 0.1;
uniform vec3 shading_noise_period = vec3(9.5, 9.5, 9.5);

// modulo function that returns positive wrapped values
vec3 modulo(vec3 divident, vec3 divisor){
	vec3 positiveDivident = mod(divident, divisor) + divisor;
	return mod(positiveDivident, divisor);
}

// 3D pseudo random number generator
vec3 random(vec3 value){
	vec3 return_value = vec3( dot(value, vec3(127.1,311.7, 201.9) ),
				  dot(value, vec3(269.5,183.3, 367.7) ),
				  dot(value, vec3(245.1,367.7, 105.6) ) );
	return -1.0 + 2.0 * fract(sin(return_value) * 43758.5453123);
}

// Calculate z-position of sphere surface
float calculate_z(vec2 uv, float radius) {
	float w = sqrt(pow(radius, 2.) - pow(uv.x - .5, 2.) - pow(uv.y - .5, 2.));
	return w;
}

// construct rotation matrix
mat3 generate_rotation_matrix(float theta) {
	vec3 rot_1 = vec3(
		.5*(1.-cos(theta)) + cos(theta),
		.5*(1.-cos(theta)),
		-(1./sqrt(2))*sin(theta)
	);
	vec3 rot_2 = vec3(
		.5*(1.-cos(theta)),
		.5*(1.-cos(theta)) + cos(theta),
		(1./sqrt(2))*sin(theta)
	);
	vec3 rot_3 = vec3(
		(1./sqrt(2))*sin(theta),
		-(1./sqrt(2))*sin(theta),
		cos(theta)
	);
	return mat3(rot_1, rot_2, rot_3);
}

// Put the UV on a pixel grid
vec2 calculate_grid_uv(vec2 uv) {
	return round(uv * pixel_scale) / pixel_scale;
}

// Get a default palette color if no texture is provided
vec3 get_default_palette_color(int index, bool is_cloud) {
	if (is_cloud) {
		int clamped = clamp(index, 0, 7);
		return DEFAULT_CLOUD_PALETTE[clamped];
	} else {
		int clamped = clamp(index, 0, 15);
		return DEFAULT_EARTH_PALETTE[clamped];
	}
}

// Return the colour from a palette that most closely matches target
vec3 get_nearest_colour(in sampler2D palette, in vec3 target, bool is_cloud) {
	ivec2 palette_size = textureSize(palette, 0);
	
	// Use default palette if texture is too small
	if (palette_size.x <= 1) {
		float min_dist = 2.0;
		vec3 closest_color = background_colour.rgb;
		int palette_length = is_cloud ? 8 : 16;
		
		for (int i = 0; i < palette_length; i++) {
			vec3 index_color = get_default_palette_color(i, is_cloud);
			float dist = length(index_color - target);
			if (dist < min_dist) {
				min_dist = dist;
				closest_color = index_color;
				if (min_dist < COLOUR_ESTIMATION_CUTOFF){
					return closest_color;
				}
			}
		}
		return closest_color;
	}
	
	// Use provided palette texture
	vec3 closest_color = background_colour.rgb;
	float min_dist = 2.0;
	
	for (int row = 0; row < palette_size.y; row++) {
		float yuv = 1.0 / (2.0 * float(palette_size.y)) + float(row) / float(palette_size.y);
		for (int column = 0; column < palette_size.x; column++){
			float xuv = 1.0 / (2.0 * float(palette_size.x)) + float(column) / float(palette_size.x);
			vec3 index_color = texture(palette, vec2(xuv,yuv)).rgb;
			float dist = length(index_color - target);
			if (dist < min_dist) {
				min_dist = dist;
				closest_color = index_color;
				if (min_dist < COLOUR_ESTIMATION_CUTOFF){
					return closest_color;
				}
			}
		}
	}
	return closest_color;
}

// Get dithering value
float get_leveled_dither(int level, vec2 uv) {
	ivec2 texture_size = textureSize(dither_texture, 0);
	int level_width = texture_size.x / dither_levels;

	float pattern_x = mod(uv.x * pixel_scale, float(level_width));
	pattern_x = pattern_x + float(level_width * level);
	float duvx = pattern_x / float(texture_size.x);

	float duvy = round(
		mod(uv.y * pixel_scale, float(texture_size.y))
	) / float(texture_size.y);

	vec2 dither_uv = vec2(duvx, duvy);
	return 1.0 - texture(dither_texture, dither_uv).a;
}

// Get color from palette by index
vec4 get_colour_by_index(sampler2D palette, int index, bool is_cloud) {
	ivec2 palette_size = textureSize(palette, 0);
	
	// Use default palette if texture is too small
	if (palette_size.x <= 1 || palette_size.y < 1) {
		vec3 color = get_default_palette_color(index, is_cloud);
		return vec4(color, 1.0);
	}
	
	// Use first row only for simplified palette
	float uvx = (1.0 / float(palette_size.x + 1)) * (float(index + 1));
	float uvy = 1.0 / (2.0 * float(palette_size.y));
	return texture(palette, vec2(uvx, uvy));
}

// Seamless noise function
float seamless_noise(vec2 uv, float w, vec3 _period, mat3 rot_p, int cell_amount) {
	vec3 uvw = rot_p * vec3(uv, w);
	uvw = vec3(uvw * float(cell_amount));
	vec3 cells_minimum = floor(uvw);
	vec3 cells_maximum = ceil(uvw);
	vec3 uvw_fract = fract(uvw);

	cells_minimum = modulo(cells_minimum, _period);
	cells_maximum = modulo(cells_maximum, _period);

	vec3 blur = smoothstep(0.3, 1.0, uvw_fract);

	vec3 p_000 = random(vec3(cells_minimum.x, cells_minimum.y, cells_minimum.z));
	vec3 p_100 = random(vec3(cells_maximum.x, cells_minimum.y, cells_minimum.z));
	vec3 p_010 = random(vec3(cells_minimum.x, cells_maximum.y, cells_minimum.z));
	vec3 p_110 = random(vec3(cells_maximum.x, cells_maximum.y, cells_minimum.z));
	vec3 p_001 = random(vec3(cells_minimum.x, cells_minimum.y, cells_maximum.z));
	vec3 p_101 = random(vec3(cells_maximum.x, cells_minimum.y, cells_maximum.z));
	vec3 p_011 = random(vec3(cells_minimum.x, cells_maximum.y, cells_maximum.z));
	vec3 p_111 = random(vec3(cells_maximum.x, cells_maximum.y, cells_maximum.z));

	return mix(mix( mix( dot( p_000, uvw_fract - vec3(0, 0, 0) ),
                     dot( p_100, uvw_fract - vec3(1, 0, 0) ), blur.x),
                mix( dot( p_010, uvw_fract - vec3(0, 1, 0) ),
                     dot( p_110, uvw_fract - vec3(1, 1, 0) ), blur.x), blur.y),
			mix( mix( dot( p_001, uvw_fract - vec3(0, 0, 1) ),
                     dot( p_101, uvw_fract - vec3(1, 0, 1) ), blur.x),
                mix( dot( p_011, uvw_fract - vec3(0, 1, 1) ),
                     dot( p_111, uvw_fract - vec3(1, 1, 1) ), blur.x), blur.y), blur.z) * 0.8 + 0.5;
}

// Calculate lighting
float calculate_light(vec2 grid_uv, float radius) {
	if (shading_mode == SHADING_MODE_NONE) {
		return 1.0;
	} else if (shading_mode == SHADING_MODE_MAX) {
		return maximum_brightness;
	}

	vec2 normalized_uv = (grid_uv - vec2(0.5)) / radius;
	vec3 sphere_point = vec3(
		normalized_uv.x,
		sqrt(max(0.0, 1.0 - dot(normalized_uv, normalized_uv))),
		normalized_uv.y
	);

	float light = dot(
		normalize(sphere_point),
		normalize(sun_direction)
	);
	float brightness_cap = maximum_brightness / sun_strength;

	if (shading_noise_strength != 0.0) {
		float w = calculate_z(grid_uv, radius);
		float noise = seamless_noise(
			grid_uv,
			w,
			shading_noise_period,
			mat3(1.0),
			shading_noise_cell_amount
		);
		if (!isnan(light)) {
			light = clamp(
				light + ((noise - 0.5) * shading_noise_strength),
				0.0,
				1.0
			);
		}
	}

	if (shading_mode == SHADING_MODE_SMOOTH) {
		light = sun_strength * min(
			brightness_cap,
			(light * shade_transition) / shade_step
		);
	} else if (shading_mode == SHADING_MODE_QUANT) {
		light = sun_strength * min(
			brightness_cap,
			floor(light * shade_transition) / shade_step
		);
	} else if (shading_mode == SHADING_MODE_DITHER) {
		light = sun_strength * min(
			brightness_cap,
			(light * shade_transition) / shade_step
		);

		for (int level = 0; level < dither_levels; level++) {
			float cutoff = float(level + 1) * (1.0 / float(dither_levels));
			if (light <= cutoff) {
				light = maximum_brightness * get_leveled_dither(level, grid_uv);
				break;
			}
		}
	}

	return light;
}

// Convert UV on sphere to spherical coordinates for texture mapping
vec2 uv_to_spherical(vec2 uv, float radius, float rotation) {
	vec2 centered = uv - vec2(0.5);
	float dist_from_center = length(centered);
	
	if (dist_from_center > radius) {
		return vec2(-1.0);
	}
	
	float z = sqrt(radius * radius - dist_from_center * dist_from_center);
	vec3 sphere_pos = vec3(centered.x, centered.y, z) / radius;
	
	float theta = atan(sphere_pos.x, sphere_pos.z);
	float phi = asin(sphere_pos.y);
	
	float tex_u = (theta + rotation) / (2.0 * 3.14159265359) + 0.5;
	float tex_v = phi / 3.14159265359 + 0.5;
	
	tex_u = fract(tex_u);
	
	return vec2(tex_u, tex_v);
}

// Apply surface noise layers
float apply_surface_noise(
	float perlin,
	vec3 period,
	vec2 uv,
	float w,
	mat3 rot_p,
	int cell_amount,
	float strength
) {
	if (isnan(perlin)) {
		return perlin;
	}
	float noise = seamless_noise(
		uv,
		w,
		period,
		rot_p,
		cell_amount
	);
	return clamp(
		perlin + ((noise - 0.5) * strength),
		0.0,
		1.0
	);
}

// Generate procedural surface (for gas giants/sun)
vec4 surface_procedural(vec2 uv, mat3 rot_p, mat3 rot_p2, mat3 rot_p3) {
	float w = calculate_z(uv, surface_radius);
	if (isnan(w)) {
		return vec4(0.0);
	}
	
	float perlin = seamless_noise(
		uv,
		w,
		surface_primary_period,
		rot_p,
		surface_primary_cell_amount
	);
	
	if (!isnan(perlin)) {
		perlin = clamp(
			((perlin - 0.5) * surface_primary_strength) + 0.5,
			0.0,
			1.0
		);
	}
	
	// Apply band distortion for gas giant effect
	if (use_band_distortion && !isnan(perlin)) {
		float band = sin((uv.y - 0.5) * band_frequency * 3.14159) * 0.5 + 0.5;
		perlin = mix(perlin, band, band_distortion_strength);
	}
	
	// Secondary noise layer
	if (surface_secondary_enabled) {
		perlin = apply_surface_noise(
			perlin,
			surface_secondary_period,
			uv,
			w,
			rot_p * rot_p2,
			surface_secondary_cell_amount,
			surface_secondary_strength
		);
	}
	
	// Tertiary noise layer
	if (surface_tertiary_enabled) {
		perlin = apply_surface_noise(
			perlin,
			surface_tertiary_period,
			uv,
			w,
			rot_p * rot_p3,
			surface_tertiary_cell_amount,
			surface_tertiary_strength
		);
	}
	
	// Map noise to palette colors
	vec4 color = background_colour;
	if (!isnan(perlin)) {
		ivec2 palette_size = textureSize(surface_palette, 0);
		int num_colors = (palette_size.x <= 1) ? 16 : palette_size.x;
		int color_index = int(perlin * float(num_colors - 1));
		color = get_colour_by_index(surface_palette, color_index, false);
	}
	
	// Apply lighting
	float light = calculate_light(uv, surface_radius);
	color.rgb = color.rgb * light;
	
	return color;
}

// Generate surface from Earth texture
vec4 surface_from_texture(vec2 uv, float rotation) {
	float w = calculate_z(uv, surface_radius);
	if (isnan(w)) {
		return vec4(0.0);
	}
	
	vec2 tex_coords = uv_to_spherical(uv, surface_radius, rotation);
	if (tex_coords.x < 0.0) {
		return vec4(0.0);
	}
	
	vec4 earth_color = texture(surface_texture, tex_coords);
	
	// Quantize to palette colors for pixelated effect
	earth_color.rgb = get_nearest_colour(surface_palette, earth_color.rgb, false);
	
	// Apply lighting
	float light = calculate_light(uv, surface_radius);
	earth_color.rgb = earth_color.rgb * light;
	
	return earth_color;
}

// Generate procedural clouds
vec4 clouds_procedural(
	float cover,
	vec2 uv,
	vec3 period,
	int cell_amount,
	vec3 noise_period,
	int noise_cell_amount,
	float noise_strength,
	mat3 rot_p,
	float radius,
	sampler2D palette,
	float fluctuation_speed,
	float opacity,
	bool shadow
) {
	if (cover == 0.0) {
		return vec4(0.0);
	}

	float w = calculate_z(uv, radius);
	if (isnan(w)) {
		return vec4(0.0);
	}
	
	float theta = TIME * fluctuation_speed;
	mat3 rot_0 = mat3(
		vec3(1, 0, 0),
		vec3(0, cos(theta), -sin(theta)),
		vec3(0, sin(theta), cos(theta))
	);

	float perlin = seamless_noise(
		uv,
		w,
		period,
		rot_0*rot_p,
		cell_amount
	);
	
	float noise = seamless_noise(
		uv,
		w,
		noise_period,
		rot_0*rot_p,
		noise_cell_amount
	);
	
	if (!isnan(perlin)) {
		perlin = clamp(
			perlin + ((noise - 0.5) * noise_strength),
			0.0,
			1.0
		);
	}

	float base_cutoff = 1.0 - cover;
	vec4 color = vec4(0.0);

	if (shadow) {
		if (perlin > base_cutoff && perlin <= 1.0) {
			color = vec4(0.0, 0.0, 0.0, cloud_shadow_darkness * opacity);
		}
	} else {
		if (perlin > base_cutoff) {
			// Map to palette
			float cloud_range = perlin - base_cutoff;
			float normalized = cloud_range / (1.0 - base_cutoff);
			
			ivec2 palette_size = textureSize(palette, 0);
			int num_colors = (palette_size.x <= 1) ? 8 : palette_size.x;
			int color_index = int(normalized * float(num_colors - 1));
			
			color = get_colour_by_index(palette, color_index, true);
			color.a = opacity;
			
			// Apply lighting
			float light = calculate_light(uv, radius);
			color.rgb = color.rgb * light;
		}
	}

	return color;
}

// Generate clouds from texture
vec4 clouds_from_texture(
	vec2 uv,
	float radius,
	sampler2D cloud_tex,
	sampler2D palette,
	float rotation,
	float opacity,
	bool is_shadow
) {
	float w = calculate_z(uv, radius);
	if (isnan(w)) {
		return vec4(0.0);
	}
	
	vec2 tex_coords = uv_to_spherical(uv, radius, rotation);
	if (tex_coords.x < 0.0) {
		return vec4(0.0);
	}
	
	vec4 cloud_color = texture(cloud_tex, tex_coords);
	
	if (is_shadow) {
		if (cloud_color.a > 0.1) {
			return vec4(0.0, 0.0, 0.0, cloud_shadow_darkness * cloud_color.a * opacity);
		}
		return vec4(0.0);
	} else {
		if (cloud_color.a > 0.1) {
			cloud_color.rgb = get_nearest_colour(palette, cloud_color.rgb, true);
			cloud_color.a *= opacity;
			
			float light = calculate_light(uv, radius);
			cloud_color.rgb = cloud_color.rgb * light;
		}
		return cloud_color;
	}
}

// Atmosphere rendering
vec4 atmosphere(vec2 uv) {
	vec4 result = vec4(0.0);
	
	if (atmosphere_radius <= surface_radius) {
		return result;
	}
	
	ivec2 palette_size = textureSize(atmosphere_palette, 0);
	float atmosphere_thickness = (atmosphere_radius - surface_radius);
	float atmos_layer_thickness = atmosphere_thickness / float(palette_size.x);
	
	for (int column = palette_size.x - 1; column >= 0; column--) {
		float radius = surface_radius + (atmos_layer_thickness * float(column + 1));
		float w = calculate_z(uv, radius);
		
		if (w < 1.0) {
			float light = calculate_light(uv, radius);
			result = vec4(texture(atmosphere_palette, vec2(float(column) / float(palette_size.x), 0.5)).rgb, 0.5);
			result.rgb = result.rgb * light;
		}
	}
	return result;
}

void fragment() {
	vec2 grid_uv = calculate_grid_uv(UV);
	
	// Calculate rotations
	float surface_rotation = surface_base_rotation + (TIME * surface_rotation_speed);
	float cloud_1_rotation = TIME * cloud_1_rotation_speed;
	float cloud_2_rotation = TIME * cloud_2_rotation_speed;
	
	// Surface rotation matrices for procedural mode
	mat3 srot = generate_rotation_matrix(surface_rotation);
	mat3 srot2 = generate_rotation_matrix(
		surface_secondary_rotation + (TIME * surface_secondary_rotation_speed)
	);
	mat3 srot3 = generate_rotation_matrix(
		surface_tertiary_rotation + (TIME * surface_tertiary_rotation_speed)
	);
	
	// Generate surface based on mode
	vec4 color;
	if (use_texture_surface && textureSize(surface_texture, 0).x > 1) {
		color = surface_from_texture(grid_uv, surface_rotation);
	} else {
		color = surface_procedural(grid_uv, srot, srot2, srot3);
	}
	
	// Cloud shadows
	vec4 cloud_1_shadows = vec4(0.0);
	vec4 cloud_2_shadows = vec4(0.0);
	
	// Cloud rotation matrix for procedural clouds
	mat3 crot1 = generate_rotation_matrix(cloud_1_rotation);
	mat3 crot2 = generate_rotation_matrix(cloud_2_rotation);
	
	// First cloud layer shadows
	if (display_cloud_shadows) {
		if (use_texture_clouds && textureSize(cloud_1_texture, 0).x > 1) {
			cloud_1_shadows = clouds_from_texture(
				grid_uv,
				surface_radius,
				cloud_1_texture,
				cloud_1_palette,
				cloud_1_rotation,
				cloud_1_opacity,
				true
			);
		} else if (cloud_1_cover > 0.0) {
			cloud_1_shadows = clouds_procedural(
				cloud_1_cover,
				grid_uv,
				cloud_1_period,
				cloud_1_cell_amount,
				cloud_1_secondary_period,
				cloud_1_secondary_cell_amount,
				cloud_1_secondary_strength,
				crot1,
				surface_radius,
				cloud_1_palette,
				cloud_1_fluctuation_speed,
				cloud_1_opacity,
				true
			);
		}
		
		// Second cloud layer shadows
		if (use_texture_clouds && textureSize(cloud_2_texture, 0).x > 1) {
			cloud_2_shadows = clouds_from_texture(
				grid_uv,
				surface_radius,
				cloud_2_texture,
				cloud_2_palette,
				cloud_2_rotation,
				cloud_2_opacity,
				true
			);
		} else if (cloud_2_cover > 0.0) {
			cloud_2_shadows = clouds_procedural(
				cloud_2_cover,
				grid_uv,
				cloud_2_period,
				cloud_2_cell_amount,
				cloud_2_secondary_period,
				cloud_2_secondary_cell_amount,
				cloud_2_secondary_strength,
				crot2,
				surface_radius,
				cloud_2_palette,
				cloud_2_fluctuation_speed,
				cloud_2_opacity,
				true
			);
		}
	}
	
	// Get cloud layers
	vec4 clouds_1 = vec4(0.0);
	vec4 clouds_2 = vec4(0.0);
	
	// First cloud layer
	if (use_texture_clouds && textureSize(cloud_1_texture, 0).x > 1) {
		clouds_1 = clouds_from_texture(
			grid_uv,
			cloud_1_radius,
			cloud_1_texture,
			cloud_1_palette,
			cloud_1_rotation,
			cloud_1_opacity,
			false
		);
	} else if (cloud_1_cover > 0.0) {
		clouds_1 = clouds_procedural(
			cloud_1_cover,
			grid_uv,
			cloud_1_period,
			cloud_1_cell_amount,
			cloud_1_secondary_period,
			cloud_1_secondary_cell_amount,
			cloud_1_secondary_strength,
			crot1,
			cloud_1_radius,
			cloud_1_palette,
			cloud_1_fluctuation_speed,
			cloud_1_opacity,
			false
		);
	}
	
	// Second cloud layer
	if (use_texture_clouds && textureSize(cloud_2_texture, 0).x > 1) {
		clouds_2 = clouds_from_texture(
			grid_uv,
			cloud_2_radius,
			cloud_2_texture,
			cloud_2_palette,
			cloud_2_rotation,
			cloud_2_opacity,
			false
		);
	} else if (cloud_2_cover > 0.0) {
		clouds_2 = clouds_procedural(
			cloud_2_cover,
			grid_uv,
			cloud_2_period,
			cloud_2_cell_amount,
			cloud_2_secondary_period,
			cloud_2_secondary_cell_amount,
			cloud_2_secondary_strength,
			crot2,
			cloud_2_radius,
			cloud_2_palette,
			cloud_2_fluctuation_speed,
			cloud_2_opacity,
			false
		);
	}
	
	// Compose final image
	COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	
	// Atmosphere
	COLOR.rgba = atmosphere(grid_uv);
	
	// Surface with shadows
	if (color.a > 0.0) {
		COLOR.rgba = color.rgba;
		COLOR.rgb = COLOR.rgb * (1.0 - cloud_1_shadows.a);
		COLOR.rgb = COLOR.rgb * (1.0 - cloud_2_shadows.a);
	}
	
	// Add clouds
	if (clouds_1.a > 0.0) {
		COLOR.rgb = mix(COLOR.rgb, clouds_1.rgb, clouds_1.a);
		COLOR.a = max(COLOR.a, clouds_1.a);
	}
	
	if (clouds_2.a > 0.0) {
		COLOR.rgb = mix(COLOR.rgb, clouds_2.rgb, clouds_2.a);
		COLOR.a = max(COLOR.a, clouds_2.a);
	}
	
	// Final posterization
	if (posterise) {
		COLOR.rgb = get_nearest_colour(posterisation_palette, COLOR.rgb, false);
	}
}