extends "res://addons/debug_draw/renderers/debug_joint_renderer_3d.gd"

var _back_fade_start := deg_to_rad(100.0)
var _back_fade_transition := deg_to_rad(20.0)


func set_back_fade_parameters(start: float, transition: float) -> void:
  _back_fade_start = start
  _back_fade_transition = transition
  if _mesh_instance == null:
    return

  var material := _mesh_instance.material_override as ShaderMaterial
  if material != null:
    material.set_shader_parameter(&"back_fade_start", _back_fade_start)
    material.set_shader_parameter(&"back_fade_transition", _back_fade_transition)


func emit_normal_joint(
    previous: Vector3,
    center: Vector3,
    next: Vector3,
    previous_normal: Vector3,
    next_normal: Vector3,
    color: Color,
    width: float,
    layer: int,
    distance: float = 0.0,
    dashed: bool = false,
    dash_width_value: float = 0.0,
    dash_space_value: float = 0.0,
    dash_offset_value: float = 0.0,
) -> void:
  if previous.is_equal_approx(center) or center.is_equal_approx(next):
    return

  _append_normal_buffer(
    previous,
    center,
    next,
    previous_normal,
    next_normal,
    color,
    width,
    distance,
    dashed,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
  )
  _layers.append(layer)


func _create_material() -> ShaderMaterial:
  var material := super._create_material()
  material.set_shader_parameter(&"back_fade_start", _back_fade_start)
  material.set_shader_parameter(&"back_fade_transition", _back_fade_transition)
  return material


func _append_normal_buffer(
    previous: Vector3,
    center: Vector3,
    next: Vector3,
    previous_normal: Vector3,
    next_normal: Vector3,
    color: Color,
    width: float,
    distance: float,
    dashed: bool,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
) -> void:
  var resolved_dash_width := dash_width_value if dashed else 0.0
  var basis := Basis(previous - center, next - center, Vector3(resolved_dash_width, dash_space_value, dash_offset_value))

  _buffer.append(basis.x.x)
  _buffer.append(basis.y.x)
  _buffer.append(basis.z.x)
  _buffer.append(center.x)
  _buffer.append(basis.x.y)
  _buffer.append(basis.y.y)
  _buffer.append(basis.z.y)
  _buffer.append(center.y)
  _buffer.append(basis.x.z)
  _buffer.append(basis.y.z)
  _buffer.append(basis.z.z)
  _buffer.append(center.z)
  _buffer.append(color.r)
  _buffer.append(color.g)
  _buffer.append(color.b)
  _buffer.append(color.a)
  _buffer.append(width)
  _buffer.append(distance)
  _buffer.append(_pack_normal(previous_normal))
  _buffer.append(_pack_normal(next_normal))


func _pack_normal(normal: Vector3) -> float:
  var resolved := _resolve_normal(normal)
  var denominator := absf(resolved.x) + absf(resolved.y) + absf(resolved.z)
  var encoded := Vector2.ZERO
  if denominator > 0.0:
    encoded = Vector2(resolved.x, resolved.y) / denominator

  if resolved.z < 0.0:
    encoded = Vector2(
      (1.0 - absf(encoded.y)) * _sign_not_zero(encoded.x),
      (1.0 - absf(encoded.x)) * _sign_not_zero(encoded.y),
    )

  var x := clampi(roundi((encoded.x * 0.5 + 0.5) * 255.0), 0, 255)
  var y := clampi(roundi((encoded.y * 0.5 + 0.5) * 255.0), 0, 255)
  return float(x * 256 + y)


func _resolve_normal(normal: Vector3) -> Vector3:
  if normal.length_squared() > 0.0:
    return normal.normalized()
  return Vector3.BACK


func _sign_not_zero(value: float) -> float:
  if value < 0.0:
    return -1.0
  return 1.0
