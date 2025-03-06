shader_type canvas_item;

uniform vec2 screen_size = vec2(1920.0, 1080.0);  // Match map size
uniform vec4 fog_color = vec4(0.0, 0.0, 0.0, 0.9);  // Dark fog
uniform vec2 points[64];  // Fixed size matching RAY_COUNT
uniform int point_count;
uniform vec2 fog_position = vec2(0.0, 0.0);  // Position of the ColorRect in world space

// Check if a point is inside the polygon
bool point_in_polygon(vec2 p, vec2[64] poly, int count) {
    bool inside = false;
    for (int i = 0, j = count - 1; i < count; j = i++) {
        vec2 vi = poly[i];
        vec2 vj = poly[j];
        if (((vi.y > p.y) != (vj.y > p.y)) &&
            (p.x < (vj.x - vi.x) * (p.y - vi.y) / (vj.y - vi.y + 0.0001) + vi.x)) {  // Add small epsilon to avoid division by zero
            inside = !inside;
        }
    }
    return inside;
}

void fragment() {
    // Convert screen coordinates to world coordinates relative to fog position
    vec2 world_pos = FRAGCOORD.xy + fog_position;
    
    // Check if current pixel is inside LOS polygon
    if (point_in_polygon(world_pos, points, point_count)) {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);  // Transparent inside LOS
    } else {
        COLOR = fog_color;  // Opaque fog outside LOS
    }
}