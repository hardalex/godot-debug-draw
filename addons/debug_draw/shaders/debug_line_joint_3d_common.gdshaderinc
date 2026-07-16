#include "debug_line_joint_geometry_3d.gdshaderinc"

varying vec4 line_color;
varying float joint_distance;
varying float joint_dash_enabled;
varying vec3 joint_dash_params;

void fragment() {
  if (joint_dash_enabled > 0.5) {
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
