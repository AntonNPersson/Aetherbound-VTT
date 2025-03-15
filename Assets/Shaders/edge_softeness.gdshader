// First, let's create a shader for soft edges
// Create a new file called "shadow_fade.gdshader"

// shadow_fade.gdshader
shader_type canvas_item;

uniform float edge_softness : hint_range(0.0, 1.0) = 0.2;
uniform vec4 shadow_color : source_color;

void fragment() {
    // Get the distance from the edge of the polygon
    float distance_from_edge = texture(TEXTURE, UV).a;

    // Apply softness to the edge
    float alpha = smoothstep(0.0, edge_softness, distance_from_edge);

    // Apply the final color with faded edges
    COLOR = vec4(shadow_color.rgb, shadow_color.a * alpha);
}