shader_type canvas_item;
// Shadow map generation parameters
const int MAX_HOLES = 100;
const int MAX_WALLS = 500;
const int SHADOW_MAP_RESOLUTION = 2880; // Higher = more accurate, but more expensive
uniform vec2 hole_positions[MAX_HOLES];
uniform float hole_radii[MAX_HOLES];
uniform int hole_count = 0;

// Wall data
uniform vec2 wall_start_points[MAX_WALLS];
uniform vec2 wall_end_points[MAX_WALLS];
uniform int wall_count = 0;

// NEW: Enhanced soft shadow parameters - adjusted for correct shadow positioning
uniform float soft_shadow_width = 0.12;  // Reduced to prevent incorrect shadows
uniform float soft_shadow_quality = 2.2; // Higher values create smoother transitions
uniform float shadow_smoothness = 0.1;   // Reduced to prevent shadows appearing on wrong side

// Function to check if a ray intersects a wall segment (same as your original shader)
bool ray_intersects_segment(vec2 ray_start, vec2 ray_dir, vec2 segment_start, vec2 segment_end, out float t) {
	vec2 v = ray_start - segment_start;
	vec2 seg_dir = segment_end - segment_start;
	vec2 perp = vec2(-ray_dir.y, ray_dir.x);
	float denom = dot(seg_dir, perp);
	if (abs(denom) < 0.0001) {
		return false;
	}
	float s = dot(v, perp) / denom;
	if (s < -0.01 || s > 1.01) {
		return false;
	}
	vec2 w = segment_start + s * seg_dir - ray_start;
	t = length(w) * sign(dot(w, ray_dir));
	return (t > 0.0);
}

// Check if a wall segment is within culling distance (same as original)
bool is_wall_near_light(vec2 light_pos, float light_radius, vec2 segment_start, vec2 segment_end) {
	float dist = min(
		distance(light_pos, segment_start),
		distance(light_pos, segment_end)
	);
	float culling_radius = light_radius * 1.1;
	return dist < culling_radius;
}

// Find nearest wall intersection for a ray
float find_nearest_intersection(vec2 origin, vec2 direction, float max_distance) {
	float min_t = max_distance;
	bool has_hit = false;
	
	for (int i = 0; i < wall_count; i++) {
		if (!is_wall_near_light(origin, max_distance, wall_start_points[i], wall_end_points[i])) {
			continue;
		}
		
		float t;
		if (ray_intersects_segment(origin, direction, wall_start_points[i], wall_end_points[i], t)) {
			if (t < min_t) {
				min_t = t;
				has_hit = true;
			}
		}
	}
	
	return has_hit ? min_t / max_distance : 1.0; // Normalized 0-1 distance
}

// CORRECTED: Soft shadow calculation that prevents shadows on wrong side of walls
float calculate_soft_shadow_edge(vec2 origin, vec2 main_dir, float max_distance, float hard_edge) {
	// For walls very close to light, keep a much smaller penumbra to prevent incorrect shadows
	// This proximity scaling is critical to prevent shadows on the wrong side of walls
	float proximity_factor = smoothstep(0.1, 0.2, hard_edge);
	proximity_factor *= proximity_factor; // Square it to make it more aggressive for close walls
	
	// If very close to the light source, keep the soft edge very close to hard edge
	if (hard_edge < 0.15) {
		return max(0.001, hard_edge - 0.01); // Minimal penumbra for very close walls
	}
	
	// Base soft width that scales with distance from light
	float base_soft_width = soft_shadow_width * proximity_factor;
	
	// Start with the hard edge as our baseline
	float soft_edge = hard_edge;
	float min_soft_edge = hard_edge; // Track minimum for true soft edge
	
	// Progressive sampling for smoother gradients
	int samples = int(soft_shadow_quality);
	
	// Only use angle-based sampling for shadows beyond a certain distance
	if (hard_edge > 0.2) {
		for (int i = 1; i <= samples; i++) {
			// Smaller angles for more precise sampling
			float progress = float(i) / float(samples);
			float angle_offset = 0.1 * progress * shadow_smoothness * proximity_factor;
			
			// Sample in both directions
			vec2 offset_dir1 = vec2(
				main_dir.x * cos(angle_offset) - main_dir.y * sin(angle_offset),
				main_dir.x * sin(angle_offset) + main_dir.y * cos(angle_offset)
			);
			
			vec2 offset_dir2 = vec2(
				main_dir.x * cos(-angle_offset) - main_dir.y * sin(-angle_offset),
				main_dir.x * sin(-angle_offset) + main_dir.y * cos(-angle_offset)
			);
			
			// Find intersections
			float t1 = find_nearest_intersection(origin, offset_dir1, max_distance);
			float t2 = find_nearest_intersection(origin, offset_dir2, max_distance);
			
			// Track minimum value but with less weight for further angles
			float weight = mix(0.8, 0.2, progress);
			float new_min = min(t1, t2);
			
			// Only consider this sample if it doesn't cause shadow to wrap around wrong side
			if (new_min > 0.1) {
				min_soft_edge = min(min_soft_edge, mix(new_min, soft_edge, 1.0 - weight));
			}
		}
		
		// Use the minimum value found as our new soft edge
		soft_edge = min_soft_edge;
	}
	
	// Calculate the offset based on distance but prevent it from being too large
	// This is key to preventing shadows from appearing on the wrong side
	float max_allowed_offset = hard_edge * 0.5; // Never go back more than halfway
	float desired_offset = base_soft_width * hard_edge * 0.7;
	float final_offset = min(desired_offset, max_allowed_offset);
	
	// Add slight extra offset for distant shadows (smoother edges for far shadows)
	if (hard_edge > 0.7) {
		final_offset = min(final_offset * 1.2, hard_edge * 0.6);
	}
	
	// Ensure soft_edge is always less than hard_edge but not too far back
	return max(0.01, hard_edge - final_offset);
}

void fragment() {
	// The shadow map texture is structured as:
	// - X axis (UV.x): angle from 0 to 2π mapped to 0-1
	// - Y axis (UV.y): each light gets a row, mapped by light_index / hole_count
	
	// Determine which light and angle this fragment represents
	int light_idx = int(UV.y * float(hole_count));
	float angle = UV.x * 2.0 * 3.14159265; // 0-1 maps to 0-2π
	
	// Get light data
	vec2 light_pos = hole_positions[light_idx];
	float light_radius = hole_radii[light_idx];
	
	// Calculate ray direction for this angle
	vec2 ray_dir = vec2(cos(angle), sin(angle));
	
	// Find nearest intersection (returns normalized 0-1 distance)
	float hard_shadow_edge = find_nearest_intersection(light_pos, ray_dir, light_radius);
	
	// Calculate soft shadow edge with improved algorithm
	float soft_shadow_edge = calculate_soft_shadow_edge(light_pos, ray_dir, light_radius, hard_shadow_edge);
	
	// Store the hard shadow distance in R channel and soft shadow in G channel
	COLOR = vec4(hard_shadow_edge, soft_shadow_edge, 0.0, 1.0);
}