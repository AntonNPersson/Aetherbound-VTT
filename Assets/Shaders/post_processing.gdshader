shader_type canvas_item;

// Controls for the edge detection and blur
uniform float edge_threshold = 0.1;    // How sensitive the edge detection is (0.05-0.2)
uniform float blur_strength = 1.5;     // How strong the blur effect is (1.0-5.0)
uniform int blur_samples = 6;          // How many samples to take for the blur (higher = smoother, more expensive)
uniform bool show_edges_only = false;  // Debug mode to show detected edges
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Function to check if a pixel is on a hard edge (high contrast)
bool is_edge(sampler2D tex, vec2 uv, float threshold) {
    // Sample neighboring pixels
    float pixel_size_x = 1.0 / float(textureSize(tex, 0).x);
    float pixel_size_y = 1.0 / float(textureSize(tex, 0).y);
    
    // Sample center pixel luminance
    vec3 center_color = texture(tex, uv).rgb;
    float center_lum = dot(center_color, vec3(0.299, 0.587, 0.114));
    
    // Sample neighboring pixels (cardinal directions)
    vec3 north_color = texture(tex, uv + vec2(0.0, pixel_size_y)).rgb;
    vec3 east_color = texture(tex, uv + vec2(pixel_size_x, 0.0)).rgb;
    vec3 south_color = texture(tex, uv + vec2(0.0, -pixel_size_y)).rgb;
    vec3 west_color = texture(tex, uv + vec2(-pixel_size_x, 0.0)).rgb;
    
    // Calculate luminance for each sample
    float north_lum = dot(north_color, vec3(0.299, 0.587, 0.114));
    float east_lum = dot(east_color, vec3(0.299, 0.587, 0.114));
    float south_lum = dot(south_color, vec3(0.299, 0.587, 0.114));
    float west_lum = dot(west_color, vec3(0.299, 0.587, 0.114));
    
    // Calculate differences
    float north_diff = abs(center_lum - north_lum);
    float east_diff = abs(center_lum - east_lum);
    float south_diff = abs(center_lum - south_lum);
    float west_diff = abs(center_lum - west_lum);
    
    // Maximum difference in any direction
    float max_diff = max(max(north_diff, east_diff), max(south_diff, west_diff));
    
    // Check if it exceeds the threshold
    return max_diff > threshold;
}

// Function to perform a directional blur
vec3 directional_blur(sampler2D tex, vec2 uv, vec2 direction, float strength, int samples) {
    vec3 color_sum = vec3(0.0);
    float weight_sum = 0.0;
    
    float step_size = strength / float(samples);
    
    // Sample multiple points along the direction
    for (int i = -samples; i <= samples; i++) {
        float weight = 1.0 - abs(float(i)) / float(samples + 1);
        vec2 sample_pos = uv + direction * step_size * float(i);
        vec3 sample_color = texture(tex, sample_pos).rgb;
        
        color_sum += sample_color * weight;
        weight_sum += weight;
    }
    
    return color_sum / weight_sum;
}

void fragment() {
    // Sample the screen at the current UV
    vec3 color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    
    // Check if this pixel is on an edge
    bool edge = is_edge(SCREEN_TEXTURE, SCREEN_UV, edge_threshold);
    
    // Debug mode to visualize edges
    if (show_edges_only) {
        COLOR = vec4(edge ? vec3(1.0) : vec3(0.0), 1.0);
    }
    
    // If on an edge, apply blur
    if (edge) {
        // Get gradient direction (perpendicular to the edge)
        vec2 gradient = vec2(0.0);
        float pixel_size_x = 1.0 / float(textureSize(SCREEN_TEXTURE, 0).x);
        float pixel_size_y = 1.0 / float(textureSize(SCREEN_TEXTURE, 0).y);
        
        // Sample in all 4 directions to find the edge direction
        float n = dot(texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, pixel_size_y)).rgb, vec3(0.299, 0.587, 0.114));
        float e = dot(texture(SCREEN_TEXTURE, SCREEN_UV + vec2(pixel_size_x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
        float s = dot(texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, -pixel_size_y)).rgb, vec3(0.299, 0.587, 0.114));
        float w = dot(texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-pixel_size_x, 0.0)).rgb, vec3(0.299, 0.587, 0.114));
        
        // Gradient is stronger in the direction with more contrast
        gradient.x = abs(e - w);
        gradient.y = abs(n - s);
        
        // Normalize the gradient and get perpendicular direction (along the edge)
        if (length(gradient) > 0.0001) {
            gradient = normalize(gradient);
            vec2 edge_direction = vec2(-gradient.y, gradient.x); // Perpendicular (along the edge)
            
            // Blur along the edge
            color = directional_blur(SCREEN_TEXTURE, SCREEN_UV, edge_direction, blur_strength * pixel_size_x * 2.0, blur_samples);
        }
    }
    
    // Output the final color
    COLOR = vec4(color, 1.0);
}