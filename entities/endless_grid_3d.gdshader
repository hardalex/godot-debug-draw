shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_disabled, fog_disabled;

// Infinite grid rendering inspired by Blender's viewport floor grid behavior.
// The shader keeps similar high-level ideas: screen-space line coverage,
// decimal LOD layers, view/edge/far fades, and low-alpha stipple discard.

uniform float grid_size = 2000.0;
uniform float edge_fade_start_ratio = 0.0;
uniform float edge_fade_end_ratio = 1.0;
uniform float cell_size = 1.0;
uniform float line_width_pixels = 1.0;
uniform float min_lod_power = -3.0;
uniform float max_lod_power = 4.0;
uniform float camera_lod_distance = 1.0;
uniform float camera_far_clip = 2000.0;
uniform bool camera_is_orthogonal = false;
uniform bool debug_lod_colors = false;
uniform bool enable_grazing_opacity = true;
uniform float grazing_fade_start_factor = 0.052335956;
uniform float grazing_fade_end_factor = 0.34202015;
uniform bool enable_stipple_discard = false;
uniform bool enable_lod_center_fade = true;
uniform float lod_center_fade_line_count = 151.0;
uniform vec2 view_grid_center = vec2(0.0);
uniform vec4 thin_line_color : source_color = vec4(0.42, 0.42, 0.42, 0.45);
uniform vec4 thick_line_color : source_color = vec4(0.62, 0.62, 0.62, 0.65);

varying vec3 world_position;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


float grid_line_alpha(vec2 uv, float current_cell_size) {
	// Compute line coverage in pixel units so grid lines keep a stable screen-space width.
	vec2 coord = uv / current_cell_size;
	vec2 pixel_size = max(abs(dFdx(coord)) + abs(dFdy(coord)), vec2(0.00001));
	vec2 distance_to_line = min(fract(coord), 1.0 - fract(coord));
	vec2 distance_pixels = distance_to_line / pixel_size;

	// Apply a 1 px AA transition in pixel units to avoid hard edges and flicker on thin lines.
	float half_line_width_pixels = max(line_width_pixels, 0.25) * 0.5;
	vec2 coverage = 1.0 - smoothstep(
		vec2(max(half_line_width_pixels - 0.5, 0.0)),
		vec2(half_line_width_pixels + 0.5),
		distance_pixels
	);
	return max(coverage.x, coverage.y);
}


float lod_center_fade(vec2 uv, float current_cell_size) {
	if (!enable_lod_center_fade) {
		return 1.0;
	}

	float half_line_count = max(lod_center_fade_line_count * 0.5, 1.0);
	vec2 snapped_center = round(view_grid_center / current_cell_size) * current_cell_size;
	vec2 level_coord = (uv - snapped_center) / max(current_cell_size * half_line_count, 0.00001);
	if (camera_is_orthogonal) {
		float edge = 1.0 - min(1.0, dot(level_coord, level_coord));
		return edge * edge;
	}
	return 1.0 - min(1.0, length(level_coord));
}


void fragment() {
	vec2 uv = world_position.xz;

	float safe_cell_size = max(cell_size, 0.00001);
	float min_power = min(min_lod_power, max_lod_power - 2.0);
	float max_power = max(max_lod_power, min_power + 2.0);
	float min_lod_cell_size = safe_cell_size * pow(10.0, min_power);
	float lod_distance = max(camera_lod_distance, min_lod_cell_size);
	float current_lod_power = clamp(
		floor(log(lod_distance / safe_cell_size) / log(10.0)),
		min_power,
		max_power
	);

	// Select the current decimal LOD and fade toward the next coarser cell size.
	float current_lod_cell_size = safe_cell_size * pow(10.0, current_lod_power);
	float next_lod_cell_size = current_lod_cell_size * 10.0;
	float lod_fade = clamp(
		(lod_distance - current_lod_cell_size) / max(next_lod_cell_size - current_lod_cell_size, 0.00001),
		0.0,
		1.0
	);

	// Draw three neighboring LOD layers so fine lines fade out while major lines remain visible.
	float lod0_power = clamp(current_lod_power - 1.0, min_power, max_power);
	float lod1_power = clamp(current_lod_power, min_power, max_power);
	float lod2_power = clamp(current_lod_power + 1.0, min_power, max_power);
	float lod0_cell_size = safe_cell_size * pow(10.0, lod0_power);
	float lod1_cell_size = safe_cell_size * pow(10.0, lod1_power);
	float lod2_cell_size = safe_cell_size * pow(10.0, lod2_power);

	float lod0_alpha = grid_line_alpha(uv, lod0_cell_size) * lod_center_fade(uv, lod0_cell_size) * (1.0 - lod_fade);
	float lod1_alpha = grid_line_alpha(uv, lod1_cell_size) * lod_center_fade(uv, lod1_cell_size);
	float lod2_alpha = grid_line_alpha(uv, lod2_cell_size) * lod_center_fade(uv, lod2_cell_size);

	// Prevent overlapping LOD layers from stacking alpha and causing brightness jumps.
	float lod2_visible_alpha = lod2_alpha;
	float lod1_visible_alpha = lod1_alpha * (1.0 - lod2_visible_alpha);
	float lod0_visible_alpha = lod0_alpha * (1.0 - lod1_alpha) * (1.0 - lod2_visible_alpha);

	// Blend minor/current/major line colors across the active LOD transition.
	vec4 lod0_color = thin_line_color;
	vec4 lod1_color = mix(thick_line_color, thin_line_color, lod_fade);
	vec4 lod2_color = thick_line_color;
	if (debug_lod_colors) {
		// Debug the three LOD layers: blue = lower/finer, green = current, red = upper/coarser.
		// Replace only RGB without raising alpha so visibility remains directly comparable with debug off.
		lod0_color = vec4(0.1, 0.35, 1.0, lod0_color.a);
		lod1_color = vec4(0.1, 1.0, 0.25, lod1_color.a);
		lod2_color = vec4(1.0, 0.15, 0.1, lod2_color.a);
	}

	float lod0_layer_alpha = lod0_visible_alpha * lod0_color.a;
	float lod1_layer_alpha = lod1_visible_alpha * lod1_color.a;
	float lod2_layer_alpha = lod2_visible_alpha * lod2_color.a;
	float line_alpha = clamp(lod0_layer_alpha + lod1_layer_alpha + lod2_layer_alpha, 0.0, 1.0);
	vec3 line_color = (
		lod0_color.rgb * lod0_layer_alpha +
		lod1_color.rgb * lod1_layer_alpha +
		lod2_color.rgb * lod2_layer_alpha
	) / max(line_alpha, 0.00001);

	// Fade out near the finite mesh bounds so the grid appears endless.
	float half_grid_size = max(grid_size * 0.5, 0.00001);
	vec2 grid_center = MODEL_MATRIX[3].xz;
	vec2 normalized_grid_coord = (world_position.xz - grid_center) / half_grid_size;
	float edge_start = clamp(edge_fade_start_ratio, 0.0, 1.0);
	float edge_end = max(clamp(edge_fade_end_ratio, 0.0, 1.0), edge_start + 0.00001);
	float edge_progress = clamp(
		(length(normalized_grid_coord) - edge_start) / (edge_end - edge_start),
		0.0,
		1.0
	);
	float edge_opacity = 1.0 - edge_progress;
	if (camera_is_orthogonal) {
		edge_opacity = pow(1.0 - edge_progress * edge_progress, 2.0);
	}

	// Fade at grazing view angles to reduce distant transparent trails.
	float grazing_opacity = 1.0;
	if (enable_grazing_opacity) {
		vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_position);
		float view_floor_factor = abs(dot(view_dir, vec3(0.0, 1.0, 0.0)));
		float grazing_start = min(grazing_fade_start_factor, grazing_fade_end_factor);
		float grazing_end = max(grazing_fade_start_factor, grazing_fade_end_factor);
		float grazing_progress = step(grazing_start, view_floor_factor);
		if (grazing_end - grazing_start > 0.00001) {
			grazing_progress = clamp(
				(view_floor_factor - grazing_start) / (grazing_end - grazing_start),
				0.0,
				1.0
			);
		}
		grazing_opacity = smoothstep(0.0, 1.0, grazing_progress);
	}

	// Fade near the camera far clip before the grid is clipped by depth.
	float far_clip = max(camera_far_clip, 0.00001);
	float camera_distance = length(CAMERA_POSITION_WORLD - world_position);
	float distance_opacity = 1.0 - smoothstep(0.0, 0.5 * far_clip, camera_distance - 0.5 * far_clip);

	ALBEDO = line_color;
	ALPHA = line_alpha * edge_opacity * distance_opacity * grazing_opacity;

	// Use stipple discard at low alpha to avoid muddy trails from transparent depth blending.
	const float dash_width = 4.0;
	const float fade_start = 0.1;
	vec2 dash_coord = uv / lod1_cell_size;
	vec2 dash_distance_to_line = min(fract(dash_coord), 1.0 - fract(dash_coord));
	float dash_axis = dash_distance_to_line.x < dash_distance_to_line.y ? FRAGCOORD.y : FRAGCOORD.x;
	if (enable_stipple_discard && ALPHA < fade_start && ALPHA / fade_start < fract(dash_axis / dash_width)) {
		discard;
	}

	if (ALPHA <= 0.001) {
		discard;
	}
}
