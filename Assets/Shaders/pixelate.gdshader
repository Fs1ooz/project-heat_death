shader_type canvas_item;

uniform float pixel_scale = 128.0;

void fragment() {
    vec2 uv = floor(UV * pixel_scale) / pixel_scale;
    COLOR = texture(TEXTURE, uv) * COLOR;
}