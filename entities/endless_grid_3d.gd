extends MeshInstance3D
## EndlessGrid3D: procedurally built 6-vertex shader grid.
##
## Creates only an XZ plane from two triangles. Grid lines and fading are computed
## in the shader, and the LOD distance is driven by the camera state.
## By default it follows the current viewport camera on XZ to create an endless grid.

const GRID_SHADER := preload("res://entities/endless_grid_3d.gdshader")

@export var follow_viewport_camera := true
@export var grid_size := 2000.0
@export var cell_size := 1.0
@export var min_pixels_between_cells := 2.0
@export var line_width_pixels := 1.0
@export var lod_finer_levels := 3
@export var lod_total_levels := 8
@export var debug_lod_colors := false:
  set(value):
    debug_lod_colors = value
    if _shader_material != null:
      _shader_material.set_shader_parameter("debug_lod_colors", debug_lod_colors)
@export var enable_grazing_opacity := true
@export var thin_line_color := Color(0.42, 0.42, 0.42, 0.45)
@export var thick_line_color := Color(0.62, 0.62, 0.62, 0.65)

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
  grid_size = maxf(value, 1.0)
  _rebuild_mesh()
  _apply_shader_parameters()


func set_cell_size(value: float) -> void:
  cell_size = maxf(value, 0.0001)
  _apply_shader_parameters()


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
  _shader_material.set_shader_parameter("cell_size", cell_size)
  _shader_material.set_shader_parameter("min_pixels_between_cells", min_pixels_between_cells)
  _shader_material.set_shader_parameter("line_width_pixels", line_width_pixels)
  _apply_lod_range_parameters()
  _shader_material.set_shader_parameter("debug_lod_colors", debug_lod_colors)
  _shader_material.set_shader_parameter("enable_grazing_opacity", enable_grazing_opacity)
  _shader_material.set_shader_parameter("thin_line_color", thin_line_color)
  _shader_material.set_shader_parameter("thick_line_color", thick_line_color)
  _shader_material.set_shader_parameter("camera_lod_distance", _get_min_lod_cell_size())
  _shader_material.set_shader_parameter("camera_far_clip", grid_size)
  _shader_material.set_shader_parameter("camera_is_orthogonal", false)


func _apply_lod_range_parameters() -> void:
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
  if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
    lod_distance = maxf(camera.size, min_lod_cell_size)
  else:
    var camera_forward := -camera.global_transform.basis.z.normalized()
    var floor_normal := Vector3.UP
    var height := absf(camera.global_position.y - global_position.y)
    var view_floor_factor := absf(camera_forward.dot(floor_normal))
    var ray_floor_distance := height / maxf(view_floor_factor, 0.0001)

    # Use the view-to-ground distance when looking down, then gradually fall back to camera height near grazing angles to avoid LOD distance blowups.
    lod_distance = maxf(lerpf(ray_floor_distance, height, 1.0 - view_floor_factor), min_lod_cell_size)

  _shader_material.set_shader_parameter("camera_lod_distance", lod_distance)
