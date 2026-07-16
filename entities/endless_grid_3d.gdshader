shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_always, cull_disabled, fog_disabled;

uniform float grid_size = 2000.0;
uniform float cell_size = 1.0;
uniform float min_pixels_between_cells = 2.0;
uniform float line_width_pixels = 1.0;
uniform float min_lod_power = -3.0;
uniform float max_lod_power = 4.0;
uniform float camera_lod_distance = 1.0;
uniform float camera_far_clip = 2000.0;
uniform bool camera_is_orthogonal = false;
uniform bool debug_lod_colors = false;
uniform bool enable_grazing_opacity = true;
uniform vec4 thin_line_color : source_color = vec4(0.42, 0.42, 0.42, 0.45);
uniform vec4 thick_line_color : source_color = vec4(0.62, 0.62, 0.62, 0.65);

varying vec3 world_position;


void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


float grid_line_alpha(vec2 uv, float current_cell_size) {
	// Match Blender's screen-space line width and AA approach: center lines on cell borders,
	// and estimate one pixel in grid space from coordinate derivatives to avoid one-sided mod coverage flicker during rotation.
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

	// Match Blender: compute the fractional level from the linear distance between adjacent steps, not log space.
	// At the upper bound, still use a virtual next step for fading, equivalent to Blender's final curr * 10 step.
	float current_lod_cell_size = safe_cell_size * pow(10.0, current_lod_power);
	float next_lod_cell_size = current_lod_cell_size * 10.0;
	float lod_fade = clamp(
		(lod_distance - current_lod_cell_size) / max(next_lod_cell_size - current_lod_cell_size, 0.00001),
		0.0,
		1.0
	);

	// Match Blender's use_level_offset: draw lower/current/upper layers around the current LOD.
	// Clamp each layer separately to the mathematically generated 8-level range, similar to Blender's lookup-level clamp.
	float lod0_power = clamp(current_lod_power - 1.0, min_power, max_power);
	float lod1_power = clamp(current_lod_power, min_power, max_power);
	float lod2_power = clamp(current_lod_power + 1.0, min_power, max_power);
	float lod0_cell_size = safe_cell_size * pow(10.0, lod0_power);
	float lod1_cell_size = safe_cell_size * pow(10.0, lod1_power);
	float lod2_cell_size = safe_cell_size * pow(10.0, lod2_power);

	float lod0_alpha = grid_line_alpha(uv, lod0_cell_size) * (1.0 - lod_fade);
	float lod1_alpha = grid_line_alpha(uv, lod1_cell_size);
	float lod2_alpha = grid_line_alpha(uv, lod2_cell_size);

	// Match Blender: higher-level lines occlude lower-level overlaps to avoid brightness jumps from stacked layers.
	float lod2_visible_alpha = lod2_alpha;
	float lod1_visible_alpha = lod1_alpha * (1.0 - lod2_visible_alpha);
	float lod0_visible_alpha = lod0_alpha * (1.0 - lod1_alpha) * (1.0 - lod2_visible_alpha);

	// Match Blender: the current layer fades from accent to normal color, while the lower layer fades by fractional level.
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

	// Match Blender: fade at the grid bounds. Perspective uses linear radius fade; orthographic uses squared fade.
	float half_grid_size = max(grid_size * 0.5, 0.00001);
	vec2 grid_center = MODEL_MATRIX[3].xz;
	vec2 normalized_grid_coord = (world_position.xz - grid_center) / half_grid_size;
	float edge_opacity = 1.0 - min(1.0, length(normalized_grid_coord));
	if (camera_is_orthogonal) {
		edge_opacity = pow(1.0 - min(1.0, dot(normalized_grid_coord, normalized_grid_coord)), 2.0);
	}

	// Match Blender: fade when viewing the ground at grazing angles, using pow3 instead of a more aggressive exponent.
	float grazing_opacity = 1.0;
	if (enable_grazing_opacity) {
		vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_position);
		float view_floor_factor = abs(dot(view_dir, vec3(0.0, 1.0, 0.0)));
		grazing_opacity = 1.0 - pow(1.0 - view_floor_factor, 3.0);
	}

	// Match Blender: fade near the far clip, gradually disappearing from far/2.
	float far_clip = max(camera_far_clip, 0.00001);
	float camera_distance = length(CAMERA_POSITION_WORLD - world_position);
	float distance_opacity = 1.0 - smoothstep(0.0, 0.5 * far_clip, camera_distance - 0.5 * far_clip);

	ALBEDO = line_color;
	ALPHA = line_alpha * edge_opacity * distance_opacity * grazing_opacity;

	// Match Blender: use stipple dashes/dither discard at low alpha to avoid muddy trails from transparent depth blending.
	const float dash_width = 4.0;
	const float fade_start = 0.1;
	vec2 dash_coord = uv / lod1_cell_size;
	vec2 dash_distance_to_line = min(fract(dash_coord), 1.0 - fract(dash_coord));
	float dash_axis = dash_distance_to_line.x < dash_distance_to_line.y ? FRAGCOORD.y : FRAGCOORD.x;
	if (ALPHA < fade_start && ALPHA / fade_start < fract(dash_axis / dash_width)) {
		discard;
	}

	if (ALPHA <= 0.001) {
		discard;
	}
}
