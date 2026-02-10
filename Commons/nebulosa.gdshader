shader_type canvas_item;

// Colori della nebulosa (cambia questi per temi diversi)
uniform vec3 color1 : source_color = vec3(0.5, 0.1, 0.8); // viola
uniform vec3 color2 : source_color = vec3(0.1, 0.3, 0.9); // blu
uniform vec3 color3 : source_color = vec3(0.8, 0.2, 0.5); // rosa

// Controlli animazione
uniform float color_shift_speed : hint_range(0.0, 2.0, 0.1) = 0.3;
uniform float gradient_scale : hint_range(0.5, 5.0, 0.1) = 2.0;
uniform float pulse_speed : hint_range(0.0, 3.0, 0.1) = 0.5;
uniform float pulse_intensity : hint_range(0.0, 2.0, 0.05) = 0.2;

// Effetti aggiuntivi
uniform bool enable_shimmer = true;
uniform float shimmer_speed : hint_range(0.0, 5.0, 0.1) = 2.0;
uniform float alpha_intensity : hint_range(0.0, 1.0, 0.05) = 1.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5);
}

void fragment() {
    // Leggi la texture originale (usa l'alpha come maschera)
    vec4 original = texture(TEXTURE, UV);
    
    // Crea gradiente animato che si muove sulla nebulosa
    float gradient = sin(UV.x * gradient_scale + TIME * color_shift_speed) * 0.5 + 0.5;
    gradient += cos(UV.y * gradient_scale * 0.7 - TIME * color_shift_speed * 0.8) * 0.3;
    gradient = fract(gradient);
    
    // Interpola tra 3 colori
    vec3 color;
    if(gradient < 0.33) {
        color = mix(color1, color2, gradient * 3.0);
    } else if(gradient < 0.66) {
        color = mix(color2, color3, (gradient - 0.33) * 3.0);
    } else {
        color = mix(color3, color1, (gradient - 0.66) * 3.0);
    }
    
    // Effetto pulsazione (respiro della nebulosa)
    float pulse = sin(TIME * pulse_speed) * pulse_intensity + pulse_intensity + 0.5;
    color *= pulse;
    
    // Shimmer (scintillio locale)
    if(enable_shimmer) {
        vec2 shimmer_uv = floor(UV * 50.0);
        float shimmer_val = hash(shimmer_uv);
        float shimmer = sin(TIME * shimmer_speed + shimmer_val * 100.0) * 0.1 + 1.0;
        
        // Applica shimmer solo dove c'è opacità
        if(original.a > 0.3 && shimmer_val > 0.7) {
            color *= shimmer;
        }
    }
    
    // Mantieni la forma originale usando l'alpha della texture
    // Moltiplica per il colore originale per preservare i dettagli
    vec3 final_color = color * original.rgb;
    
    COLOR = vec4(final_color, original.a * alpha_intensity);
}