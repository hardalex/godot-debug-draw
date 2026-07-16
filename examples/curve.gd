extends Node3D
## Curve example scene: curated debug curve parameter samples on the XZ plane.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const CURVE_Y := 0.1
const CURVE_BASE_LINE_WIDTH := 2.0
const CURVE_EMPHASIS_LINE_WIDTH := 8.0
const CURVE_MAX_STAGES := 5
const CURVE_TOLERANCE_LENGTH := 0.08
const CURVE_JOINT_TOLERANCE_LENGTH := 0.35
const ANCHOR_POINT_RADIUS := 0.045
const CONTROL_POINT_RADIUS := 0.032
const CONTROL_POINT_EDGE_WIDTH := 1.0
const CONTROL_POINT_SEGMENT_COUNT := 16
const SAMPLE_SPACING := 0.82
const CONSTRUCTION_SAMPLE_Z := -0.45
const CONSTRUCTION_TITLE_Z := 0.35
const EXAMPLE_TITLE_Z := -1.2
const EXAMPLE_START_Z := -2.0
const ROTATION_SAMPLE_COUNT := 8
const ROTATION_TUNNEL_DEPTH_STEP := 0.16
const ROTATION_TUNNEL_SCALE_STEP := 0.06
const ROTATION_TUNNEL_TWIST_STEP := PI * 0.12
const COLUMN_SPACING := 2.0
const LABEL_Y := CURVE_Y + 0.01
const SAMPLE_LABEL_GAP := 0.12
const LABEL_FONT_SIZE := 20
const TITLE_LABEL_FONT_SIZE := 28
const LABEL_PIXEL_SIZE := 0.004
const DASH_OFFSET_SPEED := 0.6
const WIDTH_VALUES := [1.0, 2.0, 5.5, 10.0]
const SHAPE_VALUES := [0.25, 0.65, 1.0, 1.35]
const TOLERANCE_VALUES := [0.04, 0.08, 0.16, 0.32]
const CLOSED_VALUES := ["open", "closed", "small", "wide"]
const DASH_VALUES := [Vector2(0.1, 0.1), Vector2(0.2, 0.1), Vector2(0.4, 0.15), Vector2(0.04, 0.12)]
const JOINT_VALUES := [
  DebugDraw3D.LineJoint.NONE,
  DebugDraw3D.LineJoint.ROUND,
  DebugDraw3D.LineJoint.BEVEL,
  DebugDraw3D.LineJoint.MITER,
]

var _dash_offset := 0.0
var _last_info_text := ""
var _base_curve: Curve3D
var _corner_curve: Curve3D
var _construction_curves: Array[Curve3D] = []
var _shape_curves: Array[Curve3D] = []
var _closed_curves: Array[Curve3D] = []

@onready var _free_camera: FreeCamera = $FreeCamera
@onready var _debug_draw: DebugDraw3D = $DebugDraw3D
@onready var _info_label: Label = $UI/InfoLabel


func _ready() -> void:
  _create_curves()
  _debug_draw.depth_bias = -0.001
  _debug_draw.line_width = CURVE_BASE_LINE_WIDTH
  _create_labels()
  _initialize_window_size()
  _update_info_label()


func _process(delta: float) -> void:
  _dash_offset = fposmod(_dash_offset + DASH_OFFSET_SPEED * delta, 10.0)
  _update_info_label()
  _draw_origin_axes()
  _draw_samples()


func _input(event: InputEvent) -> void:
  if event.is_action_pressed(&"ui_cancel") and _free_camera.is_freelook_active():
    _free_camera.set_freelook_active(false)


func _initialize_window_size() -> void:
  var dpi_scale := DisplayServer.screen_get_max_scale()
  get_window().size = Vector2i(roundi(DESIGN_WIDTH * dpi_scale), roundi(DESIGN_HEIGHT * dpi_scale))
  get_window().content_scale_size = Vector2i(DESIGN_WIDTH, DESIGN_HEIGHT)
  get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
  get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func _update_info_label() -> void:
  var text := _free_camera.get_info_text()
  if text == _last_info_text:
    return

  _info_label.text = text
  _last_info_text = text


func _draw_origin_axes() -> void:
  _debug_draw.draw_axes(Vector3.ZERO, Quaternion.IDENTITY, 0.75, 2.0)


func _draw_samples() -> void:
  _draw_construction_samples()
  _draw_width_samples(0)
  _draw_shape_samples(1)
  _draw_transform_samples(2)
  _draw_tolerance_samples(3)
  _draw_closed_samples(4)
  _draw_joint_samples(5)
  _draw_dash_samples(6)
  _draw_dash_joint_samples(7)


func _draw_construction_samples() -> void:
  for sample_index in _construction_curves.size():
    var curve := _construction_curves[sample_index]
    var curve_transform := _get_construction_transform(sample_index)
    _debug_draw.draw_curve(
      curve,
      curve_transform,
      Color(0.86, 0.94, 1.0, 1.0),
      CURVE_BASE_LINE_WIDTH,
      CURVE_MAX_STAGES,
      CURVE_TOLERANCE_LENGTH,
      DebugDraw3D.LineJoint.ROUND,
    )
    _draw_curve_control_points(curve, curve_transform)


func _draw_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _debug_draw.draw_curve(
      _base_curve,
      _get_sample_transform(column, row),
      Color.WHITE,
      WIDTH_VALUES[row],
      CURVE_MAX_STAGES,
      CURVE_TOLERANCE_LENGTH,
    )


func _draw_shape_samples(column: int) -> void:
  for row in _shape_curves.size():
    _debug_draw.draw_curve(
      _shape_curves[row],
      _get_sample_transform(column, row),
      Color(0.15, 0.85, 1.0, 0.95),
      CURVE_BASE_LINE_WIDTH,
      CURVE_MAX_STAGES,
      CURVE_TOLERANCE_LENGTH,
    )


func _draw_transform_samples(column: int) -> void:
  for row in ROTATION_SAMPLE_COUNT:
    _debug_draw.draw_curve(
      _base_curve,
      _get_sample_transform(column, row),
      Color(0.7, 1.0, 0.25, 1.0 - float(row) * 0.07),
      CURVE_BASE_LINE_WIDTH,
      CURVE_MAX_STAGES,
      CURVE_TOLERANCE_LENGTH,
    )


func _draw_tolerance_samples(column: int) -> void:
  for row in TOLERANCE_VALUES.size():
    _debug_draw.draw_curve(
      _base_curve,
      _get_sample_transform(column, row),
      Color(0.95, 0.75, 0.25, 1.0),
      CURVE_BASE_LINE_WIDTH,
      CURVE_MAX_STAGES,
      TOLERANCE_VALUES[row],
    )


func _draw_closed_samples(column: int) -> void:
  for row in _closed_curves.size():
    _debug_draw.draw_curve(
      _closed_curves[row],
      _get_sample_transform(column, row),
      Color(0.25, 0.95, 0.9, 1.0),
      CURVE_BASE_LINE_WIDTH,
      CURVE_MAX_STAGES,
      CURVE_TOLERANCE_LENGTH,
      DebugDraw3D.LineJoint.ROUND,
    )


func _draw_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_curve(
      _corner_curve,
      _get_sample_transform(column, row),
      Color(0.75, 0.45, 1.0, 1.0),
      CURVE_EMPHASIS_LINE_WIDTH,
      CURVE_MAX_STAGES,
      CURVE_JOINT_TOLERANCE_LENGTH,
      JOINT_VALUES[row],
    )


func _draw_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_curve_d(
      _base_curve,
      _get_sample_transform(column, row),
      Color(1.0, 0.45, 0.2, 1.0),
      CURVE_BASE_LINE_WIDTH,
      dash.x,
      dash.y,
      _get_dash_offset(dash),
      CURVE_MAX_STAGES,
      CURVE_TOLERANCE_LENGTH,
    )


func _draw_dash_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_curve_d(
      _corner_curve,
      _get_sample_transform(column, row),
      Color(1.0, 0.3, 0.6, 1.0),
      CURVE_EMPHASIS_LINE_WIDTH,
      0.18,
      0.1,
      fposmod(_dash_offset, 0.28),
      CURVE_MAX_STAGES,
      CURVE_JOINT_TOLERANCE_LENGTH,
      JOINT_VALUES[row],
    )


func _draw_curve_control_points(curve: Curve3D, curve_transform: Transform3D) -> void:
  var marker_rotation := _get_curve_marker_rotation(curve_transform)
  for point_index in curve.point_count:
    var anchor := curve.get_point_position(point_index)
    var anchor_world := curve_transform * anchor
    _draw_curve_control_handle(anchor, curve.get_point_in(point_index), curve_transform, marker_rotation)
    _draw_curve_control_handle(anchor, curve.get_point_out(point_index), curve_transform, marker_rotation)
    _debug_draw.draw_circle(
      anchor_world,
      marker_rotation,
      ANCHOR_POINT_RADIUS,
      Color(1.0, 0.25, 0.85, 1.0),
      CURVE_BASE_LINE_WIDTH,
      CONTROL_POINT_SEGMENT_COUNT,
      DebugDraw3D.LineJoint.ROUND,
    )


func _draw_curve_control_handle(
    anchor: Vector3,
    handle: Vector3,
    curve_transform: Transform3D,
    marker_rotation: Quaternion,
) -> void:
  if handle.is_zero_approx():
    return

  var anchor_world := curve_transform * anchor
  var handle_world := curve_transform * (anchor + handle)
  _debug_draw.draw_line(anchor_world, handle_world, Color(1.0, 0.75, 0.15, 0.85), CONTROL_POINT_EDGE_WIDTH)
  _debug_draw.draw_circle(
    handle_world,
    marker_rotation,
    CONTROL_POINT_RADIUS,
    Color(1.0, 0.75, 0.15, 1.0),
    CURVE_BASE_LINE_WIDTH,
    CONTROL_POINT_SEGMENT_COUNT,
    DebugDraw3D.LineJoint.ROUND,
  )


func _create_curves() -> void:
  _construction_curves.append(_create_straight_curve())
  _construction_curves.append(_create_smooth_symmetric_curve())
  _construction_curves.append(_create_flat_handle_curve())
  _construction_curves.append(_create_broken_corner_curve())
  _construction_curves.append(_create_one_sided_curve())
  _construction_curves.append(_create_y_curve())
  _construction_curves.append(_create_closed_curve(1.0))

  _base_curve = _create_smooth_symmetric_curve()
  _corner_curve = _create_corner_curve()

  for row in SHAPE_VALUES.size():
    var shape_scale: float = SHAPE_VALUES[row]
    _shape_curves.append(_create_smooth_symmetric_curve(shape_scale))

  _closed_curves.append(_create_smooth_symmetric_curve())
  _closed_curves.append(_create_closed_curve(1.0))
  _closed_curves.append(_create_closed_curve(0.75))
  _closed_curves.append(_create_closed_curve(1.25))


func _create_straight_curve() -> Curve3D:
  var curve := Curve3D.new()
  curve.add_point(Vector3(-0.5, 0.0, 0.18))
  curve.add_point(Vector3(0.0, 0.0, -0.18))
  curve.add_point(Vector3(0.5, 0.0, 0.18))
  return curve


func _create_smooth_symmetric_curve(shape_scale: float = 1.0) -> Curve3D:
  var curve := Curve3D.new()
  curve.add_point(Vector3(-0.55, 0.0, 0.2 * shape_scale), Vector3.ZERO, Vector3(0.28, 0.0, -0.35 * shape_scale))
  curve.add_point(
    Vector3(0.0, 0.0, -0.2 * shape_scale),
    Vector3(-0.28, 0.0, 0.35 * shape_scale),
    Vector3(0.28, 0.0, -0.35 * shape_scale),
  )
  curve.add_point(Vector3(0.55, 0.0, 0.2 * shape_scale), Vector3(-0.28, 0.0, 0.35 * shape_scale), Vector3.ZERO)
  return curve


func _create_flat_handle_curve() -> Curve3D:
  var curve := Curve3D.new()
  curve.add_point(Vector3(-0.55, 0.0, 0.0), Vector3.ZERO, Vector3(0.32, 0.0, 0.0))
  curve.add_point(Vector3(0.55, 0.0, 0.0), Vector3(-0.32, 0.0, 0.0), Vector3.ZERO)
  return curve


func _create_broken_corner_curve() -> Curve3D:
  var curve := Curve3D.new()
  curve.add_point(Vector3(-0.55, 0.0, 0.18), Vector3.ZERO, Vector3(0.28, 0.0, -0.08))
  curve.add_point(Vector3(0.0, 0.0, -0.24), Vector3(-0.18, 0.0, 0.34), Vector3(0.12, 0.0, 0.34))
  curve.add_point(Vector3(0.55, 0.0, 0.18), Vector3(-0.28, 0.0, -0.08), Vector3.ZERO)
  return curve


func _create_one_sided_curve() -> Curve3D:
  var curve := Curve3D.new()
  curve.add_point(Vector3(-0.55, 0.0, 0.18), Vector3.ZERO, Vector3(0.38, 0.0, -0.48))
  curve.add_point(Vector3(0.0, 0.0, -0.16))
  curve.add_point(Vector3(0.55, 0.0, 0.18), Vector3(-0.38, 0.0, -0.48), Vector3.ZERO)
  return curve


func _create_y_curve() -> Curve3D:
  var curve := Curve3D.new()
  curve.add_point(Vector3(-0.55, -0.18, 0.18), Vector3.ZERO, Vector3(0.28, 0.36, -0.34))
  curve.add_point(Vector3(0.0, 0.22, -0.18), Vector3(-0.28, -0.34, 0.34), Vector3(0.28, -0.34, -0.34))
  curve.add_point(Vector3(0.55, -0.18, 0.18), Vector3(-0.28, 0.36, 0.34), Vector3.ZERO)
  return curve


func _create_open_curve(shape_scale: float) -> Curve3D:
  var curve := Curve3D.new()
  curve.add_point(Vector3(-0.55, 0.0, 0.18 * shape_scale), Vector3.ZERO, Vector3(0.3, 0.0, -0.55 * shape_scale))
  curve.add_point(
    Vector3(-0.18, 0.0, -0.25 * shape_scale),
    Vector3(-0.32, 0.0, 0.42 * shape_scale),
    Vector3(0.32, 0.0, -0.22 * shape_scale),
  )
  curve.add_point(
    Vector3(0.2, 0.0, 0.28 * shape_scale),
    Vector3(-0.32, 0.0, -0.22 * shape_scale),
    Vector3(0.32, 0.0, 0.42 * shape_scale),
  )
  curve.add_point(Vector3(0.55, 0.0, -0.16 * shape_scale), Vector3(-0.3, 0.0, 0.45 * shape_scale), Vector3.ZERO)
  return curve


func _create_corner_curve() -> Curve3D:
  var curve := Curve3D.new()
  curve.add_point(Vector3(-0.55, 0.0, 0.24))
  curve.add_point(Vector3(-0.15, 0.0, -0.24))
  curve.add_point(Vector3(0.18, 0.0, 0.24))
  curve.add_point(Vector3(0.55, 0.0, -0.24))
  return curve


func _create_closed_curve(shape_scale: float) -> Curve3D:
  var curve := Curve3D.new()
  var x_radius := 0.45 * shape_scale
  var z_radius := 0.35 * shape_scale
  var x_handle := 0.28 * shape_scale
  var z_handle := 0.24 * shape_scale
  curve.closed = true
  curve.add_point(Vector3(-x_radius, 0.0, 0.0), Vector3(0.0, 0.0, z_handle), Vector3(0.0, 0.0, -z_handle))
  curve.add_point(Vector3(0.0, 0.0, -z_radius), Vector3(-x_handle, 0.0, 0.0), Vector3(x_handle, 0.0, 0.0))
  curve.add_point(Vector3(x_radius, 0.0, 0.0), Vector3(0.0, 0.0, -z_handle), Vector3(0.0, 0.0, z_handle))
  curve.add_point(Vector3(0.0, 0.0, z_radius), Vector3(x_handle, 0.0, 0.0), Vector3(-x_handle, 0.0, 0.0))
  return curve


func _create_labels() -> void:
  for sample_index in _get_construction_sample_count():
    _create_label(
      "ConstructionLabel%d" % sample_index,
      _get_construction_label(sample_index),
      Vector3(_get_construction_label_x(sample_index), LABEL_Y, CONSTRUCTION_TITLE_Z),
      TITLE_LABEL_FONT_SIZE,
      HORIZONTAL_ALIGNMENT_CENTER,
    )

  for column in _get_column_count():
    _create_label(
      "ColumnLabel%d" % column,
      _get_column_label(column),
      Vector3(_get_column_label_x(column), LABEL_Y, EXAMPLE_TITLE_Z),
      TITLE_LABEL_FONT_SIZE,
      HORIZONTAL_ALIGNMENT_CENTER,
    )

  for column in _get_column_count():
    for row in _get_column_sample_count(column):
      _create_label(
        "SampleLabel%d_%d" % [column, row],
        _get_sample_label(column, row),
        _get_sample_label_position(column, row),
        LABEL_FONT_SIZE,
        HORIZONTAL_ALIGNMENT_RIGHT,
      )


func _create_label(
    label_name: String,
    text: String,
    label_position: Vector3,
    font_size: int,
    horizontal_alignment: HorizontalAlignment,
) -> void:
  var label := Label3D.new()
  label.name = label_name
  label.text = text
  label.position = label_position
  label.rotation.x = -PI * 0.5
  label.font_size = font_size
  label.pixel_size = LABEL_PIXEL_SIZE
  label.fixed_size = false
  label.no_depth_test = false
  label.modulate = Color(0.86, 0.94, 1.0, 1.0)
  label.horizontal_alignment = horizontal_alignment
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  add_child(label)


func _get_construction_sample_count() -> int:
  return _construction_curves.size()


func _get_construction_label(sample_index: int) -> String:
  match sample_index:
    0:
      return "straight"
    1:
      return "smooth"
    2:
      return "flat handles"
    3:
      return "broken"
    4:
      return "one-sided"
    5:
      return "y curve"
    6:
      return "closed"
    _:
      return "curve"


func _get_column_count() -> int:
  return 8


func _get_column_sample_count(column: int) -> int:
  match column:
    0:
      return WIDTH_VALUES.size()
    1:
      return SHAPE_VALUES.size()
    2:
      return ROTATION_SAMPLE_COUNT
    3:
      return TOLERANCE_VALUES.size()
    4:
      return CLOSED_VALUES.size()
    5, 7:
      return JOINT_VALUES.size()
    6:
      return DASH_VALUES.size()
    _:
      return 0


func _get_column_label(column: int) -> String:
  match column:
    0:
      return "curve(width)"
    1:
      return "curve(shape)"
    2:
      return "curve(transform)"
    3:
      return "curve(tolerance)"
    4:
      return "curve(closed)"
    5:
      return "curve(joint)"
    6:
      return "curve_d(dash)"
    7:
      return "curve_d(joint)"
    _:
      return "curve"


func _get_sample_label(column: int, row: int) -> String:
  match column:
    0:
      return "w = %.1f" % WIDTH_VALUES[row]
    1:
      return _get_shape_label(row)
    2:
      return "step %d" % row
    3:
      return "tol = %.2f" % TOLERANCE_VALUES[row]
    4:
      return CLOSED_VALUES[row]
    5, 7:
      return _get_joint_label(JOINT_VALUES[row])
    6:
      var dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [dash.x, dash.y]
    _:
      return ""


func _get_shape_label(row: int) -> String:
  match row:
    0:
      return "mild"
    1:
      return "soft"
    2:
      return "base"
    3:
      return "wide"
    _:
      return "shape"


func _get_joint_label(joint: int) -> String:
  match joint:
    DebugDraw3D.LineJoint.ROUND:
      return "ROUND"
    DebugDraw3D.LineJoint.BEVEL:
      return "BEVEL"
    DebugDraw3D.LineJoint.MITER:
      return "MITER"
    _:
      return "NONE"


func _get_sample_label_position(column: int, row: int) -> Vector3:
  return Vector3(_get_curve_min_x(column, row) - SAMPLE_LABEL_GAP, LABEL_Y, _get_sample_label_z(column, row))


func _get_column_x(column: int) -> float:
  return float(column) * COLUMN_SPACING + 0.5


func _get_column_label_x(column: int) -> float:
  var min_x := INF
  var max_x := -INF
  for row in _get_column_sample_count(column):
    min_x = minf(min_x, _get_curve_min_x(column, row))
    max_x = maxf(max_x, _get_curve_max_x(column, row))
  return (min_x + max_x) * 0.5


func _get_construction_label_x(sample_index: int) -> float:
  var bounds := _get_curve_bounds_x(
    _construction_curves[sample_index],
    _get_construction_transform(sample_index),
    CURVE_TOLERANCE_LENGTH,
  )
  return (bounds.x + bounds.y) * 0.5


func _get_row_z(column: int, row: int) -> float:
  return EXAMPLE_START_Z - float(row) * _get_row_spacing(column)


func _get_row_spacing(column: int) -> float:
  if column == 2:
    return SAMPLE_SPACING * 0.85
  if column == 4:
    return SAMPLE_SPACING * 1.05
  return SAMPLE_SPACING


func _get_sample_label_z(column: int, row: int) -> float:
  if column == 2:
    return _get_rotation_tunnel_center(column, row).z
  return _get_row_z(column, row)


func _get_curve_center(column: int, row: int) -> Vector3:
  return Vector3(_get_column_x(column), CURVE_Y, _get_row_z(column, row))


func _get_construction_transform(sample_index: int) -> Transform3D:
  return Transform3D(Basis.IDENTITY, Vector3(_get_column_x(sample_index), CURVE_Y, CONSTRUCTION_SAMPLE_Z))


func _get_rotation_tunnel_center(column: int, row: int) -> Vector3:
  var center := _get_curve_center(column, row)
  center.y += 0.35
  center.z -= float(row) * ROTATION_TUNNEL_DEPTH_STEP
  return center


func _get_sample_transform(column: int, row: int) -> Transform3D:
  if column == 2:
    var tunnel_scale := 1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP
    return Transform3D(Basis(_get_rotation_tunnel_rotation(row)).scaled(Vector3.ONE * tunnel_scale), _get_rotation_tunnel_center(column, row))
  return Transform3D(Basis.IDENTITY, _get_curve_center(column, row))


func _get_curve_marker_rotation(curve_transform: Transform3D) -> Quaternion:
  var basis := curve_transform.basis
  return Basis(basis.x.normalized(), basis.z.normalized(), basis.y.normalized()).get_rotation_quaternion()


func _get_rotation_tunnel_rotation(row: int) -> Quaternion:
  var normal := Vector3.UP.rotated(Vector3.RIGHT, -PI * 0.38)
  normal = normal.rotated(Vector3.BACK, float(row) * ROTATION_TUNNEL_TWIST_STEP).normalized()
  return _get_curve_rotation(normal, float(row) * PI * 0.08)


func _get_curve_rotation(normal: Vector3, angle: float) -> Quaternion:
  var normalized_normal := normal.normalized()
  var reference := Vector3.RIGHT
  if absf(normalized_normal.dot(reference)) > 0.95:
    reference = Vector3.BACK

  var width_axis := (reference - normalized_normal * reference.dot(normalized_normal)).normalized()
  width_axis = width_axis.rotated(normalized_normal, angle).normalized()
  var depth_axis := width_axis.cross(normalized_normal).normalized()
  return Basis(width_axis, normalized_normal, depth_axis).get_rotation_quaternion()


func _get_sample_curve(column: int, row: int) -> Curve3D:
  match column:
    1:
      return _shape_curves[row]
    4:
      return _closed_curves[row]
    5, 7:
      return _corner_curve
    _:
      return _base_curve


func _get_sample_tolerance(column: int, row: int) -> float:
  if column == 3:
    return TOLERANCE_VALUES[row]
  if column == 5 or column == 7:
    return CURVE_JOINT_TOLERANCE_LENGTH
  return CURVE_TOLERANCE_LENGTH


func _get_curve_min_x(column: int, row: int) -> float:
  return _get_curve_x_bounds(column, row).x


func _get_curve_max_x(column: int, row: int) -> float:
  return _get_curve_x_bounds(column, row).y


func _get_curve_x_bounds(column: int, row: int) -> Vector2:
  return _get_curve_bounds_x(
    _get_sample_curve(column, row),
    _get_sample_transform(column, row),
    _get_sample_tolerance(column, row),
  )


func _get_curve_bounds_x(curve: Curve3D, curve_transform: Transform3D, tolerance_length: float) -> Vector2:
  var points := curve.tessellate_even_length(CURVE_MAX_STAGES, tolerance_length)
  if curve.closed and points.size() > 1 and points[0].is_equal_approx(points[points.size() - 1]):
    points.resize(points.size() - 1)

  var min_x := INF
  var max_x := -INF
  for point in points:
    var world_point := curve_transform * point
    min_x = minf(min_x, world_point.x)
    max_x = maxf(max_x, world_point.x)

  return Vector2(min_x, max_x)


func _get_dash_offset(dash: Vector2) -> float:
  return fposmod(_dash_offset, dash.x + dash.y)
