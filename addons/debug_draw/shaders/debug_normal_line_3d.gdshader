shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_always;

const float CLIP_W_EPSILON = 0.0001;
const float NEAR_CLIP_EPSILON = 0.000488;
const float DEPTH_BIAS_EPSILON = 0.000488;
const float SCREEN_EPSILON = 0.0001;
const float NORMAL_BACK_FADE_ANGLE_MAX = 3.14159265359;
const float NORMAL_BACK_FADE_ANGLE_EPSILON = 0.0001;

uniform float depth_bias = 0.0;
uniform float back_fade_start = 1.74532925199;
uniform float back_fade_transition = 0.34906585040;

varying vec4 line_color;
varying float path_distance;
varying float line_dash_enabled;
varying vec3 line_dash_params;

float clip_near_plane_t(vec4 a, vec4 b) {
  if (a.z > a.w && b.z <= b.w) {
    float distance_a = a.z - a.w;
    float distance_b = b.z - b.w;
    return clamp(distance_a / (distance_a - distance_b) + NEAR_CLIP_EPSILON, 0.0, 1.0);
  }
  return 0.0;
}

float apply_depth_bias(vec4 clip, float bias) {
  bias = clamp(bias, -1.0, 1.0);
  if (bias >= 0.0) {
    return clip.z * (1.0 - bias);
  }

  float safe_depth = max(clip.z, DEPTH_BIAS_EPSILON);
  float depth_ratio = max(clip.w / safe_depth - DEPTH_BIAS_EPSILON, DEPTH_BIAS_EPSILON);
  return clip.z * exp2(-bias * log2(depth_ratio));
}

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

void vertex() {
  mat4 view_from_local = VIEW_MATRIX * MODEL_MATRIX;
  mat4 clip_from_local = PROJECTION_MATRIX * view_from_local;
  vec4 clip_a = clip_from_local * vec4(0.0, 0.0, 0.0, 1.0);
  vec4 clip_b = clip_from_local * vec4(1.0, 0.0, 0.0, 1.0);
  vec3 line_center = (view_from_local * vec4(0.5, 0.0, 0.0, 1.0)).xyz;
  vec3 line_normal = normalize((view_from_local * vec4(0.0, 0.0, 1.0, 0.0)).xyz);

  line_color = COLOR;
  line_color.rgb *= normal_fade(line_normal, line_center);
  path_distance = 0.0;
  line_dash_enabled = INSTANCE_CUSTOM.w;
  line_dash_params = (MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;

  if (clip_a.w < CLIP_W_EPSILON && clip_b.w < CLIP_W_EPSILON) {
    POSITION = vec4(0.0, 0.0, 2.0, 1.0);
  } else {
    float distance_a = INSTANCE_CUSTOM.y;
    float distance_b = INSTANCE_CUSTOM.z;
    float clip_t = clip_near_plane_t(clip_a, clip_b);
    if (clip_t > 0.0) {
      clip_a = mix(clip_a, clip_b, clip_t);
      distance_a = mix(distance_a, distance_b, clip_t);
    }

    clip_t = clip_near_plane_t(clip_b, clip_a);
    if (clip_t > 0.0) {
      clip_b = mix(clip_b, clip_a, clip_t);
      distance_b = mix(distance_b, distance_a, clip_t);
    }

    vec2 screen_a = VIEWPORT_SIZE * (0.5 * clip_a.xy / clip_a.w + 0.5);
    vec2 screen_b = VIEWPORT_SIZE * (0.5 * clip_b.xy / clip_b.w + 0.5);
    vec2 screen_delta = screen_b - screen_a;

    if (dot(screen_delta, screen_delta) < SCREEN_EPSILON) {
      POSITION = vec4(0.0, 0.0, 2.0, 1.0);
    } else {
      float side = VERTEX.x;
      float along = VERTEX.y;
      float width = max(INSTANCE_CUSTOM.x, 0.0);
      path_distance = mix(distance_a, distance_b, along);

      if (width > 0.0 && width < 1.0) {
        line_color.a *= width;
        width = 1.0;
      }

      vec2 y_basis = normalize(screen_delta);
      vec2 x_basis = vec2(-y_basis.y, y_basis.x);
      vec4 clip = mix(clip_a, clip_b, along);
      vec2 screen = mix(screen_a, screen_b, along) + x_basis * side * width;
      vec2 ndc = screen / VIEWPORT_SIZE * 2.0 - 1.0;

      POSITION = vec4(ndc * clip.w, apply_depth_bias(clip, depth_bias), clip.w);
    }
  }
}

void fragment() {
  if (line_dash_enabled > 0.5) {
    float visible_length = max(line_dash_params.x, 0.0);
    float period = max(visible_length + max(line_dash_params.y, 0.0), 0.0001);
    float phase = mod(path_distance - line_dash_params.z, period);
    if (phase > visible_length) {
      discard;
    }
  }

  ALBEDO = line_color.rgb;
  ALPHA = line_color.a;
}
