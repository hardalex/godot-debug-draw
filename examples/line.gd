extends Node3D
## Line example scene: curated debug line parameter samples on the XZ plane.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const LINE_Y := 0.1
const LINE_BASE_WIDTH := 2.0
const SAMPLE_LENGTH := 1.1
const COLUMN_SPACING := 2.0
const SAMPLE_SPACING := 0.78
const SAMPLE_START_Z := -0.45
const STRIP_HALF_DEPTH := 0.18
const LOOP_HALF_DEPTH := 0.25
const LABEL_Y := LINE_Y + 0.01
const TITLE_Z := 0.35
const SAMPLE_LABEL_OFFSET_X := -0.12
const LABEL_FONT_SIZE := 20
const TITLE_LABEL_FONT_SIZE := 28
const LABEL_PIXEL_SIZE := 0.004
const NORMAL_LINE := Vector3(0.0, 0.0, 1.0)
const DASH_OFFSET_SPEED := 0.35
const WIDTH_VALUES := [1.0, 2.0, 5.5, 10.0]
const ALPHA_VALUES := [1.0, 0.65, 0.35, 0.1]
const DASH_VALUES := [Vector2(0.1, 0.1), Vector2(0.2, 0.1), Vector2(0.4, 0.15), Vector2(0.04, 0.12)]
const JOINT_VALUES := [
  DebugDraw3D.LineJoint.NONE,
  DebugDraw3D.LineJoint.ROUND,
  DebugDraw3D.LineJoint.BEVEL,
  DebugDraw3D.LineJoint.MITER,
]
const NORMAL_VALUES := [
  Vector3(0.0, 0.0, 1.0),
  Vector3(0.0, 0.70710677, 0.70710677),
  Vector3(0.0, 1.0, 0.0),
  Vector3(0.0, 0.0, -1.0),
]

var _dash_offset := 0.0
var _last_info_text := ""

@onready var _free_camera: FreeCamera = $FreeCamera
@onready var _debug_draw: DebugDraw3D = $DebugDraw3D
@onready var _info_label: Label = $UI/InfoLabel


func _ready() -> void:
  _debug_draw.depth_bias = -0.001
  _debug_draw.line_width = LINE_BASE_WIDTH
  _create_labels()
  _initialize_window_size()
  _update_info_label()


func _process(delta: float) -> void:
  _dash_offset = fposmod(_dash_offset + delta * DASH_OFFSET_SPEED, 10.0)
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
  _draw_alpha_samples(1)
  _draw_dash_samples(2)
  _draw_strip_joint_samples(3)
  _draw_loop_joint_samples(4)
  _draw_strip_dash_joint_samples(5)
  _draw_normal_samples(6)


func _draw_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _debug_draw.draw_line(
      _get_line_start(column, row),
      _get_line_end(column, row),
      Color.WHITE,
      WIDTH_VALUES[row],
    )


func _draw_alpha_samples(column: int) -> void:
  for row in ALPHA_VALUES.size():
    _debug_draw.draw_line(
      _get_line_start(column, row),
      _get_line_end(column, row),
      Color(1.0, 0.85, 0.1, ALPHA_VALUES[row]),
      LINE_BASE_WIDTH,
    )


func _draw_dash_samples(column: int) -> void:
  for row in DASH_VALUES.size():
    var dash: Vector2 = DASH_VALUES[row]
    _debug_draw.draw_line_d(
      _get_line_start(column, row),
      _get_line_end(column, row),
      Color(0.7, 1.0, 0.25, 1.0),
      LINE_BASE_WIDTH,
      dash.x,
      dash.y,
      _dash_offset,
    )


func _draw_strip_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_line_strip(
      _get_strip_points(column, row),
      Color(0.15, 0.85, 1.0, 0.95),
      8.0,
      JOINT_VALUES[row],
    )


func _draw_loop_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_line_loop(
      _get_loop_points(column, row),
      Color(1.0, 0.45, 0.2, 0.95),
      8.0,
      JOINT_VALUES[row],
    )


func _draw_strip_dash_joint_samples(column: int) -> void:
  for row in JOINT_VALUES.size():
    _debug_draw.draw_line_strip_d(
      _get_strip_points(column, row),
      Color(0.75, 0.45, 1.0, 1.0),
      8.0,
      0.18,
      0.1,
      _dash_offset,
      JOINT_VALUES[row],
    )


func _draw_normal_samples(column: int) -> void:
  for row in NORMAL_VALUES.size():
    _debug_draw.draw_line_n(
      _get_line_start(column, row),
      _get_line_end(column, row),
      NORMAL_VALUES[row],
      Color(0.25, 0.95, 0.9, 1.0),
      LINE_BASE_WIDTH,
    )


func _create_labels() -> void:
  for column in _get_column_count():
    _create_label(
      "ColumnLabel%d" % column,
      _get_column_label(column),
      Vector3(_get_column_x(column) + SAMPLE_LENGTH * 0.5, LABEL_Y, TITLE_Z),
      TITLE_LABEL_FONT_SIZE,
      HORIZONTAL_ALIGNMENT_CENTER,
    )

  for column in _get_column_count():
    for row in _get_column_sample_count(column):
      _create_label(
        "SampleLabel%d_%d" % [column, row],
        _get_sample_label(column, row),
        Vector3(_get_column_x(column) + SAMPLE_LABEL_OFFSET_X, LABEL_Y, _get_row_z(row)),
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
  return 7


func _get_column_sample_count(column: int) -> int:
  match column:
    0:
      return WIDTH_VALUES.size()
    1:
      return ALPHA_VALUES.size()
    2:
      return DASH_VALUES.size()
    3, 4, 5:
      return JOINT_VALUES.size()
    6:
      return NORMAL_VALUES.size()
    _:
      return 0


func _get_column_label(column: int) -> String:
  match column:
    0:
      return "line(width)"
    1:
      return "line(alpha)"
    2:
      return "line_d(dash)"
    3:
      return "strip(joint)"
    4:
      return "loop(joint)"
    5:
      return "strip_d(joint)"
    6:
      return "line_n(normal)"
    _:
      return "line"


func _get_sample_label(column: int, row: int) -> String:
  match column:
    0:
      return "w = %.1f" % WIDTH_VALUES[row]
    1:
      return "a = %.2f" % ALPHA_VALUES[row]
    2:
      var dash: Vector2 = DASH_VALUES[row]
      return "%.2f / %.2f" % [dash.x, dash.y]
    3, 4, 5:
      return _get_joint_label(JOINT_VALUES[row])
    6:
      return _get_normal_label(row)
    _:
      return ""


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
      return "front"
    1:
      return "45 deg"
    2:
      return "side"
    3:
      return "back"
    _:
      return "normal"


func _get_column_x(column: int) -> float:
  return float(column) * COLUMN_SPACING


func _get_row_z(row: int) -> float:
  return SAMPLE_START_Z - float(row) * SAMPLE_SPACING


func _get_line_start(column: int, row: int) -> Vector3:
  return Vector3(_get_column_x(column), LINE_Y, _get_row_z(row))


func _get_line_end(column: int, row: int) -> Vector3:
  return _get_line_start(column, row) + Vector3.RIGHT * SAMPLE_LENGTH


func _get_strip_points(column: int, row: int) -> PackedVector3Array:
  var x := _get_column_x(column)
  var z := _get_row_z(row)
  return PackedVector3Array(
    [
      Vector3(x, LINE_Y, z + STRIP_HALF_DEPTH),
      Vector3(x + SAMPLE_LENGTH * 0.33, LINE_Y, z - STRIP_HALF_DEPTH),
      Vector3(x + SAMPLE_LENGTH * 0.66, LINE_Y, z + STRIP_HALF_DEPTH),
      Vector3(x + SAMPLE_LENGTH, LINE_Y, z - STRIP_HALF_DEPTH),
    ],
  )


func _get_loop_points(column: int, row: int) -> PackedVector3Array:
  var x := _get_column_x(column)
  var z := _get_row_z(row)
  return PackedVector3Array(
    [
      Vector3(x, LINE_Y, z + LOOP_HALF_DEPTH),
      Vector3(x + SAMPLE_LENGTH, LINE_Y, z + LOOP_HALF_DEPTH),
      Vector3(x + SAMPLE_LENGTH, LINE_Y, z - LOOP_HALF_DEPTH),
      Vector3(x, LINE_Y, z - LOOP_HALF_DEPTH),
    ],
  )
