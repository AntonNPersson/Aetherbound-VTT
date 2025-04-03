shader_type canvas_item;

uniform sampler2D source_shadow_map : filter_linear; // Input shadow map
uniform float blur_amount = 1.5; // Blur radius in pixels (adjust!)

void fragment() {
    vec2 texel_size = 1.0 / vec2(textureSize(source_shadow_map, 0));
    vec4 blurred_color = vec4(0.0);
    float weight_sum = 0.0;

    // Simple Box Blur (Gaussian is better but more complex)
    int radius = int(ceil(blur_amount)); // Use ceil for safety
    for (int x = -radius; x <= radius; x++) {
        // Optional: Add weighting (e.g., Gaussian) here
        float weight = 1.0; // Simple box blur weight

        vec2 offset = vec2(float(x) * texel_size.x, 0.0);
        blurred_color += texture(source_shadow_map, UV + offset) * weight;
        weight_sum += weight;
    }

    if (weight_sum > 0.0) {
        blurred_color /= weight_sum;
    } else {
        blurred_color = texture(source_shadow_map, UV); // Fallback
    }

    // Output the blurred R (HardEdge) and G (SoftEdge) values
    COLOR = blurred_color;
}