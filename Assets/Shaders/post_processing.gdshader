shader_type canvas_item;
// Shadow map generation parameters
const int MAX_HOLES = 100;
const int MAX_WALLS = 500;
uniform vec2 hole_positions[MAX_HOLES];
uniform float hole_radii[MAX_HOLES];
uniform int hole_count = 0;

// Wall data
uniform vec2 wall_start_points[MAX_WALLS];
uniform vec2 wall_end_points[MAX_WALLS];
uniform int wall_count = 0;

// --- SOFTNESS PARAMETERS (Tune these uniforms from GDScript!) ---
// Suggest starting values significantly larger than before for wider/softer look
uniform float soft_shadow_width = 0.5;   // Increased Base width factor for penumbra (e.g., 0.3 to 1.0+)
uniform float soft_shadow_quality = 5.0; // Increased Detail samples (e.g., 5.0+)
uniform float shadow_smoothness = 0.5;   // Increased Angular offset scale (e.g., 0.3 to 0.8)

// Angular softness parameters
uniform float cone_edge_samples = 5.0;   // Increased Angular samples (e.g., 5.0+)
uniform float cone_angle_spread = 0.1;  // Increased Angular spread (e.g., 0.05 to 0.2)


// Helper for squared distance
float distance_squared(vec2 p1, vec2 p2) {
    vec2 d = p1 - p2;
    return dot(d, d);
}
// Function to check if a ray intersects a wall segment
bool ray_intersects_segment(vec2 rs, vec2 rd, vec2 ss, vec2 se, out float t) { /* ... as before ... */ }
// Check if a wall segment is potentially relevant
bool is_wall_near_light(vec2 lp, float lr, vec2 ss, vec2 se) { /* ... as before ... */ }
// Find nearest wall intersection distance for a ray
float find_nearest_intersection_dist(vec2 o, vec2 d, float max_d) { /* ... as before ... */ }


// --- REVISED Soft shadow calculation with more aggressive smoothing ---
float calculate_soft_shadow_edge(vec2 origin, vec2 main_dir, float max_distance, float hard_edge_dist) {

    // --- Initial Angular Sampling for Cone Edge Detection (AVERAGING) ---
    int num_cone_samples = int(cone_edge_samples);
    float avg_nearby_hard_dist = 0.0; // Use average instead of min
    float cone_sample_weight_sum = 0.0;

    if (num_cone_samples > 0) {
        for (int i = 0; i < num_cone_samples; i++) {
            float sample_offset_angle = (float(i) - float(num_cone_samples - 1) / 2.0) * cone_angle_spread / max(1.0, float(num_cone_samples - 1));
            float cs = cos(sample_offset_angle); float sn = sin(sample_offset_angle);
            vec2 offset_dir = vec2(main_dir.x * cs - main_dir.y * sn, main_dir.x * sn + main_dir.y * cs);
            float nearby_t_dist = find_nearest_intersection_dist(origin, offset_dir, max_distance);
            avg_nearby_hard_dist += nearby_t_dist;
            cone_sample_weight_sum += 1.0;
        }
        if (cone_sample_weight_sum > 0.0) {
             avg_nearby_hard_dist /= cone_sample_weight_sum; // Calculate average distance
        } else {
             avg_nearby_hard_dist = hard_edge_dist; // Fallback if no samples
        }
    } else {
        avg_nearby_hard_dist = hard_edge_dist;
    }
    // --- End Initial Angular Sampling ---


    // --- Determine effective edge distance for softness calculation ---
    float hard_edge_norm = hard_edge_dist / max_distance;
    float avg_nearby_hard_norm = avg_nearby_hard_dist / max_distance;

    // Blend towards the AVERAGE nearby hit if the main ray was far / missed.
    // Make the blend happen sooner and more gradually
    float edge_blend = smoothstep(0.98, 0.6, hard_edge_norm); // Wider range
    float effective_hard_edge_norm = mix(hard_edge_norm, avg_nearby_hard_norm, edge_blend);
    // Allow effective edge to be slightly further if avg is further (can happen with averaging)
    effective_hard_edge_norm = min(effective_hard_edge_norm, hard_edge_norm + 0.15); // Increased tolerance


    // --- Proceed with softness calculation using effective_hard_edge_norm ---
    // Slightly wider smoothstep for proximity factor
    float proximity_factor = smoothstep(0.15, 0.7, effective_hard_edge_norm); // Wider range
	proximity_factor *= proximity_factor; // Squaring makes effect stronger near light

    // Minimal penumbra near light source
	if (effective_hard_edge_norm < 0.15) {
		return max(0.005, effective_hard_edge_norm - 0.015); // Slightly smaller gap
	}

	float base_soft_width = soft_shadow_width * proximity_factor;

    // --- Detailed Radial Sampling (AVERAGING) ---
	float avg_sampled_soft_norm = effective_hard_edge_norm; // Start with effective edge
    float detail_sample_weight_sum = 0.0;
	int samples = int(soft_shadow_quality);

	if (effective_hard_edge_norm > 0.1 && samples > 0) { // Start sampling sooner
        avg_sampled_soft_norm = 0.0; // Reset for averaging
		for (int i = 0; i < samples; i++) { // Sample center too (i=0)
            float progress = float(i) / max(1.0, float(samples - 1)); // Ensure 0-1 range
			float angle_offset = 0.15 * progress * shadow_smoothness * proximity_factor; // Slightly larger angle base

            // Sample only one side if i=0 (center)? Or just average L/R pairs? Average pairs is simpler.
            if (i == 0 && samples > 1) continue; // Skip center explicitly if averaging pairs below

            // Sample in both directions (or just center if i=0 and samples=1)
            vec2 offset_dir1 = main_dir, offset_dir2 = main_dir;
            if (samples > 1){
                float cs1 = cos(angle_offset); float sn1 = sin(angle_offset);
                float cs2 = cos(-angle_offset); float sn2 = sin(-angle_offset);
                offset_dir1 = vec2( main_dir.x*cs1 - main_dir.y*sn1, main_dir.x*sn1 + main_dir.y*cs1 );
                offset_dir2 = vec2( main_dir.x*cs2 - main_dir.y*sn2, main_dir.x*sn2 + main_dir.y*cs2 );
            }

			float t1_dist = find_nearest_intersection_dist(origin, offset_dir1, max_distance);
			float t2_dist = find_nearest_intersection_dist(origin, offset_dir2, max_distance);
            float avg_pair_dist = (samples > 1) ? (t1_dist + t2_dist) * 0.5 : t1_dist; // Average L/R pair or use center

            // Normalize distance
            float avg_pair_norm = avg_pair_dist / max_distance;

            // Weight samples - maybe simpler average is better? Let's try simple average.
            avg_sampled_soft_norm += avg_pair_norm;
            detail_sample_weight_sum += 1.0;
		}
        if (detail_sample_weight_sum > 0.0) {
             avg_sampled_soft_norm /= detail_sample_weight_sum; // Calculate average distance
        } else {
             avg_sampled_soft_norm = effective_hard_edge_norm; // Fallback
        }
	}
    // --- End Detailed Sampling ---

    // Use the averaged sample result as the base for the final offset
    float soft_edge_base_norm = avg_sampled_soft_norm;

    // --- Relaxed Final Offset Calculation ---
    // Allow offset to be larger, based more on soft_shadow_width
	float desired_offset = base_soft_width; // Use the calculated width more directly
    // Limit offset based on edge distance, but allow larger offsets overall
	float max_allowed_offset = effective_hard_edge_norm * 0.8 + soft_shadow_width * 0.2; // Allow going further back
	float final_offset = min(desired_offset, max_allowed_offset);
    // Increase offset further away for very distant edges? Maybe not needed with averaging.

	float calculated_soft_edge_norm = soft_edge_base_norm - final_offset;

    // --- Final Clamping ---
    calculated_soft_edge_norm = max(0.001, calculated_soft_edge_norm); // Clamp near zero
    // Ensure soft edge isn't beyond the effective hard edge
    calculated_soft_edge_norm = min(calculated_soft_edge_norm, effective_hard_edge_norm);
    // Ensure soft edge isn't beyond the original hard edge
    calculated_soft_edge_norm = min(calculated_soft_edge_norm, hard_edge_norm);

    return calculated_soft_edge_norm; // Return final normalized soft edge distance
}


void fragment() {
	// Determine which light and angle
	int light_idx = int(UV.y * float(hole_count));
    if (light_idx < 0 || light_idx >= hole_count) { COLOR = vec4(1.,1.,0.,1.); return; } // Error Yellow

	float angle = UV.x * 2.0 * 3.14159265;

	// Get light data safely
	vec2 light_pos = hole_positions[light_idx];
	float light_radius = hole_radii[light_idx];
    if (light_radius <= 0.0) { COLOR = vec4(1.,1.,1.,1.); return; } // Fully lit

	// Calculate ray direction
	vec2 ray_dir = vec2(cos(angle), sin(angle));

	// Find nearest intersection distance
	float hard_shadow_dist = find_nearest_intersection_dist(light_pos, ray_dir, light_radius);

	// Calculate soft shadow edge distance (returns normalized 0-1 value)
	float soft_shadow_edge_norm = calculate_soft_shadow_edge(light_pos, ray_dir, light_radius, hard_shadow_dist);

    // Normalize the hard shadow distance
    float hard_shadow_edge_norm = hard_shadow_dist / light_radius;

	// Store normalized distances: R=HardEnd, G=SoftStart
    // Ensure G <= R before outputting
    soft_shadow_edge_norm = min(soft_shadow_edge_norm, hard_shadow_edge_norm);
	COLOR = vec4(hard_shadow_edge_norm, soft_shadow_edge_norm, 0.0, 1.0);
}