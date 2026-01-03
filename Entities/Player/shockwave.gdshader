shader_type canvas_item;

// Parametri estetici globali
uniform vec4 color : source_color = vec4(0.0, 0.6, 2.0, 1.0); 
uniform float frequency = 10.0;
uniform float ring_sharpness = 10.0;
uniform float wobble_strength = 0.02;
uniform float wobble_frequency = 13.0;

// Parametri passati dallo script
uniform vec2 shockwave_positions[32];
uniform float shockwave_progresses[32];
uniform int shockwave_count = 0;

void fragment() {
    float final_brightness = 0.0;
    
    // Usa UV invece di SCREEN_UV - questo è relativo al ColorRect
    float aspect_ratio = 1.0 / TEXTURE_PIXEL_SIZE.y * TEXTURE_PIXEL_SIZE.x;
    
    for (int i = 0; i < shockwave_count; i++) {
        // Usa UV invece di SCREEN_UV
        vec2 diff = UV - shockwave_positions[i];
        diff.x /= aspect_ratio; 
        float dist = length(diff);
        
        float angle = atan(diff.y, diff.x);
        float wobble = sin(angle * wobble_frequency) * wobble_strength;
        float distorted_dist = dist + (wobble * dist);
        
        float current_radius = shockwave_progresses[i] * 0.5; 
        
        float wave_pulse = sin((distorted_dist - current_radius) * frequency);
        
        float brightness = pow(1.0 - abs(wave_pulse), ring_sharpness);
        
        float edge_fade = smoothstep(0.1, 0.0, abs(dist - current_radius));
        float life_fade = smoothstep(1.0, 0.7, shockwave_progresses[i]);
		
        life_fade = pow(life_fade, 1.2);
        final_brightness += brightness * edge_fade * life_fade;
    }
    
    final_brightness = clamp(final_brightness, 0.0, 1.0);
    
    COLOR = vec4(color.rgb * final_brightness, final_brightness * color.a);
}