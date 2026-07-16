extends Node3D
## Cone example scene: curated debug cone parameter samples.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const CONE_BASE_Y := 0.1
const CONE_RADIUS := 0.28
const CONE_HEIGHT := 0.7
const CONE_BASE_LINE_WIDTH := 2.0
const CONE_JOINT_LINE_WIDTH := 8.0
const SAMPLE_SPACING := 0.84
const RADIUS_SAMPLE_SPACING := 1.05
const HEIGHT_SAMPLE_SPACING := 1.08
const SAMPLE_START_Z := -0.45
const COLUMN_SPACING := 2.0
const LABEL_Y := CONE_BASE_Y + 0.01
const TITLE_Z := 0.35
const SAMPLE_LABEL_GAP := 0.12
const LABEL_FONT_SIZE := 20
const TITLE_LABEL_FONT_SIZE := 28
const LABEL_PIXEL_SIZE := 0.004
const WIDTH_VALUES := [1.0, 2.0, 5.5, 10.0]
const RADIUS_VALUES := [0.18, 0.28, 0.38, 0.50]
const HEIGHT_VALUES := [0.45, 0.65, 0.85, 1.05]
const SEGMENT_VALUES := [3, 4, 8, 16]
const SIDE_SEGMENT_VALUES := [3, 4, 8, 16]
const ROTATION_SAMPLE_COUNT := 8
const ROTATION_TUNNEL_RADIUS := 0.34
const ROTATION_TUNNEL_HEIGHT := 0.82
const ROTATION_TUNNEL_DEPTH_STEP := 0.16
const ROTATION_TUNNEL_SCALE_STEP := 0.05
const ROTATION_TUNNEL_Y := 0.35
const CONE_S_SAMPLE_COUNT := 8
const CONE_S_TUNNEL_RADIUS := 0.34
const CONE_S_TUNNEL_HEIGHT := 0.82
const CONE_S_TUNNEL_DEPTH_STEP := 0.16
const CONE_S_TUNNEL_SCALE_STEP := 0.05
const CONE_S_TUNNEL_Y := 0.35
const JOINT_VALUES := [
  DebugDraw3D.LineJoint.NONE,
  DebugDraw3D.LineJoint.ROUND,
  DebugDraw3D.LineJoint.BEVEL,
  DebugDraw3D.LineJoint.MITER,
]
const NORMAL_SAMPLE_COUNT := 4

var _last_info_text := ""

@onready var _free_camera: FreeCamera = $FreeCamera
@onready var _debug_draw: DebugDraw3D = $DebugDraw3D
@onready var _info_label: Label = $UI/InfoLabel


func _ready() -> void:
  _debug_draw.depth_bias = -0.001
  _debug_draw.line_width = CONE_BASE_LINE_WIDTH
  _create_labels()
  _initialize_window_size()
  _update_info_label()


func _process(_delta: float) -> void:
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
  _draw_height_samples(2)
  _draw_segment_samples(3)
  _draw_side_segment_samples(4)
  _draw_rotation_samples(5)
  _draw_joint_samples(6)
  _draw_normal_samples(7)
  _draw_normal_joint_samples(8)
  _draw_cone_s_samples(9)


func _draw_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _debug_draw.draw_cone(
      _get_cone_center(column, row),
      _get_flat_rotation(0.0),
      CONE_RADIUS,
      CONE_HEIGHT,
      Color.WHITE,
      WIDTH_VALUES[row],
      16,
      8,
    )


func _draw_radius_samples(column: int) -> void:
  for row in RADIUS_VALUES.size():
    _debug_draw.draw_cone(
      _get_cone_center(column, row),
      _get_flat_rotation(0.0),
      RADIUS_VALUES[row],
      CONE_HEIGHT,
      Color(0.15, 0.85, 1.0, 0.95),
      CONE_BASE_LINE_WIDTH,
      16,
      8,
    )


func _draw_height_samples(column: int) -> void:
  for row in HEIGHT_VALUES.size():
    _debug_draw.draw_cone(
      _get_cone_center(column, row),
      _get_flat_rotation(0.0),
      CONE_RADIUS,
      HEIGHT_VALUES[row],
      Color(0.7, 1.0, 0.25, 1.0),
      CONE_BASE_LINE_WIDTH,
      16,
      8,
    )


func _draw_segment_samples(column: int) -> void:
  for row in SEGMENT_VALUES.size():
    _debug_draw.draw_cone(
      _get_cone_center(column, row),
      _get_flat_rotation(0.0),
      CONE_RADIUS,
      CONE_HEIGHT,
      Color(0.95, 0.75, 0.25, 1.0),
      CONE_BASE_LINE_WIDTH,
      SEGMENT_VALUES[row],
      8,
    )


func _draw_side_segment_samples(column: int) -> void:
  for row in SIDE_SEGMENT_VALUES.size():
    _debug_draw.draw_cone(
      _get_cone_center(column, row),
      _get_flat_rotation(0.0),
      CONE_RADIUS,
      CONE_HEIGHT,
      Color(1.0, 0.45, 0.2, 1.0),
      CONE_BASE_LINE_WIDTH,
      16,
      SIDE_SEGMENT_VALUES[row],
    )


func _draw_rotation_samples(column: int) -> void:
  for row in ROTATION_SAMPLE_COUNT:
    var tunnel_scale := 1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP
    _debug_draw.draw_cone(
      _get_rotation_tunnel_center(column, row),
      _get_rotation_tunnel_rotation(row),
      ROTATION_TUNNEL_RADIUS * tunnel_scale,
      ROTATION_TUNNEL_HEIGHT * tunnel_scale,
      Color(0.95, 0.75, 0.25, 1.0 - float(row) * 0.07),
      CONE_BASE_LINE_WIDTH,
      16,
      8,
    )


func _draw_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_cone(
      _get_cone_center(column, row),
      _get_flat_rotation(0.0),
      CONE_RADIUS,
      CONE_HEIGHT,
      Color(0.75, 0.45, 1.0, 1.0),
      CONE_JOINT_LINE_WIDTH,
      8,
      8,
      JOINT_VALUES[row],
    )


func _draw_normal_samples(column: int) -> void:
  for row in NORMAL_SAMPLE_COUNT:
    _debug_draw.draw_cone_n(
      _get_cone_center(column, row),
      _get_flat_rotation(0.0),
      CONE_RADIUS,
      CONE_HEIGHT,
      _get_normal_sample_color(row),
      _get_normal_sample_width(row),
      16,
      8,
      DebugDraw3D.LineJoint.ROUND,
    )


func _draw_normal_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_cone_n(
      _get_cone_center(column, row),
      _get_flat_rotation(0.0),
      CONE_RADIUS,
      CONE_HEIGHT,
      Color(0.25, 0.95, 0.9, 1.0),
      CONE_JOINT_LINE_WIDTH,
      8,
      8,
      JOINT_VALUES[row],
    )


func _draw_cone_s_samples(column: int) -> void:
  for row in CONE_S_SAMPLE_COUNT:
    var scale := 1.0 - float(row) * CONE_S_TUNNEL_SCALE_STEP
    var hue := fmod(float(row) / float(CONE_S_SAMPLE_COUNT) + 0.6, 1.0)
    var center := _get_cone_s_tunnel_center(column, row)
    var rotation := _get_cone_s_tunnel_rotation(row)
    var radius := CONE_S_TUNNEL_RADIUS * scale
    var height := CONE_S_TUNNEL_HEIGHT * scale
    var color := Color.from_hsv(hue, 0.7, 1.0, 0.35)
    _debug_draw.draw_cone_s(center, rotation, radius, height, color)
    _debug_draw.draw_cone_n(
      center,
      rotation,
      radius,
      height,
      Color.from_hsv(hue, 0.7, 1.0, 1.0),
      CONE_BASE_LINE_WIDTH,
      16,
      8,
      DebugDraw3D.LineJoint.ROUND,
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
  return 10


func _get_column_sample_count(column: int) -> int:
  match column:
    0:
      return WIDTH_VALUES.size()
    1:
      return RADIUS_VALUES.size()
    2:
      return HEIGHT_VALUES.size()
    3:
      return SEGMENT_VALUES.size()
    4:
      return SIDE_SEGMENT_VALUES.size()
    5:
      return ROTATION_SAMPLE_COUNT
    6:
      return JOINT_VALUES.size()
    7:
      return NORMAL_SAMPLE_COUNT
    8:
      return JOINT_VALUES.size()
    9:
      return CONE_S_SAMPLE_COUNT
    _:
      return 0


func _get_column_label(column: int) -> String:
  match column:
    0:
      return "cone(width)"
    1:
      return "cone(radius)"
    2:
      return "cone(height)"
    3:
      return "cone(segments)"
    4:
      return "cone(side segments)"
    5:
      return "cone(rotation)"
    6:
      return "cone(joint)"
    7:
      return "cone_n"
    8:
      return "cone_n(joint)"
    9:
      return "cone_s"
    _:
      return "cone"


func _get_sample_label(column: int, row: int) -> String:
  match column:
    0:
      return "w = %.1f" % WIDTH_VALUES[row]
    1:
      return "r = %.2f" % RADIUS_VALUES[row]
    2:
      return "h = %.2f" % HEIGHT_VALUES[row]
    3:
      return "%d seg" % SEGMENT_VALUES[row]
    4:
      return "%d side" % SIDE_SEGMENT_VALUES[row]
    5:
      return _get_rotation_label(row)
    6:
      return _get_joint_label(JOINT_VALUES[row])
    7:
      return _get_normal_label(row)
    8:
      return _get_joint_label(JOINT_VALUES[row])
    9:
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
    var bounds := _get_cone_x_bounds(column, row)
    min_x = minf(min_x, bounds.x)
    max_x = maxf(max_x, bounds.y)
  return (min_x + max_x) * 0.5


func _get_sample_label_position(column: int, row: int) -> Vector3:
  return Vector3(_get_cone_x_bounds(column, row).x - SAMPLE_LABEL_GAP, LABEL_Y, _get_sample_label_z(column, row))


func _get_sample_label_z(column: int, row: int) -> float:
  if column == 5:
    return _get_rotation_tunnel_center(column, row).z
  if column == 9:
    return _get_cone_s_tunnel_center(column, row).z
  return _get_sample_z(column, row)


func _get_sample_z(column: int, row: int) -> float:
  if column == 1:
    return SAMPLE_START_Z - float(row) * RADIUS_SAMPLE_SPACING
  if column == 2:
    return SAMPLE_START_Z - float(row) * HEIGHT_SAMPLE_SPACING
  return SAMPLE_START_Z - float(row) * SAMPLE_SPACING


func _get_cone_center(column: int, row: int) -> Vector3:
  var height := _get_column_height(column, row)
  return Vector3(_get_column_x(column), CONE_BASE_Y + height * 0.5, _get_sample_z(column, row))


func _get_rotation_tunnel_center(column: int, row: int) -> Vector3:
  var center := _get_cone_center(column, row)
  center.y += ROTATION_TUNNEL_Y
  center.z -= float(row) * ROTATION_TUNNEL_DEPTH_STEP
  return center


func _get_cone_s_tunnel_center(column: int, row: int) -> Vector3:
  var center := _get_cone_center(column, row)
  center.y += CONE_S_TUNNEL_Y
  center.z -= float(row) * CONE_S_TUNNEL_DEPTH_STEP
  return center


func _get_flat_rotation(angle: float) -> Quaternion:
  return Basis.IDENTITY.rotated(Vector3.UP, angle).get_rotation_quaternion()


func _get_rotation_tunnel_rotation(row: int) -> Quaternion:
  var basis := Basis.IDENTITY
  basis = basis.rotated(Vector3.RIGHT, -PI * 0.26)
  basis = basis.rotated(Vector3.BACK, float(row) * PI * 0.10)
  basis = basis.rotated(Vector3.UP, float(row) * PI * 0.08)
  return basis.get_rotation_quaternion()


func _get_cone_s_tunnel_rotation(row: int) -> Quaternion:
  var basis := Basis.IDENTITY
  basis = basis.rotated(Vector3.RIGHT, -PI * 0.26)
  basis = basis.rotated(Vector3.BACK, float(row) * PI * 0.10)
  basis = basis.rotated(Vector3.UP, float(row) * PI * 0.08)
  return basis.get_rotation_quaternion()


func _get_column_center(column: int, row: int) -> Vector3:
  if column == 5:
    return _get_rotation_tunnel_center(column, row)
  if column == 9:
    return _get_cone_s_tunnel_center(column, row)
  return _get_cone_center(column, row)


func _get_column_rotation(column: int, row: int) -> Quaternion:
  if column == 5:
    return _get_rotation_tunnel_rotation(row)
  if column == 9:
    return _get_cone_s_tunnel_rotation(row)
  return _get_flat_rotation(0.0)


func _get_column_radius(column: int, row: int) -> float:
  if column == 1:
    return RADIUS_VALUES[row]
  if column == 5:
    return ROTATION_TUNNEL_RADIUS * (1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP)
  if column == 9:
    return CONE_S_TUNNEL_RADIUS * (1.0 - float(row) * CONE_S_TUNNEL_SCALE_STEP)
  return CONE_RADIUS


func _get_column_height(column: int, row: int) -> float:
  if column == 2:
    return HEIGHT_VALUES[row]
  if column == 5:
    return ROTATION_TUNNEL_HEIGHT * (1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP)
  if column == 9:
    return CONE_S_TUNNEL_HEIGHT * (1.0 - float(row) * CONE_S_TUNNEL_SCALE_STEP)
  return CONE_HEIGHT


func _get_column_segment_count(column: int, row: int) -> int:
  if column == 3:
    return SEGMENT_VALUES[row]
  if column == 6 or column == 8:
    return 8
  return 16


func _get_column_side_segment_count(column: int, row: int) -> int:
  if column == 4:
    return SIDE_SEGMENT_VALUES[row]
  return 8


func _get_cone_x_bounds(column: int, row: int) -> Vector2:
  var center := _get_column_center(column, row)
  var basis := Basis(_get_column_rotation(column, row).normalized())
  var radius := _get_column_radius(column, row)
  var height := _get_column_height(column, row)
  var segment_count := maxi(8, _get_column_segment_count(column, row))
  var side_segment_count := maxi(1, _get_column_side_segment_count(column, row))
  var apex := center + basis.y * height * 0.5
  var base_center := center - basis.y * height * 0.5
  var min_x := apex.x
  var max_x := apex.x

  for i in segment_count:
    var angle := TAU * float(i) / float(segment_count)
    var point := base_center + (basis.x * cos(angle) + basis.z * sin(angle)) * radius
    min_x = minf(min_x, point.x)
    max_x = maxf(max_x, point.x)

  for i in side_segment_count:
    var side_angle := TAU * float(i) / float(side_segment_count)
    var side_point := base_center + (basis.x * cos(side_angle) + basis.z * sin(side_angle)) * radius
    min_x = minf(min_x, side_point.x)
    max_x = maxf(max_x, side_point.x)

  return Vector2(min_x, max_x)


func _get_normal_sample_color(row: int) -> Color:
  if row == 1:
    return Color(0.25, 0.95, 0.9, 0.35)
  if row == 2:
    return Color(1.0, 0.45, 0.2, 1.0)
  return Color(0.25, 0.95, 0.9, 1.0)


func _get_normal_sample_width(row: int) -> float:
  if row == 3:
    return 10.0
  return CONE_BASE_LINE_WIDTH
