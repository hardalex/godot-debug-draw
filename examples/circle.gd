extends Node3D
## Circle example scene: curated debug circle parameter samples on the XZ plane.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const CIRCLE_Y := 0.1
const CIRCLE_RADIUS := 0.32
const CIRCLE_BASE_LINE_WIDTH := 2.0
const CIRCLE_EMPHASIS_LINE_WIDTH := 8.0
const CIRCLE_SEGMENT_COUNT := 64
const JOINT_SEGMENT_COUNT := 12
const SAMPLE_SPACING := 0.82
const RADIUS_SAMPLE_SPACING := 1.15
const SAMPLE_START_Z := -0.45
const COLUMN_SPACING := 2.0
const LABEL_Y := CIRCLE_Y + 0.01
const TITLE_Z := 0.35
const SAMPLE_LABEL_GAP := 0.12
const LABEL_FONT_SIZE := 20
const TITLE_LABEL_FONT_SIZE := 28
const LABEL_PIXEL_SIZE := 0.004
const DASH_OFFSET_SPEED := 0.6
const WIDTH_VALUES := [1.0, 2.0, 5.5, 10.0]
const RADIUS_VALUES := [0.18, 0.28, 0.38, 0.50]
const SEGMENT_VALUES := [8, 16, 32, 64]
const ROTATION_SAMPLE_COUNT := 8
const ROTATION_TUNNEL_RADIUS := 0.42
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
  _debug_draw.line_width = CIRCLE_BASE_LINE_WIDTH
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
  _draw_segment_samples(2)
  _draw_rotation_samples(3)
  _draw_joint_samples(4)
  _draw_dash_samples(5)
  _draw_dash_joint_samples(6)
  _draw_normal_samples(7)
  _draw_normal_dash_samples(8)
  _draw_normal_joint_samples(9)


func _draw_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _debug_draw.draw_circle(
      _get_circle_center(column, row),
      _get_flat_rotation(0.0),
      CIRCLE_RADIUS,
      Color.WHITE,
      WIDTH_VALUES[row],
      CIRCLE_SEGMENT_COUNT,
    )


func _draw_radius_samples(column: int) -> void:
  for row in RADIUS_VALUES.size():
    _debug_draw.draw_circle(
      _get_circle_center(column, row),
      _get_flat_rotation(0.0),
      RADIUS_VALUES[row],
      Color(0.15, 0.85, 1.0, 0.95),
      CIRCLE_BASE_LINE_WIDTH,
      CIRCLE_SEGMENT_COUNT,
    )


func _draw_segment_samples(column: int) -> void:
  for row in SEGMENT_VALUES.size():
    _debug_draw.draw_circle(
      _get_circle_center(column, row),
      _get_flat_rotation(0.0),
      CIRCLE_RADIUS,
      Color(0.7, 1.0, 0.25, 1.0),
      CIRCLE_BASE_LINE_WIDTH,
      SEGMENT_VALUES[row],
    )


func _draw_rotation_samples(column: int) -> void:
  for row in ROTATION_SAMPLE_COUNT:
    var tunnel_scale := 1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP
    _debug_draw.draw_circle(
      _get_rotation_tunnel_center(column, row),
      _get_rotation_tunnel_rotation(row),
      ROTATION_TUNNEL_RADIUS * tunnel_scale,
      Color(0.95, 0.75, 0.25, 1.0 - float(row) * 0.07),
      CIRCLE_BASE_LINE_WIDTH,
      CIRCLE_SEGMENT_COUNT,
    )


func _draw_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_circle(
      _get_circle_center(column, row),
      _get_flat_rotation(0.0),
      CIRCLE_RADIUS,
      Color(0.75, 0.45, 1.0, 1.0),
      CIRCLE_EMPHASIS_LINE_WIDTH,
      JOINT_SEGMENT_COUNT,
      JOINT_VALUES[row],
    )


func _draw_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_circle_d(
      _get_circle_center(column, row),
      _get_flat_rotation(0.0),
      CIRCLE_RADIUS,
      Color(1.0, 0.45, 0.2, 1.0),
      CIRCLE_BASE_LINE_WIDTH,
      dash.x,
      dash.y,
      _get_dash_offset(dash),
      CIRCLE_SEGMENT_COUNT,
    )


func _draw_dash_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_circle_d(
      _get_circle_center(column, row),
      _get_flat_rotation(0.0),
      CIRCLE_RADIUS,
      Color(1.0, 0.3, 0.6, 1.0),
      CIRCLE_EMPHASIS_LINE_WIDTH,
      0.18,
      0.1,
      fposmod(_dash_offset, 0.28),
      JOINT_SEGMENT_COUNT,
      JOINT_VALUES[row],
    )


func _draw_normal_samples(column: int) -> void:
  for row in NORMAL_SAMPLE_COUNT:
    _debug_draw.draw_circle_n(
      _get_circle_center(column, row),
      _get_flat_rotation(0.0),
      CIRCLE_RADIUS,
      _get_normal_sample_color(row),
      _get_normal_sample_width(row),
      CIRCLE_SEGMENT_COUNT,
      DebugDraw3D.LineJoint.ROUND,
    )


func _draw_normal_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_circle_n_d(
      _get_circle_center(column, row),
      _get_flat_rotation(0.0),
      CIRCLE_RADIUS,
      Color(0.25, 0.95, 0.9, 1.0),
      CIRCLE_BASE_LINE_WIDTH,
      dash.x,
      dash.y,
      _get_dash_offset(dash),
      CIRCLE_SEGMENT_COUNT,
      DebugDraw3D.LineJoint.ROUND,
    )


func _draw_normal_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_circle_n(
      _get_circle_center(column, row),
      _get_flat_rotation(0.0),
      CIRCLE_RADIUS,
      Color(0.25, 0.95, 0.9, 1.0),
      CIRCLE_EMPHASIS_LINE_WIDTH,
      JOINT_SEGMENT_COUNT,
      JOINT_VALUES[row],
    )


func _create_labels() -> void:
  for column in _get_column_count():
    _create_label(
      "ColumnLabel%d" % column,
      _get_column_label(column),
      Vector3(_get_column_x(column), LABEL_Y, TITLE_Z),
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
  return 10


func _get_column_sample_count(column: int) -> int:
  match column:
    0:
      return WIDTH_VALUES.size()
    1:
      return RADIUS_VALUES.size()
    2:
      return SEGMENT_VALUES.size()
    3:
      return ROTATION_SAMPLE_COUNT
    4:
      return JOINT_VALUES.size()
    5:
      return DASH_VALUES.size()
    6:
      return JOINT_VALUES.size()
    7:
      return NORMAL_SAMPLE_COUNT
    8:
      return DASH_VALUES.size()
    9:
      return JOINT_VALUES.size()
    _:
      return 0


func _get_column_label(column: int) -> String:
  match column:
    0:
      return "circle(width)"
    1:
      return "circle(radius)"
    2:
      return "circle(segments)"
    3:
      return "circle(rotation)"
    4:
      return "circle(joint)"
    5:
      return "circle_d(dash)"
    6:
      return "circle_d(joint)"
    7:
      return "circle_n"
    8:
      return "circle_n_d(dash)"
    9:
      return "circle_n(joint)"
    _:
      return "circle"


func _get_sample_label(column: int, row: int) -> String:
  match column:
    0:
      return "w = %.1f" % WIDTH_VALUES[row]
    1:
      return "r = %.2f" % RADIUS_VALUES[row]
    2:
      return "%d seg" % SEGMENT_VALUES[row]
    3:
      return _get_rotation_label(row)
    4:
      return _get_joint_label(JOINT_VALUES[row])
    5:
      var dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [dash.x, dash.y]
    6:
      return _get_joint_label(JOINT_VALUES[row])
    7:
      return _get_normal_label(row)
    8:
      var normal_dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [normal_dash.x, normal_dash.y]
    9:
      return _get_joint_label(JOINT_VALUES[row])
    _:
      return ""


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


func _get_sample_label_position(column: int, row: int) -> Vector3:
  return Vector3(_get_sample_label_x(column), LABEL_Y, _get_sample_label_z(column, row))


func _get_sample_label_x(column: int) -> float:
  return _get_column_x(column) - _get_column_max_radius(column) - SAMPLE_LABEL_GAP


func _get_sample_label_z(column: int, row: int) -> float:
  if column == 3:
    return _get_rotation_tunnel_center(column, row).z
  return _get_sample_z(column, row)


func _get_column_max_radius(column: int) -> float:
  if column == 1:
    var max_radius := 0.0
    for radius: float in RADIUS_VALUES:
      max_radius = maxf(max_radius, radius)
    return max_radius

  if column == 3:
    return ROTATION_TUNNEL_RADIUS

  return CIRCLE_RADIUS


func _get_row_z(row: int) -> float:
  return SAMPLE_START_Z - float(row) * SAMPLE_SPACING


func _get_sample_z(column: int, row: int) -> float:
  if column == 1:
    return SAMPLE_START_Z - float(row) * RADIUS_SAMPLE_SPACING
  return _get_row_z(row)


func _get_circle_center(column: int, row: int) -> Vector3:
  return Vector3(_get_column_x(column), CIRCLE_Y, _get_sample_z(column, row))


func _get_rotation_tunnel_center(column: int, row: int) -> Vector3:
  var center := _get_circle_center(column, row)
  center.y += 0.35
  center.z -= float(row) * ROTATION_TUNNEL_DEPTH_STEP
  return center


func _get_flat_rotation(angle: float) -> Quaternion:
  return _get_circle_rotation(Vector3.UP, angle)


func _get_rotation_tunnel_rotation(row: int) -> Quaternion:
  var normal := Vector3.UP.rotated(Vector3.RIGHT, -PI * 0.38)
  normal = normal.rotated(Vector3.BACK, float(row) * ROTATION_TUNNEL_TWIST_STEP).normalized()
  return _get_circle_rotation(normal, float(row) * PI * 0.08)


func _get_circle_rotation(normal: Vector3, angle: float) -> Quaternion:
  var normalized_normal := normal.normalized()
  var reference := Vector3.RIGHT
  if absf(normalized_normal.dot(reference)) > 0.95:
    reference = Vector3.BACK

  var width_axis := (reference - normalized_normal * reference.dot(normalized_normal)).normalized()
  width_axis = width_axis.rotated(normalized_normal, angle).normalized()
  var height_axis := normalized_normal.cross(width_axis).normalized()
  return Basis(width_axis, height_axis, normalized_normal).get_rotation_quaternion()


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
  return CIRCLE_BASE_LINE_WIDTH
