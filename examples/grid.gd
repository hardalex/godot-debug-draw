extends Node3D
## Grid example scene: curated debug grid parameter samples on the XZ plane.

const DESIGN_WIDTH := 1280
const DESIGN_HEIGHT := 720
const GRID_Y := 0.06
const GRID_BASE_LINE_WIDTH := 2.0
const GRID_CELL_COUNT := Vector2i(6, 4)
const GRID_SPACING := Vector2(0.28, 0.28)
const SAMPLE_START_Z := -0.45
const COLUMN_GAP := 1.0
const LABEL_Y := GRID_Y + 0.01
const TITLE_Z := 0.35
const SAMPLE_LABEL_GAP := 0.12
const SAMPLE_SPACING_GAP := 0.55
const LABEL_FONT_SIZE := 20
const TITLE_LABEL_FONT_SIZE := 28
const LABEL_PIXEL_SIZE := 0.004
const WIDTH_VALUES := [1.0, 2.0, 5.5, 10.0]
const CELL_COUNT_VALUES := [Vector2i(4, 4), Vector2i(6, 4), Vector2i(10, 3), Vector2i(3, 8)]
const SPACING_VALUES := [Vector2(0.20, 0.20), Vector2(0.28, 0.28), Vector2(0.42, 0.22), Vector2(0.55, 0.28)]
const SKEW_VALUES := [Vector2.ZERO, Vector2(0.28, 0.0), Vector2(-0.28, 0.0), Vector2(0.28, -0.18)]
const OUTER_EDGE_VALUES := [
  DebugDraw3D.GridOuterEdges.NONE,
  DebugDraw3D.GridOuterEdges.X,
  DebugDraw3D.GridOuterEdges.Z,
  DebugDraw3D.GridOuterEdges.XZ,
]
const ROTATION_SAMPLE_COUNT := 6
const COLOR_SAMPLE_COUNT := 4
const NORMAL_SAMPLE_COUNT := 4

var _last_info_text := ""

@onready var _free_camera: FreeCamera = $FreeCamera
@onready var _debug_draw: DebugDraw3D = $DebugDraw3D
@onready var _info_label: Label = $UI/InfoLabel


func _ready() -> void:
  _debug_draw.depth_bias = -0.001
  _debug_draw.line_width = GRID_BASE_LINE_WIDTH
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
  _draw_cell_samples(1)
  _draw_spacing_samples(2)
  _draw_skew_samples(3)
  _draw_outer_samples(4)
  _draw_rotation_samples(5)
  _draw_color_samples(6)
  _draw_normal_samples(7)


func _draw_width_samples(column: int) -> void:
  for row in WIDTH_VALUES.size():
    _draw_grid_sample(column, row, Color.WHITE, WIDTH_VALUES[row])


func _draw_cell_samples(column: int) -> void:
  for row in CELL_COUNT_VALUES.size():
    _draw_grid_sample(column, row, Color(0.15, 0.85, 1.0, 0.95), GRID_BASE_LINE_WIDTH)


func _draw_spacing_samples(column: int) -> void:
  for row in SPACING_VALUES.size():
    _draw_grid_sample(column, row, Color(0.7, 1.0, 0.25, 1.0), GRID_BASE_LINE_WIDTH)


func _draw_skew_samples(column: int) -> void:
  for row in SKEW_VALUES.size():
    _draw_grid_sample(column, row, Color(1.0, 0.45, 0.2, 1.0), GRID_BASE_LINE_WIDTH)


func _draw_outer_samples(column: int) -> void:
  for row in OUTER_EDGE_VALUES.size():
    _draw_grid_sample(column, row, Color(1.0, 0.7, 0.2, 1.0), GRID_BASE_LINE_WIDTH)


func _draw_rotation_samples(column: int) -> void:
  for row in ROTATION_SAMPLE_COUNT:
    _draw_grid_sample(column, row, Color(0.75, 0.45, 1.0, 1.0 - float(row) * 0.08), GRID_BASE_LINE_WIDTH)


func _draw_color_samples(column: int) -> void:
  for row in COLOR_SAMPLE_COUNT:
    _draw_grid_sample(column, row, _get_color_sample_color(row), GRID_BASE_LINE_WIDTH)


func _draw_normal_samples(column: int) -> void:
  for row in NORMAL_SAMPLE_COUNT:
    _draw_grid_normal_sample(column, row, _get_normal_sample_color(row), _get_normal_sample_width(row))


func _draw_grid_sample(column: int, row: int, color: Color, line_width: float) -> void:
  _debug_draw.draw_grid(
    _get_grid_center(column, row),
    _get_grid_rotation(column, row),
    _get_cell_count(column, row),
    _get_spacing(column, row),
    color,
    line_width,
    DebugDraw3D.DEFAULT_LAYER,
    _get_outer_edges(column, row),
    _get_skew(column, row),
  )


func _draw_grid_normal_sample(column: int, row: int, color: Color, line_width: float) -> void:
  _debug_draw.draw_grid_n(
    _get_grid_center(column, row),
    _get_grid_rotation(column, row),
    _get_cell_count(column, row),
    _get_spacing(column, row),
    color,
    line_width,
    DebugDraw3D.DEFAULT_LAYER,
    _get_outer_edges(column, row),
    _get_skew(column, row),
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
  return 8


func _get_column_sample_count(column: int) -> int:
  match column:
    0:
      return WIDTH_VALUES.size()
    1:
      return CELL_COUNT_VALUES.size()
    2:
      return SPACING_VALUES.size()
    3:
      return SKEW_VALUES.size()
    4:
      return OUTER_EDGE_VALUES.size()
    5:
      return ROTATION_SAMPLE_COUNT
    6:
      return COLOR_SAMPLE_COUNT
    7:
      return NORMAL_SAMPLE_COUNT
    _:
      return 0


func _get_column_label(column: int) -> String:
  match column:
    0:
      return "grid(width)"
    1:
      return "grid(cells)"
    2:
      return "grid(spacing)"
    3:
      return "grid(skew)"
    4:
      return "grid(outer)"
    5:
      return "grid(rotation)"
    6:
      return "grid(color)"
    7:
      return "grid_n"
    _:
      return "grid"


func _get_sample_label(column: int, row: int) -> String:
  match column:
    0:
      return "w = %.1f" % WIDTH_VALUES[row]
    1:
      var cells: Vector2i = CELL_COUNT_VALUES[row]
      return "%d x %d" % [cells.x, cells.y]
    2:
      var spacing: Vector2 = SPACING_VALUES[row]
      return "%.2f x %.2f" % [spacing.x, spacing.y]
    3:
      return _get_skew_label(SKEW_VALUES[row])
    4:
      return _get_outer_label(OUTER_EDGE_VALUES[row])
    5:
      return _get_rotation_label(row)
    6:
      return _get_color_label(row)
    7:
      return _get_normal_label(row)
    _:
      return ""


func _get_skew_label(skew: Vector2) -> String:
  if skew == Vector2.ZERO:
    return "none"
  return "%.2f / %.2f" % [skew.x, skew.y]


func _get_outer_label(outer_edges: int) -> String:
  match outer_edges:
    DebugDraw3D.GridOuterEdges.X:
      return "X"
    DebugDraw3D.GridOuterEdges.Z:
      return "Z"
    DebugDraw3D.GridOuterEdges.XZ:
      return "XZ"
    _:
      return "none"


func _get_rotation_label(row: int) -> String:
  return "step %d" % row


func _get_color_label(row: int) -> String:
  match row:
    1:
      return "alpha"
    2:
      return "color"
    3:
      return "blue"
    _:
      return "base"


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
  var x := _get_column_width(0) * 0.5 + 0.5
  for index in column:
    x += _get_column_width(index) * 0.5 + COLUMN_GAP + _get_column_width(index + 1) * 0.5
  return x


func _get_column_width(column: int) -> float:
  var width := 0.0
  for row in _get_column_sample_count(column):
    width = maxf(width, _get_grid_bounds(column, row).size.x)
  return width


func _get_column_label_x(column: int) -> float:
  var min_x := INF
  var max_x := -INF
  for row in _get_column_sample_count(column):
    var bounds := _get_grid_x_bounds(column, row)
    min_x = minf(min_x, bounds.x)
    max_x = maxf(max_x, bounds.y)
  return (min_x + max_x) * 0.5


func _get_sample_label_position(column: int, row: int) -> Vector3:
  return Vector3(_get_grid_x_bounds(column, row).x - SAMPLE_LABEL_GAP, LABEL_Y, _get_grid_center(column, row).z)


func _get_grid_center(column: int, row: int) -> Vector3:
  return Vector3(_get_column_x(column), GRID_Y, _get_row_z(column, row))


func _get_row_z(column: int, row: int) -> float:
  var z := SAMPLE_START_Z
  for index in row:
    z -= _get_grid_z_size(column, index) + SAMPLE_SPACING_GAP
  return z


func _get_cell_count(column: int, row: int) -> Vector2i:
  if column == 1:
    return CELL_COUNT_VALUES[row]
  return GRID_CELL_COUNT


func _get_spacing(column: int, row: int) -> Vector2:
  if column == 2:
    return SPACING_VALUES[row]
  return GRID_SPACING


func _get_skew(column: int, row: int) -> Vector2:
  if column == 3:
    return SKEW_VALUES[row]
  return Vector2.ZERO


func _get_outer_edges(column: int, row: int) -> int:
  if column == 4:
    return OUTER_EDGE_VALUES[row]
  return DebugDraw3D.GridOuterEdges.NONE


func _get_grid_rotation(column: int, row: int) -> Quaternion:
  if column != 5:
    return Quaternion.IDENTITY

  var basis := Basis.IDENTITY
  basis = basis.rotated(Vector3.UP, float(row) * PI * 0.07)
  basis = basis.rotated(Vector3.RIGHT, -float(row) * PI * 0.035)
  return basis.get_rotation_quaternion()


func _get_grid_x_bounds(column: int, row: int) -> Vector2:
  var bounds := _get_grid_bounds(column, row)
  var center := _get_grid_center(column, row)
  return Vector2(center.x + bounds.position.x, center.x + bounds.position.x + bounds.size.x)


func _get_grid_z_size(column: int, row: int) -> float:
  return _get_grid_bounds(column, row).size.y


func _get_grid_bounds(column: int, row: int) -> Rect2:
  var cell_count := _get_cell_count(column, row)
  var spacing := _get_spacing(column, row)
  var skew := _get_skew(column, row)
  var skew_tan := Vector2(tan(skew.x), tan(skew.y))
  var dx := Vector3(spacing.x, 0.0, spacing.x * skew_tan.y)
  var dz := Vector3(spacing.y * skew_tan.x, 0.0, spacing.y)
  var grid_start := -dx * float(cell_count.x) * 0.5 - dz * float(cell_count.y) * 0.5
  var basis := Basis(_get_grid_rotation(column, row))
  var corners := [
    grid_start,
    grid_start + dx * float(cell_count.x),
    grid_start + dz * float(cell_count.y),
    grid_start + dx * float(cell_count.x) + dz * float(cell_count.y),
  ]
  var first_corner: Vector3 = basis * corners[0]
  var min_x := first_corner.x
  var max_x := first_corner.x
  var min_z := first_corner.z
  var max_z := first_corner.z

  for index in range(1, corners.size()):
    var corner: Vector3 = basis * corners[index]
    min_x = minf(min_x, corner.x)
    max_x = maxf(max_x, corner.x)
    min_z = minf(min_z, corner.z)
    max_z = maxf(max_z, corner.z)

  return Rect2(Vector2(min_x, min_z), Vector2(max_x - min_x, max_z - min_z))


func _get_color_sample_color(row: int) -> Color:
  match row:
    1:
      return Color(1.0, 0.85, 0.1, 0.35)
    2:
      return Color(1.0, 0.45, 0.2, 1.0)
    3:
      return Color(0.25, 0.6, 1.0, 1.0)
    _:
      return Color.WHITE


func _get_normal_sample_color(row: int) -> Color:
  if row == 1:
    return Color(0.25, 0.95, 0.9, 0.35)
  if row == 2:
    return Color(1.0, 0.45, 0.2, 1.0)
  return Color(0.25, 0.95, 0.9, 1.0)


func _get_normal_sample_width(row: int) -> float:
  if row == 3:
    return 10.0
  return GRID_BASE_LINE_WIDTH
