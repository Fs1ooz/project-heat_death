shader_type canvas_item;

uniform float dust_strength : hint_range(0.0, 5.0) = 3.0;
uniform vec3 dust_color : source_color = vec3(0.8, 0.34, .43);
uniform float arm_count : hint_range(0.0, 10.0) = 5.0;
uniform float arm_compression : hint_range(0.0, 1.0) = 0.1;
uniform float core_radius : hint_range(0.0, 1.0) = 0.25;
uniform vec3 core_color : source_color = vec3(.98, 0.8, 0.79);
uniform float galaxy_radius : hint_range(0.1, 2.0) = 0.5;
uniform float rotation_speed : hint_range(0.0, 1.0) = 0.1;
uniform vec3 sky_color : source_color = vec3(0.23, 0.08, 0.14);
uniform float star_size : hint_range(0.1, 2.0) = 0.537;
uniform vec2 galaxy_center = vec2(0.5, 0.5);

uniform sampler2D noise_texture_1;
uniform sampler2D noise_texture_2;

float get_noise_value(vec2 uv) {
	float n = texture(noise_texture_1, uv).r;
	return 1.0 - abs(2.0 * n - 1.0);
}

float turbulent_noise(vec2 uv) {
	float value = 0.0;
	float angle = -rotation_speed * TIME;
	mat2 rotation_matrix = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
	
	float scale = 1.0;
	for (int i = 0; i < 7; i++) {
		uv = rotation_matrix * uv;
		float noise_val = get_noise_value(uv * scale);
		value += (1.0 / scale) * pow(noise_val, dust_strength);
		scale *= 2.0;
	}
	
	return value / 2.0;
}


void fragment() {
	vec2 uv = UV - galaxy_center;
	
	float aspect_ratio = TEXTURE_PIXEL_SIZE.y / TEXTURE_PIXEL_SIZE.x;
uv.x *= aspect_ratio;
	uv.x *= aspect_ratio;
	float rho = length(uv);
	float ang = atan(uv.y, uv.x);
	float shear = 2.0 * log(rho);
	mat2 shear_matrix = mat2(vec2(cos(shear), -sin(shear)), vec2(sin(shear), cos(shear)));

	float disk_density = exp(-pow(rho / galaxy_radius, 2.0));
	float core_glow = exp(-pow(rho / core_radius, 2.0));
	
	float phase = arm_count * (ang - shear);
	float arm_warp_angle = ang - arm_compression * cos(phase) + rotation_speed * TIME;
	vec2 warped_uv = rho * vec2(cos(arm_warp_angle), sin(arm_warp_angle));
	
	float arm_density = 1.0 + arm_count * arm_compression * sin(phase);
	disk_density *= 0.7 * arm_density;	
	
	float dust = turbulent_noise(0.09 * 1.2 * shear_matrix * warped_uv);
	float dust_transparency = pow((1.0 - dust * disk_density), 2.0);

	float stars1 = texture(noise_texture_2, star_size * uv + 0.5).r;
	float stars2 = texture(noise_texture_1, star_size * uv + 0.5).r;
	float stars = pow(1.0 - (1.0 - stars1) * (1.0 - stars2), 5.0);
	
	vec3 final_color;
	final_color = mix(sky_color, dust_transparency * (1.7 * dust_color) + 1.2 * stars, disk_density);
	final_color = mix(final_color, 1.2 * core_color, core_glow);
		
	COLOR = vec4(final_color, 1.0);
}