shader_type canvas_item;

uniform float t;
uniform sampler2D grad_tex; // piccola texture 1x256 con colori arcobaleno

void fragment() {
    vec2 uv = UV;
    
    float fade = smoothstep(1.0, 0.0, uv.y); // dissolvenza verso la fine
    float noise = fract(sin(dot(uv*25.0 , vec2(12.9898,78.233))) * 43758.5453);

    // variazione temporale
    float shift = fract(uv.y + t * 0.6);

    // campiona la texture gradiente per dare la paletta arcobaleno
    vec4 col = texture(grad_tex, vec2(shift, 0.0));

    col.rgb += noise * 0.1; // piccoli scintilli
    col.a *= fade;

    COLOR = col;
}
