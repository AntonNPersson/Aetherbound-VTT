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

// Shadow map uniforms
uniform sampler2D shadow_map;
uniform bool use_shadow_map = true;
uniform float shadow_softness = 0.03; // Not used in shadow map lookup directly, but could influence soft shadow distance generation
uniform bool debug_mode = false; // Original debug mode for geometry

// *** NEW: Debug uniform specifically for shadow map texture visualization ***
uniform bool visualize_shadow_map_debug = false; // Set to true to view the shadow map texture
uniform float ambient_light = 0.05; // NEW: Ambient light level (how dark shadows can get)

// Function to calculate distance from point to line segment (unchanged)
float line_segment_distance(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// Calculate light intensity based on distance and texture (unchanged)
float light_intensity(float distance, float radius, vec2 uv_center, vec2 current_uv) {
	// Basic check to prevent division by zero or NaN issues if radius is invalid
	if (radius <= 0.0) {
		return 0.0;
	}
	float normalized_dist = distance / radius;
	// Avoid issues if current_uv is exactly uv_center
	vec2 dir = current_uv - uv_center;
	if (length(dir) < 0.0001) {
		dir = vec2(1.0, 0.0); // Assign arbitrary direction if points coincide
	} else {
		dir = normalize(dir);
	}
	vec2 light_tex_coord = vec2(0.5, 0.5) + dir * normalized_dist * 0.5;
	float texture_intensity = texture(light_texture, light_tex_coord).r;
	// Clamp normalized_dist to prevent smoothstep issues if distance slightly exceeds radius
	return texture_intensity * smoothstep(1.0, 0.0, clamp(normalized_dist, 0.0, 1.0));
}

// NEW: Function to lookup shadow value from shadow map
float get_shadow_from_map(vec2 uv, vec2 light_pos, float light_radius, int light_idx) {
	// Safety checks for invalid input
	if (light_radius <= 0.0 || hole_count == 0 || light_idx >= hole_count) {
		return 1.0; // Assume fully lit if data is invalid
	}

	// Convert world position to light-local polar coordinates
	vec2 dir = light_pos - uv; // Flipped direction
	float dist_sq = dot(dir, dir); // Use squared distance for initial check
	if (dist_sq < 0.00001) { // If very close to the center
		return 1.0; // Assume fully lit at the exact center
	}
	float dist = sqrt(dist_sq); // Calculate actual distance
	dir /= dist; // Normalize direction vector

	float normalized_dist = dist / light_radius; // Normalized 0-1 distance

	// Get angle in 0-1 range (convert from -π to π into 0 to 1)
	float angle = (atan(dir.y, dir.x) / (2.0 * 3.14159265)) + 0.5;

	// Calculate shadow map lookup coordinates
	// Use max(1.0, ...) to prevent division by zero if hole_count is checked after being set to 0 elsewhere
	float row = (float(light_idx) + 0.5) / max(1.0, float(hole_count));
	vec2 shadow_coord = vec2(angle, row);

	// Get stored distance from shadow map (R = hard shadow, G = soft shadow edge)
	vec2 stored_dist = texture(shadow_map, shadow_coord).rg;

	// Soft shadows comparison (stored_dist.g should be <= stored_dist.r)
	if (normalized_dist <= stored_dist.g) { // Check against soft edge first for full lit
		return 1.0; // Fully lit
	} else if (normalized_dist >= stored_dist.r) { // Check against hard edge for full shadow
		return 0.0; // Full shadow
	} else {
		// In penumbra - gradual transition using inverse smoothstep logic
		// Ensure g < r before smoothstep to avoid NaN
        if (stored_dist.r > stored_dist.g) {
            return 1.0 - smoothstep(stored_dist.g, stored_dist.r, normalized_dist);
        } else {
            // If g >= r (shouldn't happen with shadow map shader logic, but as fallback)
            // Treat as hard shadow based on 'r' distance
            return (normalized_dist < stored_dist.r) ? 1.0 : 0.0;
        }
	}
}


void fragment() {
	// Sample the screen
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);

	// Apply background tint
	vec4 tinted_screen = screen_color * background_tint;

	// Start with the base color
	vec4 final_color = tinted_screen;


	// === Shadow Map Visualization Check ===
	if (visualize_shadow_map_debug) {
		if (hole_count > 0) {
			// Visualize the row for the first light (index 0)
			// Sample the texture across the screen width (UV.x) at the calculated row
			float row = 0.5 / max(1.0, float(hole_count)); // Use middle of the first light's row, prevent div by zero
			vec2 shadow_coord = vec2(UV.x, row);
			vec4 map_color = texture(shadow_map, shadow_coord);
			// Output the sampled color (R=hard distance, G=soft distance) directly
			// You might want to visualize R and G differently, e.g., final_color.r = map_color.r; final_color.g = map_color.g;
			final_color = map_color;
			final_color.a = 1.0; // Ensure it's visible
		} else {
			// If no lights, show a distinct color (e.g., Magenta) to indicate this state
			final_color = vec4(1.0, 0.0, 1.0, 1.0); // Magenta
		}
	}
	// === Original Debug Mode Check ===
	else if (debug_mode) {
		// Debug visualization code for geometry
		float checker = mod(floor(UV.x * 20.0) + floor(UV.y * 20.0), 2.0);
		vec4 bg = mix(vec4(0.1, 0.1, 0.1, 1.0), vec4(0.2, 0.2, 0.2, 1.0), checker);
		final_color = bg; // Start with checker background

		// Draw walls as lines (on top of checker)
		for (int i = 0; i < wall_count; i++) {
			// Check wall index validity
			if (i < MAX_WALLS) {
				float dist = line_segment_distance(UV, wall_start_points[i], wall_end_points[i]);
				if (dist < 0.005) {
					final_color = vec4(0.0, 1.0, 0.0, 1.0); // Green for walls
				}
			}
		}

		// Draw hole centers and radii (potentially overwriting walls/checker)
		for (int i = 0; i < hole_count; i++) {
			// Check light index validity
			if (i < MAX_HOLES) {
				float dist_to_center = distance(UV, hole_positions[i]);

				if (dist_to_center < 0.01) {
					final_color = vec4(1.0, 0.0, 0.0, 1.0); // Red for hole centers
				}

				// Check radius validity before using
				if (hole_radii[i] > 0.0) {
					float dist_to_edge = abs(dist_to_center - hole_radii[i]);
					if (dist_to_edge < 0.002) {
						final_color = vec4(1.0, 1.0, 0.0, 1.0); // Yellow for radius
					}

					// Visualize shadow map visibility factor inside the light radius
					if (dist_to_center < hole_radii[i]) {
						float vis;
						if (use_shadow_map) {
							vis = get_shadow_from_map(UV, hole_positions[i], hole_radii[i], i);
							// Mix with blue based on visibility (less visible = more blue)
							vec4 shadow_color = mix(vec4(0.0, 0.0, 0.5, 1.0), vec4(0.0, 0.5, 1.0, 1.0), vis);
							// Only apply blue tint if visibility is less than 1
							if (vis < 0.99) { // Use 0.99 to avoid floating point issues
								// Mix the calculated shadow color with the current final_color
								// (which might be checker, wall color, or light center color)
								final_color = mix(final_color, shadow_color, 0.7);
							}
						}
						// else { // Add legacy visibility debug visualization here if needed }
					}
				}
			}
		}
	}
	// === COMPLETELY NEW Lighting Calculation ===
	else {
		// Step 1: Start with ambient lighting only (dark scene)
		vec3 scene_color = tinted_screen.rgb * ambient_light;

		// Step 2: Calculate shadow and light for each light source
		vec3 total_light_color = vec3(0.0);

		for (int i = 0; i < hole_count; i++) {
			if (i < MAX_HOLES && hole_radii[i] > 0.0) {
				float dist_to_hole = distance(UV, hole_positions[i]);

				// Check if pixel is within light radius
				if (dist_to_hole < hole_radii[i]) {
					// Get light intensity from distance and texture
					float light_intensity_val = light_intensity(dist_to_hole, hole_radii[i], hole_positions[i], UV);

					// Get shadow value (0 = full shadow, 1 = no shadow)
					float shadow_val = 1.0;
					if (use_shadow_map) {
						shadow_val = get_shadow_from_map(UV, hole_positions[i], hole_radii[i], i);
					}

					// Calculate amount of light reaching this pixel from this light source
					float light_factor = light_intensity_val * shadow_val;

					// Calculate attenuation based on underlying brightness
					float under_brightness = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
					float attenuation = mix(1.0, under_brightness, attenuation_strength[i]);

					// Calculate light color contribution
					vec3 light_color = hole_colors[i].rgb * brightness[i] * intensity[i] * light_factor * attenuation;

					// Add this light's color contribution
					total_light_color += light_color;

					// Illuminate the scene by this light + shadow
					// Smoothly blend light contributions based on light_factor
					scene_color = mix(
						scene_color,
						screen_color.rgb * (1.0 + light_color),
						light_factor
					);
				}
			}
		}

		// Apply final color
		final_color = vec4(scene_color, tinted_screen.a);
	}

	// --- Final Output ---
	// Assign the calculated final_color to the output COLOR
	COLOR = final_color;
}