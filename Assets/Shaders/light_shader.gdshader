shader_type canvas_item;

// Screen texture access
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// Background tint (replaces CanvasModulate)
uniform vec4 background_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Light and shadow parameters
const int MAX_HOLES = 100;
const int MAX_WALLS = 500;

// Arrays to store hole positions and radii
uniform vec2 hole_positions[MAX_HOLES];
uniform float hole_radii[MAX_HOLES];
uniform vec4 hole_colors[MAX_HOLES];  // RGB is light color, A is intensity
uniform int hole_count = 0;

// Arrays to store wall segment endpoints
uniform vec2 wall_start_points[MAX_WALLS];
uniform vec2 wall_end_points[MAX_WALLS];
uniform int wall_count = 0;

// Light customization
uniform sampler2D light_texture;  // Light gradient texture
uniform float brightness[MAX_HOLES];
uniform float attenuation_strength[MAX_HOLES];
uniform float intensity[MAX_HOLES];

// Shadow quality improvements
uniform float shadow_softness = 0.03; // Controls penumbra size
uniform int shadow_quality = 0;      // 0=hard, 1=soft, 2=high quality

// Other settings
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
	float dist = line_segment_distance(light_pos, segment_start, segment_end);
	float culling_radius = light_radius * 1.1;
	return dist < culling_radius;
}

// IMPROVED: Function to check if a point is visible from a hole center with soft shadows
float visibility_factor(vec2 point, vec2 hole_center, float max_distance) {
	vec2 ray_dir = point - hole_center;
	float ray_length = length(ray_dir);

	if (ray_length < 0.0001) {
		return 1.0;
	}

	ray_dir = normalize(ray_dir);

	float min_t = max_distance;
	bool has_hit = false;

	for (int i = 0; i < wall_count; i++) {
		if (!is_wall_near_light(hole_center, max_distance, wall_start_points[i], wall_end_points[i])) {
			continue;
		}

		float t;
		if (ray_intersects_segment(hole_center, ray_dir, wall_start_points[i], wall_end_points[i], t)) {
			if (t < ray_length && t < min_t) {
				min_t = t;
				has_hit = true;
			}
		}
	}

	if (!has_hit) {
		return 1.0;
	}

	// Penumbra effect - soften shadow edges based on distance to intersection vs ray length
	float penumbra_size = shadow_softness * max_distance;
	float shadow_end = min_t;
	float shadow_start = max(0.0, shadow_end - penumbra_size);

	if (ray_length < shadow_start) {
		return 1.0; // Fully lit
	} else if (ray_length > shadow_end) {
		return 0.0; // Full shadow
	} else {
		// Penumbra (soft shadow) - gradual transition
		return 1.0 - smoothstep(shadow_start, shadow_end, ray_length);
	}
}

// NEW: Multi-sample visibility for higher quality shadows
float multi_sample_visibility(vec2 point, vec2 hole_center, float max_distance) {
	// If using hard shadows, just use the original function
	if (shadow_quality == 0) {
		return visibility_factor(point, hole_center, max_distance);
	}

	// For higher quality, take multiple samples
	float visibility = visibility_factor(point, hole_center, max_distance);

	if (shadow_quality >= 1) {
		// If in the transition zone, use multiple samples
		if (visibility > 0.0 && visibility < 1.0) {
			// Sample offset vectors for soft shadows (penumbra)
			vec2 offset = (point - hole_center) * 0.02;
			vec2 perp = vec2(-offset.y, offset.x) * shadow_softness;

			// Take additional samples at slight offsets for smoother shadows
			visibility += visibility_factor(point + perp, hole_center, max_distance);
			visibility += visibility_factor(point - perp, hole_center, max_distance);

			if (shadow_quality >= 2) {
				// Even higher quality with more samples
				visibility += visibility_factor(point + offset * 0.3, hole_center, max_distance);
				visibility += visibility_factor(point - offset * 0.3, hole_center, max_distance);
				visibility /= 5.0; // Average all samples
			} else {
				visibility /= 3.0; // Average the three samples
			}
		}
	}

	return visibility;
}

// Calculate light intensity based on distance and texture
float light_intensity(float distance, float radius, vec2 uv_center, vec2 current_uv) {
	// Normalized distance (0 at center, 1 at edge)
	float normalized_dist = distance / radius;

	// Get direction from center to current point
	vec2 dir = normalize(current_uv - uv_center);

	// Calculate texture coordinates for the light texture
	// Map distance from 0 to radius into 0 to 0.5 texture coordinates
	// (assuming the texture has radial gradient with center at 0.5,0.5)
	vec2 light_tex_coord = vec2(0.5, 0.5) + dir * normalized_dist * 0.5;

	// Sample light texture
	float texture_intensity = texture(light_texture, light_tex_coord).r;

	// Combine with standard falloff
	return texture_intensity * smoothstep(1.0, 0.0, normalized_dist);
}

void fragment() {
	// Sample the screen
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

	// Apply background tint (replaces CanvasModulate)
	vec4 tinted_screen = screen_color * background_tint;

	// Start with the tinted screen as our base color
	vec4 final_color = tinted_screen;

	if (debug_mode) {
		// Debug mode (unchanged from your original shader)
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
				float vis = multi_sample_visibility(UV, hole_positions[i], hole_radii[i]);

				// If visibility factor is less than 1.0, show in shades of blue (darker = more occluded)
				if (vis < 1.0) {
					vec4 occluded_color = mix(vec4(0.0, 0.0, 0.5, 1.0), vec4(0.0, 0.5, 1.0, 1.0), vis);
					final_color = mix(final_color, occluded_color, 0.7);
				}
			}
		}
	}
	else {
		// Process each light/hole
		for (int i = 0; i < hole_count; i++) {
			// Calculate distance from current pixel to hole center
			float dist_to_hole = distance(UV, hole_positions[i]);

			// If we're inside the hole radius
			if (dist_to_hole < hole_radii[i]) {
				// Get visibility factor (0-1 based on occlusion) - use multi-sampling
				float vis = multi_sample_visibility(UV, hole_positions[i], hole_radii[i]);

				if (vis > 0.0) {
					// Use enhanced light intensity calculation
					float light_factor = light_intensity(dist_to_hole, hole_radii[i], hole_positions[i], UV);

					// Apply visibility factor to light intensity
					light_factor *= vis;

					// Calculate the brightness of the underlying pixel
					float under_brightness = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));

					// Apply attenuation based on the underlying brightness
					float attenuation = mix(1.0, under_brightness, attenuation_strength[i]);

					// Apply all modifiers to the light
					vec3 light_contribution = hole_colors[i].rgb * brightness[i] * intensity[i] * light_factor * attenuation;

					// Mix original screen color with light (no tint in light areas)
					float light_influence = light_factor * 0.7; // Adjust this value for light strength
					// Use multiplication for tinting instead of addition
					final_color.rgb = mix(final_color.rgb, screen_color.rgb * (1.0 + light_contribution), light_influence);
				}
			}
		}
	}

	// Output the final color
	COLOR = final_color;
}