shader_type canvas_item;

uniform float star_density : hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float asteroid_count : hint_range(0.0, 1.0, 0.01) = 0.08;
uniform float scroll_speed : hint_range(0.0, 2.0, 0.1) = 0.5;
uniform vec3 space_color : source_color = vec3(0.02, 0.01, 0.05);

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vec2 hash2(vec2 p) {
    return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}

// Stelle a croce
vec3 stars(vec2 uv, float time, float parallax) {
    vec2 star_uv = uv + vec2(time * scroll_speed * parallax, 0.0);
    vec2 grid = floor(star_uv * 100.0);
    float h = hash(grid);
    
    if(h < star_density) {
        vec2 local_pos = fract(star_uv * 100.0) - 0.5;
        float twinkle = 0.7 + 0.3 * sin(time * 3.0 + h * 100.0);
        
        // Forma a croce
        bool is_star = (abs(local_pos.x) < 0.08 && abs(local_pos.y) < 0.25) || 
                       (abs(local_pos.y) < 0.08 && abs(local_pos.x) < 0.25);
        
        if(is_star) {
            float brightness = 0.9 + hash(grid + vec2(10.0)) * 0.2;
            return vec3(1.0, 0.98, 0.95) * brightness * twinkle;
        }
    }
    return vec3(0.0);
}

// Asteroidi (invariati, sono belli)
vec3 asteroids(vec2 uv, float time) {
    vec2 ast_uv = uv + vec2(time * scroll_speed * 0.4, 0.0);
    vec2 grid = floor(ast_uv * 30.0);
    float h = hash(grid);
    
    if(h < asteroid_count) {
        vec2 cell = fract(ast_uv * 30.0);
        vec2 pos = cell - (hash2(grid) * 0.3 + 0.35);
        
        float rotation = hash(grid + vec2(5.0)) * 6.28 + time * hash(grid + vec2(15.0)) * 0.5;
        float c = cos(rotation);
        float s = sin(rotation);
        pos = vec2(pos.x * c - pos.y * s, pos.x * s + pos.y * c);
        
        float size = hash(grid + vec2(25.0)) * 0.15 + 0.1;
        vec2 pixel_pos = floor(pos / (size * 0.2)) * (size * 0.2);
        float dist = length(pixel_pos);
        
        float shape = hash(floor(atan(pixel_pos.y, pixel_pos.x) * 3.0 / 3.14159) + grid);
        
        if(dist < size * (0.7 + shape * 0.3)) {
            float brightness = 0.15 + hash(pixel_pos + grid) * 0.15;
            float shade = 0.7 + 0.3 * sin(atan(pixel_pos.y, pixel_pos.x) + 2.0);
            return vec3(brightness * 1.1, brightness * 0.9, brightness * 0.7) * shade;
        }
    }
    return vec3(0.0);
}

void fragment() {
    vec2 uv = UV;
    vec3 color = space_color;
    
    // 3 layer di stelle a croce con parallasse
    color += stars(uv, TIME, 0.2) * 0.6;
    color += stars(uv * 1.3 + vec2(0.5), TIME, 0.5) * 0.8;
    color += stars(uv * 0.7 + vec2(0.3), TIME, 0.8);
    
    // Asteroidi
    vec3 ast = asteroids(uv, TIME);
    color = mix(color, ast, step(0.001, length(ast)));
    
    COLOR = vec4(color, 1.0);
}