shader_type canvas_item;

uniform float crack_progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D crack_texture; // Texture con linee di frattura
uniform float crack_intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    vec4 crack = texture(crack_texture, UV);
    
    // Le crepe diventano più visibili col danno
    float crack_alpha = crack.r * crack_progress * crack_intensity;
    vec3 darkened = original.rgb * (1.0 - crack_alpha * 0.5);
    
    COLOR = vec4(darkened, original.a);
}