extends Node3D
## Arrow example scene: curated debug arrow parameter samples on the XZ plane.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const ARROW_Y := 0.1
const ARROW_LENGTH := 1.1
const ARROW_BASE_WIDTH := 2.0
const ARROW_JOINT_WIDTH := 8.0
const ARROW_HEAD_LENGTH := 0.22
const ARROW_JOINT_HEAD_LENGTH := 0.34
const ARROW_BASE_HEAD_ANGLE := PI / 6.0
const ARROW_JOINT_HEAD_ANGLE := PI / 4.0
const SAMPLE_SPACING := 0.78
const SAMPLE_START_Z := -0.45
const COLUMN_SPACING := 2.0
const LABEL_Y := ARROW_Y + 0.01
const TITLE_Z := 0.35
const SAMPLE_LABEL_GAP := 0.12
const LABEL_FONT_SIZE := 20
const TITLE_LABEL_FONT_SIZE := 28
const LABEL_PIXEL_SIZE := 0.004
const DASH_OFFSET_SPEED := 0.6
const NORMAL := Vector3(0.0, 0.0, 1.0)
const WIDTH_VALUES := [1.0, 2.0, 5.5, 10.0]
const DIR_ANGLE_VALUES := [-PI * 0.35, -PI * 0.12, PI * 0.12, PI * 0.35]
const HEAD_LENGTH_VALUES := [0.12, 0.22, 0.34, 0.46]
const HEAD_ANGLE_VALUES := [PI / 9.0, PI / 6.0, PI / 4.0, PI * 0.42]
const ROTATION_SAMPLE_COUNT := 8
const ROTATION_TUNNEL_DEPTH_STEP := 0.16
const ROTATION_TUNNEL_SCALE_STEP := 0.05
const ROTATION_TUNNEL_Y := 0.32
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
  _debug_draw.line_width = ARROW_BASE_WIDTH
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
  _draw_arrow_width_samples(0)
  _draw_arrow_dir_samples(1)
  _draw_arrow_head_angle_samples(2)
  _draw_arrow_joint_samples(3)
  _draw_normal_arrow_samples(4)
  _draw_normal_arrow_joint_samples(5)
  _draw_line_width_samples(6)
  _draw_line_head_length_samples(7)
  _draw_line_head_angle_samples(8)
  _draw_line_rotation_samples(9)
  _draw_line_joint_samples(10)
  _draw_line_dash_samples(11)
  _draw_line_dash_joint_samples(12)
  _draw_normal_line_samples(13)
  _draw_normal_line_joint_samples(14)
  _draw_normal_line_dash_samples(15)
  _draw_normal_line_dash_joint_samples(16)


func _draw_arrow_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _debug_draw.draw_arrow(
      _get_arrow_tip(column, row),
      Vector3.RIGHT * ARROW_HEAD_LENGTH,
      Color.WHITE,
      WIDTH_VALUES[row],
      ARROW_BASE_HEAD_ANGLE,
    )


func _draw_arrow_dir_samples(column: int) -> void:
  for row in DIR_ANGLE_VALUES.size():
    _debug_draw.draw_arrow(
      _get_arrow_tip(column, row),
      _get_arrow_dir(row),
      Color(0.15, 0.85, 1.0, 0.95),
      ARROW_BASE_WIDTH,
      ARROW_BASE_HEAD_ANGLE,
    )


func _draw_arrow_head_angle_samples(column: int) -> void:
  for row in HEAD_ANGLE_VALUES.size():
    _debug_draw.draw_arrow(
      _get_arrow_tip(column, row),
      Vector3.RIGHT * ARROW_HEAD_LENGTH,
      Color(0.7, 1.0, 0.25, 1.0),
      ARROW_BASE_WIDTH,
      HEAD_ANGLE_VALUES[row],
    )


func _draw_arrow_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_arrow(
      _get_arrow_tip(column, row),
      Vector3.RIGHT * ARROW_JOINT_HEAD_LENGTH,
      Color(0.75, 0.45, 1.0, 1.0),
      ARROW_JOINT_WIDTH,
      ARROW_JOINT_HEAD_ANGLE,
      JOINT_VALUES[row],
    )


func _draw_normal_arrow_samples(column: int) -> void:
  for row in NORMAL_SAMPLE_COUNT:
    _debug_draw.draw_arrow_n(
      _get_arrow_tip(column, row),
      Vector3.RIGHT * ARROW_HEAD_LENGTH,
      NORMAL,
      _get_normal_sample_color(row),
      _get_normal_sample_width(row),
      ARROW_BASE_HEAD_ANGLE,
    )


func _draw_normal_arrow_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_arrow_n(
      _get_arrow_tip(column, row),
      Vector3.RIGHT * ARROW_JOINT_HEAD_LENGTH,
      NORMAL,
      Color(0.25, 0.95, 0.9, 1.0),
      ARROW_JOINT_WIDTH,
      ARROW_JOINT_HEAD_ANGLE,
      JOINT_VALUES[row],
    )


func _draw_line_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _debug_draw.draw_arrow_line(
      _get_line_start(column, row),
      _get_line_end(column, row),
      Color.WHITE,
      WIDTH_VALUES[row],
      ARROW_HEAD_LENGTH,
      ARROW_BASE_HEAD_ANGLE,
    )


func _draw_line_head_length_samples(column: int) -> void:
  for row in HEAD_LENGTH_VALUES.size():
    _debug_draw.draw_arrow_line(
      _get_line_start(column, row),
      _get_line_end(column, row),
      Color(0.95, 0.75, 0.25, 1.0),
      ARROW_BASE_WIDTH,
      HEAD_LENGTH_VALUES[row],
      ARROW_BASE_HEAD_ANGLE,
    )


func _draw_line_head_angle_samples(column: int) -> void:
  for row in HEAD_ANGLE_VALUES.size():
    _debug_draw.draw_arrow_line(
      _get_line_start(column, row),
      _get_line_end(column, row),
      Color(0.75, 0.45, 1.0, 1.0),
      ARROW_BASE_WIDTH,
      ARROW_HEAD_LENGTH,
      HEAD_ANGLE_VALUES[row],
    )


func _draw_line_rotation_samples(column: int) -> void:
  for row in ROTATION_SAMPLE_COUNT:
    _debug_draw.draw_arrow_line(
      _get_line_start(column, row),
      _get_line_end(column, row),
      Color(0.95, 0.75, 0.25, 1.0 - float(row) * 0.07),
      ARROW_BASE_WIDTH,
      ARROW_HEAD_LENGTH,
      ARROW_BASE_HEAD_ANGLE,
    )


func _draw_line_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_arrow_line(
      _get_line_start(column, row),
      _get_line_end(column, row),
      Color(0.75, 0.45, 1.0, 1.0),
      ARROW_JOINT_WIDTH,
      ARROW_JOINT_HEAD_LENGTH,
      ARROW_JOINT_HEAD_ANGLE,
      JOINT_VALUES[row],
    )


func _draw_line_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_arrow_line_d(
      _get_line_start(column, row),
      _get_line_end(column, row),
      Color(1.0, 0.45, 0.2, 1.0),
      ARROW_BASE_WIDTH,
      ARROW_HEAD_LENGTH,
      ARROW_BASE_HEAD_ANGLE,
      dash.x,
      dash.y,
      _get_dash_offset(dash),
    )


func _draw_line_dash_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_arrow_line_d(
      _get_line_start(column, row),
      _get_line_end(column, row),
      Color(1.0, 0.3, 0.6, 1.0),
      ARROW_JOINT_WIDTH,
      ARROW_JOINT_HEAD_LENGTH,
      ARROW_JOINT_HEAD_ANGLE,
      0.18,
      0.1,
      fposmod(_dash_offset, 0.28),
      JOINT_VALUES[row],
    )


func _draw_normal_line_samples(column: int) -> void:
  for row in NORMAL_SAMPLE_COUNT:
    _debug_draw.draw_arrow_line_n(
      _get_line_start(column, row),
      _get_line_end(column, row),
      NORMAL,
      _get_normal_sample_color(row),
      _get_normal_sample_width(row),
      ARROW_HEAD_LENGTH,
      ARROW_BASE_HEAD_ANGLE,
    )


func _draw_normal_line_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_arrow_line_n(
      _get_line_start(column, row),
      _get_line_end(column, row),
      NORMAL,
      Color(0.25, 0.95, 0.9, 1.0),
      ARROW_JOINT_WIDTH,
      ARROW_JOINT_HEAD_LENGTH,
      ARROW_JOINT_HEAD_ANGLE,
      JOINT_VALUES[row],
    )


func _draw_normal_line_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_arrow_line_n_d(
      _get_line_start(column, row),
      _get_line_end(column, row),
      NORMAL,
      Color(0.25, 0.95, 0.9, 1.0),
      ARROW_BASE_WIDTH,
      ARROW_HEAD_LENGTH,
      ARROW_BASE_HEAD_ANGLE,
      dash.x,
      dash.y,
      _get_dash_offset(dash),
    )


func _draw_normal_line_dash_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_arrow_line_n_d(
      _get_line_start(column, row),
      _get_line_end(column, row),
      NORMAL,
      Color(0.25, 0.95, 0.9, 1.0),
      ARROW_JOINT_WIDTH,
      ARROW_JOINT_HEAD_LENGTH,
      ARROW_JOINT_HEAD_ANGLE,
      0.18,
      0.1,
      fposmod(_dash_offset, 0.28),
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
  return 17


func _get_column_sample_count(column: int) -> int:
  match column:
    0, 6:
      return WIDTH_VALUES.size()
    1:
      return DIR_ANGLE_VALUES.size()
    2, 8:
      return HEAD_ANGLE_VALUES.size()
    3, 5, 10, 12, 14, 16:
      return JOINT_VALUES.size()
    4, 13:
      return NORMAL_SAMPLE_COUNT
    7:
      return HEAD_LENGTH_VALUES.size()
    9:
      return ROTATION_SAMPLE_COUNT
    11, 15:
      return DASH_VALUES.size()
    _:
      return 0


func _get_column_label(column: int) -> String:
  match column:
    0:
      return "arrow(width)"
    1:
      return "arrow(dir)"
    2:
      return "arrow(head angle)"
    3:
      return "arrow(joint)"
    4:
      return "arrow_n"
    5:
      return "arrow_n(joint)"
    6:
      return "arrow_line(width)"
    7:
      return "arrow_line(head length)"
    8:
      return "arrow_line(head angle)"
    9:
      return "arrow_line(rotation)"
    10:
      return "arrow_line(joint)"
    11:
      return "arrow_line_d(dash)"
    12:
      return "arrow_line_d(joint)"
    13:
      return "arrow_line_n"
    14:
      return "arrow_line_n(joint)"
    15:
      return "arrow_line_n_d(dash)"
    16:
      return "arrow_line_n_d(joint)"
    _:
      return "arrow"


func _get_sample_label(column: int, row: int) -> String:
  match column:
    0, 6:
      return "w = %.1f" % WIDTH_VALUES[row]
    1:
      return _get_angle_label(DIR_ANGLE_VALUES[row])
    2, 8:
      return _get_angle_label(HEAD_ANGLE_VALUES[row])
    3, 5, 10, 12, 14, 16:
      return _get_joint_label(JOINT_VALUES[row])
    4, 13:
      return _get_normal_label(row)
    7:
      return "head = %.2f" % HEAD_LENGTH_VALUES[row]
    9:
      return _get_rotation_label(row)
    11:
      var dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [dash.x, dash.y]
    15:
      var normal_dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [normal_dash.x, normal_dash.y]
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
    var bounds := _get_sample_x_bounds(column, row)
    min_x = minf(min_x, bounds.x)
    max_x = maxf(max_x, bounds.y)
  return (min_x + max_x) * 0.5


func _get_sample_label_position(column: int, row: int) -> Vector3:
  return Vector3(_get_sample_x_bounds(column, row).x - SAMPLE_LABEL_GAP, LABEL_Y, _get_label_z(column, row))


func _get_label_z(column: int, row: int) -> float:
  if column == 9:
    return _get_line_start(column, row).z
  return _get_row_z(row)


func _get_row_z(row: int) -> float:
  return SAMPLE_START_Z - float(row) * SAMPLE_SPACING


func _get_arrow_tip(column: int, row: int) -> Vector3:
  return Vector3(_get_column_x(column) + _get_arrow_tip_offset_x(column), ARROW_Y, _get_row_z(row))


func _get_arrow_tip_offset_x(column: int) -> float:
  return ARROW_LENGTH if column == 1 else ARROW_LENGTH * 0.5


func _get_line_start(column: int, row: int) -> Vector3:
  var start := Vector3(_get_column_x(column), ARROW_Y, _get_row_z(row))
  if column == 9:
    start.y += ROTATION_TUNNEL_Y
    start.z -= float(row) * ROTATION_TUNNEL_DEPTH_STEP
  return start


func _get_line_end(column: int, row: int) -> Vector3:
  if column == 9:
    return _get_line_start(column, row) + _get_rotation_vector(row)
  return _get_line_start(column, row) + Vector3.RIGHT * ARROW_LENGTH


func _get_rotation_vector(row: int) -> Vector3:
  var tunnel_scale := 1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP
  var vector := Vector3.RIGHT * ARROW_LENGTH * tunnel_scale
  vector = vector.rotated(Vector3.UP, float(row) * PI * 0.08)
  vector = vector.rotated(Vector3.BACK, -PI * 0.18 + float(row) * PI * 0.08)
  return vector


func _get_arrow_dir(row: int) -> Vector3:
  return Vector3.RIGHT.rotated(Vector3.BACK, DIR_ANGLE_VALUES[row]) * ARROW_HEAD_LENGTH


func _get_column_dir_length(column: int) -> float:
  if column == 3 or column == 5:
    return ARROW_JOINT_HEAD_LENGTH
  return ARROW_HEAD_LENGTH


func _get_column_head_length(column: int, row: int) -> float:
  if column == 7:
    return HEAD_LENGTH_VALUES[row]
  if column == 10 or column == 12 or column == 14 or column == 16:
    return ARROW_JOINT_HEAD_LENGTH
  return ARROW_HEAD_LENGTH


func _get_column_head_angle(column: int, row: int) -> float:
  if column == 2 or column == 8:
    return HEAD_ANGLE_VALUES[row]
  if column == 3 or column == 5 or column == 10 or column == 12 or column == 14 or column == 16:
    return ARROW_JOINT_HEAD_ANGLE
  return ARROW_BASE_HEAD_ANGLE


func _get_sample_x_bounds(column: int, row: int) -> Vector2:
  if _is_arrow_only_column(column):
    return _get_arrow_x_bounds(column, row)
  return _get_line_x_bounds(column, row)


func _is_arrow_only_column(column: int) -> bool:
  return column == 0 or column == 1 or column == 2 or column == 3 or column == 4 or column == 5


func _get_arrow_x_bounds(column: int, row: int) -> Vector2:
  var tip := _get_arrow_tip(column, row)
  var dir := _get_arrow_bounds_dir(column, row)
  var head_length := dir.length()
  var direction := dir / head_length
  var tangent := _get_arrow_bounds_tangent(direction)
  var bitangent := direction.cross(tangent).normalized()
  var head_radius := tan(_get_column_head_angle(column, row)) * head_length
  var head_center := tip - dir
  var min_x := tip.x
  var max_x := tip.x

  for point in [
    head_center + tangent * head_radius,
    head_center - tangent * head_radius,
    head_center + bitangent * head_radius,
    head_center - bitangent * head_radius,
  ]:
    min_x = minf(min_x, point.x)
    max_x = maxf(max_x, point.x)

  return Vector2(min_x, max_x)


func _get_arrow_bounds_dir(column: int, row: int) -> Vector3:
  if column == 1:
    return _get_arrow_dir(row)
  return Vector3.RIGHT * _get_column_dir_length(column)


func _get_arrow_bounds_tangent(direction: Vector3) -> Vector3:
  var reference := Vector3.UP
  if absf(direction.dot(reference)) > 0.95:
    reference = Vector3.BACK
  return direction.cross(reference).normalized()


func _get_line_x_bounds(column: int, row: int) -> Vector2:
  var start := _get_line_start(column, row)
  var end := _get_line_end(column, row)
  var direction := start.direction_to(end)
  var head_length := _get_column_head_length(column, row)
  var head_radius := tan(_get_column_head_angle(column, row)) * head_length
  var head_center := end - direction * head_length
  var min_x := minf(start.x, end.x)
  var max_x := maxf(start.x, end.x)
  min_x = minf(min_x, head_center.x - head_radius)
  max_x = maxf(max_x, head_center.x + head_radius)
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
  return ARROW_BASE_WIDTH
