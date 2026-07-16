extends RefCounted

const BUFFER_STRIDE := 20
const MIN_AABB_GROW := 0.25

var _buffer := PackedFloat32Array()
var _layers := PackedInt32Array()
var _visible_buffer := PackedFloat32Array()
var _mesh_instance: MultiMeshInstance3D


func setup(mesh_instance: MultiMeshInstance3D, mesh: ArrayMesh, shader: Shader, depth_bias: float) -> void:
  _mesh_instance = mesh_instance

  var multi_mesh := MultiMesh.new()
  multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
  multi_mesh.use_colors = true
  multi_mesh.use_custom_data = true
  multi_mesh.mesh = mesh
  multi_mesh.visible_instance_count = 0

  mesh_instance.multimesh = multi_mesh
  mesh_instance.material_override = _create_material(shader, depth_bias)
  mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func set_depth_bias(depth_bias: float) -> void:
  if _mesh_instance == null:
    return

  var material := _mesh_instance.material_override as ShaderMaterial
  if material != null:
    material.set_shader_parameter(&"depth_bias", depth_bias)


func emit_regular_line(
    from: Vector3,
    to: Vector3,
    color: Color,
    width: float,
    layer: int,
    distance_start: float = 0.0,
    distance_end: float = -1.0,
    dashed: bool = false,
    dash_width_value: float = 0.0,
    dash_space_value: float = 0.0,
    dash_offset_value: float = 0.0,
) -> void:
  if from.is_equal_approx(to):
    return

  if distance_end < 0.0:
    distance_end = distance_start + from.distance_to(to)

  _append_buffer(
    from,
    to,
    color,
    width,
    distance_start,
    distance_end,
    dashed,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
  )
  _layers.append(layer)


func commit(visible_layers: int) -> AABB:
  var visible_count := _get_visible_count(visible_layers)
  var multi_mesh := _mesh_instance.multimesh
  _ensure_multimesh_capacity(multi_mesh, visible_count)
  multi_mesh.visible_instance_count = visible_count

  if visible_count == 0:
    multi_mesh.custom_aabb = AABB()
    return multi_mesh.custom_aabb

  var upload_buffer := _get_visible_buffer(visible_count, multi_mesh.instance_count, visible_layers)
  multi_mesh.buffer = upload_buffer
  multi_mesh.custom_aabb = _get_buffer_aabb(upload_buffer, visible_count).grow(MIN_AABB_GROW)
  return multi_mesh.custom_aabb


func clear() -> void:
  var multi_mesh := _mesh_instance.multimesh
  multi_mesh.visible_instance_count = 0
  multi_mesh.custom_aabb = AABB()


func reset() -> void:
  _buffer.clear()
  _layers.clear()
  _visible_buffer.clear()


func _create_material(shader: Shader, depth_bias: float) -> ShaderMaterial:
  var material := ShaderMaterial.new()
  material.shader = shader
  material.set_shader_parameter(&"depth_bias", depth_bias)
  material.render_priority = Material.RENDER_PRIORITY_MIN
  return material


func _append_buffer(
    start: Vector3,
    end: Vector3,
    color: Color,
    width: float,
    distance_start: float,
    distance_end: float,
    dashed: bool,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
) -> void:
  var basis := Basis(end - start, Vector3(dash_width_value, dash_space_value, dash_offset_value), Vector3.BACK)

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


func _get_buffer_aabb(buffer: PackedFloat32Array, count: int) -> AABB:
  var start := _get_buffer_start(buffer, 0)
  var aabb := AABB(start, Vector3.ZERO)
  for i in count:
    start = _get_buffer_start(buffer, i)
    var end := _get_buffer_end(buffer, i, start)
    aabb = aabb.expand(start)
    aabb = aabb.expand(end)
  return aabb


func _get_buffer_start(buffer: PackedFloat32Array, index: int) -> Vector3:
  var offset := index * BUFFER_STRIDE
  return Vector3(buffer[offset + 3], buffer[offset + 7], buffer[offset + 11])


func _get_buffer_end(buffer: PackedFloat32Array, index: int, start: Vector3) -> Vector3:
  var offset := index * BUFFER_STRIDE
  var line_vector := Vector3(buffer[offset], buffer[offset + 4], buffer[offset + 8])
  return start + line_vector


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
