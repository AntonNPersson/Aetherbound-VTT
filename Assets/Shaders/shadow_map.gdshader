
shader_type canvas_item;

// Shadow map generation parameters
const int MAX_HOLES = 100;
const int MAX_WALLS = 500;
const int SHADOW_MAP_RESOLUTION = 720; // Higher = more accurate, but more expensive

uniform vec2 hole_positions[MAX_HOLES];
uniform float hole_radii[MAX_HOLES];
uniform int hole_count = 0;

// Wall data
uniform vec2 wall_start_points[MAX_WALLS];
uniform vec2 wall_end_points[MAX_WALLS];
uniform int wall_count = 0;

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
	float normalized_dist = find_nearest_intersection(light_pos, ray_dir, light_radius);
	
	// Store the normalized distance in the R channel
	// G channel can store a distance for soft shadows
	COLOR = vec4(normalized_dist, max(0.0, normalized_dist - 0.05), 0.0, 1.0);
}