extends Node3D
## Axes example scene: curated debug axes parameter samples.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const AXES_Y := 0.1
const AXES_LENGTH := 0.75
const AXES_BASE_WIDTH := 2.0
const SAMPLE_SPACING := 0.86
const LENGTH_SAMPLE_SPACING := 1.05
const SAMPLE_START_Z := -0.45
const COLUMN_SPACING := 2.2
const LABEL_Y := AXES_Y + 0.01
const TITLE_Z := 0.35
const SAMPLE_LABEL_GAP := 0.12
const LABEL_FONT_SIZE := 20
const TITLE_LABEL_FONT_SIZE := 28
const LABEL_PIXEL_SIZE := 0.004
const LENGTH_VALUES := [0.35, 0.55, 0.75, 1.0]
const WIDTH_VALUES := [1.0, 2.0, 5.5, 10.0]
const ROTATION_SAMPLE_COUNT := 8
const ROTATION_TUNNEL_LENGTH := 0.9
const ROTATION_TUNNEL_DEPTH_STEP := 0.16
const ROTATION_TUNNEL_SCALE_STEP := 0.05
const ROTATION_TUNNEL_Y := 0.35

var _last_info_text := ""

@onready var _free_camera: FreeCamera = $FreeCamera
@onready var _debug_draw: DebugDraw3D = $DebugDraw3D
@onready var _info_label: Label = $UI/InfoLabel


func _ready() -> void:
  _debug_draw.depth_bias = -0.001
  _debug_draw.line_width = AXES_BASE_WIDTH
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
  _draw_length_samples(0)
  _draw_width_samples(1)
  _draw_rotation_samples(2)
  _draw_normal_length_samples(3)
  _draw_normal_width_samples(4)
  _draw_normal_rotation_samples(5)


func _draw_length_samples(column: int) -> void:
  for row in LENGTH_VALUES.size():
    _debug_draw.draw_axes(
      _get_axes_pos(column, row),
      _get_flat_rotation(0.0),
      LENGTH_VALUES[row],
      AXES_BASE_WIDTH,
    )


func _draw_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _debug_draw.draw_axes(
      _get_axes_pos(column, row),
      _get_flat_rotation(0.0),
      AXES_LENGTH,
      WIDTH_VALUES[row],
    )


func _draw_rotation_samples(column: int) -> void:
  for row in ROTATION_SAMPLE_COUNT:
    var tunnel_scale := 1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP
    _debug_draw.draw_axes(
      _get_rotation_tunnel_pos(column, row),
      _get_rotation_tunnel_rotation(row),
      ROTATION_TUNNEL_LENGTH * tunnel_scale,
      AXES_BASE_WIDTH,
    )


func _draw_normal_length_samples(column: int) -> void:
  for row in LENGTH_VALUES.size():
    _debug_draw.draw_axes_n(
      _get_axes_pos(column, row),
      _get_flat_rotation(0.0),
      LENGTH_VALUES[row],
      AXES_BASE_WIDTH,
    )


func _draw_normal_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _debug_draw.draw_axes_n(
      _get_axes_pos(column, row),
      _get_flat_rotation(0.0),
      AXES_LENGTH,
      WIDTH_VALUES[row],
    )


func _draw_normal_rotation_samples(column: int) -> void:
  for row in ROTATION_SAMPLE_COUNT:
    var tunnel_scale := 1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP
    _debug_draw.draw_axes_n(
      _get_rotation_tunnel_pos(column, row),
      _get_rotation_tunnel_rotation(row),
      ROTATION_TUNNEL_LENGTH * tunnel_scale,
      AXES_BASE_WIDTH,
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
  return 6


func _get_column_sample_count(column: int) -> int:
  match column:
    0, 3:
      return LENGTH_VALUES.size()
    1, 4:
      return WIDTH_VALUES.size()
    2, 5:
      return ROTATION_SAMPLE_COUNT
    _:
      return 0


func _get_column_label(column: int) -> String:
  match column:
    0:
      return "axes(length)"
    1:
      return "axes(width)"
    2:
      return "axes(rotation)"
    3:
      return "axes_n(length)"
    4:
      return "axes_n(width)"
    5:
      return "axes_n(rotation)"
    _:
      return "axes"


func _get_sample_label(column: int, row: int) -> String:
  match column:
    0, 3:
      return "len = %.2f" % LENGTH_VALUES[row]
    1, 4:
      return "w = %.1f" % WIDTH_VALUES[row]
    2, 5:
      return _get_rotation_label(row)
    _:
      return ""


func _get_rotation_label(row: int) -> String:
  return "step %d" % row


func _get_column_x(column: int) -> float:
  return float(column) * COLUMN_SPACING + 0.5


func _get_column_label_x(column: int) -> float:
  var min_x := INF
  var max_x := -INF
  for row in _get_column_sample_count(column):
    var bounds := _get_axes_x_bounds(column, row)
    min_x = minf(min_x, bounds.x)
    max_x = maxf(max_x, bounds.y)
  return (min_x + max_x) * 0.5


func _get_sample_label_position(column: int, row: int) -> Vector3:
  return Vector3(_get_axes_x_bounds(column, row).x - SAMPLE_LABEL_GAP, LABEL_Y, _get_sample_label_z(column, row))


func _get_sample_label_z(column: int, row: int) -> float:
  if _is_rotation_column(column):
    return _get_rotation_tunnel_pos(column, row).z
  return _get_sample_z(column, row)


func _get_sample_z(column: int, row: int) -> float:
  if column == 0 or column == 3:
    return SAMPLE_START_Z - float(row) * LENGTH_SAMPLE_SPACING
  return SAMPLE_START_Z - float(row) * SAMPLE_SPACING


func _get_axes_pos(column: int, row: int) -> Vector3:
  return Vector3(_get_column_x(column), AXES_Y, _get_sample_z(column, row))


func _get_rotation_tunnel_pos(column: int, row: int) -> Vector3:
  var pos := _get_axes_pos(column, row)
  pos.y += ROTATION_TUNNEL_Y
  pos.z -= float(row) * ROTATION_TUNNEL_DEPTH_STEP
  return pos


func _get_flat_rotation(angle: float) -> Quaternion:
  return Basis.IDENTITY.rotated(Vector3.UP, angle).get_rotation_quaternion()


func _get_rotation_tunnel_rotation(row: int) -> Quaternion:
  var basis := Basis.IDENTITY
  basis = basis.rotated(Vector3.RIGHT, -PI * 0.26)
  basis = basis.rotated(Vector3.BACK, float(row) * PI * 0.11)
  basis = basis.rotated(Vector3.UP, float(row) * PI * 0.08)
  return basis.get_rotation_quaternion()


func _get_column_pos(column: int, row: int) -> Vector3:
  if _is_rotation_column(column):
    return _get_rotation_tunnel_pos(column, row)
  return _get_axes_pos(column, row)


func _get_column_rotation(column: int, row: int) -> Quaternion:
  if _is_rotation_column(column):
    return _get_rotation_tunnel_rotation(row)
  return _get_flat_rotation(0.0)


func _get_column_length(column: int, row: int) -> float:
  if column == 0 or column == 3:
    return LENGTH_VALUES[row]
  if _is_rotation_column(column):
    return ROTATION_TUNNEL_LENGTH * (1.0 - float(row) * ROTATION_TUNNEL_SCALE_STEP)
  return AXES_LENGTH


func _get_axes_x_bounds(column: int, row: int) -> Vector2:
  var pos := _get_column_pos(column, row)
  var basis := Basis(_get_column_rotation(column, row).normalized())
  var length := _get_column_length(column, row)
  var min_x := pos.x
  var max_x := pos.x
  for point in [pos + basis.x * length, pos + basis.y * length, pos + basis.z * length]:
    min_x = minf(min_x, point.x)
    max_x = maxf(max_x, point.x)
  return Vector2(min_x, max_x)


func _is_rotation_column(column: int) -> bool:
  return column == 2 or column == 5
