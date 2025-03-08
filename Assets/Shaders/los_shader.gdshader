shader_type canvas_item;

// Maximum number of holes
const int MAX_HOLES = 100;

// Arrays to store hole positions and radii
uniform vec2 hole_positions[MAX_HOLES];
uniform float hole_radii[MAX_HOLES];
uniform int hole_count = 0;
uniform vec4 hole_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_softness = 0.01;

void fragment() {
    // Start with the background color
    vec4 final_color = background_color;
    
    // Check each hole
    for(int i = 0; i < MAX_HOLES; i++) {
        // Break if we've processed all active holes
        if(i >= hole_count) {
            break;
        }
        
        // Calculate the distance from the current pixel to the hole center
        float distance = distance(UV, hole_positions[i]);
        
        // If the distance is less than the radius, we're inside the hole
        if(distance < hole_radii[i]) {
            // Calculate smooth transition at the edge
            float alpha = smoothstep(hole_radii[i] - edge_softness, hole_radii[i], distance);
            
            // Mix the hole color with what we have so far
            final_color = mix(hole_color, final_color, alpha);
        }
    }
    
    COLOR = final_color;
}