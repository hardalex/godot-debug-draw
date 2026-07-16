extends MeshInstance3D
## EndlessGrid3D: procedurally built 6-vertex shader grid.
##
## Creates only an XZ plane from two triangles. Grid lines and fading are computed
## in the shader, and the LOD distance is driven by the camera state.
## By default it follows the current viewport camera on XZ to create an infinite grid.

const GRID_SHADER := preload("res://entities/endless_grid_3d.gdshader")

@export var follow_viewport_camera := true
@export var grid_size := 2000.0:
  set(value):
    grid_size = maxf(value, 1.0)
    if is_node_ready():
      _rebuild_mesh()
    _set_shader_parameter(&"grid_size", grid_size)
    _set_shader_parameter(&"camera_far_clip", grid_size)
@export_range(0.0, 1.0, 0.01) var edge_fade_start_ratio := 0.0:
  set(value):
    edge_fade_start_ratio = clampf(value, 0.0, 1.0)
    _set_shader_parameter(&"edge_fade_start_ratio", edge_fade_start_ratio)
@export_range(0.0, 1.0, 0.01) var edge_fade_end_ratio := 1.0:
  set(value):
    edge_fade_end_ratio = clampf(value, 0.0, 1.0)
    _set_shader_parameter(&"edge_fade_end_ratio", edge_fade_end_ratio)
@export var cell_size := 1.0:
  set(value):
    cell_size = maxf(value, 0.0001)
    _set_shader_parameter(&"cell_size", cell_size)
    _apply_min_lod_distance_parameter()
@export var line_width_pixels := 1.0:
  set(value):
    line_width_pixels = maxf(value, 0.25)
    _set_shader_parameter(&"line_width_pixels", line_width_pixels)
@export var lod_finer_levels := 3:
  set(value):
    lod_finer_levels = maxi(value, 0)
    _apply_lod_range_parameters()
    _apply_min_lod_distance_parameter()
@export var lod_total_levels := 8:
  set(value):
    lod_total_levels = maxi(value, 3)
    _apply_lod_range_parameters()
@export var enable_grazing_opacity := true:
  set(value):
    enable_grazing_opacity = value
    _set_shader_parameter(&"enable_grazing_opacity", enable_grazing_opacity)
@export_range(0.0, 90.0, 0.1, "degrees") var grazing_fade_start := 3.0:
  set(value):
    grazing_fade_start = clampf(value, 0.0, 90.0)
    _apply_grazing_fade_parameters()
@export_range(0.0, 90.0, 0.1, "degrees") var grazing_fade_end := 20.0:
  set(value):
    grazing_fade_end = clampf(value, 0.0, 90.0)
    _apply_grazing_fade_parameters()
@export var enable_stipple_discard := false:
  set(value):
    enable_stipple_discard = value
    _set_shader_parameter(&"enable_stipple_discard", enable_stipple_discard)
@export var enable_lod_center_fade := true:
  set(value):
    enable_lod_center_fade = value
    _set_shader_parameter(&"enable_lod_center_fade", enable_lod_center_fade)
@export var lod_center_fade_line_count := 151.0:
  set(value):
    lod_center_fade_line_count = value
    _set_shader_parameter(&"lod_center_fade_line_count", lod_center_fade_line_count)
@export var thin_line_color := Color(0.42, 0.42, 0.42, 0.45):
  set(value):
    thin_line_color = value
    _set_shader_parameter(&"thin_line_color", thin_line_color)
@export var thick_line_color := Color(0.62, 0.62, 0.62, 0.65):
  set(value):
    thick_line_color = value
    _set_shader_parameter(&"thick_line_color", thick_line_color)
@export var debug_lod_colors := false:
  set(value):
    debug_lod_colors = value
    _set_shader_parameter(&"debug_lod_colors", debug_lod_colors)

var _shader_material: ShaderMaterial


func _ready() -> void:
  _rebuild_mesh()
  _ensure_shader_material()
  _apply_shader_parameters()


func _process(_delta: float) -> void:
  var camera := get_viewport().get_camera_3d()
  if camera == null:
    return

  if follow_viewport_camera:
    follow_camera(camera)

  _update_camera_lod_distance(camera)


func follow_camera(camera: Camera3D) -> void:
  global_position = Vector3(camera.global_position.x, 0.0, camera.global_position.z)


func set_grid_size(value: float) -> void:
  grid_size = value


func set_cell_size(value: float) -> void:
  cell_size = value


func _rebuild_mesh() -> void:
  var half := maxf(grid_size, 1.0) * 0.5
  var vertices := PackedVector3Array(
    [
      Vector3(-half, 0.0, -half),
      Vector3(half, 0.0, -half),
      Vector3(half, 0.0, half),
      Vector3(-half, 0.0, -half),
      Vector3(half, 0.0, half),
      Vector3(-half, 0.0, half),
    ],
  )

  var arrays := []
  arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX] = vertices

  var array_mesh := ArrayMesh.new()
  array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
  mesh = array_mesh


func _ensure_shader_material() -> void:
  _shader_material = material_override as ShaderMaterial
  if _shader_material != null:
    return

  _shader_material = ShaderMaterial.new()
  _shader_material.shader = GRID_SHADER
  _shader_material.render_priority = Material.RENDER_PRIORITY_MIN + 1
  material_override = _shader_material


func _apply_shader_parameters() -> void:
  if _shader_material == null:
    return

  _shader_material.set_shader_parameter("grid_size", grid_size)
  _shader_material.set_shader_parameter("edge_fade_start_ratio", edge_fade_start_ratio)
  _shader_material.set_shader_parameter("edge_fade_end_ratio", edge_fade_end_ratio)
  _shader_material.set_shader_parameter("cell_size", cell_size)
  _shader_material.set_shader_parameter("line_width_pixels", line_width_pixels)
  _apply_lod_range_parameters()
  _shader_material.set_shader_parameter("debug_lod_colors", debug_lod_colors)
  _shader_material.set_shader_parameter("enable_grazing_opacity", enable_grazing_opacity)
  _apply_grazing_fade_parameters()
  _shader_material.set_shader_parameter("enable_stipple_discard", enable_stipple_discard)
  _shader_material.set_shader_parameter("enable_lod_center_fade", enable_lod_center_fade)
  _shader_material.set_shader_parameter("lod_center_fade_line_count", lod_center_fade_line_count)
  _shader_material.set_shader_parameter("thin_line_color", thin_line_color)
  _shader_material.set_shader_parameter("thick_line_color", thick_line_color)
  _shader_material.set_shader_parameter("camera_lod_distance", _get_min_lod_cell_size())
  _shader_material.set_shader_parameter("camera_far_clip", grid_size)
  _shader_material.set_shader_parameter("camera_is_orthogonal", false)
  _shader_material.set_shader_parameter("view_grid_center", Vector2(global_position.x, global_position.z))


func _set_shader_parameter(parameter_name: StringName, value: Variant) -> void:
  if _shader_material == null:
    return

  _shader_material.set_shader_parameter(parameter_name, value)


func _apply_min_lod_distance_parameter() -> void:
  if _shader_material == null:
    return

  _shader_material.set_shader_parameter("camera_lod_distance", _get_min_lod_cell_size())


func _apply_grazing_fade_parameters() -> void:
  if _shader_material == null:
    return

  var start_factor := sin(deg_to_rad(grazing_fade_start))
  var end_factor := sin(deg_to_rad(grazing_fade_end))
  _shader_material.set_shader_parameter("grazing_fade_start_factor", start_factor)
  _shader_material.set_shader_parameter("grazing_fade_end_factor", end_factor)


func _apply_lod_range_parameters() -> void:
  if _shader_material == null:
    return

  var finer_levels := maxi(lod_finer_levels, 0)
  var total_levels := maxi(lod_total_levels, 3)
  var min_lod_power := -float(finer_levels)
  var max_lod_power := min_lod_power + float(total_levels - 1)
  _shader_material.set_shader_parameter("min_lod_power", min_lod_power)
  _shader_material.set_shader_parameter("max_lod_power", max_lod_power)


func _get_min_lod_cell_size() -> float:
  return maxf(cell_size * pow(10.0, -float(maxi(lod_finer_levels, 0))), 0.0001)


func _update_camera_lod_distance(camera: Camera3D) -> void:
  if _shader_material == null:
    return

  _shader_material.set_shader_parameter("camera_far_clip", camera.far)
  _shader_material.set_shader_parameter("camera_is_orthogonal", camera.projection == Camera3D.PROJECTION_ORTHOGONAL)

  var min_lod_cell_size := _get_min_lod_cell_size()
  var lod_distance := min_lod_cell_size
  var camera_forward := -camera.global_transform.basis.z.normalized()
  var view_grid_center := Vector2(camera.global_position.x, camera.global_position.z)
  if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
    lod_distance = maxf(camera.size, min_lod_cell_size)
    if absf(camera_forward.y) > 0.0001:
      var ray_distance := (global_position.y - camera.global_position.y) / camera_forward.y
      var focus_position := camera.global_position + camera_forward * ray_distance
      view_grid_center = Vector2(focus_position.x, focus_position.z)
  else:
    var floor_normal := Vector3.UP
    var height := absf(camera.global_position.y - global_position.y)
    var view_floor_factor := absf(camera_forward.dot(floor_normal))
    var ray_floor_distance := height / maxf(view_floor_factor, 0.0001)

    # Match Blender: use the view-to-ground distance when looking down, and gradually fall back to camera height near grazing angles to avoid LOD distance blowups.
    lod_distance = maxf(lerpf(ray_floor_distance, height, 1.0 - view_floor_factor), min_lod_cell_size)
    var focus_position := camera.global_position + camera_forward * lod_distance
    view_grid_center = Vector2(focus_position.x, focus_position.z)

  _shader_material.set_shader_parameter("camera_lod_distance", lod_distance)
  _shader_material.set_shader_parameter("view_grid_center", view_grid_center)
