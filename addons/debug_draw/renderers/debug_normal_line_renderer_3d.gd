extends "res://addons/debug_draw/renderers/debug_line_renderer_3d.gd"

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


func emit_line(
    from: Vector3,
    to: Vector3,
    normal: Vector3,
    color: Color,
    width: float,
    layer: int,
    dash_width_value: float = 0.0,
    dash_space_value: float = 0.0,
    dash_offset_value: float = 0.0,
    distance_start: float = 0.0,
    distance_end: float = -1.0,
    dashed: bool = false,
) -> void:
  if from.is_equal_approx(to):
    return

  if distance_end < 0.0:
    distance_end = distance_start + from.distance_to(to)

  _append_normal_buffer(
    from,
    to,
    _resolve_normal(normal),
    color,
    width,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
    distance_start,
    distance_end,
    dashed,
  )
  _layers.append(layer)


func _create_material(shader: Shader, depth_bias: float) -> ShaderMaterial:
  var material := super._create_material(shader, depth_bias)
  material.set_shader_parameter(&"back_fade_start", _back_fade_start)
  material.set_shader_parameter(&"back_fade_transition", _back_fade_transition)
  return material


func _append_normal_buffer(
    start: Vector3,
    end: Vector3,
    normal: Vector3,
    color: Color,
    width: float,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
    distance_start: float,
    distance_end: float,
    dashed: bool,
) -> void:
  var basis := Basis(end - start, Vector3(dash_width_value, dash_space_value, dash_offset_value), normal)

  _buffer.append(basis.x.x)
  _buffer.append(basis.y.x)
  _buffer.append(basis.z.x)
  _buffer.append(start.x)
  _buffer.append(basis.x.y)
  _buffer.append(basis.y.y)
  _buffer.append(basis.z.y)
  _buffer.append(start.y)
  _buffer.append(basis.x.z)
  _buffer.append(basis.y.z)
  _buffer.append(basis.z.z)
  _buffer.append(start.z)
  _buffer.append(color.r)
  _buffer.append(color.g)
  _buffer.append(color.b)
  _buffer.append(color.a)
  _buffer.append(width)
  _buffer.append(distance_start)
  _buffer.append(distance_end)
  _buffer.append(1.0 if dashed else 0.0)


func _resolve_normal(normal: Vector3) -> Vector3:
  if normal.length_squared() > 0.0:
    return normal.normalized()
  return Vector3.BACK
