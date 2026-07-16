extends RefCounted

const BUFFER_STRIDE := 16
const MIN_AABB_GROW := 0.25

var _buffer := PackedFloat32Array()
var _layers := PackedInt32Array()
var _visible_buffer := PackedFloat32Array()
var _visible_indices := PackedInt32Array()
var _sort_indices := PackedInt32Array()
var _sort_depths := PackedFloat32Array()
var _mesh_instance: MultiMeshInstance3D


func setup(mesh_instance: MultiMeshInstance3D, mesh: Mesh, shader: Shader, depth_bias: float) -> void:
  _mesh_instance = mesh_instance

  var multi_mesh := MultiMesh.new()
  multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
  multi_mesh.use_colors = true
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


func emit_mesh(transform: Transform3D, color: Color, layer: int) -> void:
  _append_buffer(transform, color)
  _layers.append(layer)


func commit(visible_layers: int, camera_transform: Transform3D = Transform3D.IDENTITY) -> AABB:
  _collect_visible_indices(visible_layers)
  var visible_count := _visible_indices.size()
  var multi_mesh := _mesh_instance.multimesh
  _ensure_multimesh_capacity(multi_mesh, visible_count)
  multi_mesh.visible_instance_count = visible_count

  if visible_count == 0:
    multi_mesh.custom_aabb = AABB()
    return multi_mesh.custom_aabb

  _ensure_sort_buffers(visible_count)
  _sort_visible(_visible_indices, camera_transform)

  var instance_count := multi_mesh.instance_count
  var upload_size := instance_count * BUFFER_STRIDE
  var upload_buffer: PackedFloat32Array
  if visible_count == _layers.size():
    _reorder_buffer_self(visible_count)
    _buffer.resize(upload_size)
    upload_buffer = _buffer
  else:
    _visible_buffer.resize(upload_size)
    for i in visible_count:
      _copy_buffer_entry(_buffer, _sort_indices[i], _visible_buffer, i)
    upload_buffer = _visible_buffer

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
  _visible_indices.clear()
  _sort_indices.clear()
  _sort_depths.clear()


func _collect_visible_indices(visible_layers: int) -> void:
  _visible_indices.clear()
  for i in _layers.size():
    if _is_layer_visible(_layers[i], visible_layers):
      _visible_indices.append(i)


func _ensure_sort_buffers(count: int) -> void:
  _sort_indices.resize(count)
  _sort_depths.resize(count)


func _sort_visible(indices: PackedInt32Array, camera_transform: Transform3D) -> void:
  var camera_position := camera_transform.origin
  var camera_forward := -camera_transform.basis.z.normalized()
  for i in indices.size():
    _sort_indices[i] = indices[i]
    _sort_depths[i] = (_get_buffer_origin(_buffer, indices[i]) - camera_position).dot(camera_forward)

  _heap_sort_back_to_front(indices.size())


func _heap_sort_back_to_front(count: int) -> void:
  var heap_size := count
  _heap_build(heap_size)
  while heap_size > 1:
    heap_size -= 1
    _heap_swap(0, heap_size)
    _heap_sift_down(0, heap_size)


func _heap_build(heap_size: int) -> void:
  for i in range(int(heap_size / 2) - 1, -1, -1):
    _heap_sift_down(i, heap_size)


func _heap_sift_down(root: int, heap_size: int) -> void:
  var node := root
  while true:
    var child := node * 2 + 1
    if child >= heap_size:
      break

    if child + 1 < heap_size and _sort_depths[child + 1] < _sort_depths[child]:
      child += 1

    if _sort_depths[node] <= _sort_depths[child]:
      break

    _heap_swap(node, child)
    node = child


func _heap_swap(a: int, b: int) -> void:
  var tmp_i := _sort_indices[a]
  var tmp_d := _sort_depths[a]
  _sort_indices[a] = _sort_indices[b]
  _sort_depths[a] = _sort_depths[b]
  _sort_indices[b] = tmp_i
  _sort_depths[b] = tmp_d


func _reorder_buffer_self(count: int) -> void:
  _visible_buffer.resize(count * BUFFER_STRIDE)
  for i in count:
    _copy_buffer_entry(_buffer, _sort_indices[i], _visible_buffer, i)
  for i in count * BUFFER_STRIDE:
    _buffer[i] = _visible_buffer[i]


func _create_material(shader: Shader, depth_bias: float) -> ShaderMaterial:
  var material := ShaderMaterial.new()
  material.shader = shader
  material.set_shader_parameter(&"depth_bias", depth_bias)
  material.render_priority = Material.RENDER_PRIORITY_MIN + 2
  return material


func _append_buffer(transform: Transform3D, color: Color) -> void:
  _buffer.append_array(
    [
      transform.basis.x.x,
      transform.basis.y.x,
      transform.basis.z.x,
      transform.origin.x,
      transform.basis.x.y,
      transform.basis.y.y,
      transform.basis.z.y,
      transform.origin.y,
      transform.basis.x.z,
      transform.basis.y.z,
      transform.basis.z.z,
      transform.origin.z,
      color.r,
      color.g,
      color.b,
      color.a,
    ],
  )


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
  var start := _get_buffer_origin(buffer, 0)
  var aabb := AABB(start, Vector3.ZERO)
  for i in count:
    var origin := _get_buffer_origin(buffer, i)
    var extent := _get_buffer_extent(buffer, i)
    aabb = aabb.expand(origin - extent)
    aabb = aabb.expand(origin + extent)
  return aabb


func _get_buffer_origin(buffer: PackedFloat32Array, index: int) -> Vector3:
  var offset := index * BUFFER_STRIDE
  return Vector3(buffer[offset + 3], buffer[offset + 7], buffer[offset + 11])


func _get_buffer_extent(buffer: PackedFloat32Array, index: int) -> Vector3:
  var offset := index * BUFFER_STRIDE
  var dx := Vector3(buffer[offset + 0], buffer[offset + 4], buffer[offset + 8])
  var dy := Vector3(buffer[offset + 1], buffer[offset + 5], buffer[offset + 9])
  var dz := Vector3(buffer[offset + 2], buffer[offset + 6], buffer[offset + 10])
  return (dx.abs() + dy.abs() + dz.abs()) * 0.5


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
