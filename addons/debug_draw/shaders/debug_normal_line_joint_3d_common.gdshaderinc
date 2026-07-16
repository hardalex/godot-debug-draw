#include "debug_line_joint_geometry_3d.gdshaderinc"

const float NORMAL_BACK_FADE_ANGLE_MAX = 3.14159265359;
const float NORMAL_BACK_FADE_ANGLE_EPSILON = 0.0001;

uniform float back_fade_start = 1.74532925199;
uniform float back_fade_transition = 0.34906585040;

varying vec4 line_color;
varying float joint_distance;
varying vec3 joint_dash_params;

float normal_fade(vec3 normal, vec3 position) {
  vec3 view_dir = normalize(-position);
  float facing_dot = dot(normal, view_dir);
  float fade_start_angle = clamp(back_fade_start, 0.0, NORMAL_BACK_FADE_ANGLE_MAX - NORMAL_BACK_FADE_ANGLE_EPSILON);
  float fade_end_angle = min(
    fade_start_angle + max(back_fade_transition, NORMAL_BACK_FADE_ANGLE_EPSILON),
    NORMAL_BACK_FADE_ANGLE_MAX
  );
  float fade_start_dot = cos(fade_start_angle);
  float fade_end_dot = cos(fade_end_angle);
  return mix(0.2, 1.0, smoothstep(fade_end_dot, fade_start_dot, facing_dot));
}

vec3 unpack_joint_normal(float packed) {
  float x = floor(packed / 256.0);
  float y = packed - x * 256.0;
  vec2 encoded = vec2(x, y) / 255.0 * 2.0 - 1.0;
  vec3 normal = vec3(encoded.x, encoded.y, 1.0 - abs(encoded.x) - abs(encoded.y));
  float t = clamp(-normal.z, 0.0, 1.0);
  normal.x += (normal.x >= 0.0) ? -t : t;
  normal.y += (normal.y >= 0.0) ? -t : t;
  return normalize(normal);
}

float joint_normal_fade(
    float normal_t,
    vec3 view_position,
    float previous_normal_packed,
    float next_normal_packed,
    mat4 view_matrix
) {
  vec3 previous_normal = unpack_joint_normal(previous_normal_packed);
  vec3 next_normal = unpack_joint_normal(next_normal_packed);
  vec3 normal = normalize(mix(previous_normal, next_normal, clamp(normal_t, 0.0, 1.0)));
  vec3 view_normal = normalize((view_matrix * vec4(normal, 0.0)).xyz);
  return normal_fade(view_normal, view_position);
}

float round_normal_t(int vertex_index, int resolution) {
  int triangle_index = vertex_index / 3;
  int in_triangle_index = vertex_index - triangle_index * 3;
  if (in_triangle_index == 0) {
    return (float(triangle_index) + 0.5) / float(max(resolution, 1));
  }
  return (float(triangle_index) + float(in_triangle_index) - 1.0) / float(max(resolution, 1));
}

float bevel_normal_t(int vertex_index) {
  int local_index = vertex_index % 3;
  if (local_index == 1) {
    return 1.0;
  }
  if (local_index == 2) {
    return 0.0;
  }
  return 0.5;
}

float miter_normal_t(int vertex_index) {
  int local_index = vertex_index % 6;
  if (local_index == 1) {
    return 0.0;
  }
  if (local_index == 2 || local_index == 4) {
    return 0.5;
  }
  if (local_index == 5) {
    return 1.0;
  }
  if (local_index == 3) {
    return 0.75;
  }
  return 0.25;
}

void fragment() {
  if (joint_dash_params.x > 0.0) {
    float visible_length = max(joint_dash_params.x, 0.0);
    float period = max(visible_length + max(joint_dash_params.y, 0.0), 0.0001);
    float phase = mod(joint_distance - joint_dash_params.z, period);
    if (phase > visible_length) {
      discard;
    }
  }

  ALBEDO = line_color.rgb;
  ALPHA = line_color.a;
}
