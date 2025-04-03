shader_type canvas_item;

// Screen texture access
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
// The Shadow Map (R=HardEnd, G=SoftStart)
uniform sampler2D shadow_map : filter_linear;

// Background tint
uniform vec4 background_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Light and shadow parameters
const int MAX_HOLES = 100;

// Arrays for lights
uniform vec2 hole_positions[MAX_HOLES];
uniform float hole_radii[MAX_HOLES];
uniform vec4 hole_colors[MAX_HOLES];
uniform int hole_count = 0;

// Light customization
uniform sampler2D light_texture;
// !!! Reminder: Tune these values for THIS additive structure !!!
// (Values like brightness=0.1-0.2, intensity=0.1-0.4 might be starting points)
uniform float brightness[MAX_HOLES];
uniform float attenuation_strength[MAX_HOLES];
uniform float intensity[MAX_HOLES];

// Shadow map usage flag
uniform bool use_shadow_map = true;
uniform bool debug_mode = false;
uniform bool visualize_shadow_map_debug = false;
uniform float ambient_light = 1.0; // Ambient light level

// Edge softness parameter
uniform float light_edge_softness = 0.5;

// Function to calculate distance from point to line segment (for debug)
float line_segment_distance(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a; vec2 ba = b - a; float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0); return length(pa - ba * h);
}

float saturate(float x) {
    return clamp(x, 0.0, 1.0);
}
// Calculate light intensity with soft edges (Original or Smoother version)
float light_intensity(float distance, float radius, vec2 uv_center, vec2 current_uv) {
    // *** Use either your original or the smooth version here ***
    // For testing, let's assume the smooth one:
    if (radius <= 0.0) { return 0.0; }
    float normalized_dist = distance / radius;
    float max_norm_dist = 1.0 + max(0.001, light_edge_softness);
    if (normalized_dist > max_norm_dist) { return 0.0; }
    float falloff_multiplier = smoothstep(max_norm_dist, 0.0, normalized_dist);
    float tex_norm_dist = min(normalized_dist, 1.0);
    vec2 dir = normalize(current_uv - uv_center + vec2(0.0001));
    vec2 light_tex_coord = vec2(0.5) + dir * tex_norm_dist * 0.5;
    float texture_intensity_val = texture(light_texture, light_tex_coord).r;
    return texture_intensity_val * falloff_multiplier;
}

float get_shadow_from_map(vec2 uv, vec2 light_pos, float light_radius, int light_idx) {
	// Safety checks
	if (light_radius <= 0.0 || hole_count == 0 || light_idx >= hole_count || light_idx >= MAX_HOLES) {
		return 1.0; // Assume fully lit
	}
	// Polar coords & distance relative to light
	vec2 dir = light_pos - uv;
	float dist_sq = dot(dir, dir);
	if (dist_sq < 0.00001) { return 1.0; } // At center
	float dist = sqrt(dist_sq);
	dir /= dist;
	float normalized_dist = dist / light_radius; // Pixel distance from light center (0 to radius+)

	// Check distance relative to map definition (radius)
    // Allow check slightly beyond 1.0 as map values are 0-1
	if (normalized_dist > 1.05) { // Use a small tolerance
        return 0.0; // Definitely beyond any defined edge
    }

	// Angle & map coords
	float angle = (atan(dir.y, dir.x) / (2.0 * 3.14159265)) + 0.5;
    // Clamp angle just in case to avoid potential issues at 0/1 seam if filtering wraps badly
    angle = clamp(angle, 0.001, 0.999);
	float row = (float(light_idx) + 0.5) / max(1.0, float(hole_count));
	vec2 shadow_coord = vec2(angle, row);

	// Lookup R=hard_edge_end, G=soft_edge_start from YOUR generated map
    // Ensure linear filtering is ON for the sampler uniform
	vec2 stored_dist_norm = texture(shadow_map, shadow_coord).rg;
	float shadow_soft_start = stored_dist_norm.g; // Where penumbra begins (0-1)
	float shadow_hard_end = stored_dist_norm.r;   // Where full shadow begins (0-1)

	// --- Interpretation ---
    // Compare pixel's normalized distance to the stored map distances
	if (normalized_dist <= shadow_soft_start) {
		return 1.0; // Pixel is closer than the start of the penumbra = Fully lit
	} else if (normalized_dist >= shadow_hard_end) {
		return 0.0; // Pixel is further than the start of full shadow = Fully shadowed
	} else {
        // Pixel is in the penumbra region
		if (shadow_hard_end > shadow_soft_start) { // Ensure valid range
			// Smooth transition from 1.0 (lit) down to 0.0 (shadow)
            // Use saturate (clamp 0-1) just in case smoothstep output is slightly out of bounds due to precision
            return saturate(1.0 - smoothstep(shadow_soft_start, shadow_hard_end, normalized_dist));
		} else {
			// If soft_start >= hard_end, treat as hard edge at hard_end
			return (normalized_dist < shadow_hard_end) ? 1.0 : 0.0;
		}
	}
}

// ... line_segment_distance ...

void fragment() {
	// Sample screen & apply tint
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 tinted_screen = screen_color * background_tint;
	vec4 final_color;

	// === Debug Modes ===
	if (visualize_shadow_map_debug) { /* ... */ }
    else if (debug_mode) { /* ... */ }
	// === Main Rendering Logic (Multiplicative Shadow Base + Multiplicative Lit Target + Intensity Blend) ===
	else {
		// --- Initialize ---
		float light_intensities[MAX_HOLES]; // Stores light_factor
		float light_shadows[MAX_HOLES];     // Stores actual shadow_val
		int active_count = 0;

        vec3 total_light_contrib = vec3(0.0); // Accumulates actual light: color * intensity * shadow
		float combined_shadow_multiplier = 1.0; // Multiplicative shadow factor (1=lit, 0=shadow block)
        bool light_influenced = false;

		// --- Collect Light & Shadow Information ---
		for (int i = 0; i < hole_count; i++) {
			if (i < MAX_HOLES && hole_radii[i] > 0.0) {
				float dist_to_hole = distance(UV, hole_positions[i]);
				float extended_radius = hole_radii[i] * (1.0 + max(0.001, light_edge_softness));

				if (dist_to_hole < extended_radius) {
					int idx = active_count;
                    if (idx >= MAX_HOLES) break;

					float light_factor = light_intensity(dist_to_hole, hole_radii[i], hole_positions[i], UV);

					if (light_factor > 0.001) {
                        light_influenced = true;

						float raw_shadow_val = 1.0;
						if (use_shadow_map) {
							raw_shadow_val = get_shadow_from_map(UV, hole_positions[i], hole_radii[i], i);
						}
                        // Store for intensity calc later
                        light_intensities[idx] = light_factor;
                        light_shadows[idx] = raw_shadow_val;

						// Calculate light color (Tune brightness/intensity!)
						float under_brightness = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
						float attenuation = mix(1.0, under_brightness, attenuation_strength[i]);
						vec3 light_color = hole_colors[i].rgb * brightness[i] * intensity[i] * attenuation;

						// --- Accumulate ACTUAL Light Contribution ---
						total_light_contrib += light_color * light_factor * raw_shadow_val;

						// --- Combine Shadow Multipliers ---
                        combined_shadow_multiplier *= raw_shadow_val;

                    } else {
                         // Store 0 if light_factor is too low, important for intensity calc loop later
                         if(idx < MAX_HOLES){ // Check idx validity before storing
                             light_intensities[idx] = 0.0;
                             light_shadows[idx] = 1.0; // Shadow value doesn't matter if intensity is 0
                         }
                    }
                    // Increment active_count *only* if idx was valid and potentially processed
                    if (idx < MAX_HOLES) {
                        active_count++;
                    }
				} // End if within radius
			} // End if radius > 0
		} // --- End of Main Loop ---

		// --- Final Color Calculation ---
        // Handle cases with no active lights first
		if (!light_influenced && ambient_light >= 0.999) {
             final_color = tinted_screen; // No lights, full ambient
        } else if (!light_influenced && ambient_light < 0.999) {
             final_color.rgb = tinted_screen.rgb * ambient_light; // No lights, ambient darkness
             final_color.a = tinted_screen.a;
        } else { // Light influenced, proceed with blending

            // 1. Calculate the minimum brightness level (ambient floor)
            vec3 ambient_floor_color = tinted_screen.rgb * ambient_light;

            // 2. Calculate the potential brightness range shadows can affect
            vec3 potential_brightness_range = max(tinted_screen.rgb - ambient_floor_color, vec3(0.0));

            // 3. Calculate the SMOOTH shadowed base color using multiplicative shadows
            vec3 shadowed_base = ambient_floor_color + potential_brightness_range * combined_shadow_multiplier;

            // 4. Calculate the target lit color using MULTIPLICATIVE approach
            // !!! REQUIRES Appropriate brightness/intensity tuning !!!
            vec3 lit_color_target = screen_color.rgb * (1.0 + total_light_contrib);

            // 5. Calculate total intensity factor of light ACTUALLY arriving
            float total_actual_intensity = 0.0;
            // Use active_count which was correctly incremented
            for (int i = 0; i < active_count; i++) {
                // Ensure accessing valid data (should be okay due to loop structure)
                total_actual_intensity += light_intensities[i] * light_shadows[i];
            }

            // 6. Calculate the blend factor based on total incoming light intensity
            float blend_sensitivity = 1.5; // TUNABLE: Try values like 0.75, 1.0, 1.5
            float blend_factor = smoothstep(0.0, blend_sensitivity, total_actual_intensity);
            blend_factor = clamp(blend_factor, 0.0, 1.0);

			// Final Mix: Blend between the SMOOTH base and the MULTIPLICATIVE lit target
			final_color.rgb = mix(
				shadowed_base,
				lit_color_target,
				blend_factor
			);
            final_color.a = tinted_screen.a;
        }

        // Clamp final color
        final_color.rgb = clamp(final_color.rgb, 0.0, 1.5);
	} // --- End Main Rendering Block ---

	// Final color assignment
	COLOR = final_color;
}