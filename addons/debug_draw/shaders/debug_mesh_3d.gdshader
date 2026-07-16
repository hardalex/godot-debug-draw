shader_type spatial;
render_mode unshaded, cull_back, blend_mix, depth_draw_always;

const float DEPTH_BIAS_EPSILON = 0.000488;

uniform float depth_bias = 0.0;

float apply_depth_bias(vec4 clip, float bias) {
  bias = clamp(bias, -1.0, 1.0);
  if (bias >= 0.0) {
    return clip.z * (1.0 - bias);
  }
  float safe_depth = max(clip.z, DEPTH_BIAS_EPSILON);
  float depth_ratio = max(clip.w / safe_depth - DEPTH_BIAS_EPSILON, DEPTH_BIAS_EPSILON);
  return clip.z * exp2(-bias * log2(depth_ratio));
}

void vertex() {
  vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
  POSITION = vec4(clip.xy, apply_depth_bias(clip, depth_bias), clip.w);
}

void fragment() {
  ALBEDO = COLOR.rgb;
  ALPHA = COLOR.a;
}
