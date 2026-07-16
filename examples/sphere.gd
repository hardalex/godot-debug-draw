extends Node3D
## Sphere example scene: curated debug sphere parameter samples.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const SPHERE_Y := 0.1
const SPHERE_RADIUS := 0.30
const SPHERE_BASE_LINE_WIDTH := 2.0
const SPHERE_JOINT_LINE_WIDTH := 8.0
const SPHERE_SEGMENT_COUNT := 48
const SPHERE_AXIS_SEGMENT_COUNT := 2
const SAMPLE_SPACING := 0.86
const RADIUS_SAMPLE_SPACING := 1.08
const SAMPLE_START_Z := -0.45
const COLUMN_SPACING := 2.0
const LABEL_Y := SPHERE_Y + 0.01
const TITLE_Z := 0.35
const SAMPLE_LABEL_GAP := 0.12
const LABEL_FONT_SIZE := 20
const TITLE_LABEL_FONT_SIZE := 28
const LABEL_PIXEL_SIZE := 0.004
const DASH_OFFSET_SPEED := 0.6
const WIDTH_VALUES := [1.0, 2.0, 5.5, 10.0]
const RADIUS_VALUES := [0.18, 0.28, 0.38, 0.50]
const SEGMENT_VALUES := [8, 16, 32, 64]
const Y_AXIS_SEGMENT_VALUES := [0, 1, 2, 6]
const Z_AXIS_SEGMENT_VALUES := [0, 1, 2, 6]
const ROTATION_SAMPLE_COUNT := 8
const ROTATION_TUNNEL_RADIUS := 0.42
const ROTATION_TUNNEL_DEPTH_STEP := 0.16
const ROTATION_TUNNEL_SCALE_STEP := 0.05
const ROTATION_TUNNEL_Y := 0.35
const SPHERE_S_SAMPLE_COUNT := 8
const SPHERE_S_TUNNEL_RADIUS := 0.42
const SPHERE_S_TUNNEL_DEPTH_STEP := 0.16
const SPHERE_S_TUNNEL_SCALE_STEP := 0.05
const SPHERE_S_TUNNEL_Y := 0.35
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
  _debug_draw.line_width = SPHERE_BASE_LINE_WIDTH
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
  _draw_y_axis_samples(3)
  _draw_z_axis_samples(4)
  _draw_rotation_samples(5)
  _draw_joint_samples(6)
  _draw_dash_samples(7)
  _draw_dash_joint_samples(8)
  _draw_normal_samples(9)
  _draw_normal_joint_samples(10)
  _draw_normal_dash_samples(11)
  _draw_normal_dash_joint_samples(12)
  _draw_sphere_s_samples(13)


func _draw_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _debug_draw.draw_sphere(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      SPHERE_RADIUS,
      Color.WHITE,
      WIDTH_VALUES[row],
      SPHERE_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
    )


func _draw_radius_samples(column: int) -> void:
  for row in RADIUS_VALUES.size():
    _debug_draw.draw_sphere(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      RADIUS_VALUES[row],
      Color(0.15, 0.85, 1.0, 0.95),
      SPHERE_BASE_LINE_WIDTH,
      SPHERE_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
    )


func _draw_segment_samples(column: int) -> void:
  for row in SEGMENT_VALUES.size():
    _debug_draw.draw_sphere(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      SPHERE_RADIUS,
      Color(0.7, 1.0, 0.25, 1.0),
      SPHERE_BASE_LINE_WIDTH,
      SEGMENT_VALUES[row],
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
    )


func _draw_y_axis_samples(column: int) -> void:
  for row in Y_AXIS_SEGMENT_VALUES.size():
    _debug_draw.draw_sphere(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      SPHERE_RADIUS,
      Color(0.95, 0.75, 0.25, 1.0),
      SPHERE_BASE_LINE_WIDTH,
      SPHERE_SEGMENT_COUNT,
      Y_AXIS_SEGMENT_VALUES[row],
      SPHERE_AXIS_SEGMENT_COUNT,
    )


func _draw_z_axis_samples(column: int) -> void:
  for row in Z_AXIS_SEGMENT_VALUES.size():
    _debug_draw.draw_sphere(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      SPHERE_RADIUS,
      Color(1.0, 0.45, 0.2, 1.0),
      SPHERE_BASE_LINE_WIDTH,
      SPHERE_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      Z_AXIS_SEGMENT_VALUES[row],
    )


func _draw_rotation_samples(column: int) -> void:
  for row in ROTATION_SAMPLE_COUNT:
    var tunnel_scale := 1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP
    _debug_draw.draw_sphere(
      _get_rotation_tunnel_center(column, row),
      _get_rotation_tunnel_rotation(row),
      ROTATION_TUNNEL_RADIUS * tunnel_scale,
      Color(0.95, 0.75, 0.25, 1.0 - float(row) * 0.07),
      SPHERE_BASE_LINE_WIDTH,
      SPHERE_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
    )


func _draw_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_sphere(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      SPHERE_RADIUS,
      Color(0.75, 0.45, 1.0, 1.0),
      SPHERE_JOINT_LINE_WIDTH,
      16,
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      JOINT_VALUES[row],
    )


func _draw_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_sphere_d(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      SPHERE_RADIUS,
      Color(1.0, 0.45, 0.2, 1.0),
      SPHERE_BASE_LINE_WIDTH,
      dash.x,
      dash.y,
      _get_dash_offset(dash),
      SPHERE_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
    )


func _draw_dash_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_sphere_d(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      SPHERE_RADIUS,
      Color(1.0, 0.3, 0.6, 1.0),
      SPHERE_JOINT_LINE_WIDTH,
      0.18,
      0.1,
      fposmod(_dash_offset, 0.28),
      16,
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      JOINT_VALUES[row],
    )


func _draw_normal_samples(column: int) -> void:
  for row in NORMAL_SAMPLE_COUNT:
    _debug_draw.draw_sphere_n(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      SPHERE_RADIUS,
      _get_normal_sample_color(row),
      _get_normal_sample_width(row),
      SPHERE_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      DebugDraw3D.LineJoint.ROUND,
    )


func _draw_normal_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_sphere_n(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      SPHERE_RADIUS,
      Color(0.25, 0.95, 0.9, 1.0),
      SPHERE_JOINT_LINE_WIDTH,
      16,
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      JOINT_VALUES[row],
    )


func _draw_normal_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_sphere_n_d(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      SPHERE_RADIUS,
      Color(0.25, 0.95, 0.9, 1.0),
      SPHERE_BASE_LINE_WIDTH,
      dash.x,
      dash.y,
      _get_dash_offset(dash),
      SPHERE_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      DebugDraw3D.LineJoint.ROUND,
    )


func _draw_normal_dash_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_sphere_n_d(
      _get_sphere_center(column, row),
      _get_flat_rotation(0.0),
      SPHERE_RADIUS,
      Color(0.25, 0.95, 0.9, 1.0),
      SPHERE_JOINT_LINE_WIDTH,
      0.18,
      0.1,
      fposmod(_dash_offset, 0.28),
      16,
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      JOINT_VALUES[row],
    )


func _draw_sphere_s_samples(column: int) -> void:
  for row in SPHERE_S_SAMPLE_COUNT:
    var scale := 1.0 - float(row) * SPHERE_S_TUNNEL_SCALE_STEP
    var hue := fmod(float(row) / float(SPHERE_S_SAMPLE_COUNT) + 0.6, 1.0)
    var center := _get_sphere_s_tunnel_center(column, row)
    var rotation := _get_sphere_s_tunnel_rotation(row)
    var radius := SPHERE_S_TUNNEL_RADIUS * scale
    var color := Color.from_hsv(hue, 0.7, 1.0, 0.35)
    _debug_draw.draw_sphere_s(center, rotation, radius, color)
    _debug_draw.draw_sphere_n(
      center,
      rotation,
      radius,
      Color.from_hsv(hue, 0.7, 1.0, 1.0),
      SPHERE_BASE_LINE_WIDTH,
      SPHERE_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
      SPHERE_AXIS_SEGMENT_COUNT,
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
  return 14


func _get_column_sample_count(column: int) -> int:
  match column:
    0:
      return WIDTH_VALUES.size()
    1:
      return RADIUS_VALUES.size()
    2:
      return SEGMENT_VALUES.size()
    3:
      return Y_AXIS_SEGMENT_VALUES.size()
    4:
      return Z_AXIS_SEGMENT_VALUES.size()
    5:
      return ROTATION_SAMPLE_COUNT
    6:
      return JOINT_VALUES.size()
    7:
      return DASH_VALUES.size()
    8:
      return JOINT_VALUES.size()
    9:
      return NORMAL_SAMPLE_COUNT
    10:
      return JOINT_VALUES.size()
    11:
      return DASH_VALUES.size()
    12:
      return JOINT_VALUES.size()
    13:
      return SPHERE_S_SAMPLE_COUNT
    _:
      return 0


func _get_column_label(column: int) -> String:
  match column:
    0:
      return "sphere(width)"
    1:
      return "sphere(radius)"
    2:
      return "sphere(segments)"
    3:
      return "sphere(y axis)"
    4:
      return "sphere(z axis)"
    5:
      return "sphere(rotation)"
    6:
      return "sphere(joint)"
    7:
      return "sphere_d(dash)"
    8:
      return "sphere_d(joint)"
    9:
      return "sphere_n"
    10:
      return "sphere_n(joint)"
    11:
      return "sphere_n_d(dash)"
    12:
      return "sphere_n_d(joint)"
    13:
      return "sphere_s"
    _:
      return "sphere"


func _get_sample_label(column: int, row: int) -> String:
  match column:
    0:
      return "w = %.1f" % WIDTH_VALUES[row]
    1:
      return "r = %.2f" % RADIUS_VALUES[row]
    2:
      return "%d seg" % SEGMENT_VALUES[row]
    3:
      return "y = %d" % Y_AXIS_SEGMENT_VALUES[row]
    4:
      return "z = %d" % Z_AXIS_SEGMENT_VALUES[row]
    5:
      return _get_rotation_label(row)
    6:
      return _get_joint_label(JOINT_VALUES[row])
    7:
      var dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [dash.x, dash.y]
    8:
      return _get_joint_label(JOINT_VALUES[row])
    9:
      return _get_normal_label(row)
    10:
      return _get_joint_label(JOINT_VALUES[row])
    11:
      var normal_dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [normal_dash.x, normal_dash.y]
    12:
      return _get_joint_label(JOINT_VALUES[row])
    13:
      return _get_rotation_label(row)
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


func _get_column_label_x(column: int) -> float:
  var min_x := INF
  var max_x := -INF
  for row in _get_column_sample_count(column):
    var bounds := _get_sphere_x_bounds(column, row)
    min_x = minf(min_x, bounds.x)
    max_x = maxf(max_x, bounds.y)
  return (min_x + max_x) * 0.5


func _get_sample_label_position(column: int, row: int) -> Vector3:
  return Vector3(_get_sphere_x_bounds(column, row).x - SAMPLE_LABEL_GAP, LABEL_Y, _get_sample_label_z(column, row))


func _get_sample_label_z(column: int, row: int) -> float:
  if column == 5:
    return _get_rotation_tunnel_center(column, row).z
  if column == 13:
    return _get_sphere_s_tunnel_center(column, row).z
  return _get_sample_z(column, row)


func _get_sample_z(column: int, row: int) -> float:
  if column == 1:
    return SAMPLE_START_Z - float(row) * RADIUS_SAMPLE_SPACING
  return SAMPLE_START_Z - float(row) * SAMPLE_SPACING


func _get_sphere_center(column: int, row: int) -> Vector3:
  var radius := _get_column_radius(column, row)
  return Vector3(_get_column_x(column), SPHERE_Y + radius, _get_sample_z(column, row))


func _get_rotation_tunnel_center(column: int, row: int) -> Vector3:
  var center := _get_sphere_center(column, row)
  center.y += ROTATION_TUNNEL_Y
  center.z -= float(row) * ROTATION_TUNNEL_DEPTH_STEP
  return center


func _get_sphere_s_tunnel_center(column: int, row: int) -> Vector3:
  var center := _get_sphere_center(column, row)
  center.y += SPHERE_S_TUNNEL_Y
  center.z -= float(row) * SPHERE_S_TUNNEL_DEPTH_STEP
  return center


func _get_flat_rotation(angle: float) -> Quaternion:
  return Basis.IDENTITY.rotated(Vector3.UP, angle).get_rotation_quaternion()


func _get_rotation_tunnel_rotation(row: int) -> Quaternion:
  var basis := Basis.IDENTITY
  basis = basis.rotated(Vector3.RIGHT, -PI * 0.35)
  basis = basis.rotated(Vector3.BACK, float(row) * PI * 0.10)
  basis = basis.rotated(Vector3.UP, float(row) * PI * 0.08)
  return basis.get_rotation_quaternion()


func _get_sphere_s_tunnel_rotation(row: int) -> Quaternion:
  var basis := Basis.IDENTITY
  basis = basis.rotated(Vector3.RIGHT, -PI * 0.35)
  basis = basis.rotated(Vector3.BACK, float(row) * PI * 0.10)
  basis = basis.rotated(Vector3.UP, float(row) * PI * 0.08)
  return basis.get_rotation_quaternion()


func _get_column_center(column: int, row: int) -> Vector3:
  if column == 5:
    return _get_rotation_tunnel_center(column, row)
  if column == 13:
    return _get_sphere_s_tunnel_center(column, row)
  return _get_sphere_center(column, row)


func _get_column_rotation(column: int, row: int) -> Quaternion:
  if column == 5:
    return _get_rotation_tunnel_rotation(row)
  if column == 13:
    return _get_sphere_s_tunnel_rotation(row)
  return _get_flat_rotation(0.0)


func _get_column_radius(column: int, row: int) -> float:
  if column == 1:
    return RADIUS_VALUES[row]
  if column == 5:
    return ROTATION_TUNNEL_RADIUS * (1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP)
  if column == 13:
    return SPHERE_S_TUNNEL_RADIUS * (1.0 - float(row) * SPHERE_S_TUNNEL_SCALE_STEP)
  return SPHERE_RADIUS


func _get_sphere_x_bounds(column: int, row: int) -> Vector2:
  var center := _get_column_center(column, row)
  var basis := Basis(_get_column_rotation(column, row).normalized())
  var radius := _get_column_radius(column, row)
  var min_x := INF
  var max_x := -INF

  for axis: Vector3 in [basis.x, basis.y, basis.z]:
    for sign_value: float in [-1.0, 1.0]:
      var point: Vector3 = center + axis * radius * sign_value
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
  return SPHERE_BASE_LINE_WIDTH
