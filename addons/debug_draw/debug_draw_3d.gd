class_name DebugDraw3D
extends Node3D
## In-scene 3D debug draw node.
##
## Lines are submitted for the current frame, converted to MultiMesh instances,
## and expanded to screen-space quads in the vertex shader.

enum LineJoint { NONE = 0, ROUND = -1, BEVEL = -2, MITER = -3 }
enum GridOuterEdges { NONE = 0, X = 1, Y = 2, Z = 4, XZ = 5, ALL = 7 }

const DEFAULT_LAYER := 1
const DEFAULT_PROCESS_PRIORITY := 100000
const DEPTH_BIAS_MIN := -1.0
const DEPTH_BIAS_MAX := 1.0
const MITER_LIMIT_MIN := 1.0
const BACK_FADE_START_DEFAULT := deg_to_rad(100.0)
const BACK_FADE_TRANSITION_DEFAULT := deg_to_rad(20.0)
const BACK_FADE_START_MIN := 0.0
const BACK_FADE_START_MAX := PI - 0.001
const BACK_FADE_TRANSITION_MIN := 0.001
const BACK_FADE_TRANSITION_MAX := PI
const ROUND_JOINT_RESOLUTION_MIN := 3
const ROUND_JOINT_RESOLUTION_MAX := 8
const CIRCLE_SEGMENT_COUNT_DEFAULT := 64
const CIRCLE_SEGMENT_COUNT_MIN := 3
const CURVE_MAX_STAGES_DEFAULT := 5
const CURVE_TOLERANCE_LENGTH_DEFAULT := 0.2
const SPHERE_AXIS_SEGMENT_COUNT_DEFAULT := 2
const SPHERE_AXIS_SEGMENT_COUNT_MIN := 1
const ARROW_HEAD_LENGTH_DEFAULT := 0.2
const ARROW_HEAD_ANGLE_DEFAULT := PI / 6.0
const ARROW_HEAD_ANGLE_MIN := 0.001
const ARROW_HEAD_ANGLE_MAX := PI * 0.49
const LINE_SHADER := preload("res://addons/debug_draw/shaders/debug_line_3d.gdshader")
const NORMAL_LINE_SHADER := preload("res://addons/debug_draw/shaders/debug_normal_line_3d.gdshader")
const JOINT_ROUND_SHADER := preload("res://addons/debug_draw/shaders/debug_line_joint_round_3d.gdshader")
const JOINT_BEVEL_SHADER := preload("res://addons/debug_draw/shaders/debug_line_joint_bevel_3d.gdshader")
const JOINT_MITER_SHADER := preload("res://addons/debug_draw/shaders/debug_line_joint_miter_3d.gdshader")
const NORMAL_JOINT_ROUND_SHADER := preload("res://addons/debug_draw/shaders/debug_normal_line_joint_round_3d.gdshader")
const NORMAL_JOINT_BEVEL_SHADER := preload("res://addons/debug_draw/shaders/debug_normal_line_joint_bevel_3d.gdshader")
const NORMAL_JOINT_MITER_SHADER := preload("res://addons/debug_draw/shaders/debug_normal_line_joint_miter_3d.gdshader")
const LINE_RENDERER_SCRIPT := preload("res://addons/debug_draw/renderers/debug_line_renderer_3d.gd")
const NORMAL_LINE_RENDERER_SCRIPT := preload("res://addons/debug_draw/renderers/debug_normal_line_renderer_3d.gd")
const JOINT_RENDERER_SCRIPT := preload("res://addons/debug_draw/renderers/debug_joint_renderer_3d.gd")
const NORMAL_JOINT_RENDERER_SCRIPT := preload("res://addons/debug_draw/renderers/debug_normal_joint_renderer_3d.gd")
const RECT_SHADER := preload("res://addons/debug_draw/shaders/debug_rect_3d.gdshader")
const MESH_SHADER := preload("res://addons/debug_draw/shaders/debug_mesh_3d.gdshader")
const RECT_RENDERER_SCRIPT := preload("res://addons/debug_draw/renderers/debug_rect_renderer_3d.gd")
const MESH_RENDERER_SCRIPT := preload("res://addons/debug_draw/renderers/debug_mesh_renderer_3d.gd")

@export var debug_visible := true
@export_range(0.1, 64.0, 0.1) var line_width := 1.0
@export_range(0.0, 179.9, 0.1, "radians_as_degrees") var back_fade_start := BACK_FADE_START_DEFAULT:
  set(value):
    back_fade_start = clampf(value, BACK_FADE_START_MIN, BACK_FADE_START_MAX)
    _update_back_fade_parameters()
@export_range(0.1, 180.0, 0.1, "radians_as_degrees") var back_fade_transition := BACK_FADE_TRANSITION_DEFAULT:
  set(value):
    back_fade_transition = clampf(value, BACK_FADE_TRANSITION_MIN, BACK_FADE_TRANSITION_MAX)
    _update_back_fade_parameters()
@export_range(3, 8, 1) var round_joint_resolution := 8:
  set(value):
    round_joint_resolution = clampi(value, ROUND_JOINT_RESOLUTION_MIN, ROUND_JOINT_RESOLUTION_MAX)
    if is_node_ready():
      _round_joint_mesh = _create_joint_fan_mesh(round_joint_resolution * 3)
    _update_joint_material_parameters()
@export_range(1.0, 16.0, 0.1) var miter_limit := 4.0:
  set(value):
    miter_limit = maxf(value, MITER_LIMIT_MIN)
    _update_joint_material_parameters()
@export_range(-1.0, 1.0, 0.001) var depth_bias := 0.0:
  set(value):
    depth_bias = _resolve_depth_bias(value)
    _update_line_material_depth_bias()
@export_flags_3d_render var visible_layers := DEFAULT_LAYER

var _line_mesh: ArrayMesh
var _round_joint_mesh: ArrayMesh
var _bevel_joint_mesh: ArrayMesh
var _miter_joint_mesh: ArrayMesh
var _rect_mesh: ArrayMesh
var _box_mesh: BoxMesh
var _sphere_mesh: SphereMesh
var _cylinder_mesh: CylinderMesh
var _cone_mesh: CylinderMesh
var _line_renderer: RefCounted
var _normal_line_renderer: RefCounted
var _rect_renderer: RefCounted
var _box_renderer: RefCounted
var _sphere_renderer: RefCounted
var _cylinder_renderer: RefCounted
var _cone_renderer: RefCounted
var _joint_renderers := { }
var _normal_joint_renderers := { }
var _joint_mesh_instances := { }
var _normal_joint_mesh_instances := { }
var _circle_unit_points_by_segment_count := { }
var _circle_unit_normal_points_by_segment_count := { }

@onready var _mesh_instance: MultiMeshInstance3D = $LineMesh
@onready var _normal_line_mesh_instance: MultiMeshInstance3D = $NormalLineMesh
@onready var _joint_mesh_instance: MultiMeshInstance3D = $JointMesh
@onready var _normal_joint_mesh_instance: MultiMeshInstance3D = $NormalJointMesh
@onready var _rect_mesh_instance: MultiMeshInstance3D = $RectMesh
@onready var _box_mesh_instance: MultiMeshInstance3D = $BoxMesh
@onready var _sphere_mesh_instance: MultiMeshInstance3D = $SphereMesh
@onready var _cylinder_mesh_instance: MultiMeshInstance3D = $CylinderMesh
@onready var _cone_mesh_instance: MultiMeshInstance3D = $ConeMesh


func _ready() -> void:
  _validate_global_basis()
  process_priority = DEFAULT_PROCESS_PRIORITY
  _line_mesh = _create_line_quad_mesh()
  _round_joint_mesh = _create_joint_fan_mesh(round_joint_resolution * 3)
  _bevel_joint_mesh = _create_joint_fan_mesh(3)
  _miter_joint_mesh = _create_joint_fan_mesh(6)
  _rect_mesh = _create_rect_mesh()
  _box_mesh = _create_box_mesh()
  _sphere_mesh = _create_sphere_mesh()
  _cylinder_mesh = _create_cylinder_mesh()
  _cone_mesh = _create_cone_mesh()
  _setup_renderers()


func _process(_delta: float) -> void:
  flush()


func flush() -> void:
  if debug_visible:
    var camera_transform := _get_camera_transform()
    _rect_renderer.commit(visible_layers, camera_transform)
    _box_renderer.commit(visible_layers, camera_transform)
    _sphere_renderer.commit(visible_layers, camera_transform)
    _cylinder_renderer.commit(visible_layers, camera_transform)
    _cone_renderer.commit(visible_layers, camera_transform)
    var line_aabb: AABB = _line_renderer.commit(visible_layers)
    var normal_line_aabb: AABB = _normal_line_renderer.commit(visible_layers)
    for joint in _get_rendered_line_joints():
      _joint_renderers[joint].commit(visible_layers, line_aabb)
      _normal_joint_renderers[joint].commit(visible_layers, normal_line_aabb)
  else:
    _line_renderer.clear()
    _normal_line_renderer.clear()
    _rect_renderer.clear()
    _box_renderer.clear()
    _sphere_renderer.clear()
    _cylinder_renderer.clear()
    _cone_renderer.clear()
    for joint in _get_rendered_line_joints():
      _joint_renderers[joint].clear()
      _normal_joint_renderers[joint].clear()

  _reset_buffers()


func set_layer_enabled(layer: int, enabled: bool) -> void:
  if layer <= 0:
    return
  if enabled:
    visible_layers |= layer
  else:
    visible_layers &= ~layer


func get_mesh_instance() -> MultiMeshInstance3D:
  return _mesh_instance


func get_normal_line_mesh_instance() -> MultiMeshInstance3D:
  return _normal_line_mesh_instance


func get_dashed_normal_line_mesh_instance() -> MultiMeshInstance3D:
  return _normal_line_mesh_instance


func get_joint_mesh_instance(joint: int = LineJoint.ROUND) -> MultiMeshInstance3D:
  return _joint_mesh_instances.get(joint) as MultiMeshInstance3D


func get_normal_joint_mesh_instance(joint: int = LineJoint.ROUND) -> MultiMeshInstance3D:
  return _normal_joint_mesh_instances.get(joint) as MultiMeshInstance3D


func get_multimesh_instance() -> MultiMeshInstance3D:
  return _mesh_instance


func get_depth_mesh_instance() -> MultiMeshInstance3D:
  return _mesh_instance


func get_depth_multimesh_instance() -> MultiMeshInstance3D:
  return _mesh_instance


func draw_line(
    from: Vector3,
    to: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_line(from, to, color, width, layer)


func draw_line_n(
    from: Vector3,
    to: Vector3,
    normal: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_normal_line(from, to, normal, color, width, layer)


func draw_ray(
    from: Vector3,
    vector: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  draw_line(from, from + vector, color, width, layer)


func draw_arrow(
    pos: Vector3,
    dir: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    head_angle: float = ARROW_HEAD_ANGLE_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_arrow(pos, dir, color, width, head_angle, joint, layer)


func draw_arrow_n(
    pos: Vector3,
    dir: Vector3,
    normal: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    head_angle: float = ARROW_HEAD_ANGLE_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_arrow_with_normal(pos, dir, normal, color, width, head_angle, joint, layer)


func draw_arrow_line(
    from: Vector3,
    to: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    head_length: float = ARROW_HEAD_LENGTH_DEFAULT,
    head_angle: float = ARROW_HEAD_ANGLE_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_line(from, to, color, width, layer)
  if from.is_equal_approx(to) or head_length <= 0.0:
    return

  _emit_arrow(to, from.direction_to(to) * head_length, color, width, head_angle, joint, layer)


func draw_arrow_line_n(
    from: Vector3,
    to: Vector3,
    normal: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    head_length: float = ARROW_HEAD_LENGTH_DEFAULT,
    head_angle: float = ARROW_HEAD_ANGLE_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_line(from, to, color, width, layer)
  if from.is_equal_approx(to) or head_length <= 0.0:
    return

  var direction := from.direction_to(to)
  var resolved_normal := _get_projected_perpendicular_unit(direction, normal)
  _emit_arrow_with_normal(to, direction * head_length, resolved_normal, color, width, head_angle, joint, layer)


func draw_arrow_line_d(
    from: Vector3,
    to: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    head_length: float = ARROW_HEAD_LENGTH_DEFAULT,
    head_angle: float = ARROW_HEAD_ANGLE_DEFAULT,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_dashed_line(
    from,
    to,
    color,
    width,
    layer,
    maxf(dash_width, 0.001),
    maxf(dash_space, 0.0),
    dash_offset,
  )
  if from.is_equal_approx(to) or head_length <= 0.0:
    return

  _emit_arrow(to, from.direction_to(to) * head_length, color, width, head_angle, joint, layer)


func draw_arrow_line_n_d(
    from: Vector3,
    to: Vector3,
    normal: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    head_length: float = ARROW_HEAD_LENGTH_DEFAULT,
    head_angle: float = ARROW_HEAD_ANGLE_DEFAULT,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_dashed_line(
    from,
    to,
    color,
    width,
    layer,
    maxf(dash_width, 0.001),
    maxf(dash_space, 0.0),
    dash_offset,
  )
  if from.is_equal_approx(to) or head_length <= 0.0:
    return

  var direction := from.direction_to(to)
  var resolved_normal := _get_projected_perpendicular_unit(direction, normal)
  _emit_arrow_with_normal(to, direction * head_length, resolved_normal, color, width, head_angle, joint, layer)


func draw_ray_n(
    from: Vector3,
    vector: Vector3,
    normal: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  draw_line_n(from, from + vector, normal, color, width, layer)


func draw_axes(
    pos: Vector3,
    rotation: Quaternion,
    length: float = 1.0,
    width: float = -1.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  if length <= 0.0:
    return

  var basis := Basis(rotation.normalized())
  _emit_line(pos, pos + basis.x * length, Color.RED, width, layer)
  _emit_line(pos, pos + basis.y * length, Color.GREEN, width, layer)
  _emit_line(pos, pos + basis.z * length, Color.BLUE, width, layer)


func draw_axes_n(
    pos: Vector3,
    rotation: Quaternion,
    length: float = 1.0,
    width: float = -1.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  if length <= 0.0:
    return

  var basis := Basis(rotation.normalized())
  _emit_normal_line(pos, pos + basis.x * length, basis.x, Color.RED, width, layer)
  _emit_normal_line(pos, pos + basis.y * length, basis.y, Color.GREEN, width, layer)
  _emit_normal_line(pos, pos + basis.z * length, basis.z, Color.BLUE, width, layer)


func draw_line_d(
    from: Vector3,
    to: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_dashed_line(
    from,
    to,
    color,
    width,
    layer,
    maxf(dash_width, 0.001),
    maxf(dash_space, 0.0),
    dash_offset,
  )


func draw_line_n_d(
    from: Vector3,
    to: Vector3,
    normal: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_dashed_normal_line(
    from,
    to,
    normal,
    color,
    width,
    layer,
    maxf(dash_width, 0.001),
    maxf(dash_space, 0.0),
    dash_offset,
  )


func draw_ray_d(
    from: Vector3,
    vector: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  draw_line_d(
    from,
    from + vector,
    color,
    width,
    dash_width,
    dash_space,
    dash_offset,
    layer,
  )


func draw_ray_n_d(
    from: Vector3,
    vector: Vector3,
    normal: Vector3,
    color: Color = Color.WHITE,
    width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  draw_line_n_d(
    from,
    from + vector,
    normal,
    color,
    width,
    dash_width,
    dash_space,
    dash_offset,
    layer,
  )


func draw_line_list(
    points: PackedVector3Array,
    color: Color = Color.WHITE,
    width: float = -1.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  if points.size() < 2:
    return

  _emit_line_list(points, color, width, layer)


func draw_line_list_n(
    points: PackedVector3Array,
    normals: PackedVector3Array,
    color: Color = Color.WHITE,
    width: float = -1.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  var segment_count := int(points.size() / 2)
  if segment_count == 0 or normals.size() < segment_count:
    return

  _emit_normal_line_list(points, normals, color, width, layer)


func draw_line_strip(
    points: PackedVector3Array,
    color: Color = Color.WHITE,
    width: float = -1.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if points.size() < 2:
    return

  _emit_line_strip(points, color, width, joint, layer)


func draw_line_strip_n(
    points: PackedVector3Array,
    normals: PackedVector3Array,
    color: Color = Color.WHITE,
    width: float = -1.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if points.size() < 2 or normals.size() < points.size() - 1:
    return

  _emit_normal_line_strip(points, normals, color, width, joint, layer)


func draw_line_strip_d(
    points: PackedVector3Array,
    color: Color = Color.WHITE,
    width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if points.size() < 2:
    return

  _emit_dashed_line_strip(
    points,
    color,
    width,
    joint,
    layer,
    maxf(dash_width, 0.001),
    maxf(dash_space, 0.0),
    dash_offset,
  )


func draw_line_strip_n_d(
    points: PackedVector3Array,
    normals: PackedVector3Array,
    color: Color = Color.WHITE,
    width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if points.size() < 2 or normals.size() < points.size() - 1:
    return

  _emit_dashed_normal_line_strip(
    points,
    normals,
    color,
    width,
    joint,
    layer,
    maxf(dash_width, 0.001),
    maxf(dash_space, 0.0),
    dash_offset,
  )


func draw_line_loop(
    points: PackedVector3Array,
    color: Color = Color.WHITE,
    width: float = -1.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if points.size() < 2:
    return

  _emit_line_loop(points, color, width, joint, layer)


func draw_line_loop_n(
    points: PackedVector3Array,
    normals: PackedVector3Array,
    color: Color = Color.WHITE,
    width: float = -1.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if points.size() < 2 or normals.size() < points.size():
    return

  _emit_normal_line_loop(points, normals, color, width, joint, layer)


func draw_line_loop_d(
    points: PackedVector3Array,
    color: Color = Color.WHITE,
    width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if points.size() < 2:
    return

  _emit_dashed_line_loop(
    points,
    color,
    width,
    joint,
    layer,
    maxf(dash_width, 0.001),
    maxf(dash_space, 0.0),
    dash_offset,
  )


func draw_line_loop_n_d(
    points: PackedVector3Array,
    normals: PackedVector3Array,
    color: Color = Color.WHITE,
    width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if points.size() < 2 or normals.size() < points.size():
    return

  _emit_dashed_normal_line_loop(
    points,
    normals,
    color,
    width,
    joint,
    layer,
    maxf(dash_width, 0.001),
    maxf(dash_space, 0.0),
    dash_offset,
  )


func draw_curve(
    curve: Curve3D,
    curve_transform: Transform3D = Transform3D.IDENTITY,
    color: Color = Color.WHITE,
    width: float = -1.0,
    max_stages: int = CURVE_MAX_STAGES_DEFAULT,
    tolerance_length: float = CURVE_TOLERANCE_LENGTH_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_curve_points(curve, curve_transform, max_stages, tolerance_length)
  if points.size() < 2:
    return

  if curve.closed:
    draw_line_loop(points, color, width, joint, layer)
  else:
    draw_line_strip(points, color, width, joint, layer)


func draw_curve_d(
    curve: Curve3D,
    curve_transform: Transform3D = Transform3D.IDENTITY,
    color: Color = Color.WHITE,
    width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    max_stages: int = CURVE_MAX_STAGES_DEFAULT,
    tolerance_length: float = CURVE_TOLERANCE_LENGTH_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_curve_points(curve, curve_transform, max_stages, tolerance_length)
  if points.size() < 2:
    return

  if curve.closed:
    draw_line_loop_d(points, color, width, dash_width, dash_space, dash_offset, joint, layer)
  else:
    draw_line_strip_d(points, color, width, dash_width, dash_space, dash_offset, joint, layer)


func draw_grid(
    center: Vector3,
    rotation: Quaternion,
    cell_count: Vector2i,
    spacing: Vector2,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    layer: int = DEFAULT_LAYER,
    outer_edges: int = GridOuterEdges.NONE,
    skew: Vector2 = Vector2.ZERO,
) -> void:
  _emit_grid_lines(center, rotation, cell_count, spacing, color, line_width, layer, outer_edges, skew, false)


func draw_grid_n(
    center: Vector3,
    rotation: Quaternion,
    cell_count: Vector2i,
    spacing: Vector2,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    layer: int = DEFAULT_LAYER,
    outer_edges: int = GridOuterEdges.NONE,
    skew: Vector2 = Vector2.ZERO,
) -> void:
  _emit_grid_lines(center, rotation, cell_count, spacing, color, line_width, layer, outer_edges, skew, true)


func draw_rect(
    center: Vector3,
    rotation: Quaternion,
    rect_width: float,
    rect_height: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_rect_points(center, rotation, rect_width, rect_height)
  if points.size() == 0:
    return

  draw_line_loop(points, color, line_width, joint, layer)


func draw_rect_s(
    center: Vector3,
    rotation: Quaternion,
    rect_width: float,
    rect_height: float,
    color: Color = Color.WHITE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if rect_width <= 0.0 or rect_height <= 0.0:
    return

  _emit_rect_s(center, rotation, rect_width, rect_height, color, layer)


func draw_rect_n(
    center: Vector3,
    rotation: Quaternion,
    rect_width: float,
    rect_height: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_rect_points(center, rotation, rect_width, rect_height)
  if points.size() == 0:
    return

  draw_line_loop_n(points, _get_rect_normals(rotation), color, line_width, joint, layer)


func draw_rect_d(
    center: Vector3,
    rotation: Quaternion,
    rect_width: float,
    rect_height: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_rect_points(center, rotation, rect_width, rect_height)
  if points.size() == 0:
    return

  draw_line_loop_d(
    points,
    color,
    line_width,
    dash_width,
    dash_space,
    dash_offset,
    joint,
    layer,
  )


func draw_rect_n_d(
    center: Vector3,
    rotation: Quaternion,
    rect_width: float,
    rect_height: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_rect_points(center, rotation, rect_width, rect_height)
  if points.size() == 0:
    return

  draw_line_loop_n_d(
    points,
    _get_rect_normals(rotation),
    color,
    line_width,
    dash_width,
    dash_space,
    dash_offset,
    joint,
    layer,
  )


func draw_box(
    pos: Vector3,
    rotation: Quaternion,
    size: Vector3,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_box_line_points(pos, rotation, size)
  if points.size() == 0:
    return

  draw_line_list(points, color, line_width, layer)


func draw_box_s(
    pos: Vector3,
    rotation: Quaternion,
    size: Vector3,
    color: Color = Color.WHITE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
    return

  _emit_box_s(pos, rotation, size, color, layer)


func draw_box_n(
    pos: Vector3,
    rotation: Quaternion,
    size: Vector3,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_box_line_points(pos, rotation, size)
  if points.size() == 0:
    return

  draw_line_list_n(points, _get_box_line_normals(rotation), color, line_width, layer)


func draw_box_d(
    pos: Vector3,
    rotation: Quaternion,
    size: Vector3,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_box_line_points(pos, rotation, size)
  if points.size() == 0:
    return

  _emit_dashed_line_list(
    points,
    color,
    line_width,
    layer,
    maxf(dash_width, 0.001),
    maxf(dash_space, 0.0),
    dash_offset,
  )


func draw_box_n_d(
    pos: Vector3,
    rotation: Quaternion,
    size: Vector3,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_box_line_points(pos, rotation, size)
  if points.size() == 0:
    return

  _emit_dashed_normal_line_list(
    points,
    _get_box_line_normals(rotation),
    color,
    line_width,
    layer,
    maxf(dash_width, 0.001),
    maxf(dash_space, 0.0),
    dash_offset,
  )


func draw_circle(
    center: Vector3,
    rotation: Quaternion,
    radius: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_circle_points(center, rotation, radius, segment_count)
  if points.size() == 0:
    return

  draw_line_loop(points, color, line_width, joint, layer)


func draw_circle_n(
    center: Vector3,
    rotation: Quaternion,
    radius: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_circle_points(center, rotation, radius, segment_count)
  if points.size() == 0:
    return

  draw_line_loop_n(points, _get_circle_normals(rotation, points.size()), color, line_width, joint, layer)


func draw_circle_d(
    center: Vector3,
    rotation: Quaternion,
    radius: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_circle_points(center, rotation, radius, segment_count)
  if points.size() == 0:
    return

  draw_line_loop_d(
    points,
    color,
    line_width,
    dash_width,
    dash_space,
    dash_offset,
    joint,
    layer,
  )


func draw_circle_n_d(
    center: Vector3,
    rotation: Quaternion,
    radius: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_circle_points(center, rotation, radius, segment_count)
  if points.size() == 0:
    return

  draw_line_loop_n_d(
    points,
    _get_circle_normals(rotation, points.size()),
    color,
    line_width,
    dash_width,
    dash_space,
    dash_offset,
    joint,
    layer,
  )


func draw_arc(
    center: Vector3,
    rotation: Quaternion,
    radius: float,
    angle: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_arc_points(center, rotation, radius, angle, segment_count)
  if points.size() == 0:
    return

  draw_line_strip(points, color, line_width, joint, layer)


func draw_arc_n(
    center: Vector3,
    rotation: Quaternion,
    radius: float,
    angle: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_arc_points(center, rotation, radius, angle, segment_count)
  if points.size() == 0:
    return

  draw_line_strip_n(points, _get_arc_normals(rotation, angle, segment_count), color, line_width, joint, layer)


func draw_arc_d(
    center: Vector3,
    rotation: Quaternion,
    radius: float,
    angle: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_arc_points(center, rotation, radius, angle, segment_count)
  if points.size() == 0:
    return

  draw_line_strip_d(
    points,
    color,
    line_width,
    dash_width,
    dash_space,
    dash_offset,
    joint,
    layer,
  )


func draw_arc_n_d(
    center: Vector3,
    rotation: Quaternion,
    radius: float,
    angle: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var points := _get_arc_points(center, rotation, radius, angle, segment_count)
  if points.size() == 0:
    return

  draw_line_strip_n_d(
    points,
    _get_arc_normals(rotation, angle, segment_count),
    color,
    line_width,
    dash_width,
    dash_space,
    dash_offset,
    joint,
    layer,
  )


func draw_sphere(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    y_axis_segment_count: int = SPHERE_AXIS_SEGMENT_COUNT_DEFAULT,
    z_axis_segment_count: int = SPHERE_AXIS_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_sphere_axis_rings(
    pos,
    rotation,
    radius,
    color,
    line_width,
    joint,
    layer,
    segment_count,
    y_axis_segment_count,
    z_axis_segment_count,
    false,
    false,
  )


func draw_sphere_s(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    color: Color = Color.WHITE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if radius <= 0.0:
    return

  _emit_sphere_s(pos, rotation, radius, color, layer)


func draw_sphere_n(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    y_axis_segment_count: int = SPHERE_AXIS_SEGMENT_COUNT_DEFAULT,
    z_axis_segment_count: int = SPHERE_AXIS_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_sphere_axis_rings(
    pos,
    rotation,
    radius,
    color,
    line_width,
    joint,
    layer,
    segment_count,
    y_axis_segment_count,
    z_axis_segment_count,
    true,
    false,
  )


func draw_sphere_d(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    y_axis_segment_count: int = SPHERE_AXIS_SEGMENT_COUNT_DEFAULT,
    z_axis_segment_count: int = SPHERE_AXIS_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_sphere_axis_rings(
    pos,
    rotation,
    radius,
    color,
    line_width,
    joint,
    layer,
    segment_count,
    y_axis_segment_count,
    z_axis_segment_count,
    false,
    true,
    dash_width,
    dash_space,
    dash_offset,
  )


func draw_sphere_n_d(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    y_axis_segment_count: int = SPHERE_AXIS_SEGMENT_COUNT_DEFAULT,
    z_axis_segment_count: int = SPHERE_AXIS_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_sphere_axis_rings(
    pos,
    rotation,
    radius,
    color,
    line_width,
    joint,
    layer,
    segment_count,
    y_axis_segment_count,
    z_axis_segment_count,
    true,
    true,
    dash_width,
    dash_space,
    dash_offset,
  )


func draw_cone(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    height: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    side_segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var base_points := _get_cone_base_points(pos, rotation, radius, height, segment_count)
  if base_points.size() == 0:
    return

  draw_line_loop(base_points, color, line_width, joint, layer)
  draw_line_list(
    _get_cone_side_line_points(pos, rotation, radius, height, side_segment_count),
    color,
    line_width,
    layer,
  )


func draw_cone_s(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    height: float,
    color: Color = Color.WHITE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if radius <= 0.0 or height <= 0.0:
    return

  _emit_cone_s(pos, rotation, radius, height, color, layer)


func draw_cone_n(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    height: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    side_segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var base_points := _get_cone_base_points(pos, rotation, radius, height, segment_count)
  if base_points.size() == 0:
    return

  var base_rotation := _get_cone_base_rotation(rotation)
  var side_points := _get_cone_side_line_points(pos, rotation, radius, height, side_segment_count)
  draw_line_loop_n(base_points, _get_circle_normals(base_rotation, base_points.size()), color, line_width, joint, layer)
  draw_line_list_n(
    side_points,
    _get_cone_side_line_normals(rotation, radius, height, side_segment_count),
    color,
    line_width,
    layer,
  )


func draw_cylinder(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    half_height: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    side_segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var bottom_points := _get_cylinder_ring_points(pos, rotation, radius, half_height, -1.0, segment_count)
  if bottom_points.size() == 0:
    return

  var top_points := _get_cylinder_ring_points(pos, rotation, radius, half_height, 1.0, segment_count)
  draw_line_loop(bottom_points, color, line_width, joint, layer)
  draw_line_loop(top_points, color, line_width, joint, layer)
  draw_line_list(
    _get_cylinder_side_line_points(pos, rotation, radius, half_height, side_segment_count),
    color,
    line_width,
    layer,
  )


func draw_cylinder_s(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    half_height: float,
    color: Color = Color.WHITE,
    layer: int = DEFAULT_LAYER,
) -> void:
  if radius <= 0.0 or half_height <= 0.0:
    return

  _emit_cylinder_s(pos, rotation, radius, half_height, color, layer)


func draw_cylinder_n(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    half_height: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    side_segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  var bottom_points := _get_cylinder_ring_points(pos, rotation, radius, half_height, -1.0, segment_count)
  if bottom_points.size() == 0:
    return

  var top_points := _get_cylinder_ring_points(pos, rotation, radius, half_height, 1.0, segment_count)
  var ring_rotation := _get_cone_base_rotation(rotation)
  var side_points := _get_cylinder_side_line_points(pos, rotation, radius, half_height, side_segment_count)
  draw_line_loop_n(bottom_points, _get_circle_normals(ring_rotation, bottom_points.size()), color, line_width, joint, layer)
  draw_line_loop_n(top_points, _get_circle_normals(ring_rotation, top_points.size()), color, line_width, joint, layer)
  draw_line_list_n(
    side_points,
    _get_cylinder_side_line_normals(rotation, radius, half_height, side_segment_count),
    color,
    line_width,
    layer,
  )


func draw_capsule(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    half_height: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    side_segment_count: int = SPHERE_AXIS_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_capsule(
    pos,
    rotation,
    radius,
    half_height,
    color,
    line_width,
    segment_count,
    side_segment_count,
    joint,
    layer,
    false,
  )


func draw_capsule_n(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    half_height: float,
    color: Color = Color.WHITE,
    line_width: float = -1.0,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
    side_segment_count: int = SPHERE_AXIS_SEGMENT_COUNT_DEFAULT,
    joint: int = LineJoint.NONE,
    layer: int = DEFAULT_LAYER,
) -> void:
  _emit_capsule(
    pos,
    rotation,
    radius,
    half_height,
    color,
    line_width,
    segment_count,
    side_segment_count,
    joint,
    layer,
    true,
  )


func _setup_renderers() -> void:
  _line_renderer = LINE_RENDERER_SCRIPT.new()
  _normal_line_renderer = NORMAL_LINE_RENDERER_SCRIPT.new()
  _rect_renderer = RECT_RENDERER_SCRIPT.new()
  _box_renderer = MESH_RENDERER_SCRIPT.new()
  _sphere_renderer = MESH_RENDERER_SCRIPT.new()
  _cylinder_renderer = MESH_RENDERER_SCRIPT.new()
  _cone_renderer = MESH_RENDERER_SCRIPT.new()

  _line_renderer.setup(_mesh_instance, _line_mesh, LINE_SHADER, depth_bias)
  _normal_line_renderer.setup(_normal_line_mesh_instance, _line_mesh, NORMAL_LINE_SHADER, depth_bias)
  _rect_renderer.setup(_rect_mesh_instance, _rect_mesh, RECT_SHADER, depth_bias)
  _box_renderer.setup(_box_mesh_instance, _box_mesh, MESH_SHADER, depth_bias)
  _sphere_renderer.setup(_sphere_mesh_instance, _sphere_mesh, MESH_SHADER, depth_bias)
  _cylinder_renderer.setup(_cylinder_mesh_instance, _cylinder_mesh, MESH_SHADER, depth_bias)
  _cone_renderer.setup(_cone_mesh_instance, _cone_mesh, MESH_SHADER, depth_bias)
  _setup_joint_renderers()
  _update_back_fade_parameters()


func _create_line_quad_mesh() -> ArrayMesh:
  var vertices := PackedVector3Array(
    [
      Vector3(-0.5, 0.0, 0.0),
      Vector3(-0.5, 1.0, 0.0),
      Vector3(0.5, 1.0, 0.0),
      Vector3(-0.5, 0.0, 0.0),
      Vector3(0.5, 1.0, 0.0),
      Vector3(0.5, 0.0, 0.0),
    ],
  )
  var arrays := []
  arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX] = vertices

  var mesh := ArrayMesh.new()
  mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
  return mesh


func _create_rect_mesh() -> ArrayMesh:
  var vertices := PackedVector3Array(
    [
      Vector3(-0.5, -0.5, 0.0),
      Vector3(0.5, -0.5, 0.0),
      Vector3(0.5, 0.5, 0.0),
      Vector3(-0.5, -0.5, 0.0),
      Vector3(0.5, 0.5, 0.0),
      Vector3(-0.5, 0.5, 0.0),
    ],
  )
  var arrays := []
  arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX] = vertices

  var mesh := ArrayMesh.new()
  mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
  return mesh


func _create_box_mesh() -> BoxMesh:
  var mesh := BoxMesh.new()
  mesh.size = Vector3.ONE
  return mesh


func _create_sphere_mesh() -> SphereMesh:
  var mesh := SphereMesh.new()
  mesh.radius = 0.5
  mesh.height = 1.0
  return mesh


func _create_cylinder_mesh() -> CylinderMesh:
  var mesh := CylinderMesh.new()
  mesh.bottom_radius = 0.5
  mesh.top_radius = 0.5
  mesh.height = 1.0
  return mesh


func _create_cone_mesh() -> CylinderMesh:
  var mesh := CylinderMesh.new()
  mesh.bottom_radius = 0.5
  mesh.top_radius = 0.0
  mesh.height = 1.0
  return mesh


func _create_joint_fan_mesh(vertex_count: int) -> ArrayMesh:
  var vertices := PackedVector3Array()
  vertices.resize(vertex_count)
  for index in vertices.size():
    vertices[index] = Vector3(float(index), 0.0, 0.0)

  var arrays := []
  arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX] = vertices

  var mesh := ArrayMesh.new()
  mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
  return mesh


func _setup_joint_renderers() -> void:
  for joint in _get_rendered_line_joints():
    var joint_mesh_instance := _get_or_create_joint_mesh_instance(joint, false)
    var normal_joint_mesh_instance := _get_or_create_joint_mesh_instance(joint, true)
    var joint_renderer: RefCounted = JOINT_RENDERER_SCRIPT.new()
    var normal_joint_renderer: RefCounted = NORMAL_JOINT_RENDERER_SCRIPT.new()

    joint_renderer.setup(
      joint_mesh_instance,
      _get_joint_mesh(joint),
      _get_joint_shader(joint),
      depth_bias,
      round_joint_resolution,
      miter_limit,
    )
    normal_joint_renderer.setup(
      normal_joint_mesh_instance,
      _get_joint_mesh(joint),
      _get_normal_joint_shader(joint),
      depth_bias,
      round_joint_resolution,
      miter_limit,
    )

    _joint_mesh_instances[joint] = joint_mesh_instance
    _normal_joint_mesh_instances[joint] = normal_joint_mesh_instance
    _joint_renderers[joint] = joint_renderer
    _normal_joint_renderers[joint] = normal_joint_renderer


func _get_or_create_joint_mesh_instance(joint: int, normal: bool) -> MultiMeshInstance3D:
  if joint == LineJoint.ROUND:
    return _normal_joint_mesh_instance if normal else _joint_mesh_instance

  var node_name := _get_joint_node_name(joint, normal)
  var existing := get_node_or_null(node_name) as MultiMeshInstance3D
  if existing != null:
    return existing

  var mesh_instance := MultiMeshInstance3D.new()
  mesh_instance.name = node_name
  add_child(mesh_instance)
  return mesh_instance


func _get_joint_node_name(joint: int, normal: bool) -> String:
  var prefix := "NormalJointMesh" if normal else "JointMesh"
  if joint == LineJoint.BEVEL:
    return prefix + "Bevel"
  if joint == LineJoint.MITER:
    return prefix + "Miter"
  return prefix + "Round"


func _get_rendered_line_joints() -> Array[int]:
  return [LineJoint.ROUND, LineJoint.BEVEL, LineJoint.MITER]


func _get_joint_mesh(joint: int) -> ArrayMesh:
  if joint == LineJoint.BEVEL:
    return _bevel_joint_mesh
  if joint == LineJoint.MITER:
    return _miter_joint_mesh
  return _round_joint_mesh


func _get_joint_shader(joint: int) -> Shader:
  if joint == LineJoint.BEVEL:
    return JOINT_BEVEL_SHADER
  if joint == LineJoint.MITER:
    return JOINT_MITER_SHADER
  return JOINT_ROUND_SHADER


func _get_normal_joint_shader(joint: int) -> Shader:
  if joint == LineJoint.BEVEL:
    return NORMAL_JOINT_BEVEL_SHADER
  if joint == LineJoint.MITER:
    return NORMAL_JOINT_MITER_SHADER
  return NORMAL_JOINT_ROUND_SHADER


func _update_line_material_depth_bias() -> void:
  if not is_node_ready() or _line_renderer == null:
    return

  _line_renderer.set_depth_bias(depth_bias)
  _normal_line_renderer.set_depth_bias(depth_bias)
  _rect_renderer.set_depth_bias(depth_bias)
  _box_renderer.set_depth_bias(depth_bias)
  _sphere_renderer.set_depth_bias(depth_bias)
  _cylinder_renderer.set_depth_bias(depth_bias)
  _cone_renderer.set_depth_bias(depth_bias)
  for joint in _get_rendered_line_joints():
    _joint_renderers[joint].set_depth_bias(depth_bias)
    _normal_joint_renderers[joint].set_depth_bias(depth_bias)


func _update_joint_material_parameters() -> void:
  if not is_node_ready() or _joint_renderers.is_empty():
    return

  for joint in _get_rendered_line_joints():
    var joint_mesh := _get_joint_mesh(joint)
    _joint_renderers[joint].set_mesh(joint_mesh)
    _normal_joint_renderers[joint].set_mesh(joint_mesh)
    _joint_renderers[joint].set_material_parameters(
      _get_joint_shader(joint),
      depth_bias,
      round_joint_resolution,
      miter_limit,
    )
    _normal_joint_renderers[joint].set_material_parameters(
      _get_normal_joint_shader(joint),
      depth_bias,
      round_joint_resolution,
      miter_limit,
    )
    _normal_joint_renderers[joint].set_back_fade_parameters(
      back_fade_start,
      back_fade_transition,
    )


func _update_back_fade_parameters() -> void:
  if _normal_line_renderer == null:
    return

  _normal_line_renderer.set_back_fade_parameters(
    back_fade_start,
    back_fade_transition,
  )
  for joint in _get_rendered_line_joints():
    _normal_joint_renderers[joint].set_back_fade_parameters(
      back_fade_start,
      back_fade_transition,
    )


func _reset_buffers() -> void:
  _line_renderer.reset()
  _normal_line_renderer.reset()
  _rect_renderer.reset()
  _box_renderer.reset()
  _sphere_renderer.reset()
  _cylinder_renderer.reset()
  _cone_renderer.reset()
  for joint in _get_rendered_line_joints():
    _joint_renderers[joint].reset()
    _normal_joint_renderers[joint].reset()


func _get_camera_transform() -> Transform3D:
  var viewport := get_viewport()
  var camera := viewport.get_camera_3d()
  if camera != null:
    return camera.global_transform
  return Transform3D.IDENTITY


func _validate_global_basis() -> void:
  if global_transform.basis.is_equal_approx(Basis.IDENTITY):
    return

  push_error("DebugDraw3D must not be rotated or scaled. Keep its global basis as identity.")


func _emit_grid_lines(
    center: Vector3,
    rotation: Quaternion,
    cell_count: Vector2i,
    spacing: Vector2,
    color: Color,
    line_width: float,
    layer: int,
    outer_edges: int,
    skew: Vector2,
    use_normal: bool,
) -> void:
  if cell_count.x <= 0 or cell_count.y <= 0 or spacing.x <= 0.0 or spacing.y <= 0.0:
    return

  var basis := Basis(rotation.normalized())
  var normal := basis.y.normalized()
  var skew_tan := Vector2(tan(skew.x), tan(skew.y))
  var dx := Vector3(spacing.x, 0.0, spacing.x * skew_tan.y)
  var dz := Vector3(spacing.y * skew_tan.x, 0.0, spacing.y)
  var grid_start := -dx * float(cell_count.x) * 0.5 - dz * float(cell_count.y) * 0.5

  var x_lines_start := 0 if (outer_edges & GridOuterEdges.X) != 0 else 1
  var x_lines_end := cell_count.y + 1 if (outer_edges & GridOuterEdges.X) != 0 else cell_count.y
  for z_index in range(x_lines_start, x_lines_end):
    var line_start := center + basis * (grid_start + dz * float(z_index))
    var line_end := center + basis * (grid_start + dz * float(z_index) + dx * float(cell_count.x))
    if use_normal:
      _emit_normal_line(line_start, line_end, normal, color, line_width, layer)
    else:
      _emit_line(line_start, line_end, color, line_width, layer)

  var z_lines_start := 0 if (outer_edges & GridOuterEdges.Z) != 0 else 1
  var z_lines_end := cell_count.x + 1 if (outer_edges & GridOuterEdges.Z) != 0 else cell_count.x
  for x_index in range(z_lines_start, z_lines_end):
    var line_start := center + basis * (grid_start + dx * float(x_index))
    var line_end := center + basis * (grid_start + dx * float(x_index) + dz * float(cell_count.y))
    if use_normal:
      _emit_normal_line(line_start, line_end, normal, color, line_width, layer)
    else:
      _emit_line(line_start, line_end, color, line_width, layer)


func _get_rect_points(
    center: Vector3,
    rotation: Quaternion,
    rect_width: float,
    rect_height: float,
) -> PackedVector3Array:
  if rect_width <= 0.0 or rect_height <= 0.0:
    return PackedVector3Array()

  var basis := Basis(rotation.normalized())
  var half_width := basis.x * rect_width * 0.5
  var half_height := basis.y * rect_height * 0.5
  return PackedVector3Array(
    [
      center - half_width - half_height,
      center + half_width - half_height,
      center + half_width + half_height,
      center - half_width + half_height,
    ],
  )


func _get_rect_normals(rotation: Quaternion) -> PackedVector3Array:
  var basis := Basis(rotation.normalized())
  return PackedVector3Array(
    [
      -basis.y,
      basis.x,
      basis.y,
      -basis.x,
    ],
  )


func _get_box_line_points(
    pos: Vector3,
    rotation: Quaternion,
    size: Vector3,
) -> PackedVector3Array:
  if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
    return PackedVector3Array()

  var basis := Basis(rotation.normalized())
  var half_x := basis.x * size.x * 0.5
  var half_y := basis.y * size.y * 0.5
  var half_z := basis.z * size.z * 0.5
  var p000 := pos - half_x - half_y - half_z
  var p100 := pos + half_x - half_y - half_z
  var p110 := pos + half_x + half_y - half_z
  var p010 := pos - half_x + half_y - half_z
  var p001 := pos - half_x - half_y + half_z
  var p101 := pos + half_x - half_y + half_z
  var p111 := pos + half_x + half_y + half_z
  var p011 := pos - half_x + half_y + half_z

  return PackedVector3Array(
    [
      p000,
      p100,
      p100,
      p110,
      p110,
      p010,
      p010,
      p000,
      p001,
      p101,
      p101,
      p111,
      p111,
      p011,
      p011,
      p001,
      p000,
      p001,
      p100,
      p101,
      p110,
      p111,
      p010,
      p011,
    ],
  )


func _get_box_line_normals(rotation: Quaternion) -> PackedVector3Array:
  var basis := Basis(rotation.normalized())
  return PackedVector3Array(
    [
      (-basis.y - basis.z).normalized(),
      (basis.x - basis.z).normalized(),
      (basis.y - basis.z).normalized(),
      (-basis.x - basis.z).normalized(),
      (-basis.y + basis.z).normalized(),
      (basis.x + basis.z).normalized(),
      (basis.y + basis.z).normalized(),
      (-basis.x + basis.z).normalized(),
      (-basis.x - basis.y).normalized(),
      (basis.x - basis.y).normalized(),
      (basis.x + basis.y).normalized(),
      (-basis.x + basis.y).normalized(),
    ],
  )


func _get_circle_points(
    center: Vector3,
    rotation: Quaternion,
    radius: float,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
) -> PackedVector3Array:
  if radius <= 0.0 or segment_count < CIRCLE_SEGMENT_COUNT_MIN:
    return PackedVector3Array()

  var basis := Basis(rotation.normalized())
  var unit_points := _get_circle_unit_points(segment_count)
  var points := PackedVector3Array()
  points.resize(segment_count)
  for i in points.size():
    var unit_point: Vector2 = unit_points[i]
    points[i] = center + (basis.x * unit_point.x + basis.y * unit_point.y) * radius
  return points


func _get_circle_normals(
    rotation: Quaternion,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
) -> PackedVector3Array:
  if segment_count < CIRCLE_SEGMENT_COUNT_MIN:
    return PackedVector3Array()

  var basis := Basis(rotation.normalized())
  var unit_points := _get_circle_unit_normal_points(segment_count)
  var normals := PackedVector3Array()
  normals.resize(segment_count)
  for i in normals.size():
    var unit_point: Vector2 = unit_points[i]
    normals[i] = basis.x * unit_point.x + basis.y * unit_point.y
  return normals


func _get_circle_unit_points(segment_count: int) -> PackedVector2Array:
  if _circle_unit_points_by_segment_count.has(segment_count):
    return _circle_unit_points_by_segment_count[segment_count]

  var points := PackedVector2Array()
  points.resize(segment_count)
  for i in points.size():
    var angle := TAU * float(i) / float(segment_count)
    points[i] = Vector2(cos(angle), sin(angle))
  _circle_unit_points_by_segment_count[segment_count] = points
  return points


func _get_circle_unit_normal_points(segment_count: int) -> PackedVector2Array:
  if _circle_unit_normal_points_by_segment_count.has(segment_count):
    return _circle_unit_normal_points_by_segment_count[segment_count]

  var points := PackedVector2Array()
  points.resize(segment_count)
  for i in points.size():
    var angle := TAU * (float(i) + 0.5) / float(segment_count)
    points[i] = Vector2(cos(angle), sin(angle))
  _circle_unit_normal_points_by_segment_count[segment_count] = points
  return points


func _get_arc_points(
    center: Vector3,
    rotation: Quaternion,
    radius: float,
    angle: float,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
) -> PackedVector3Array:
  if radius <= 0.0 or is_zero_approx(angle) or segment_count < CIRCLE_SEGMENT_COUNT_MIN:
    return PackedVector3Array()

  var basis := Basis(rotation.normalized())
  var points := PackedVector3Array()
  points.resize(segment_count + 1)
  for i in points.size():
    var arc_angle := angle * float(i) / float(segment_count)
    points[i] = center + (basis.x * cos(arc_angle) + basis.y * sin(arc_angle)) * radius
  return points


func _get_arc_normals(
    rotation: Quaternion,
    angle: float,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
) -> PackedVector3Array:
  if is_zero_approx(angle) or segment_count < CIRCLE_SEGMENT_COUNT_MIN:
    return PackedVector3Array()

  var basis := Basis(rotation.normalized())
  var normals := PackedVector3Array()
  normals.resize(segment_count)
  for i in normals.size():
    var arc_angle := angle * (float(i) + 0.5) / float(segment_count)
    normals[i] = basis.x * cos(arc_angle) + basis.y * sin(arc_angle)
  return normals


func _get_curve_points(
    curve: Curve3D,
    curve_transform: Transform3D,
    max_stages: int,
    tolerance_length: float,
) -> PackedVector3Array:
  if curve == null or curve.point_count < 2 or tolerance_length <= 0.0:
    return PackedVector3Array()

  var points := curve.tessellate_even_length(maxi(max_stages, 0), tolerance_length)
  if points.size() < 2:
    return PackedVector3Array()

  if curve.closed and points[0].is_equal_approx(points[points.size() - 1]):
    points.resize(points.size() - 1)
    if points.size() < 2:
      return PackedVector3Array()

  for i in points.size():
    points[i] = curve_transform * points[i]
  return points


func _emit_sphere_axis_rings(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    color: Color,
    line_width: float,
    joint: int,
    layer: int,
    segment_count: int,
    y_axis_segment_count: int,
    z_axis_segment_count: int,
    use_normals: bool,
    use_dashes: bool,
    dash_width: float = 0.2,
    dash_space: float = 0.1,
    dash_offset: float = 0.0,
) -> void:
  if radius <= 0.0 or segment_count < CIRCLE_SEGMENT_COUNT_MIN:
    return

  var basis := Basis(rotation.normalized())
  var emitted_ring_keys := { }
  _emit_sphere_y_axis_rings(
    pos,
    basis,
    radius,
    color,
    line_width,
    joint,
    layer,
    segment_count,
    y_axis_segment_count,
    use_normals,
    use_dashes,
    dash_width,
    dash_space,
    dash_offset,
    emitted_ring_keys,
  )
  _emit_sphere_y_axis_rotated_great_circles(
    pos,
    basis,
    radius,
    color,
    line_width,
    joint,
    layer,
    segment_count,
    z_axis_segment_count,
    use_normals,
    use_dashes,
    dash_width,
    dash_space,
    dash_offset,
    emitted_ring_keys,
  )


func _emit_sphere_y_axis_rings(
    pos: Vector3,
    basis: Basis,
    radius: float,
    color: Color,
    line_width: float,
    joint: int,
    layer: int,
    segment_count: int,
    y_axis_segment_count: int,
    use_normals: bool,
    use_dashes: bool,
    dash_width: float,
    dash_space: float,
    dash_offset: float,
    emitted_ring_keys: Dictionary,
) -> void:
  if y_axis_segment_count < 2:
    return

  var ring_rotation := Basis(basis.x, basis.z, -basis.y).get_rotation_quaternion()
  for offset in _get_sphere_y_axis_ring_offsets(radius, y_axis_segment_count):
    var ring_radius := sqrt(maxf(radius * radius - offset * offset, 0.0))
    if ring_radius <= 0.0:
      continue

    var ring_center := pos + basis.y * offset
    var ring_key := _get_sphere_ring_key(ring_center, basis.y, ring_radius)
    if emitted_ring_keys.has(ring_key):
      continue
    emitted_ring_keys[ring_key] = true

    var points := _get_circle_points(ring_center, ring_rotation, ring_radius, segment_count)
    _emit_sphere_ring_points(points, pos, color, line_width, joint, layer, use_normals, use_dashes, dash_width, dash_space, dash_offset)


func _emit_sphere_y_axis_rotated_great_circles(
    pos: Vector3,
    basis: Basis,
    radius: float,
    color: Color,
    line_width: float,
    joint: int,
    layer: int,
    segment_count: int,
    z_axis_segment_count: int,
    use_normals: bool,
    use_dashes: bool,
    dash_width: float,
    dash_space: float,
    dash_offset: float,
    emitted_ring_keys: Dictionary,
) -> void:
  if z_axis_segment_count < SPHERE_AXIS_SEGMENT_COUNT_MIN:
    return

  var base_circle_basis := Basis(basis.y, basis.z, basis.x)
  var angle_step := PI / float(z_axis_segment_count)
  for segment_index in z_axis_segment_count:
    var circle_basis := Basis(basis.y.normalized(), angle_step * float(segment_index)) * base_circle_basis
    var ring_key := _get_sphere_ring_key(pos, circle_basis.z, radius)
    if emitted_ring_keys.has(ring_key):
      continue
    emitted_ring_keys[ring_key] = true

    var points := _get_circle_points(pos, circle_basis.get_rotation_quaternion(), radius, segment_count)
    _emit_sphere_ring_points(points, pos, color, line_width, joint, layer, use_normals, use_dashes, dash_width, dash_space, dash_offset)


func _emit_sphere_ring_points(
    points: PackedVector3Array,
    sphere_center: Vector3,
    color: Color,
    line_width: float,
    joint: int,
    layer: int,
    use_normals: bool,
    use_dashes: bool,
    dash_width: float,
    dash_space: float,
    dash_offset: float,
) -> void:
  if points.size() == 0:
    return

  if use_normals:
    var normals := _get_sphere_ring_normals(sphere_center, points)
    if use_dashes:
      draw_line_loop_n_d(points, normals, color, line_width, dash_width, dash_space, dash_offset, joint, layer)
    else:
      draw_line_loop_n(points, normals, color, line_width, joint, layer)
    return

  if use_dashes:
    draw_line_loop_d(points, color, line_width, dash_width, dash_space, dash_offset, joint, layer)
  else:
    draw_line_loop(points, color, line_width, joint, layer)


func _get_sphere_y_axis_ring_offsets(radius: float, y_axis_segment_count: int) -> PackedFloat32Array:
  var offsets := PackedFloat32Array()
  if radius <= 0.0 or y_axis_segment_count < 2:
    return offsets

  for segment_index in range(1, y_axis_segment_count):
    offsets.append(radius * (-1.0 + 2.0 * float(segment_index) / float(y_axis_segment_count)))
  return offsets


func _get_sphere_ring_normals(
    sphere_center: Vector3,
    points: PackedVector3Array,
) -> PackedVector3Array:
  var normals := PackedVector3Array()
  normals.resize(points.size())
  for i in points.size():
    var to_index := 0 if i == points.size() - 1 else i + 1
    normals[i] = ((points[i] + points[to_index]) * 0.5 - sphere_center).normalized()
  return normals


func _get_sphere_ring_key(center: Vector3, normal: Vector3, radius: float) -> String:
  var canonical_normal := normal.normalized()
  if _should_flip_sphere_ring_normal(canonical_normal):
    canonical_normal = -canonical_normal

  var scale := 100000.0
  return "%d:%d:%d:%d:%d:%d:%d" % [
    roundi(center.x * scale),
    roundi(center.y * scale),
    roundi(center.z * scale),
    roundi(canonical_normal.x * scale),
    roundi(canonical_normal.y * scale),
    roundi(canonical_normal.z * scale),
    roundi(radius * scale),
  ]


func _should_flip_sphere_ring_normal(normal: Vector3) -> bool:
  if not is_zero_approx(normal.x):
    return normal.x < 0.0
  if not is_zero_approx(normal.y):
    return normal.y < 0.0
  return normal.z < 0.0


func _get_cone_base_points(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    height: float,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
) -> PackedVector3Array:
  if radius <= 0.0 or height <= 0.0 or segment_count < CIRCLE_SEGMENT_COUNT_MIN:
    return PackedVector3Array()

  var basis := Basis(rotation.normalized())
  var base_center := pos - basis.y * height * 0.5
  return _get_circle_points(base_center, _get_cone_base_rotation(rotation), radius, segment_count)


func _get_cone_base_rotation(rotation: Quaternion) -> Quaternion:
  var basis := Basis(rotation.normalized())
  var axis := basis.y.normalized()
  var width_axis := basis.x.normalized()
  var height_axis := axis.cross(width_axis)
  if height_axis.length_squared() <= 0.0:
    height_axis = basis.z.normalized()
  else:
    height_axis = height_axis.normalized()
  return Basis(width_axis, height_axis, axis).get_rotation_quaternion()


func _get_cone_side_line_points(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    height: float,
    side_segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
) -> PackedVector3Array:
  if radius <= 0.0 or height <= 0.0 or side_segment_count <= 0:
    return PackedVector3Array()

  var basis := Basis(rotation.normalized())
  var base_rotation := Basis(_get_cone_base_rotation(rotation))
  var apex := pos + basis.y * height * 0.5
  var base_center := pos - basis.y * height * 0.5
  var points := PackedVector3Array()
  points.resize(side_segment_count * 2)
  for i in side_segment_count:
    var angle := TAU * float(i) / float(side_segment_count)
    var index := i * 2
    points[index] = apex
    points[index + 1] = base_center + (base_rotation.x * cos(angle) + base_rotation.y * sin(angle)) * radius
  return points


func _get_cone_side_line_normals(
    rotation: Quaternion,
    radius: float,
    height: float,
    side_segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
) -> PackedVector3Array:
  if radius <= 0.0 or height <= 0.0 or side_segment_count <= 0:
    return PackedVector3Array()

  var basis := Basis(rotation.normalized())
  var axis := basis.y.normalized()
  var base_rotation := Basis(_get_cone_base_rotation(rotation))
  var normals := PackedVector3Array()
  normals.resize(side_segment_count)
  for i in normals.size():
    var angle := TAU * float(i) / float(side_segment_count)
    var radial := base_rotation.x * cos(angle) + base_rotation.y * sin(angle)
    normals[i] = (radial * height + axis * radius).normalized()
  return normals


func _get_cylinder_ring_points(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    half_height: float,
    height_sign: float,
    segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
) -> PackedVector3Array:
  if radius <= 0.0 or half_height <= 0.0 or segment_count < CIRCLE_SEGMENT_COUNT_MIN:
    return PackedVector3Array()

  var basis := Basis(rotation.normalized())
  var ring_center := pos + basis.y * half_height * signf(height_sign)
  return _get_circle_points(ring_center, _get_cone_base_rotation(rotation), radius, segment_count)


func _get_cylinder_side_line_points(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    half_height: float,
    side_segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
) -> PackedVector3Array:
  if radius <= 0.0 or half_height <= 0.0 or side_segment_count <= 0:
    return PackedVector3Array()

  var basis := Basis(rotation.normalized())
  var ring_rotation := Basis(_get_cone_base_rotation(rotation))
  var bottom_center := pos - basis.y * half_height
  var top_center := pos + basis.y * half_height
  var points := PackedVector3Array()
  points.resize(side_segment_count * 2)
  for i in side_segment_count:
    var angle := TAU * float(i) / float(side_segment_count)
    var radial := (ring_rotation.x * cos(angle) + ring_rotation.y * sin(angle)) * radius
    var index := i * 2
    points[index] = bottom_center + radial
    points[index + 1] = top_center + radial
  return points


func _get_cylinder_side_line_normals(
    rotation: Quaternion,
    radius: float,
    half_height: float,
    side_segment_count: int = CIRCLE_SEGMENT_COUNT_DEFAULT,
) -> PackedVector3Array:
  if radius <= 0.0 or half_height <= 0.0 or side_segment_count <= 0:
    return PackedVector3Array()

  var ring_rotation := Basis(_get_cone_base_rotation(rotation))
  var normals := PackedVector3Array()
  normals.resize(side_segment_count)
  for i in normals.size():
    var angle := TAU * float(i) / float(side_segment_count)
    normals[i] = (ring_rotation.x * cos(angle) + ring_rotation.y * sin(angle)).normalized()
  return normals


func _emit_capsule(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    half_height: float,
    color: Color,
    line_width: float,
    segment_count: int,
    side_segment_count: int,
    joint: int,
    layer: int,
    use_normals: bool,
) -> void:
  if radius <= 0.0 or half_height < 0.0 or segment_count < CIRCLE_SEGMENT_COUNT_MIN:
    return

  var basis := Basis(rotation.normalized())
  var axis := basis.y.normalized()
  var bottom_center := pos - axis * half_height
  var top_center := pos + axis * half_height
  var ring_rotation := _get_cone_base_rotation(rotation)
  _emit_capsule_cylinder_rings(
    bottom_center,
    top_center,
    ring_rotation,
    radius,
    color,
    line_width,
    segment_count,
    joint,
    layer,
    use_normals,
  )
  _emit_capsule_side_outlines(
    bottom_center,
    top_center,
    axis,
    ring_rotation,
    radius,
    color,
    line_width,
    segment_count,
    side_segment_count,
    joint,
    layer,
    use_normals,
  )


func _emit_capsule_cylinder_rings(
    bottom_center: Vector3,
    top_center: Vector3,
    ring_rotation: Quaternion,
    radius: float,
    color: Color,
    line_width: float,
    segment_count: int,
    joint: int,
    layer: int,
    use_normals: bool,
) -> void:
  var bottom_points := _get_circle_points(bottom_center, ring_rotation, radius, segment_count)
  if use_normals:
    var ring_normals := _get_circle_normals(ring_rotation, bottom_points.size())
    draw_line_loop_n(bottom_points, ring_normals, color, line_width, joint, layer)
  else:
    draw_line_loop(bottom_points, color, line_width, joint, layer)

  if bottom_center.is_equal_approx(top_center):
    return

  var top_points := _get_circle_points(top_center, ring_rotation, radius, segment_count)
  if use_normals:
    draw_line_loop_n(top_points, _get_circle_normals(ring_rotation, top_points.size()), color, line_width, joint, layer)
  else:
    draw_line_loop(top_points, color, line_width, joint, layer)


func _emit_capsule_side_outlines(
    bottom_center: Vector3,
    top_center: Vector3,
    axis: Vector3,
    ring_rotation: Quaternion,
    radius: float,
    color: Color,
    line_width: float,
    segment_count: int,
    side_segment_count: int,
    joint: int,
    layer: int,
    use_normals: bool,
) -> void:
  if side_segment_count < SPHERE_AXIS_SEGMENT_COUNT_MIN:
    return

  var ring_basis := Basis(ring_rotation)
  for side_index in side_segment_count:
    var angle := PI * float(side_index) / float(side_segment_count)
    var radial := (ring_basis.x * cos(angle) + ring_basis.y * sin(angle)).normalized()
    var points := _get_capsule_side_outline_points(
      bottom_center,
      top_center,
      axis,
      radial,
      radius,
      _get_capsule_arc_segment_count(segment_count),
    )
    if use_normals:
      draw_line_loop_n(
        points,
        _get_capsule_side_outline_normals(bottom_center, top_center, axis, points),
        color,
        line_width,
        joint,
        layer,
      )
    else:
      draw_line_loop(points, color, line_width, joint, layer)


func _get_capsule_side_outline_points(
    bottom_center: Vector3,
    top_center: Vector3,
    axis: Vector3,
    radial: Vector3,
    radius: float,
    arc_segment_count: int,
) -> PackedVector3Array:
  var points := PackedVector3Array()
  points.resize((arc_segment_count + 1) * 2)

  for i in arc_segment_count + 1:
    var angle := PI * float(i) / float(arc_segment_count)
    points[i] = top_center + radial * cos(angle) * radius + axis * sin(angle) * radius

  var bottom_start := arc_segment_count + 1
  for i in arc_segment_count + 1:
    var angle := PI + PI * float(i) / float(arc_segment_count)
    points[bottom_start + i] = bottom_center + radial * cos(angle) * radius + axis * sin(angle) * radius

  return points


func _get_capsule_side_outline_normals(
    bottom_center: Vector3,
    top_center: Vector3,
    axis: Vector3,
    points: PackedVector3Array,
) -> PackedVector3Array:
  var normals := PackedVector3Array()
  normals.resize(points.size())
  var mid_height := bottom_center.distance_to(top_center)
  for i in points.size():
    var to_index := 0 if i == points.size() - 1 else i + 1
    var midpoint := (points[i] + points[to_index]) * 0.5
    var axis_distance := clampf((midpoint - bottom_center).dot(axis), 0.0, mid_height)
    var normal_center := bottom_center + axis * axis_distance
    normals[i] = (midpoint - normal_center).normalized()
  return normals


func _get_capsule_arc_segment_count(segment_count: int) -> int:
  return maxi(1, ceili(float(segment_count) * 0.5))


func _emit_line_list(
    points: PackedVector3Array,
    color: Color,
    width: float,
    layer: int,
) -> void:
  var pair_count := int(points.size() / 2)
  for i in pair_count:
    var index := i * 2
    _emit_line(points[index], points[index + 1], color, width, layer)


func _emit_normal_line_list(
    points: PackedVector3Array,
    normals: PackedVector3Array,
    color: Color,
    width: float,
    layer: int,
) -> void:
  var pair_count := int(points.size() / 2)
  for i in pair_count:
    var index := i * 2
    _emit_normal_line(points[index], points[index + 1], normals[i], color, width, layer)


func _emit_dashed_line_list(
    points: PackedVector3Array,
    color: Color,
    width: float,
    layer: int,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
) -> void:
  var pair_count := int(points.size() / 2)
  for i in pair_count:
    var index := i * 2
    _emit_dashed_line(
      points[index],
      points[index + 1],
      color,
      width,
      layer,
      dash_width_value,
      dash_space_value,
      dash_offset_value,
    )


func _emit_dashed_normal_line_list(
    points: PackedVector3Array,
    normals: PackedVector3Array,
    color: Color,
    width: float,
    layer: int,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
) -> void:
  var pair_count := int(points.size() / 2)
  if normals.size() < pair_count:
    return

  for i in pair_count:
    var index := i * 2
    _emit_dashed_normal_line(
      points[index],
      points[index + 1],
      normals[i],
      color,
      width,
      layer,
      dash_width_value,
      dash_space_value,
      dash_offset_value,
    )


func _emit_line_strip(
    points: PackedVector3Array,
    color: Color,
    width: float,
    joint: int,
    layer: int,
) -> void:
  var distance := 0.0
  for i in points.size() - 1:
    var from := points[i]
    var to := points[i + 1]
    var next_distance := distance + from.distance_to(to)
    _emit_line(from, to, color, width, layer, distance, next_distance)
    distance = next_distance

  if _is_rendered_line_joint(joint):
    for i in range(1, points.size() - 1):
      _emit_joint(points[i - 1], points[i], points[i + 1], color, width, joint, layer)


func _emit_normal_line_strip(
    points: PackedVector3Array,
    normals: PackedVector3Array,
    color: Color,
    width: float,
    joint: int,
    layer: int,
) -> void:
  for i in points.size() - 1:
    _emit_normal_line(points[i], points[i + 1], normals[i], color, width, layer)

  if _is_rendered_line_joint(joint):
    for i in range(1, points.size() - 1):
      _emit_normal_joint(
        points[i - 1],
        points[i],
        points[i + 1],
        normals[i - 1],
        normals[i],
        color,
        width,
        joint,
        layer,
      )


func _emit_line_loop(
    points: PackedVector3Array,
    color: Color,
    width: float,
    joint: int,
    layer: int,
) -> void:
  var distance := 0.0
  for i in points.size() - 1:
    var from := points[i]
    var to := points[i + 1]
    var next_distance := distance + from.distance_to(to)
    _emit_line(from, to, color, width, layer, distance, next_distance)
    distance = next_distance

  var loop_from := points[points.size() - 1]
  var loop_to := points[0]
  _emit_line(loop_from, loop_to, color, width, layer, distance, distance + loop_from.distance_to(loop_to))

  if _is_rendered_line_joint(joint) and points.size() > 2:
    for i in range(1, points.size() - 1):
      _emit_joint(points[i - 1], points[i], points[i + 1], color, width, joint, layer)
    _emit_joint(points[points.size() - 1], points[0], points[1], color, width, joint, layer)
    _emit_joint(points[points.size() - 2], points[points.size() - 1], points[0], color, width, joint, layer)


func _emit_normal_line_loop(
    points: PackedVector3Array,
    normals: PackedVector3Array,
    color: Color,
    width: float,
    joint: int,
    layer: int,
) -> void:
  for i in points.size() - 1:
    _emit_normal_line(points[i], points[i + 1], normals[i], color, width, layer)

  _emit_normal_line(points[points.size() - 1], points[0], normals[points.size() - 1], color, width, layer)

  if _is_rendered_line_joint(joint) and points.size() > 2:
    for i in range(1, points.size() - 1):
      _emit_normal_joint(
        points[i - 1],
        points[i],
        points[i + 1],
        normals[i - 1],
        normals[i],
        color,
        width,
        joint,
        layer,
      )
    _emit_normal_joint(
      points[points.size() - 1],
      points[0],
      points[1],
      normals[points.size() - 1],
      normals[0],
      color,
      width,
      joint,
      layer,
    )
    _emit_normal_joint(
      points[points.size() - 2],
      points[points.size() - 1],
      points[0],
      normals[points.size() - 2],
      normals[points.size() - 1],
      color,
      width,
      joint,
      layer,
    )


func _emit_dashed_line(
    from: Vector3,
    to: Vector3,
    color: Color,
    width: float,
    layer: int,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
    distance_start: float = 0.0,
    distance_end: float = -1.0,
) -> void:
  _emit_line(
    from,
    to,
    color,
    width,
    layer,
    distance_start,
    distance_end,
    true,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
  )


func _emit_dashed_line_strip(
    points: PackedVector3Array,
    color: Color,
    width: float,
    joint: int,
    layer: int,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
) -> void:
  var distances := PackedFloat32Array()
  distances.resize(points.size())

  var distance := 0.0
  for i in points.size() - 1:
    var from := points[i]
    var to := points[i + 1]
    var next_distance := distance + from.distance_to(to)
    distances[i + 1] = next_distance
    _emit_dashed_line(
      from,
      to,
      color,
      width,
      layer,
      dash_width_value,
      dash_space_value,
      dash_offset_value,
      distance,
      next_distance,
    )
    distance = next_distance

  if _is_rendered_line_joint(joint):
    for i in range(1, points.size() - 1):
      _emit_dashed_joint(
        points[i - 1],
        points[i],
        points[i + 1],
        color,
        width,
        joint,
        layer,
        distances[i],
        dash_width_value,
        dash_space_value,
        dash_offset_value,
      )


func _emit_dashed_line_loop(
    points: PackedVector3Array,
    color: Color,
    width: float,
    joint: int,
    layer: int,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
) -> void:
  var distances := PackedFloat32Array()
  distances.resize(points.size())

  var distance := 0.0
  for i in points.size() - 1:
    var from := points[i]
    var to := points[i + 1]
    var next_distance := distance + from.distance_to(to)
    distances[i + 1] = next_distance
    _emit_dashed_line(
      from,
      to,
      color,
      width,
      layer,
      dash_width_value,
      dash_space_value,
      dash_offset_value,
      distance,
      next_distance,
    )
    distance = next_distance

  var loop_from := points[points.size() - 1]
  var loop_to := points[0]
  _emit_dashed_line(
    loop_from,
    loop_to,
    color,
    width,
    layer,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
    distance,
    distance + loop_from.distance_to(loop_to),
  )

  if _is_rendered_line_joint(joint) and points.size() > 2:
    for i in range(1, points.size() - 1):
      _emit_dashed_joint(
        points[i - 1],
        points[i],
        points[i + 1],
        color,
        width,
        joint,
        layer,
        distances[i],
        dash_width_value,
        dash_space_value,
        dash_offset_value,
      )
    _emit_dashed_joint(
      points[points.size() - 1],
      points[0],
      points[1],
      color,
      width,
      joint,
      layer,
      0.0,
      dash_width_value,
      dash_space_value,
      dash_offset_value,
    )
    _emit_dashed_joint(
      points[points.size() - 2],
      points[points.size() - 1],
      points[0],
      color,
      width,
      joint,
      layer,
      distances[points.size() - 1],
      dash_width_value,
      dash_space_value,
      dash_offset_value,
    )


func _emit_dashed_normal_line(
    from: Vector3,
    to: Vector3,
    normal: Vector3,
    color: Color,
    width: float,
    layer: int,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
    distance_start: float = 0.0,
    distance_end: float = -1.0,
) -> void:
  _normal_line_renderer.emit_line(
    from,
    to,
    normal,
    color,
    _resolve_line_width(width),
    layer,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
    distance_start,
    distance_end,
    true,
  )


func _emit_dashed_normal_line_strip(
    points: PackedVector3Array,
    normals: PackedVector3Array,
    color: Color,
    width: float,
    joint: int,
    layer: int,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
) -> void:
  var distances := PackedFloat32Array()
  distances.resize(points.size())

  var distance := 0.0
  for i in points.size() - 1:
    var from := points[i]
    var to := points[i + 1]
    var next_distance := distance + from.distance_to(to)
    distances[i + 1] = next_distance
    _emit_dashed_normal_line(
      from,
      to,
      normals[i],
      color,
      width,
      layer,
      dash_width_value,
      dash_space_value,
      dash_offset_value,
      distance,
      next_distance,
    )
    distance = next_distance

  if _is_rendered_line_joint(joint):
    for i in range(1, points.size() - 1):
      _emit_dashed_normal_joint(
        points[i - 1],
        points[i],
        points[i + 1],
        normals[i - 1],
        normals[i],
        color,
        width,
        joint,
        layer,
        distances[i],
        dash_width_value,
        dash_space_value,
        dash_offset_value,
      )


func _emit_dashed_normal_line_loop(
    points: PackedVector3Array,
    normals: PackedVector3Array,
    color: Color,
    width: float,
    joint: int,
    layer: int,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
) -> void:
  var distances := PackedFloat32Array()
  distances.resize(points.size())

  var distance := 0.0
  for i in points.size() - 1:
    var from := points[i]
    var to := points[i + 1]
    var next_distance := distance + from.distance_to(to)
    distances[i + 1] = next_distance
    _emit_dashed_normal_line(
      from,
      to,
      normals[i],
      color,
      width,
      layer,
      dash_width_value,
      dash_space_value,
      dash_offset_value,
      distance,
      next_distance,
    )
    distance = next_distance

  var loop_from := points[points.size() - 1]
  var loop_to := points[0]
  _emit_dashed_normal_line(
    loop_from,
    loop_to,
    normals[points.size() - 1],
    color,
    width,
    layer,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
    distance,
    distance + loop_from.distance_to(loop_to),
  )

  if _is_rendered_line_joint(joint) and points.size() > 2:
    for i in range(1, points.size() - 1):
      _emit_dashed_normal_joint(
        points[i - 1],
        points[i],
        points[i + 1],
        normals[i - 1],
        normals[i],
        color,
        width,
        joint,
        layer,
        distances[i],
        dash_width_value,
        dash_space_value,
        dash_offset_value,
      )
    _emit_dashed_normal_joint(
      points[points.size() - 1],
      points[0],
      points[1],
      normals[points.size() - 1],
      normals[0],
      color,
      width,
      joint,
      layer,
      0.0,
      dash_width_value,
      dash_space_value,
      dash_offset_value,
    )
    _emit_dashed_normal_joint(
      points[points.size() - 2],
      points[points.size() - 1],
      points[0],
      normals[points.size() - 2],
      normals[points.size() - 1],
      color,
      width,
      joint,
      layer,
      distances[points.size() - 1],
      dash_width_value,
      dash_space_value,
      dash_offset_value,
    )


func _emit_line(
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
  _line_renderer.emit_regular_line(
    from,
    to,
    color,
    _resolve_line_width(width),
    layer,
    distance_start,
    distance_end,
    dashed,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
  )


func _emit_arrow(
    pos: Vector3,
    dir: Vector3,
    color: Color,
    width: float,
    head_angle: float,
    joint: int,
    layer: int,
) -> void:
  var head_length := dir.length()
  if head_length <= 0.0:
    return

  var direction := dir / head_length
  var tangent := _get_perpendicular_unit(direction)
  var bitangent := direction.cross(tangent).normalized()
  var resolved_head_angle := clampf(head_angle, ARROW_HEAD_ANGLE_MIN, ARROW_HEAD_ANGLE_MAX)
  var head_radius := tan(resolved_head_angle) * head_length
  var head_center := pos - direction * head_length

  _emit_line_strip(
    PackedVector3Array(
      [
        head_center + tangent * head_radius,
        pos,
        head_center - tangent * head_radius,
      ],
    ),
    color,
    width,
    joint,
    layer,
  )
  _emit_line_strip(
    PackedVector3Array(
      [
        head_center + bitangent * head_radius,
        pos,
        head_center - bitangent * head_radius,
      ],
    ),
    color,
    width,
    joint,
    layer,
  )


func _emit_normal_line(
    from: Vector3,
    to: Vector3,
    normal: Vector3,
    color: Color,
    width: float,
    layer: int,
) -> void:
  _normal_line_renderer.emit_line(from, to, normal, color, _resolve_line_width(width), layer)


func _emit_arrow_with_normal(
    pos: Vector3,
    dir: Vector3,
    normal: Vector3,
    color: Color,
    width: float,
    head_angle: float,
    joint: int,
    layer: int,
) -> void:
  var head_length := dir.length()
  if head_length <= 0.0:
    return

  var direction := dir / head_length
  var tangent := _get_projected_perpendicular_unit(direction, normal)
  var bitangent := direction.cross(tangent).normalized()
  var resolved_head_angle := clampf(head_angle, ARROW_HEAD_ANGLE_MIN, ARROW_HEAD_ANGLE_MAX)
  var head_radius := tan(resolved_head_angle) * head_length
  var head_center := pos - direction * head_length

  _emit_normal_line_strip(
    PackedVector3Array(
      [
        head_center + tangent * head_radius,
        pos,
        head_center - tangent * head_radius,
      ],
    ),
    PackedVector3Array(
      [
        _get_arrow_surface_normal(direction, tangent, head_length, head_radius),
        _get_arrow_surface_normal(direction, -tangent, head_length, head_radius),
      ],
    ),
    color,
    width,
    joint,
    layer,
  )
  _emit_normal_line_strip(
    PackedVector3Array(
      [
        head_center + bitangent * head_radius,
        pos,
        head_center - bitangent * head_radius,
      ],
    ),
    PackedVector3Array(
      [
        _get_arrow_surface_normal(direction, bitangent, head_length, head_radius),
        _get_arrow_surface_normal(direction, -bitangent, head_length, head_radius),
      ],
    ),
    color,
    width,
    joint,
    layer,
  )


func _emit_dashed_joint(
    previous: Vector3,
    center: Vector3,
    next: Vector3,
    color: Color,
    width: float,
    joint: int,
    layer: int,
    distance: float,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
) -> void:
  _emit_joint(
    previous,
    center,
    next,
    color,
    width,
    joint,
    layer,
    distance,
    true,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
  )


func _emit_dashed_normal_joint(
    previous: Vector3,
    center: Vector3,
    next: Vector3,
    previous_normal: Vector3,
    next_normal: Vector3,
    color: Color,
    width: float,
    joint: int,
    layer: int,
    distance: float,
    dash_width_value: float,
    dash_space_value: float,
    dash_offset_value: float,
) -> void:
  _emit_normal_joint(
    previous,
    center,
    next,
    previous_normal,
    next_normal,
    color,
    width,
    joint,
    layer,
    distance,
    true,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
  )


func _emit_normal_joint(
    previous: Vector3,
    center: Vector3,
    next: Vector3,
    previous_normal: Vector3,
    next_normal: Vector3,
    color: Color,
    width: float,
    joint: int,
    layer: int,
    distance: float = 0.0,
    dashed: bool = false,
    dash_width_value: float = 0.0,
    dash_space_value: float = 0.0,
    dash_offset_value: float = 0.0,
) -> void:
  if not _is_rendered_line_joint(joint):
    return

  _normal_joint_renderers[joint].emit_normal_joint(
    previous,
    center,
    next,
    previous_normal,
    next_normal,
    color,
    _resolve_line_width(width),
    layer,
    distance,
    dashed,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
  )


func _emit_joint(
    previous: Vector3,
    center: Vector3,
    next: Vector3,
    color: Color,
    width: float,
    joint: int,
    layer: int,
    distance: float = 0.0,
    dashed: bool = false,
    dash_width_value: float = 0.0,
    dash_space_value: float = 0.0,
    dash_offset_value: float = 0.0,
) -> void:
  if not _is_rendered_line_joint(joint):
    return

  _joint_renderers[joint].emit_joint(
    previous,
    center,
    next,
    color,
    _resolve_line_width(width),
    layer,
    distance,
    dashed,
    dash_width_value,
    dash_space_value,
    dash_offset_value,
  )


func _emit_box_s(
    pos: Vector3,
    rotation: Quaternion,
    size: Vector3,
    color: Color,
    layer: int,
) -> void:
  var basis := Basis(rotation.normalized())
  _box_renderer.emit_mesh(
    Transform3D(Basis(basis.x * size.x, basis.y * size.y, basis.z * size.z), pos),
    color,
    layer,
  )


func _emit_sphere_s(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    color: Color,
    layer: int,
) -> void:
  var basis := Basis(rotation.normalized())
  var diameter := radius * 2.0
  _sphere_renderer.emit_mesh(
    Transform3D(Basis(basis.x * diameter, basis.y * diameter, basis.z * diameter), pos),
    color,
    layer,
  )


func _emit_cylinder_s(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    half_height: float,
    color: Color,
    layer: int,
) -> void:
  var basis := Basis(rotation.normalized())
  var diameter := radius * 2.0
  var height := half_height * 2.0
  _cylinder_renderer.emit_mesh(
    Transform3D(Basis(basis.x * diameter, basis.y * height, basis.z * diameter), pos),
    color,
    layer,
  )


func _emit_cone_s(
    pos: Vector3,
    rotation: Quaternion,
    radius: float,
    height: float,
    color: Color,
    layer: int,
) -> void:
  var basis := Basis(rotation.normalized())
  var diameter := radius * 2.0
  _cone_renderer.emit_mesh(
    Transform3D(Basis(basis.x * diameter, basis.y * height, basis.z * diameter), pos),
    color,
    layer,
  )


func _emit_rect_s(
    center: Vector3,
    rotation: Quaternion,
    width: float,
    height: float,
    color: Color,
    layer: int,
) -> void:
  var basis := Basis(rotation.normalized())
  _emit_rect_s_transform(center, basis.x * width, basis.y * height, color, layer)


func _emit_rect_s_transform(
    center: Vector3,
    width_axis: Vector3,
    height_axis: Vector3,
    color: Color,
    layer: int,
) -> void:
  var normal := width_axis.cross(height_axis).normalized()
  _rect_renderer.emit_rect(Transform3D(Basis(width_axis, height_axis, normal), center), color, layer)


func _resolve_line_width(width: float) -> float:
  if width > 0.0:
    return width
  return maxf(line_width, 0.1)


func _is_rendered_line_joint(joint: int) -> bool:
  return joint == LineJoint.ROUND or joint == LineJoint.BEVEL or joint == LineJoint.MITER


func _get_perpendicular_unit(direction: Vector3) -> Vector3:
  var reference := Vector3.UP
  if absf(direction.dot(reference)) > 0.99:
    reference = Vector3.RIGHT
  return direction.cross(reference).normalized()


func _get_projected_perpendicular_unit(direction: Vector3, vector: Vector3) -> Vector3:
  var perpendicular := vector - direction * vector.dot(direction)
  if perpendicular.length_squared() <= 0.0:
    return _get_perpendicular_unit(direction)
  return perpendicular.normalized()


func _get_arrow_surface_normal(
    direction: Vector3,
    radial: Vector3,
    head_length: float,
    head_radius: float,
) -> Vector3:
  return (radial * head_length + direction * head_radius).normalized()


func _resolve_depth_bias(value: float) -> float:
  return clampf(value, DEPTH_BIAS_MIN, DEPTH_BIAS_MAX)
