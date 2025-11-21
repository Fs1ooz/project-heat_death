shader_type canvas_item;

uniform vec4 core_color : source_color = vec4(0.9, 0.95, 1.0, 1.0);
uniform vec4 outer_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform float glow_intensity = 1.5;
uniform float core_size = 0.35;
uniform float halo_radius = 0.1;
uniform float tail_stretch = 1.0;
uniform vec2 tail_direction = vec2(-1.0, 0.0);
uniform float pixelation = 80.0;

void fragment() {
    // Pixelazione UV (PRIMA DI TUTTO)
    vec2 pix_uv = floor(UV * pixelation) / pixelation;

    // UV centrata (sostituisce quella originale)
    vec2 uv = pix_uv - vec2(0.5);
    
    // Direzione normalizzata della coda
    vec2 tail_dir = normalize(tail_direction);
    
    // Proiezione del punto sulla direzione della coda
    float tail_proj = dot(uv, tail_dir);
    
    // Allungamento coda
    vec2 stretched_uv = uv;
    if (tail_proj < 0.0) {
        stretched_uv = uv - tail_dir * tail_proj * (tail_stretch - 1.0);
    }
    
    float dist = length(stretched_uv);
    
    // Core luminoso
    float core = exp(-dist * dist / (core_size * core_size)) * glow_intensity;
    
    // Alone
    float halo = smoothstep(halo_radius, 0.0, dist);
    
    // Colori
    vec3 color = mix(outer_color.rgb, core_color.rgb, core);
    
    // Alpha
    float alpha = clamp(core + halo * 0.6, 0.0, 1.0);
	if (alpha < 0.01) {
	    discard; // elimina il pixel
	}

    
    COLOR = vec4(color, alpha);
}
