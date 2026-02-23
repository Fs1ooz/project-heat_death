shader_type canvas_item;

uniform sampler2D gradient : source_color;
uniform float frequency = 10.0;
uniform float ring_sharpness = 10.0;
uniform float wobble_strength = 0.02;
uniform float wobble_frequency = 13.0;
uniform float radius_mult : hint_range(0.01, 1.0, 0.01) = 0.5;

uniform float strength : hint_range(0.001, 0.1, 0.001) = 0.075;
uniform float dist_width : hint_range(0.0001, 0.1, 0.0001) = 0.04;
uniform float feather : hint_range(0.001, 1.0, 0.001) = 0.135;

uniform vec2 shockwave_positions[32];
uniform float shockwave_progresses[32];
uniform int shockwave_count = 0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;


void fragment() {
    float aspect_ratio = TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y;
    vec2 total_offset = vec2(0.0);
    vec4 final_color = vec4(0.0); // ← ora è vec4 invece di float

    for (int i = 0; i < shockwave_count; i++) {
        vec2 diff = UV - shockwave_positions[i];
        diff.x /= aspect_ratio;
        float dist = length(diff);

        float angle = atan(diff.y, diff.x);
        float wobble = sin(angle * wobble_frequency) * wobble_strength;
        float distorted_dist = dist + (wobble * dist);

        float current_radius = shockwave_progresses[i] * radius_mult;
        float life_fade = pow(smoothstep(1.0, 0.7, shockwave_progresses[i]), 1.2);

        float wave_pulse = sin((distorted_dist - current_radius) * frequency);
        float brightness = pow(1.0 - abs(wave_pulse), ring_sharpness);
        float edge_fade = smoothstep(0.1, 0.0, abs(dist - current_radius));

        // ← Campiona il gradient in base al progresso (0.0 = inizio, 1.0 = fine)
        vec4 grad_color = texture(gradient, vec2(shockwave_progresses[i], 0.5));
        final_color += grad_color * brightness * edge_fade * life_fade;

        float mask = (1.0 - smoothstep(current_radius - feather, current_radius, dist))
                   * smoothstep(current_radius - dist_width - feather, current_radius - dist_width, dist);
        vec2 dir = length(diff) > 0.0001 ? normalize(diff) : vec2(0.0);
        total_offset += dir * strength * mask * life_fade;
    }

    final_color = clamp(final_color, 0.0, 1.0);

	vec2 suv = SCREEN_UV;
    
    // Campiona lo schermo una sola volta usando solo l'offset totale della shockwave
    vec4 distorted_screen = texture(SCREEN_TEXTURE, suv - total_offset);

    COLOR = final_color + distorted_screen;
}