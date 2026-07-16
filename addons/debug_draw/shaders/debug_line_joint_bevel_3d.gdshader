shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_always;

#include "debug_line_joint_3d_common.gdshaderinc"

void vertex() {
  mat4 clip_from_local = PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX;
  vec4 clip_a = clip_from_local * vec4(1.0, 0.0, 0.0, 1.0);
  vec4 clip_b = clip_from_local * vec4(0.0, 0.0, 0.0, 1.0);
  vec4 clip_c = clip_from_local * vec4(0.0, 1.0, 0.0, 1.0);

  line_color = COLOR;
  joint_distance = INSTANCE_CUSTOM.y;
  joint_dash_enabled = INSTANCE_CUSTOM.z;
  joint_dash_params = (MODEL_MATRIX * vec4(0.0, 0.0, 1.0, 0.0)).xyz;

  if (clip_a.w < CLIP_W_EPSILON && clip_b.w < CLIP_W_EPSILON && clip_c.w < CLIP_W_EPSILON) {
    POSITION = vec4(0.0, 0.0, 2.0, 1.0);
  } else {
    clip_a = clip_near_plane(clip_a, clip_c);
    clip_b = clip_near_plane(clip_b, clip_a);
    clip_c = clip_near_plane(clip_c, clip_b);
    clip_a = clip_near_plane(clip_a, clip_c);

    vec2 screen_a = screen_from_clip(clip_a, VIEWPORT_SIZE);
    vec2 screen_b = screen_from_clip(clip_b, VIEWPORT_SIZE);
    vec2 screen_c = screen_from_clip(clip_c, VIEWPORT_SIZE);
    vec2 ab = safe_normalize(screen_b - screen_a);
    vec2 cb = safe_normalize(screen_b - screen_c);

    if (dot(ab, ab) < SCREEN_EPSILON || dot(cb, cb) < SCREEN_EPSILON) {
      POSITION = vec4(0.0, 0.0, 2.0, 1.0);
    } else {
      float width = max(INSTANCE_CUSTOM.x, 0.0);

      if (width > 0.0 && width < 1.0) {
        line_color.a *= width;
        width = 1.0;
      }

      int vertex_index = int(VERTEX.x);
      if (vertex_index < 3) {
        vec2 ab_norm = vec2(-ab.y, ab.x);
        vec2 cb_norm = vec2(cb.y, -cb.x);
        vec2 offset = bevel_offset(vertex_index, width, ab, cb, ab_norm, cb_norm);
        vec2 screen = screen_b + offset;
        vec2 ndc = screen / VIEWPORT_SIZE * 2.0 - 1.0;
        POSITION = vec4(ndc * clip_b.w, apply_depth_bias(clip_b, depth_bias), clip_b.w);
      } else {
        POSITION = vec4(0.0, 0.0, 2.0, 1.0);
      }
    }
  }
}
