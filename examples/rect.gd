extends Node3D
## Rect example scene: curated debug rect parameter samples on the XZ plane.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const RECT_Y := 0.1
const RECT_WIDTH := 0.95
const RECT_HEIGHT := 0.45
const RECT_BASE_LINE_WIDTH := 2.0
const RECT_EMPHASIS_LINE_WIDTH := 5.5
const SAMPLE_SPACING := 0.62
const SIZE_SAMPLE_SPACING := 0.9
const SAMPLE_START_Z := -0.45
const COLUMN_SPACING := 2.0
const LABEL_Y := RECT_Y + 0.01
const TITLE_Z := 0.35
const SAMPLE_LABEL_GAP := 0.12
const LABEL_FONT_SIZE := 20
const TITLE_LABEL_FONT_SIZE := 28
const LABEL_PIXEL_SIZE := 0.004
const DASH_OFFSET_SPEED := 0.6
const WIDTH_VALUES := [1.0, 2.0, 5.5, 10.0]
const SIZE_VALUES := [Vector2(0.95, 0.45), Vector2(1.25, 0.45), Vector2(0.95, 0.75), Vector2(0.55, 0.55)]
const ROTATION_SAMPLE_COUNT := 8
const ROTATION_TUNNEL_WIDTH := 1.15
const ROTATION_TUNNEL_HEIGHT := 0.7
const ROTATION_TUNNEL_DEPTH_STEP := 0.16
const ROTATION_TUNNEL_SCALE_STEP := 0.07
const ROTATION_TUNNEL_TWIST_STEP := PI * 0.12
const RECT_S_SAMPLE_COUNT := 8
const RECT_S_TUNNEL_WIDTH := 1.1
const RECT_S_TUNNEL_HEIGHT := 0.65
const RECT_S_TUNNEL_DEPTH_STEP := 0.15
const RECT_S_TUNNEL_SCALE_STEP := 0.06
const RECT_S_TUNNEL_TWIST_STEP := PI * 0.12
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
  _debug_draw.line_width = RECT_BASE_LINE_WIDTH
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
  _draw_size_samples(1)
  _draw_rotation_samples(2)
  _draw_joint_samples(3)
  _draw_dash_samples(4)
  _draw_dash_joint_samples(5)
  _draw_normal_samples(6)
  _draw_normal_dash_samples(7)
  _draw_normal_joint_samples(8)
  _draw_rect_s_samples(9)


func _draw_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _debug_draw.draw_rect(
      _get_rect_center(column, row),
      _get_flat_rotation(0.0),
      RECT_WIDTH,
      RECT_HEIGHT,
      Color.WHITE,
      WIDTH_VALUES[row],
    )


func _draw_size_samples(column: int) -> void:
  for row in SIZE_VALUES.size():
    var size: Vector2 = SIZE_VALUES[row]
    _debug_draw.draw_rect(
      _get_rect_center(column, row),
      _get_flat_rotation(0.0),
      size.x,
      size.y,
      Color(0.15, 0.85, 1.0, 0.95),
      RECT_BASE_LINE_WIDTH,
    )


func _draw_rotation_samples(column: int) -> void:
  for row in ROTATION_SAMPLE_COUNT:
    var tunnel_scale := 1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP
    _debug_draw.draw_rect(
      _get_rotation_tunnel_center(column, row),
      _get_rotation_tunnel_rotation(row),
      ROTATION_TUNNEL_WIDTH * tunnel_scale,
      ROTATION_TUNNEL_HEIGHT * tunnel_scale,
      Color(0.7, 1.0, 0.25, 1.0 - float(row) * 0.07),
      RECT_BASE_LINE_WIDTH,
    )


func _draw_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_rect_d(
      _get_rect_center(column, row),
      _get_flat_rotation(0.0),
      RECT_WIDTH,
      RECT_HEIGHT,
      Color(1.0, 0.45, 0.2, 1.0),
      RECT_BASE_LINE_WIDTH,
      dash.x,
      dash.y,
      _dash_offset,
    )


func _draw_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_rect(
      _get_rect_center(column, row),
      _get_flat_rotation(0.0),
      RECT_WIDTH,
      RECT_HEIGHT,
      Color(0.75, 0.45, 1.0, 1.0),
      8.0,
      JOINT_VALUES[row],
    )


func _draw_dash_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_rect_d(
      _get_rect_center(column, row),
      _get_flat_rotation(0.0),
      RECT_WIDTH,
      RECT_HEIGHT,
      Color(1.0, 0.3, 0.6, 1.0),
      8.0,
      0.18,
      0.1,
      _dash_offset,
      JOINT_VALUES[row],
    )


func _draw_normal_samples(column: int) -> void:
  for row in NORMAL_SAMPLE_COUNT:
    _debug_draw.draw_rect_n(
      _get_rect_center(column, row),
      _get_flat_rotation(0.0),
      RECT_WIDTH,
      RECT_HEIGHT,
      _get_normal_sample_color(row),
      _get_normal_sample_width(row),
      DebugDraw3D.LineJoint.ROUND,
    )


func _draw_normal_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_rect_n_d(
      _get_rect_center(column, row),
      _get_flat_rotation(0.0),
      RECT_WIDTH,
      RECT_HEIGHT,
      Color(0.25, 0.95, 0.9, 1.0),
      RECT_BASE_LINE_WIDTH,
      dash.x,
      dash.y,
      _dash_offset,
      DebugDraw3D.LineJoint.ROUND,
    )


func _draw_normal_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_rect_n(
      _get_rect_center(column, row),
      _get_flat_rotation(0.0),
      RECT_WIDTH,
      RECT_HEIGHT,
      Color(0.25, 0.95, 0.9, 1.0),
      RECT_EMPHASIS_LINE_WIDTH,
      JOINT_VALUES[row],
    )


func _draw_rect_s_samples(column: int) -> void:
  for row in RECT_S_SAMPLE_COUNT:
    var scale := 1.0 - float(row) * RECT_S_TUNNEL_SCALE_STEP
    var hue := fmod(float(row) / float(RECT_S_SAMPLE_COUNT) + 0.6, 1.0)
    _debug_draw.draw_rect_s(
      _get_rect_s_tunnel_center(column, row),
      _get_rect_s_tunnel_rotation(row),
      RECT_S_TUNNEL_WIDTH * scale,
      RECT_S_TUNNEL_HEIGHT * scale,
      Color.from_hsv(hue, 0.7, 1.0, 1.0 - float(row) * 0.08),
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
      return SIZE_VALUES.size()
    2:
      return ROTATION_SAMPLE_COUNT
    3:
      return JOINT_VALUES.size()
    4:
      return DASH_VALUES.size()
    5:
      return JOINT_VALUES.size()
    6:
      return NORMAL_SAMPLE_COUNT
    7:
      return DASH_VALUES.size()
    8:
      return JOINT_VALUES.size()
    9:
      return RECT_S_SAMPLE_COUNT
    _:
      return 0


func _get_column_label(column: int) -> String:
  match column:
    0:
      return "rect(width)"
    1:
      return "rect(size)"
    2:
      return "rect(rotation)"
    3:
      return "rect(joint)"
    4:
      return "rect_d(dash)"
    5:
      return "rect_d(joint)"
    6:
      return "rect_n"
    7:
      return "rect_n_d(dash)"
    8:
      return "rect_n(joint)"
    9:
      return "rect_s(solid)"
    _:
      return "rect"


func _get_sample_label(column: int, row: int) -> String:
  match column:
    0:
      return "w = %.1f" % WIDTH_VALUES[row]
    1:
      var size: Vector2 = SIZE_VALUES[row]
      return "%.2f x %.2f" % [size.x, size.y]
    2:
      return _get_rotation_label(row)
    3:
      return _get_joint_label(JOINT_VALUES[row])
    4:
      var dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [dash.x, dash.y]
    5:
      return _get_joint_label(JOINT_VALUES[row])
    6:
      return _get_normal_label(row)
    7:
      var normal_dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [normal_dash.x, normal_dash.y]
    8:
      return _get_joint_label(JOINT_VALUES[row])
    9:
      return _get_rect_s_label(row)
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


func _get_rect_s_label(row: int) -> String:
  return "%s  %s  %s" % [
    _get_rect_s_scale_text(row),
    _get_rect_s_rotation_text(row),
    _get_rect_s_color_text(row),
  ]


func _get_rect_s_scale_text(row: int) -> String:
  var scale := 1.0 - float(row) * RECT_S_TUNNEL_SCALE_STEP
  return "s:%.2f" % scale


func _get_rect_s_rotation_text(row: int) -> String:
  var angle := rad_to_deg(float(row) * RECT_S_TUNNEL_TWIST_STEP)
  return "r:%.0f°" % angle


func _get_rect_s_color_text(row: int) -> String:
  var hue := fmod(float(row) / float(RECT_S_SAMPLE_COUNT) + 0.6, 1.0)
  return "h:%.0f°" % (hue * 360.0)


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
  return _get_column_x(column) - _get_column_max_rect_width(column) * 0.5 - SAMPLE_LABEL_GAP


func _get_sample_label_z(column: int, row: int) -> float:
  if column == 2:
    return _get_rotation_tunnel_center(column, row).z
  if column == 9:
    return _get_rect_s_tunnel_center(column, row).z
  return _get_sample_z(column, row)


func _get_column_max_rect_width(column: int) -> float:
  if column == 1:
    var max_width := 0.0
    for size: Vector2 in SIZE_VALUES:
      max_width = maxf(max_width, size.x)
    return max_width

  if column == 9:
    return RECT_S_TUNNEL_WIDTH

  return RECT_WIDTH


func _get_row_z(row: int) -> float:
  return SAMPLE_START_Z - float(row) * SAMPLE_SPACING


func _get_sample_z(column: int, row: int) -> float:
  if column == 1:
    return SAMPLE_START_Z - float(row) * SIZE_SAMPLE_SPACING
  return _get_row_z(row)


func _get_rect_center(column: int, row: int) -> Vector3:
  return Vector3(_get_column_x(column), RECT_Y, _get_sample_z(column, row))


func _get_flat_rotation(angle: float) -> Quaternion:
  return _get_rect_rotation(angle, true)


func _get_rotation_tunnel_center(column: int, row: int) -> Vector3:
  var center := _get_rect_center(column, row)
  center.y += 0.35
  center.z -= float(row) * ROTATION_TUNNEL_DEPTH_STEP
  return center


func _get_rotation_tunnel_rotation(row: int) -> Quaternion:
  var basis := Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK)
  basis = basis.rotated(Vector3.BACK, float(row) * ROTATION_TUNNEL_TWIST_STEP)
  return basis.get_rotation_quaternion()


func _get_rect_s_tunnel_center(column: int, row: int) -> Vector3:
  var center := _get_rect_center(column, row)
  center.y += 0.5
  center.z -= float(row) * RECT_S_TUNNEL_DEPTH_STEP
  return center


func _get_rect_s_tunnel_rotation(row: int) -> Quaternion:
  var basis := Basis(Vector3.RIGHT, Vector3.UP, Vector3.BACK)
  basis = basis.rotated(Vector3.BACK, float(row) * RECT_S_TUNNEL_TWIST_STEP)
  basis = basis.rotated(Vector3.RIGHT, float(row) * 0.08)
  return basis.get_rotation_quaternion()


func _get_rect_rotation(angle: float, front: bool) -> Quaternion:
  var normal := Vector3.UP if front else Vector3.DOWN
  var width_axis := Vector3.RIGHT.rotated(Vector3.UP, angle).normalized()
  var height_axis := normal.cross(width_axis).normalized()
  return Basis(width_axis, height_axis, normal).get_rotation_quaternion()


func _get_normal_sample_color(row: int) -> Color:
  if row == 1:
    return Color(0.25, 0.95, 0.9, 0.35)
  if row == 2:
    return Color(1.0, 0.45, 0.2, 1.0)
  return Color(0.25, 0.95, 0.9, 1.0)


func _get_normal_sample_width(row: int) -> float:
  if row == 3:
    return 10.0
  return RECT_BASE_LINE_WIDTH
