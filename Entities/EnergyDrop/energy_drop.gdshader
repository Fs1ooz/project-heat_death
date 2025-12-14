shader_type canvas_item;

uniform sampler2D noise_texture;
uniform float fade_distance = 0.3;
uniform float edge_softness = 0.2;

void fragment() {
    vec2 centered_uv = UV - vec2(0.5);
    float dist = length(centered_uv) * 2.0;
    
    // Maschera circolare morbida
    float circle_mask = 1.0 - smoothstep(1.0 - fade_distance, 1.0 - fade_distance + edge_softness, dist);
    
    vec4 noise = texture(noise_texture, UV);
    COLOR = noise;
    COLOR.a *= circle_mask;
}