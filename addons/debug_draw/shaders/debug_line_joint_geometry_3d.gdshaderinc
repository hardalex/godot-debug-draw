const float CLIP_W_EPSILON = 0.0001;
const float NEAR_CLIP_EPSILON = 0.000488;
const float DEPTH_BIAS_EPSILON = 0.000488;
const float SCREEN_EPSILON = 0.0001;

uniform float depth_bias = 0.0;
uniform int round_resolution = 8;
uniform float miter_limit = 4.0;

vec4 clip_near_plane(vec4 a, vec4 b) {
  if (a.z > a.w && b.z <= b.w) {
    float distance_a = a.z - a.w;
    float distance_b = b.z - b.w;
    float t = distance_a / (distance_a - distance_b) + NEAR_CLIP_EPSILON;
    return mix(a, b, t);
  }
  return a;
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

vec2 screen_from_clip(vec4 clip, vec2 viewport_size) {
  return viewport_size * (0.5 * clip.xy / clip.w + 0.5);
}

vec2 safe_normalize(vec2 value) {
  float length_sq = dot(value, value);
  if (length_sq < SCREEN_EPSILON) {
    return vec2(0.0, 0.0);
  }
  return value * inversesqrt(length_sq);
}

vec2 limit_vector(vec2 value, float max_length) {
  float length_sq = dot(value, value);
  float max_length_sq = max_length * max_length;
  if (length_sq > max_length_sq && length_sq > SCREEN_EPSILON) {
    return value * (max_length * inversesqrt(length_sq));
  }
  return value;
}

vec2 round_offset(int vertex_index, int resolution, float width, vec2 ab, vec2 ab_norm, vec2 cb_norm, vec2 cb) {
  int triangle_index = vertex_index / 3;
  int in_triangle_index = vertex_index - triangle_index * 3;
  float radius = sign(float(in_triangle_index)) * 0.5 * width;
  float theta = acos(clamp(dot(ab_norm, cb_norm), -1.0, 1.0));
  float sigma = sign(dot(ab_norm, cb));

  if (sigma == 0.0) {
    sigma = 1.0;
  }

  float angle = theta * (float(triangle_index) + float(in_triangle_index) - 1.0) / float(max(resolution, 1));
  float position_x = sigma * radius * cos(angle);
  float position_y = radius * sin(angle);
  return position_x * ab_norm + position_y * ab;
}

vec2 bevel_offset(int vertex_index, float width, vec2 ab, vec2 cb, vec2 ab_norm, vec2 cb_norm) {
  int local_index = vertex_index % 3;
  vec2 tangent = safe_normalize(ab - cb);
  vec2 normal = vec2(-tangent.y, tangent.x);
  float sigma = sign(dot(ab + cb, normal));

  if (sigma == 0.0) {
    sigma = 1.0;
  }

  vec2 p0 = width * sigma * ab_norm;
  vec2 p1 = width * sigma * cb_norm;

  if (local_index == 1) {
    return 0.5 * p1;
  }
  if (local_index == 2) {
    return 0.5 * p0;
  }
  return vec2(0.0, 0.0);
}

vec2 miter_offset(int vertex_index, float width, vec2 ab, vec2 cb, vec2 ab_norm, vec2 cb_norm) {
  int local_index = vertex_index % 6;
  vec2 tangent = safe_normalize(ab - cb);
  vec2 normal = vec2(-tangent.y, tangent.x);
  float sigma = sign(dot(ab + cb, normal));

  if (sigma == 0.0) {
    sigma = 1.0;
  }

  float denominator = dot(normal, ab_norm);
  if (abs(denominator) < SCREEN_EPSILON) {
    return bevel_offset(vertex_index, width, ab, cb, ab_norm, cb_norm);
  }

  vec2 p0 = width * sigma * ab_norm;
  vec2 p1 = limit_vector(width * sigma * normal / denominator, width * max(miter_limit, 1.0));
  vec2 p2 = width * sigma * cb_norm;

  if (local_index == 1) {
    return 0.5 * p0;
  }
  if (local_index == 2 || local_index == 4) {
    return 0.5 * p1;
  }
  if (local_index == 5) {
    return 0.5 * p2;
  }
  return vec2(0.0, 0.0);
}
