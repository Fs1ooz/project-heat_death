shader_type canvas_item;

// ---- Flash hit effect ----------------------------------------
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_value : hint_range(0.0, 1.0, 0.01) = 0.0;

// ---- Pixel art -----------------------------------------------
uniform float pixel_scale = 128.0;

void fragment() {
    // Calcolo delle UV per l'effetto pixel art
    vec2 uv = floor(UV * pixel_scale) / pixel_scale;

    // Campionamento della texture moltiplicata per il modulate (COLOR)
    vec4 tex_color = texture(TEXTURE, uv) * COLOR;

    // Applicazione del flash sulla componente RGB
    // Se flash_value è 0, il colore resta invariato.
    // Se flash_value è 1, il colore diventa flash_color.
    tex_color.rgb = mix(tex_color.rgb, flash_color.rgb, flash_value);

    COLOR = tex_color;
}