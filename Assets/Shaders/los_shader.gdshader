shader_type canvas_item;
// Maximum number of holes and walls
const int MAX_HOLES = 100;
const int MAX_WALLS = 500;

// Arrays to store hole positions and radii
uniform vec2 hole_positions[MAX_HOLES];
uniform float hole_radii[MAX_HOLES];
uniform int hole_count = 0;

// Arrays to store wall segment endpoints
uniform vec2 wall_start_points[MAX_WALLS];
uniform vec2 wall_end_points[MAX_WALLS];
uniform int wall_count = 0;

uniform vec4 hole_color : source_color = vec4(0.0, 0.0, 0.0, 0.0);
uniform vec4 background_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float edge_softness = 0.01;
uniform float wall_bias = 0.002;
uniform bool debug_mode = false;

// Function to check if a ray intersects a wall segment
bool ray_intersects_segment(vec2 ray_start, vec2 ray_dir, vec2 segment_start, vec2 segment_end, out float t) {
	// Vector from ray start to segment start
	vec2 v = ray_start - segment_start;
	// Wall segment direction
	vec2 seg_dir = segment_end - segment_start;
	// Perpendicular to ray direction
	vec2 perp = vec2(-ray_dir.y, ray_dir.x);

	// Denominator for intersection calculation
	float denom = dot(seg_dir, perp);

	// Near-parallel lines (no intersection)
	if (abs(denom) < 0.0001) {
		return false;
	}

	// Calculate parametric coordinates
	float s = dot(v, perp) / denom;

	// Intersection point is not on the line segment
	if (s < -0.01 || s > 1.01) { // Slightly relaxed bounds for numerical stability
		return false;
	}

	// Calculate distance along ray
	vec2 w = segment_start + s * seg_dir - ray_start;
	t = length(w) * sign(dot(w, ray_dir));

	// Return true for intersections in front of the ray
	return (t > 0.0);
}

// Function to calculate distance from point to line segment
float line_segment_distance(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// Check if a wall segment is within culling distance of a light
bool is_wall_near_light(vec2 light_pos, float light_radius, vec2 segment_start, vec2 segment_end) {
	// Calculate minimum distance from light to wall segment
	float dist = line_segment_distance(light_pos, segment_start, segment_end);

	// Add some margin to light_radius to avoid culling walls that might affect the light edge
	float culling_radius = light_radius * 1.1;

	// If the wall is within the culling radius, it's considered "near"
	return dist < culling_radius;
}

// Function to check if a point is visible from a hole center
// Returns visibility (1.0 = visible, 0.0 = occluded)
float visibility_factor(vec2 point, vec2 hole_center, float max_distance) {
	// Direction and distance from hole to current point
	vec2 ray_dir = point - hole_center;
	float ray_length = length(ray_dir);

	// Same point is always visible
	if (ray_length < 0.0001) {
		return 1.0;
	}

	ray_dir = normalize(ray_dir);

	// Check against all wall segments, but only those near the light
	for (int i = 0; i < wall_count; i++) {
		// Distance-based culling: skip walls too far from this light
		if (!is_wall_near_light(hole_center, max_distance, wall_start_points[i], wall_end_points[i])) {
			continue;
		}

		float t;
		if (ray_intersects_segment(hole_center, ray_dir, wall_start_points[i], wall_end_points[i], t)) {
			// If intersection is closer than current point
			if (t < ray_length) {
				// Wall is between light and current point
				return 0.0;
			}
		}
	}

	return 1.0; // No walls hit, fully visible
}

// Function to calculate light falloff based on distance
float light_intensity(float distance, float radius) {
	// Apply a smoother falloff curve
	float normalized_dist = distance / radius;
	return smoothstep(1.0, 0.0, normalized_dist);
}

void fragment() {
	// Start with the background color
	vec4 final_color = background_color;

	if (debug_mode) {
		// Draw a checkerboard pattern for the background in debug mode
		float checker = mod(floor(UV.x * 20.0) + floor(UV.y * 20.0), 2.0);
		vec4 bg = mix(vec4(0.1, 0.1, 0.1, 1.0), vec4(0.2, 0.2, 0.2, 1.0), checker);
		final_color = bg;

		// Draw walls as lines
		for (int i = 0; i < wall_count; i++) {
			float dist = line_segment_distance(UV, wall_start_points[i], wall_end_points[i]);
			if (dist < 0.005) {
				final_color = vec4(0.0, 1.0, 0.0, 1.0); // Green for walls
			}
		}

		// Draw hole centers and radii
		for (int i = 0; i < hole_count; i++) {
			if (distance(UV, hole_positions[i]) < 0.01) {
				final_color = vec4(1.0, 0.0, 0.0, 1.0); // Red for hole centers
			}

			float dist_to_edge = abs(distance(UV, hole_positions[i]) - hole_radii[i]);
			if (dist_to_edge < 0.002) {
				final_color = vec4(1.0, 1.0, 0.0, 1.0); // Yellow for radius
			}

			// Visualize culling radius (10% larger than light radius)
			float culling_dist = abs(distance(UV, hole_positions[i]) - (hole_radii[i] * 1.1));
			if (culling_dist < 0.002) {
				final_color = vec4(1.0, 0.5, 0.0, 1.0); // Orange for culling radius
			}

			// Visualize visibility
			if (distance(UV, hole_positions[i]) < hole_radii[i]) {
				float vis = visibility_factor(UV, hole_positions[i], hole_radii[i]);

				// If visibility factor is less than 1.0, show in shades of blue (darker = more occluded)
				if (vis < 1.0) {
					vec4 occluded_color = mix(vec4(0.0, 0.0, 0.5, 1.0), vec4(0.0, 0.5, 1.0, 1.0), vis);
					final_color = mix(final_color, occluded_color, 0.7);
				}
			}
		}
	}
	else {
		// Process each hole
		for (int i = 0; i < hole_count; i++) {
			// Calculate distance from current pixel to hole center
			float dist_to_hole = distance(UV, hole_positions[i]);

			// If we're inside the hole radius
			if (dist_to_hole < hole_radii[i]) {
				// Get visibility factor (0-1 based on occlusion)
				float vis = visibility_factor(UV, hole_positions[i], hole_radii[i]);

				if (vis > 0.0) {
					// Calculate light intensity based on distance
					float light_factor = light_intensity(dist_to_hole, hole_radii[i]);

					// Apply visibility factor to light intensity
					light_factor *= vis;

					// Calculate smooth transition at the edge
					float alpha = light_factor;

					// Mix the hole color with what we have so far
					// Use max blend mode for overlapping lights (lighter areas stay lighter)
					final_color = mix(final_color, hole_color, alpha);
				}
			}
		}
	}

	COLOR = final_color;
}