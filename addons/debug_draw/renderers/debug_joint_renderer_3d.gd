extends RefCounted

const BUFFER_STRIDE := 20

var _buffer := PackedFloat32Array()
var _layers := PackedInt32Array()
var _visible_buffer := PackedFloat32Array()
var _mesh_instance: MultiMeshInstance3D
var _shader: Shader
var _depth_bias := 0.0
var _round_resolution := 8
var _miter_limit := 4.0


func setup(
    mesh_instance: MultiMeshInstance3D,
    mesh: ArrayMesh,
    shader: Shader,
    depth_bias: float,
    round_resolution: int,
    miter_limit: float,
) -> void:
  _mesh_instance = mesh_instance
  _shader = shader
  _depth_bias = depth_bias
  _round_resolution = round_resolution
  _miter_limit = miter_limit

  var multi_mesh := MultiMesh.new()
  multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
  multi_mesh.use_colors = true
  multi_mesh.use_custom_data = true
  multi_mesh.mesh = mesh
  multi_mesh.visible_instance_count = 0

  mesh_instance.multimesh = multi_mesh
  mesh_instance.material_override = _create_material()
  mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func set_material_parameters(shader: Shader, depth_bias: float, round_resolution: int, miter_limit: float) -> void:
  _shader = shader
  _depth_bias = depth_bias
  _round_resolution = round_resolution
  _miter_limit = miter_limit

  if _mesh_instance != null:
    _mesh_instance.material_override = _create_material()


func set_mesh(mesh: ArrayMesh) -> void:
  if _mesh_instance == null:
    return

  var multi_mesh := _mesh_instance.multimesh
  if multi_mesh != null:
    multi_mesh.mesh = mesh


func set_depth_bias(depth_bias: float) -> void:
  _depth_bias = depth_bias
  if _mesh_instance == null:
    return

  var material := _mesh_instance.material_override as ShaderMaterial
  if material != null:
    material.set_shader_parameter(&"depth_bias", depth_bias)


func emit_joint(
    previous: Vector3,
    center: Vector3,
    next: Vector3,
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

  _append_buffer(
    previous,
    center,
    next,
    color,
    width,
    distance,
    dashed,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
  )
  _layers.append(layer)


func commit(visible_layers: int, source_aabb: AABB) -> void:
  var visible_count := _get_visible_count(visible_layers)
  var multi_mesh := _mesh_instance.multimesh
  _ensure_multimesh_capacity(multi_mesh, visible_count)
  multi_mesh.visible_instance_count = visible_count

  if visible_count == 0 or not source_aabb.has_volume():
    multi_mesh.custom_aabb = AABB()
    return

  multi_mesh.buffer = _get_visible_buffer(visible_count, multi_mesh.instance_count, visible_layers)
  multi_mesh.custom_aabb = source_aabb


func clear() -> void:
  var multi_mesh := _mesh_instance.multimesh
  multi_mesh.visible_instance_count = 0
  multi_mesh.custom_aabb = AABB()


func reset() -> void:
  _buffer.clear()
  _layers.clear()
  _visible_buffer.clear()


func _create_material() -> ShaderMaterial:
  var material := ShaderMaterial.new()
  material.shader = _shader
  material.set_shader_parameter(&"depth_bias", _depth_bias)
  material.set_shader_parameter(&"round_resolution", _round_resolution)
  material.set_shader_parameter(&"miter_limit", _miter_limit)
  material.render_priority = Material.RENDER_PRIORITY_MIN + 1
  return material


func _append_buffer(
    previous: Vector3,
    center: Vector3,
    next: Vector3,
    color: Color,
    width: float,
    distance: float,
    dashed: bool,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
) -> void:
  var basis := Basis(previous - center, next - center, Vector3(dash_width_value, dash_space_value, dash_offset_value))

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
  _buffer.append(1.0 if dashed else 0.0)
  _buffer.append(0.0)


func _get_visible_count(visible_layers: int) -> int:
  var count := 0
  for layer in _layers:
    if _is_layer_visible(layer, visible_layers):
      count += 1
  return count


func _get_visible_buffer(visible_count: int, instance_count: int, visible_layers: int) -> PackedFloat32Array:
  var upload_size := instance_count * BUFFER_STRIDE
  if visible_count == _layers.size():
    _buffer.resize(upload_size)
    return _buffer

  _visible_buffer.resize(upload_size)
  var write_index := 0
  for i in _layers.size():
    if not _is_layer_visible(_layers[i], visible_layers):
      continue

    _copy_buffer_entry(_buffer, i, _visible_buffer, write_index)
    write_index += 1

  return _visible_buffer


func _copy_buffer_entry(
    from_buffer: PackedFloat32Array,
    from_index: int,
    to_buffer: PackedFloat32Array,
    to_index: int,
) -> void:
  var from_offset := from_index * BUFFER_STRIDE
  var to_offset := to_index * BUFFER_STRIDE
  for i in BUFFER_STRIDE:
    to_buffer[to_offset + i] = from_buffer[from_offset + i]


func _is_layer_visible(layer: int, visible_layers: int) -> bool:
  return layer > 0 and (visible_layers & layer) != 0


func _ensure_multimesh_capacity(multi_mesh: MultiMesh, count: int) -> void:
  if count <= multi_mesh.instance_count:
    return

  var capacity := maxi(1, multi_mesh.instance_count)
  while capacity < count:
    capacity *= 2

  multi_mesh.visible_instance_count = 0
  multi_mesh.instance_count = capacity
