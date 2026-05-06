shader_type canvas_item;
render_mode unshaded;

// ============================================================
//  ASTEROID SHADER
//  Da applicare allo Sprite2D che mostra il SubViewport 3D.
//  La luce e la rotazione sono gestite dal 3D — questo shader
//  aggiunge gli effetti 2D: flash, pixel art, palette, atmosfera.
// ============================================================


// ---- Flash hit effect ----------------------------------------
uniform vec4  flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_value : hint_range(0.0, 1.0, 0.01) = 0.0;


// ---- Pixel art -----------------------------------------------
// Deve corrispondere alla dimensione del SubViewport (es. 64, 128, 256)
uniform bool  pixelate = true;
uniform float pixel_scale   = 256.0;



// ---- Palette -------------------------------------------------
// Opzionale: quantizza i colori del render 3D a una palette pixel art.
// Lascia vuota per usare i colori del render 3D direttamente.
uniform bool      use_palette = false;
uniform sampler2D surface_palette : filter_nearest, hint_default_white;

const float COLOUR_ESTIMATION_CUTOFF = 0.001;

const vec3 DEFAULT_ROCK_PALETTE[16] = vec3[16](
    vec3(0.05, 0.04, 0.04), // Quasi nero
    vec3(0.12, 0.10, 0.09), // Nero roccia
    vec3(0.18, 0.15, 0.13), // Grigio scurissimo
    vec3(0.25, 0.21, 0.18), // Grigio scuro
    vec3(0.32, 0.27, 0.23), // Grigio medio-scuro
    vec3(0.40, 0.34, 0.29), // Grigio medio
    vec3(0.48, 0.41, 0.35), // Grigio
    vec3(0.55, 0.48, 0.41), // Grigio medio-chiaro
    vec3(0.62, 0.55, 0.47), // Grigio chiaro
    vec3(0.68, 0.61, 0.53), // Grigio sabbia
    vec3(0.73, 0.66, 0.58), // Beige roccia
    vec3(0.78, 0.71, 0.63), // Beige chiaro
    vec3(0.83, 0.77, 0.69), // Grigio chiarissimo
    vec3(0.88, 0.83, 0.76), // Quasi bianco roccia
    vec3(0.93, 0.89, 0.83), // Bianco sporco
    vec3(1.00, 1.00, 1.00)  // Bianco puro (crateri illuminati)
);

vec3 get_nearest_colour(in sampler2D palette, in vec3 target) {
    ivec2 palette_size = textureSize(palette, 0);
    vec3  closest      = vec3(0.0);
    float min_dist     = 2.0;

    if (palette_size.x <= 1) {
        for (int i = 0; i < 16; i++) {
            vec3  c = DEFAULT_ROCK_PALETTE[i];
            float d = length(c - target);
            if (d < min_dist) {
                min_dist = d;
                closest  = c;
                if (d < COLOUR_ESTIMATION_CUTOFF) return c;
            }
        }
        return closest;
    }

    for (int row = 0; row < palette_size.y; row++) {
        float yuv = 1.0 / (2.0 * float(palette_size.y)) + float(row) / float(palette_size.y);
        for (int col = 0; col < palette_size.x; col++) {
            float xuv = 1.0 / (2.0 * float(palette_size.x)) + float(col) / float(palette_size.x);
            vec3  c   = texture(palette, vec2(xuv, yuv)).rgb;
            float d   = length(c - target);
            if (d < min_dist) {
                min_dist = d;
                closest  = c;
                if (d < COLOUR_ESTIMATION_CUTOFF) return c;
            }
        }
    }
    return closest;
}


// ---- Posterizzazione -----------------------------------------
uniform bool      posterise             = false;
uniform sampler2D posterisation_palette : filter_nearest, hint_default_black;


// ---- Atmosfera (rim glow) ------------------------------------
// Aggiunge un alone colorato sul bordo di Vesta.
// Funziona leggendo l'alpha del render 3D: bassa alpha = bordo = glow.
uniform bool      use_atmosphere    = false;
uniform vec4      atmosphere_color  : source_color = vec4(0.3, 0.5, 1.0, 1.0);
uniform float     atmosphere_width  : hint_range(0.0, 0.5, 0.01) = 0.08;
uniform float     atmosphere_intensity : hint_range(0.0, 2.0, 0.01) = 0.6;


void fragment() {
    // UV pixelate (pixel art crisp)
	vec2 grid_uv = pixelate
	    ? round(UV * pixel_scale) / pixel_scale
	    : UV;

    // Campiona il render 3D del SubViewport
    vec4 color = texture(TEXTURE, grid_uv);

    // Pixel trasparente = fuori da Vesta
    if (color.a < 0.01) {
        COLOR = vec4(0.0);
    } else {
        // Palette quantization
        if (use_palette) {
            color.rgb = get_nearest_colour(surface_palette, color.rgb);
        }

        // Posterizzazione
        if (posterise) {
            color.rgb = get_nearest_colour(posterisation_palette, color.rgb);
        }

        COLOR = color;

        // Atmosfera: rim glow sui bordi
        if (use_atmosphere) {
            float rim_step = atmosphere_width / pixel_scale;
            float a_r = texture(TEXTURE, grid_uv + vec2(rim_step, 0.0)).a;
            float a_l = texture(TEXTURE, grid_uv - vec2(rim_step, 0.0)).a;
            float a_u = texture(TEXTURE, grid_uv + vec2(0.0,  rim_step)).a;
            float a_d = texture(TEXTURE, grid_uv - vec2(0.0,  rim_step)).a;
            float rim = 1.0 - min(min(a_r, a_l), min(a_u, a_d));
            rim = smoothstep(0.0, 1.0, rim) * atmosphere_intensity;
            COLOR.rgb = mix(COLOR.rgb, atmosphere_color.rgb, clamp(rim, 0.0, 1.0));
        }

        // Flash hit effect
        if (flash_value > 0.0) {
            COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_value);
        }
    }
}
