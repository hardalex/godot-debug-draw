extends Node3D
## Arc example scene: curated debug arc parameter samples on the XZ plane.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const ARC_Y := 0.1
const ARC_RADIUS := 0.34
const ARC_ANGLE := PI * 1.5
const ARC_BASE_LINE_WIDTH := 2.0
const ARC_EMPHASIS_LINE_WIDTH := 8.0
const ARC_SEGMENT_COUNT := 64
const ARC_JOINT_SEGMENT_COUNT := 12
const SAMPLE_SPACING := 0.92
const RADIUS_SAMPLE_SPACING := 1.15
const ANGLE_SAMPLE_SPACING := 1.08
const SAMPLE_START_Z := -0.45
const COLUMN_SPACING := 2.0
const LABEL_Y := ARC_Y + 0.01
const TITLE_Z := 0.35
const SAMPLE_LABEL_GAP := 0.12
const LABEL_FONT_SIZE := 20
const TITLE_LABEL_FONT_SIZE := 28
const LABEL_PIXEL_SIZE := 0.004
const DASH_OFFSET_SPEED := 0.6
const WIDTH_VALUES := [1.0, 2.0, 5.5, 10.0]
const RADIUS_VALUES := [0.18, 0.28, 0.38, 0.50]
const ANGLE_VALUES := [PI * 0.5, PI, PI * 1.5, TAU]
const SEGMENT_VALUES := [8, 16, 32, 64]
const ROTATION_SAMPLE_COUNT := 8
const ROTATION_TUNNEL_RADIUS := 0.44
const ROTATION_TUNNEL_DEPTH_STEP := 0.16
const ROTATION_TUNNEL_SCALE_STEP := 0.06
const ROTATION_TUNNEL_TWIST_STEP := PI * 0.12
const DASH_VALUES := [Vector2(0.1, 0.1), Vector2(0.2, 0.1), Vector2(0.4, 0.15), Vector2(0.04, 0.12)]
const JOINT_VALUES := [
  DebugDraw3D.LineJoint.NONE,
  DebugDraw3D.LineJoint.ROUND,
  DebugDraw3D.LineJoint.BEVEL,
  DebugDraw3D.LineJoint.MITER,
]
const NORMAL_SAMPLE_COUNT := 4

var _dash_offset := 0.0
var _last_info_text := ""

@onready var _free_camera: FreeCamera = $FreeCamera
@onready var _debug_draw: DebugDraw3D = $DebugDraw3D
@onready var _info_label: Label = $UI/InfoLabel


func _ready() -> void:
  _debug_draw.depth_bias = -0.001
  _debug_draw.line_width = ARC_BASE_LINE_WIDTH
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
  _draw_width_samples(0)
  _draw_radius_samples(1)
  _draw_angle_samples(2)
  _draw_segment_samples(3)
  _draw_rotation_samples(4)
  _draw_joint_samples(5)
  _draw_dash_samples(6)
  _draw_dash_joint_samples(7)
  _draw_normal_samples(8)
  _draw_normal_dash_samples(9)
  _draw_normal_joint_samples(10)


func _draw_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _debug_draw.draw_arc(
      _get_arc_center(column, row),
      _get_flat_rotation(0.0),
      ARC_RADIUS,
      ARC_ANGLE,
      Color.WHITE,
      WIDTH_VALUES[row],
      ARC_SEGMENT_COUNT,
    )


func _draw_radius_samples(column: int) -> void:
  for row in RADIUS_VALUES.size():
    _debug_draw.draw_arc(
      _get_arc_center(column, row),
      _get_flat_rotation(0.0),
      RADIUS_VALUES[row],
      ARC_ANGLE,
      Color(0.15, 0.85, 1.0, 0.95),
      ARC_BASE_LINE_WIDTH,
      ARC_SEGMENT_COUNT,
    )


func _draw_angle_samples(column: int) -> void:
  for row in ANGLE_VALUES.size():
    _debug_draw.draw_arc(
      _get_arc_center(column, row),
      _get_flat_rotation(0.0),
      ARC_RADIUS,
      ANGLE_VALUES[row],
      Color(0.7, 1.0, 0.25, 1.0),
      ARC_BASE_LINE_WIDTH,
      ARC_SEGMENT_COUNT,
    )


func _draw_segment_samples(column: int) -> void:
  for row in SEGMENT_VALUES.size():
    _debug_draw.draw_arc(
      _get_arc_center(column, row),
      _get_flat_rotation(0.0),
      ARC_RADIUS,
      ARC_ANGLE,
      Color(0.95, 0.75, 0.25, 1.0),
      ARC_BASE_LINE_WIDTH,
      SEGMENT_VALUES[row],
    )


func _draw_rotation_samples(column: int) -> void:
  for row in ROTATION_SAMPLE_COUNT:
    var tunnel_scale := 1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP
    _debug_draw.draw_arc(
      _get_rotation_tunnel_center(column, row),
      _get_rotation_tunnel_rotation(row),
      ROTATION_TUNNEL_RADIUS * tunnel_scale,
      ARC_ANGLE,
      Color(0.95, 0.75, 0.25, 1.0 - float(row) * 0.07),
      ARC_BASE_LINE_WIDTH,
      ARC_SEGMENT_COUNT,
    )


func _draw_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_arc(
      _get_arc_center(column, row),
      _get_flat_rotation(0.0),
      ARC_RADIUS,
      ARC_ANGLE,
      Color(0.75, 0.45, 1.0, 1.0),
      ARC_EMPHASIS_LINE_WIDTH,
      ARC_JOINT_SEGMENT_COUNT,
      JOINT_VALUES[row],
    )


func _draw_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_arc_d(
      _get_arc_center(column, row),
      _get_flat_rotation(0.0),
      ARC_RADIUS,
      ARC_ANGLE,
      Color(1.0, 0.45, 0.2, 1.0),
      ARC_BASE_LINE_WIDTH,
      dash.x,
      dash.y,
      _get_dash_offset(dash),
      ARC_SEGMENT_COUNT,
    )


func _draw_dash_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_arc_d(
      _get_arc_center(column, row),
      _get_flat_rotation(0.0),
      ARC_RADIUS,
      ARC_ANGLE,
      Color(1.0, 0.3, 0.6, 1.0),
      ARC_EMPHASIS_LINE_WIDTH,
      0.18,
      0.1,
      fposmod(_dash_offset, 0.28),
      ARC_JOINT_SEGMENT_COUNT,
      JOINT_VALUES[row],
    )


func _draw_normal_samples(column: int) -> void:
  for row in NORMAL_SAMPLE_COUNT:
    _debug_draw.draw_arc_n(
      _get_arc_center(column, row),
      _get_flat_rotation(0.0),
      ARC_RADIUS,
      ARC_ANGLE,
      _get_normal_sample_color(row),
      _get_normal_sample_width(row),
      ARC_SEGMENT_COUNT,
      DebugDraw3D.LineJoint.ROUND,
    )


func _draw_normal_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_arc_n_d(
      _get_arc_center(column, row),
      _get_flat_rotation(0.0),
      ARC_RADIUS,
      ARC_ANGLE,
      Color(0.25, 0.95, 0.9, 1.0),
      ARC_BASE_LINE_WIDTH,
      dash.x,
      dash.y,
      _get_dash_offset(dash),
      ARC_SEGMENT_COUNT,
      DebugDraw3D.LineJoint.ROUND,
    )


func _draw_normal_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_arc_n(
      _get_arc_center(column, row),
      _get_flat_rotation(0.0),
      ARC_RADIUS,
      ARC_ANGLE,
      Color(0.25, 0.95, 0.9, 1.0),
      ARC_EMPHASIS_LINE_WIDTH,
      ARC_JOINT_SEGMENT_COUNT,
      JOINT_VALUES[row],
    )


func _create_labels() -> void:
  for column in _get_column_count():
    _create_label(
      "ColumnLabel%d" % column,
      _get_column_label(column),
      Vector3(_get_column_label_x(column), LABEL_Y, TITLE_Z),
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


func _get_column_count() -> int:
  return 11


func _get_column_sample_count(column: int) -> int:
  match column:
    0:
      return WIDTH_VALUES.size()
    1:
      return RADIUS_VALUES.size()
    2:
      return ANGLE_VALUES.size()
    3:
      return SEGMENT_VALUES.size()
    4:
      return ROTATION_SAMPLE_COUNT
    5:
      return JOINT_VALUES.size()
    6:
      return DASH_VALUES.size()
    7:
      return JOINT_VALUES.size()
    8:
      return NORMAL_SAMPLE_COUNT
    9:
      return DASH_VALUES.size()
    10:
      return JOINT_VALUES.size()
    _:
      return 0


func _get_column_label(column: int) -> String:
  match column:
    0:
      return "arc(width)"
    1:
      return "arc(radius)"
    2:
      return "arc(angle)"
    3:
      return "arc(segments)"
    4:
      return "arc(rotation)"
    5:
      return "arc(joint)"
    6:
      return "arc_d(dash)"
    7:
      return "arc_d(joint)"
    8:
      return "arc_n"
    9:
      return "arc_n_d(dash)"
    10:
      return "arc_n(joint)"
    _:
      return "arc"


func _get_sample_label(column: int, row: int) -> String:
  match column:
    0:
      return "w = %.1f" % WIDTH_VALUES[row]
    1:
      return "r = %.2f" % RADIUS_VALUES[row]
    2:
      return _get_angle_label(ANGLE_VALUES[row])
    3:
      return "%d seg" % SEGMENT_VALUES[row]
    4:
      return _get_rotation_label(row)
    5:
      return _get_joint_label(JOINT_VALUES[row])
    6:
      var dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [dash.x, dash.y]
    7:
      return _get_joint_label(JOINT_VALUES[row])
    8:
      return _get_normal_label(row)
    9:
      var normal_dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [normal_dash.x, normal_dash.y]
    10:
      return _get_joint_label(JOINT_VALUES[row])
    _:
      return ""


func _get_angle_label(angle: float) -> String:
  return "%d deg" % roundi(rad_to_deg(angle))


func _get_rotation_label(row: int) -> String:
  return "step %d" % row


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


func _get_normal_label(row: int) -> String:
  match row:
    0:
      return "base"
    1:
      return "alpha"
    2:
      return "color"
    3:
      return "wide"
    _:
      return "normal"


func _get_column_x(column: int) -> float:
  return float(column) * COLUMN_SPACING + 0.5


func _get_column_label_x(column: int) -> float:
  var min_x := INF
  var max_x := -INF
  for row in _get_column_sample_count(column):
    min_x = minf(min_x, _get_arc_min_x(column, row))
    max_x = maxf(max_x, _get_arc_max_x(column, row))
  return (min_x + max_x) * 0.5


func _get_sample_label_position(column: int, row: int) -> Vector3:
  return Vector3(_get_sample_label_x(column, row), LABEL_Y, _get_sample_label_z(column, row))


func _get_sample_label_x(column: int, row: int) -> float:
  return _get_arc_min_x(column, row) - SAMPLE_LABEL_GAP


func _get_sample_label_z(column: int, row: int) -> float:
  if column == 4:
    return _get_rotation_tunnel_center(column, row).z
  return _get_sample_z(column, row)


func _get_row_z(row: int) -> float:
  return SAMPLE_START_Z - float(row) * SAMPLE_SPACING


func _get_sample_z(column: int, row: int) -> float:
  if column == 1:
    return SAMPLE_START_Z - float(row) * RADIUS_SAMPLE_SPACING
  if column == 2:
    return SAMPLE_START_Z - float(row) * ANGLE_SAMPLE_SPACING
  return _get_row_z(row)


func _get_arc_center(column: int, row: int) -> Vector3:
  return Vector3(_get_column_x(column), ARC_Y, _get_sample_z(column, row))


func _get_rotation_tunnel_center(column: int, row: int) -> Vector3:
  var center := _get_arc_center(column, row)
  center.y += 0.35
  center.z -= float(row) * ROTATION_TUNNEL_DEPTH_STEP
  return center


func _get_flat_rotation(angle: float) -> Quaternion:
  return _get_arc_rotation(Vector3.UP, angle)


func _get_rotation_tunnel_rotation(row: int) -> Quaternion:
  var normal := Vector3.UP.rotated(Vector3.RIGHT, -PI * 0.38)
  normal = normal.rotated(Vector3.BACK, float(row) * ROTATION_TUNNEL_TWIST_STEP).normalized()
  return _get_arc_rotation(normal, float(row) * PI * 0.08)


func _get_arc_rotation(normal: Vector3, angle: float) -> Quaternion:
  var normalized_normal := normal.normalized()
  var reference := Vector3.RIGHT
  if absf(normalized_normal.dot(reference)) > 0.95:
    reference = Vector3.BACK

  var width_axis := (reference - normalized_normal * reference.dot(normalized_normal)).normalized()
  width_axis = width_axis.rotated(normalized_normal, angle).normalized()
  var height_axis := normalized_normal.cross(width_axis).normalized()
  return Basis(width_axis, height_axis, normalized_normal).get_rotation_quaternion()


func _get_column_radius(column: int, row: int) -> float:
  if column == 1:
    return RADIUS_VALUES[row]
  if column == 4:
    return ROTATION_TUNNEL_RADIUS * (1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP)
  return ARC_RADIUS


func _get_column_angle(column: int, row: int) -> float:
  if column == 2:
    return ANGLE_VALUES[row]
  return ARC_ANGLE


func _get_column_rotation(column: int, row: int) -> Quaternion:
  if column == 4:
    return _get_rotation_tunnel_rotation(row)
  return _get_flat_rotation(0.0)


func _get_column_center(column: int, row: int) -> Vector3:
  if column == 4:
    return _get_rotation_tunnel_center(column, row)
  return _get_arc_center(column, row)


func _get_column_segment_count(column: int, row: int) -> int:
  if column == 3:
    return SEGMENT_VALUES[row]
  if column == 5 or column == 7 or column == 10:
    return ARC_JOINT_SEGMENT_COUNT
  return ARC_SEGMENT_COUNT


func _get_arc_min_x(column: int, row: int) -> float:
  return _get_arc_x_bounds(column, row).x


func _get_arc_max_x(column: int, row: int) -> float:
  return _get_arc_x_bounds(column, row).y


func _get_arc_x_bounds(column: int, row: int) -> Vector2:
  var center := _get_column_center(column, row)
  var basis := Basis(_get_column_rotation(column, row).normalized())
  var radius := _get_column_radius(column, row)
  var angle := _get_column_angle(column, row)
  var steps := maxi(8, _get_column_segment_count(column, row))
  var min_x := INF
  var max_x := -INF

  for i in steps + 1:
    var arc_angle := angle * float(i) / float(steps)
    var point := center + (basis.x * cos(arc_angle) + basis.y * sin(arc_angle)) * radius
    min_x = minf(min_x, point.x)
    max_x = maxf(max_x, point.x)

  return Vector2(min_x, max_x)


func _get_dash_offset(dash: Vector2) -> float:
  return fposmod(_dash_offset, dash.x + dash.y)


func _get_normal_sample_color(row: int) -> Color:
  if row == 1:
    return Color(0.25, 0.95, 0.9, 0.35)
  if row == 2:
    return Color(1.0, 0.45, 0.2, 1.0)
  return Color(0.25, 0.95, 0.9, 1.0)


func _get_normal_sample_width(row: int) -> float:
  if row == 3:
    return 10.0
  return ARC_BASE_LINE_WIDTH
